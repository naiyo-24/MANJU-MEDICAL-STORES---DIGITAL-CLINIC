import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

class WindowsAutoUpdater {
  static final UpdateService _service = UpdateService(
    manifestUrl: UpdateService.defaultManifestUrl,
  );

  /// Check whether an update is available on Windows
  static Future<UpdateInfo?> checkForUpdate() async {
    if (kIsWeb || !Platform.isWindows) {
      return null;
    }

    try {
      final manifest = await _service.checkForUpdate();
      if (manifest == null) return null;

      return UpdateInfo(
        version: manifest.version,
        releaseNotes: manifest.releaseNotes,
        downloadUrl: manifest.packageUrl,
        sha256: manifest.sha256,
        manifest: manifest,
      );
    } catch (e) {
      if (kDebugMode) {
        print('[WindowsAutoUpdater] Error checking for updates: $e');
      }
      return null;
    }
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
      _statusText = 'Downloading update package...';
      _errorMessage = null;
    });

    try {
      final packageFile = await widget.service.downloadPackage(
        widget.updateInfo.manifest!,
        onProgress: (p) {
          if (mounted) {
            setState(() {
              _progress = p;
              _statusText = 'Downloading update... ${(p * 100).toStringAsFixed(0)}%';
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _statusText = 'Verifying and launching updater...';
        });
      }

      await Future.delayed(const Duration(milliseconds: 600));
      await widget.service.startUpdater(packageFile);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
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
              const SizedBox(height: 14),
              Text(
                _statusText,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey[300] : const Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 6),
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
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(fontSize: 12, color: Colors.red),
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
