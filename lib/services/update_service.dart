import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pub_semver/pub_semver.dart';

class UpdateManifest {
  final String productId;
  final String platform;
  final String channel;
  final String version;
  final bool mandatory;
  final String releaseNotes;
  final String packageUrl;
  final String sha256;

  UpdateManifest({
    required this.productId,
    required this.platform,
    required this.channel,
    required this.version,
    required this.mandatory,
    required this.releaseNotes,
    required this.packageUrl,
    required this.sha256,
  });

  factory UpdateManifest.fromJson(Map<String, dynamic> json) {
    return UpdateManifest(
      productId: json['product_id'] as String? ?? 'SirfBill',
      platform: json['platform'] as String? ?? 'windows-x64',
      channel: json['channel'] as String? ?? 'stable',
      version: json['version'] as String,
      mandatory: json['mandatory'] as bool? ?? false,
      releaseNotes: json['release_notes'] as String? ?? '',
      packageUrl: json['package_url'] as String,
      sha256: (json['sha256'] as String).trim().toLowerCase(),
    );
  }
}

class UpdateService {
  UpdateService({
    required this.manifestUrl,
    this.updaterExecutableName = 'updater.exe',
  });

  final String manifestUrl;
  final String updaterExecutableName;

  /// Default GitHub repository manifest URL for SirfBill
  static const String defaultManifestUrl =
      'https://github.com/naiyo-24/MANJU-MEDICAL-STORES---DIGITAL-CLINIC/releases/latest/download/latest.json';

