import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'update_service.dart';

class UpdateInfo {
  final String version;
  final String releaseNotes;
  final String downloadUrl;
  final String sha256;
  final UpdateManifest? manifest;

  UpdateInfo({
    required this.version,
    required this.releaseNotes,
    required this.downloadUrl,
    required this.sha256,
    this.manifest,
  });
}

class UpdateCheckResult {
  final bool isAvailable;
  final UpdateInfo? updateInfo;
  final String message;
  final bool isError;

  UpdateCheckResult({
    required this.isAvailable,
    this.updateInfo,
    required this.message,
    this.isError = false,
  });
}

class WindowsAutoUpdater {
  static final UpdateService _service = UpdateService(
    manifestUrl: UpdateService.defaultManifestUrl,
  );

  /// Check whether an update is available on Windows
  static Future<UpdateCheckResult> checkForUpdateDetailed() async {
    if (kIsWeb || !Platform.isWindows) {
      final info = await PackageInfo.fromPlatform().catchError((_) => PackageInfo(
        appName: 'SirfBill',
        packageName: '',
        version: '1.0.20',
        buildNumber: '20',
      ));
      return UpdateCheckResult(
        isAvailable: false,
        message: 'Auto-update is active on the installed Windows Desktop app (.exe). Current version: v${info.version}',
      );
    }

    try {
      final manifest = await _service.checkForUpdate();
      if (manifest == null) {
        final info = await PackageInfo.fromPlatform();
        return UpdateCheckResult(
          isAvailable: false,
          message: 'SirfBill is already up to date! (v${info.version})',
        );
      }

      final updateInfo = UpdateInfo(
        version: manifest.version,
        releaseNotes: manifest.releaseNotes,
        downloadUrl: manifest.packageUrl,
        sha256: manifest.sha256,
        manifest: manifest,
      );

      return UpdateCheckResult(
        isAvailable: true,
        updateInfo: updateInfo,
        message: 'A new update (v${manifest.version}) is available!',
      );
    } catch (e, stack) {
      debugPrint('[WindowsAutoUpdater] Error checking for updates: $e\n$stack');
      return UpdateCheckResult(
        isAvailable: false,
        isError: true,
        message: 'Could not connect to update server. Please check your internet connection.',
      );
    }
  }

  /// Check whether an update is available on Windows (convenience method)
  static Future<UpdateInfo?> checkForUpdate() async {
    final result = await checkForUpdateDetailed();
    return result.updateInfo;
  }

  /// Show the interactive update confirmation, download progress dialog, and updater launcher
  static void showUpdateDialog(BuildContext context, UpdateInfo updateInfo) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => _UpdateDownloadDialog(
        updateInfo: updateInfo,
        service: _service,
      ),
    );
  }
}

class _UpdateDownloadDialog extends StatefulWidget {
  final UpdateInfo updateInfo;
  final UpdateService service;

  const _UpdateDownloadDialog({
    required this.updateInfo,
    required this.service,
  });

  @override
  State<_UpdateDownloadDialog> createState() => _UpdateDownloadDialogState();
}

class _UpdateDownloadDialogState extends State<_UpdateDownloadDialog> {
  bool _isDownloading = false;
  double _progress = 0.0;
  String _statusText = '';
  String? _errorMessage;
  final List<String> _consoleLogs = [];
  final ScrollController _logScrollController = ScrollController();

  void _addLog(String message) {
    if (!mounted) return;
    setState(() {
      final time = TimeOfDay.now().format(context);
      _consoleLogs.add('[$time] $message');
      _statusText = message;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_logScrollController.hasClients) {
        _logScrollController.jumpTo(_logScrollController.position.maxScrollExtent);
      }
    });
  }

  Future<void> _startUpdate() async {
    if (widget.updateInfo.manifest == null) return;

    setState(() {
      _isDownloading = true;
      _statusText = 'Starting update process...';
      _errorMessage = null;
      _consoleLogs.clear();
    });

    _addLog('Target version: v${widget.updateInfo.version}');
    _addLog('Package URL: ${widget.updateInfo.downloadUrl}');

    try {
      final packageFile = await widget.service.downloadPackage(
        widget.updateInfo.manifest!,
        onProgress: (p) {
          if (mounted) {
            setState(() {
              _progress = p;
            });
          }
        },
        onStatusLog: (logMsg) {
          _addLog(logMsg);
        },
      );

      _addLog('Package downloaded successfully: ${packageFile.path}');
      _addLog('Detaching application and handing over to updater.exe...');

      await Future.delayed(const Duration(milliseconds: 600));
      await widget.service.startUpdater(
        packageFile,
        targetVersion: widget.updateInfo.version,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
        _addLog('ERROR: $_errorMessage');
      }
    }
  }

  @override
  void dispose() {
    _logScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryColor = Color(0xFF166534);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.system_update_rounded, color: primaryColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'New Version Available (${widget.updateInfo.version})',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_isDownloading && _errorMessage == null) ...[
              Text(
                'A new update is available. Do you want to download and install it now?',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey[300] : const Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 12),
              if (widget.updateInfo.releaseNotes.isNotEmpty) ...[
                const Text(
                  'Release Notes:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.updateInfo.releaseNotes,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: isDark ? Colors.grey[300] : const Color(0xFF334155),
                    ),
                  ),
                ),
              ],
            ] else if (_isDownloading) ...[
              LinearProgressIndicator(
                value: _progress > 0 ? _progress : null,
                backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(primaryColor),
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _statusText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.grey[300] : const Color(0xFF334155),
                      ),
                    ),
                  ),
                  if (_progress > 0)
                    Text(
                      '${(_progress * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              // Live On-Screen Diagnostic Terminal
              Container(
                height: 110,
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white12),
                ),
                child: ListView.builder(
                  controller: _logScrollController,
                  itemCount: _consoleLogs.length,
                  itemBuilder: (ctx, idx) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      _consoleLogs[idx],
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: Color(0xFF4ADE80),
                        height: 1.3,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'The application will restart automatically after applying update.',
                style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[500] : Colors.grey[600]),
              ),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFB91C1C), // Matching the red banner in user's image
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Update Error Details:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: _errorMessage!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Error copied to clipboard'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: Row(
                              children: [
                                Icon(Icons.copy_rounded, color: Colors.white, size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'Copy',
                                  style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SelectableText(
                      _errorMessage!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontFamily: 'monospace',
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (!_isDownloading) ...[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              _errorMessage != null ? 'Close' : 'Later',
              style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _startUpdate,
            child: Text(_errorMessage != null ? 'Retry' : 'Update Now'),
          ),
        ],
      ],
    );
  }
}
