using System;
using System.Diagnostics;
using System.IO;
using System.IO.Compression;
using System.Threading;

namespace AppUpdater
{
    internal class Program
    {
        private static int _waitPid = 0;
        private static string _installDir = "";
        private static string _packagePath = "";
        private static string _restartExe = "";
        private static string _logFile = "";

        static void Main(string[] args)
        {
            ParseArgs(args);

            string localAppData = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
            string logDir = Path.Combine(localAppData, "SirfBill", "logs");
            Directory.CreateDirectory(logDir);
            _logFile = Path.Combine(logDir, "updater.log");

            Log($"--- Updater started at {DateTime.Now:yyyy-MM-dd HH:mm:ss} ---");
            Log($"PID: {Environment.ProcessId}");
            Log($"WaitPid: {_waitPid}, InstallDir: '{_installDir}', Package: '{_packagePath}', RestartExe: '{_restartExe}'");

            if (string.IsNullOrWhiteSpace(_installDir) || !Directory.Exists(_installDir))
            {
                Log("Error: Install directory invalid or missing.");
                return;
            }

            if (string.IsNullOrWhiteSpace(_packagePath) || !File.Exists(_packagePath))
            {
                Log("Error: Package file missing.");
                return;
            }

            // Step 1: Wait for parent app process to exit
            if (_waitPid > 0)
            {
                Log($"Waiting for process {_waitPid} to exit...");
                try
                {
                    var proc = Process.GetProcessById(_waitPid);
                    if (!proc.WaitForExit(15000))
                    {
                        Log("Process did not exit cleanly within 15s. Terminating forcefully...");
                        proc.Kill(true);
                        proc.WaitForExit(5000);
                    }
                }
                catch (ArgumentException)
                {
                    Log($"Process {_waitPid} already terminated.");
                }
                catch (Exception ex)
                {
                    Log($"Note waiting for process: {ex.Message}");
                }
            }

            // Also check for any lingering SirfBill child instances that may hold file locks
            try
            {
                var siblings = Process.GetProcessesByName("SirfBill");
                foreach (var p in siblings)
                {
                    try
                    {
                        if (!p.HasExited)
                        {
                            Log($"Killing lingering process: {p.ProcessName} (PID {p.Id})");
                            p.Kill(true);
                            p.WaitForExit(3000);
                        }
                    }
                    catch { }
                }
            }
            catch { }

            // Generous cooldown for Windows OS and GPU drivers to release file handles
            Log("Waiting 3.5 seconds for Windows file system locks to release...");
            Thread.Sleep(3500);

            string stagingDir = Path.Combine(Path.GetTempPath(), "SirfBill_Update_Staging_" + Guid.NewGuid().ToString("N"));
            string backupDir = Path.Combine(_installDir, "_backup_prev_version");

            try
            {
                // Step 2: Extract to staging folder to validate ZIP integrity
                Log($"Extracting package to staging: {stagingDir}");
                Directory.CreateDirectory(stagingDir);
                ZipFile.ExtractToDirectory(_packagePath, stagingDir, true);

                // If the zip contains a single root folder (e.g., Release or bundle), locate source directory
                string sourceDir = stagingDir;
                var subDirs = Directory.GetDirectories(stagingDir);
                var subFiles = Directory.GetFiles(stagingDir);
                if (subDirs.Length == 1 && subFiles.Length == 0)
                {
                    sourceDir = subDirs[0];
                }

                // Step 3: Create backup of current files
                Log($"Backing up current installation to {backupDir}");
                if (Directory.Exists(backupDir))
                {
                    Directory.Delete(backupDir, true);
                }
                Directory.CreateDirectory(backupDir);

                // Step 4: Copy new files over installation directory
                Log($"Copying updated files from {sourceDir} to {_installDir}");
                CopyDirectory(sourceDir, _installDir, backupDir);

                Log("Update successfully applied!");

                // Clean staging
                try { Directory.Delete(stagingDir, true); } catch { }
                try { File.Delete(_packagePath); } catch { }

                // Step 5: Launch updated app
                if (!string.IsNullOrWhiteSpace(_restartExe) && File.Exists(_restartExe))
                {
                    Log($"Launching updated executable: {_restartExe}");
                    var startInfo = new ProcessStartInfo
                    {
                        FileName = _restartExe,
                        WorkingDirectory = _installDir,
                        UseShellExecute = true
                    };
                    Process.Start(startInfo);
                }

                // Clean backup folder on success
                try
                {
                    if (Directory.Exists(backupDir))
                    {
                        Directory.Delete(backupDir, true);
                    }
                }
                catch { }

                Log("Updater completed successfully.");
            }
            catch (Exception ex)
            {
                Log($"CRITICAL UPDATE ERROR: {ex}");

                // Step 6: Rollback if backup exists
                if (Directory.Exists(backupDir))
                {
                    Log("Attempting rollback from backup directory...");
                    try
                    {
                        CopyDirectory(backupDir, _installDir, null);
                        Log("Rollback restored successfully.");

                        if (!string.IsNullOrWhiteSpace(_restartExe) && File.Exists(_restartExe))
                        {
                            Process.Start(new ProcessStartInfo
                            {
                                FileName = _restartExe,
                                WorkingDirectory = _installDir,
                                UseShellExecute = true
                            });
                        }
                    }
                    catch (Exception rbEx)
                    {
                        Log($"Rollback failed: {rbEx.Message}");
                    }
                }
            }
        }

