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

  /// Default GitHub repository manifest URL for SirfBill / Manju Medical Stores
  static const String defaultManifestUrl =
      'https://raw.githubusercontent.com/naiyo-24/MANJU-MEDICAL-STORES---DIGITAL-CLINIC/main/release/latest.json';

  /// Fetches the manifest, parses versions, and returns UpdateManifest if an update is available.
  Future<UpdateManifest?> checkForUpdate() async {
    if (kIsWeb || !Platform.isWindows) {
      return null;
    }

    final uri = Uri.parse(manifestUrl);
    if (uri.scheme != 'https') {
      throw Exception('HTTPS update URL required.');
    }

    final response = await http.get(uri).timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('Update check failed: HTTP ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final manifest = UpdateManifest.fromJson(data);

    final info = await PackageInfo.fromPlatform();
    final cleanCurrentVersion = info.version.split('+').first;
    final cleanLatestVersion = manifest.version.split('+').first;

    final current = Version.parse(cleanCurrentVersion);
    final latest = Version.parse(cleanLatestVersion);

    if (latest <= current) {
      return null;
    }

    final packageUri = Uri.parse(manifest.packageUrl);
    if (packageUri.scheme != 'https') {
      throw Exception('Invalid package URL: HTTPS scheme required.');
    }

    if (!RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(manifest.sha256)) {
      throw Exception('Invalid SHA-256 value in update manifest.');
    }

    return manifest;
  }

  /// Downloads the update package with download progress stream/callback and verifies SHA-256 hash.
  Future<File> downloadPackage(
    UpdateManifest manifest, {
    void Function(double progress)? onProgress,
  }) async {
    final uri = Uri.parse(manifest.packageUrl);
    final request = http.Request('GET', uri);
    final streamedResponse = await request.send().timeout(const Duration(minutes: 5));

    if (streamedResponse.statusCode != 200) {
      throw Exception('Package download failed: HTTP ${streamedResponse.statusCode}');
    }

    final totalBytes = streamedResponse.contentLength ?? 0;
    int receivedBytes = 0;

    final temp = await getTemporaryDirectory();
    final updateFile = File('${temp.path}${Platform.pathSeparator}app-update.zip');
    if (await updateFile.exists()) {
      await updateFile.delete();
    }

    final sink = updateFile.openWrite();

    await for (final chunk in streamedResponse.stream) {
      sink.add(chunk);
      receivedBytes += chunk.length;
      if (totalBytes > 0 && onProgress != null) {
        onProgress(receivedBytes / totalBytes);
      }
    }
    await sink.flush();
    await sink.close();

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

    return updateFile;
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

    // Give process brief moment to detach, then exit Flutter app cleanly
    exit(0);
  }
}
