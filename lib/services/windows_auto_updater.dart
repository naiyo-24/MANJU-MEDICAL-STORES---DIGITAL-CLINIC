import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

  Future<void> _startUpdate() async {
    if (widget.updateInfo.manifest == null) return;

    setState(() {
      _isDownloading = true;
      _statusText = 'Connecting to update server...';
      _errorMessage = null;
    });

    try {
      final packageFile = await widget.service.downloadPackage(
        widget.updateInfo.manifest!,
        onProgress: (p) {
          if (mounted) {
            setState(() {
              _progress = p;
              final percent = (p * 100).toStringAsFixed(0);
              _statusText = 'Downloading package ($percent%)...';
            });
          }
        },
        onStatusLog: (logMsg) {
          debugPrint('[Updater] $logMsg');
          // Only show friendly user messages, keep raw internal/GitHub logs hidden
          if (mounted && _isDownloading) {
            if (logMsg.contains('Verifying')) {
              setState(() => _statusText = 'Verifying package integrity...');
            } else if (logMsg.contains('handing over') || logMsg.contains('Launching')) {
              setState(() => _statusText = 'Restarting SirfBill to apply update...');
            }
          }
        },
      );

      if (mounted) {
        setState(() => _statusText = 'Preparing restart...');
      }

      await Future.delayed(const Duration(milliseconds: 600));
      await widget.service.startUpdater(
        packageFile,
        targetVersion: widget.updateInfo.version,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          // Sanitize raw URLs or internal system details from customer display
          final rawMsg = e.toString().replaceFirst('Exception: ', '');
          if (rawMsg.contains('github') || rawMsg.contains('SocketException') || rawMsg.contains('Failed host lookup')) {
            _errorMessage = 'Could not reach update server. Please check your internet connection and try again.';
          } else {
            _errorMessage = rawMsg;
          }
        });
      }
    }
  }

  String _sanitizeReleaseNotes(String rawNotes) {
    if (rawNotes.trim().isEmpty) {
      return 'Performance improvements, stability enhancements, and operational updates.';
    }

    // Strip out GitHub URLs, changelog comparisons, and commit hashes
    final cleaned = rawNotes
        .replaceAll(RegExp(r'\*\*Full Changelog\*\*:\s*https?://[^\s]+', caseSensitive: false), '')
        .replaceAll(RegExp(r'https?://(?:www\.)?github\.com/[^\s]+', caseSensitive: false), '')
        .replaceAll(RegExp(r'@[\w-]+', caseSensitive: false), '')
        .trim();

    if (cleaned.isEmpty || cleaned.length < 5) {
      return 'Performance improvements, stability enhancements, and operational updates.';
    }

    return cleaned;
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
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_isDownloading && _errorMessage == null) ...[
              Text(
                'A new update is ready for installation. Would you like to update now?',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey[300] : const Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 12),
              Builder(
                builder: (context) {
                  final displayNotes = _sanitizeReleaseNotes(widget.updateInfo.releaseNotes);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'What\'s New:',
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
                          displayNotes,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: isDark ? Colors.grey[300] : const Color(0xFF334155),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ] else if (_isDownloading) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: _progress > 0 ? _progress : null,
                  minHeight: 8,
                  backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(primaryColor),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _statusText.isNotEmpty ? _statusText : 'Updating application...',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.grey[200] : const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  if (_progress > 0)
                    Text(
                      '${(_progress * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'SirfBill will restart automatically once the update is complete.',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? Colors.red.shade700 : const Color(0xFFFCA5A5),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      color: isDark ? Colors.white : const Color(0xFFDC2626),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white : const Color(0xFF991B1B),
                          height: 1.4,
                        ),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: _startUpdate,
            child: Text(_errorMessage != null ? 'Retry' : 'Update Now'),
          ),
        ],
      ],
    );
  }
}