        private static void CopyDirectory(string source, string destination, string? backup)
        {
            Directory.CreateDirectory(destination);

            // Ensure backup directory exists if backing up
            if (backup != null)
            {
                Directory.CreateDirectory(backup);
            }

            foreach (var file in Directory.GetFiles(source))
            {
                string fileName = Path.GetFileName(file);
                string destFile = Path.Combine(destination, fileName);

                // Preserve backup if provided
                if (backup != null && File.Exists(destFile))
                {
                    string backupFile = Path.Combine(backup, fileName);
                    File.Copy(destFile, backupFile, true);
                }

                // Do not overwrite updater if it's currently running
                if (string.Equals(fileName, "updater.exe", StringComparison.OrdinalIgnoreCase))
                {
                    continue;
                }

                // Copy with up to 25 retries (with backoff) in case Windows file locks linger
                bool copied = false;
                Exception? lastEx = null;
                for (int attempt = 1; attempt <= 25; attempt++)
                {
                    try
                    {
                        File.Copy(file, destFile, true);
                        copied = true;
                        break;
                    }
                    catch (IOException ioEx)
                    {
                        lastEx = ioEx;
                        Log($"[Attempt {attempt}/25] File locked: {fileName}, retrying in 400ms...");
                        Thread.Sleep(400);
                    }
                    catch (UnauthorizedAccessException uaEx)
                    {
                        lastEx = uaEx;
                        Log($"[Attempt {attempt}/25] Access denied: {fileName}, retrying in 500ms...");
                        Thread.Sleep(500);
                    }
                }

                if (!copied && lastEx != null)
                {
                    Log($"Failed to copy file '{fileName}' after 25 attempts: {lastEx.Message}");
                    throw lastEx;
                }
            }

            foreach (var dir in Directory.GetDirectories(source))
            {
                string dirName = Path.GetFileName(dir);
                if (dirName.Equals("_backup_prev_version", StringComparison.OrdinalIgnoreCase))
                {
                    continue;
                }

                string destSubDir = Path.Combine(destination, dirName);
                string? backupSubDir = backup != null ? Path.Combine(backup, dirName) : null;

                CopyDirectory(dir, destSubDir, backupSubDir);
            }
        }

        private static void ParseArgs(string[] args)
        {
            for (int i = 0; i < args.Length; i++)
            {
                if (args[i] == "--wait-pid" && i + 1 < args.Length)
                {
                    int.TryParse(args[++i], out _waitPid);
                }
                else if (args[i] == "--install-dir" && i + 1 < args.Length)
                {
                    _installDir = args[++i];
                }
                else if (args[i] == "--package" && i + 1 < args.Length)
                {
                    _packagePath = args[++i];
                }
                else if (args[i] == "--restart-exe" && i + 1 < args.Length)
                {
                    _restartExe = args[++i];
                }
            }
        }

        private static void Log(string message)
        {
            try
            {
                Console.WriteLine(message);
                if (!string.IsNullOrWhiteSpace(_logFile))
                {
                    File.AppendAllText(_logFile, $"[{DateTime.Now:HH:mm:ss}] {message}{Environment.NewLine}");
                }
            }
            catch { }
        }
    }
}