  /// Fetches releases and returns UpdateManifest if a higher semver version is available.
  Future<UpdateManifest?> checkForUpdate() async {
    if (kIsWeb || !Platform.isWindows) {
      return null;
    }

    final info = await PackageInfo.fromPlatform();
    final cleanCurrentVersion = info.version.split('+').first;
    final current = Version.parse(cleanCurrentVersion);

    UpdateManifest? highestManifest;
    Version highestVersion = current;

    try {
      // 1. First attempt: Query GitHub API for all releases to accurately find highest semver
      final apiUri = Uri.parse(
        'https://api.github.com/repos/naiyo-24/MANJU-MEDICAL-STORES---DIGITAL-CLINIC/releases',
      );
      final apiResp = await http.get(apiUri, headers: {
        'Accept': 'application/vnd.github.v3+json',
        'User-Agent': 'SirfBill-Desktop-App',
      }).timeout(const Duration(seconds: 15));

      if (apiResp.statusCode == 200) {
        final List<dynamic> releases = jsonDecode(apiResp.body);
        for (final release in releases) {
          if (release['draft'] == true || release['prerelease'] == true) {
            continue;
          }
          final tagName = (release['tag_name'] as String? ?? '').replaceFirst('v', '').trim();
          try {
            final releaseVer = Version.parse(tagName.split('+').first);
            if (releaseVer > highestVersion) {
              final assets = release['assets'] as List<dynamic>? ?? [];
              final latestJsonAsset = assets.firstWhere(
                (a) => a['name'] == 'latest.json',
                orElse: () => null,
              );
              if (latestJsonAsset != null) {
                final manifestDownloadUrl = latestJsonAsset['browser_download_url'] as String;
                final manifestResp = await http.get(Uri.parse(manifestDownloadUrl)).timeout(const Duration(seconds: 15));
                if (manifestResp.statusCode == 200) {
                  final data = jsonDecode(manifestResp.body) as Map<String, dynamic>;
                  final manifest = UpdateManifest.fromJson(data);
                  final manifestVer = Version.parse(manifest.version.split('+').first);
                  if (manifestVer > highestVersion) {
                    highestVersion = manifestVer;
                    highestManifest = manifest;
                  }
                }
              }
            }
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('[UpdateService] GitHub releases API query failed: $e, falling back to direct URL.');
    }

    // 2. Fallback: Check defaultManifestUrl directly if GitHub API was unavailable or rate-limited
    if (highestManifest == null) {
      try {
        // Append cache-busting timestamp to prevent intermediate CDN caching of latest.json
        final separator = manifestUrl.contains('?') ? '&' : '?';
        final freshUrl = '$manifestUrl${separator}_t=${DateTime.now().millisecondsSinceEpoch}';
        final uri = Uri.parse(freshUrl);
        final request = http.Request('GET', uri)
          ..followRedirects = true
          ..maxRedirects = 10
          ..headers.addAll({
            'User-Agent': 'SirfBill-Desktop-App',
            'Accept': 'application/json',
            'Cache-Control': 'no-cache, no-store, must-revalidate',
            'Pragma': 'no-cache',
          });
        final streamedResponse = await request.send().timeout(const Duration(seconds: 20));
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final manifest = UpdateManifest.fromJson(data);
          final cleanLatestVersion = manifest.version.split('+').first;
          final latest = Version.parse(cleanLatestVersion);

          if (latest > highestVersion) {
            highestVersion = latest;
            highestManifest = manifest;
          }
        }
      } catch (e) {
        debugPrint('[UpdateService] Fallback manifest check failed: $e');
      }
    }

    debugPrint('[UpdateService] Installed version: $current | Highest detected: $highestVersion');

    if (highestManifest == null || highestVersion <= current) {
      debugPrint('[UpdateService] App is up to date.');
      return null;
    }

    if (!RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(highestManifest.sha256)) {
      throw Exception('Invalid SHA-256 value in update manifest.');
    }

    return highestManifest;
  }

  /// Downloads the update package with download progress stream/callback and verifies SHA-256 hash.
  /// Uses a resilient HTTP client with User-Agent, redirects, and retry logic to prevent dropped CDN connections.
  Future<File> downloadPackage(
    UpdateManifest manifest, {
    void Function(double progress)? onProgress,
  }) async {
    final temp = await getTemporaryDirectory();
    final updateFile = File('${temp.path}${Platform.pathSeparator}app-update.zip');
    
    int maxAttempts = 3;
    Exception? lastError;

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        if (await updateFile.exists()) {
          await updateFile.delete();
        }

        final client = HttpClient();
        client.connectionTimeout = const Duration(seconds: 30);
        client.idleTimeout = const Duration(seconds: 60);

        final request = await client.getUrl(Uri.parse(manifest.packageUrl));
        request.headers.set('User-Agent', 'SirfBill-Desktop-App');
        request.headers.set('Accept', 'application/octet-stream');
        request.headers.set('Connection', 'keep-alive');
        request.followRedirects = true;
        request.maxRedirects = 10;

        final response = await request.close();
        if (response.statusCode != 200) {
          throw Exception('Package download failed with HTTP ${response.statusCode}');
        }

        final totalBytes = response.contentLength;
        int receivedBytes = 0;
        final sink = updateFile.openWrite();

        await for (final chunk in response) {
          sink.add(chunk);
          receivedBytes += chunk.length;
          if (totalBytes > 0 && onProgress != null) {
            onProgress(receivedBytes / totalBytes);
          }
        }
        await sink.flush();
        await sink.close();
        client.close();

        // Verify SHA-256 Digest
        final digest = await sha256.bind(updateFile.openRead()).first;
        final calculatedSha = digest.toString().toLowerCase();

        if (calculatedSha != manifest.sha256) {
          if (await updateFile.exists()) {
            await updateFile.delete();
          }
          throw Exception(
            'SHA-256 verification failed.\nExpected: ${manifest.sha256}\nActual: $calculatedSha',
          );
        }

        // Successfully downloaded and verified
        return updateFile;
      } catch (e) {
        lastError = Exception('Attempt $attempt/$maxAttempts failed: $e');
        debugPrint('[UpdateService] $lastError');
        if (attempt < maxAttempts) {
          await Future.delayed(Duration(seconds: attempt));
        }
      }
    }

    throw lastError ?? Exception('Failed to download update package after $maxAttempts attempts.');
  }

  /// Finds and launches the updater executable, passing arguments, and closes the running Flutter app.
  Future<void> startUpdater(File packageFile) async {
    final appExecutable = File(Platform.resolvedExecutable);
    final installDir = appExecutable.parent;

    // Check updater in install dir
    var updaterFile = File('${installDir.path}${Platform.pathSeparator}$updaterExecutableName');

    if (!await updaterFile.exists()) {
      // Fallback search in updater subfolder
      final subUpdater = File('${installDir.path}${Platform.pathSeparator}updater${Platform.pathSeparator}$updaterExecutableName');
      if (await subUpdater.exists()) {
        updaterFile = subUpdater;
      } else {
        throw Exception('Updater executable not found at ${updaterFile.path}');
      }
    }

    // Launch standalone updater with ProcessStartMode.detached
    await Process.start(
      updaterFile.path,
      [
        '--wait-pid', '$pid',
        '--install-dir', installDir.path,
        '--package', packageFile.path,
        '--restart-exe', appExecutable.path,
      ],
      mode: ProcessStartMode.detached,
    );

    // Give the operating system a moment to register process handover before exiting
    await Future.delayed(const Duration(milliseconds: 500));
    exit(0);
  }
}
