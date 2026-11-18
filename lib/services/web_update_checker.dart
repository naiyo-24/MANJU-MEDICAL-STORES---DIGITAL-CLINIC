import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

// Conditional web import for reloading window cleanly on web
import 'web_reload_stub.dart'
    if (dart.library.js_interop) 'web_reload_web.dart';

class WebUpdateChecker {
  static Timer? _periodicTimer;
  static bool _updatePromptShown = false;

  /// Starts periodic background checking for web deployments (checks every 15 minutes)
  static void startPeriodicCheck({
    Duration interval = const Duration(minutes: 15),
    void Function(String newVersion)? onNewVersionAvailable,
  }) {
    if (!kIsWeb) return;

    // Check once after initial 30 seconds
    Timer(const Duration(seconds: 30), () {
      checkForUpdate(onNewVersionAvailable: onNewVersionAvailable);
    });

    // Then periodically
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(interval, (_) {
      checkForUpdate(onNewVersionAvailable: onNewVersionAvailable);
    });
  }

  /// Manually trigger a check against /version.json
  static Future<bool> checkForUpdate({
    void Function(String newVersion)? onNewVersionAvailable,
  }) async {
    if (!kIsWeb) return false;

    try {
      // Append high-entropy timestamp to bypass any browser/CDN caching
      final uri = Uri.parse('/version.json?t=${DateTime.now().millisecondsSinceEpoch}');
      final response = await http.get(uri).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final serverVersion = data['version']?.toString();
        final serverBuild = data['build_number']?.toString();

        if (serverVersion == null && serverBuild == null) return false;

        final packageInfo = await PackageInfo.fromPlatform();
        final localVersion = packageInfo.version;
        final localBuild = packageInfo.buildNumber;

        final hasNewVersion = (serverVersion != null && serverVersion != localVersion) ||
            (serverBuild != null && serverBuild != localBuild);

        if (hasNewVersion && !_updatePromptShown) {
          _updatePromptShown = true;
          final newVer = serverVersion ?? serverBuild ?? 'latest';
          debugPrint('WebUpdateChecker: New version detected on server ($newVer vs current $localVersion+$localBuild)');

          if (onNewVersionAvailable != null) {
            onNewVersionAvailable(newVer);
          } else {
            // Default behavior: trigger clean page reload
            reloadApp();
          }
          return true;
        }
      }
    } catch (e) {
      debugPrint('WebUpdateChecker error: $e');
    }
    return false;
  }

  /// Cleanly reload the web application
  static void reloadApp() {
    if (kIsWeb) {
      performWebReload();
    }
  }

  static void stopPeriodicCheck() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }
}
