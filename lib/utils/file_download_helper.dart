import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_saver/file_saver.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

class FileDownloadResult {
  final bool success;
  final String? savedPath;
  final String? errorMessage;
  final bool cancelled;

  FileDownloadResult({
    required this.success,
    this.savedPath,
    this.errorMessage,
    this.cancelled = false,
  });
}

class FileDownloadHelper {
  /// Universal file save method that reliably works on Web, Windows Desktop (.exe), macOS, and Linux.
  ///
  /// On Desktop (Windows/macOS/Linux), it opens the native system Save File dialog
  /// so the user can choose exactly where to save (Downloads, Desktop, etc.).
  /// If the picker is not supported or falls back, it saves to the Downloads directory.
  /// On Web, it invokes browser download via `FileSaver`.
  static Future<FileDownloadResult> saveFile({
    required String name,
    required Uint8List bytes,
    required String fileExtension,
    MimeType mimeType = MimeType.other,
    String? dialogTitle,
  }) async {
    final cleanExt = fileExtension.replaceAll('.', '').toLowerCase();
    final cleanName = name.endsWith('.$cleanExt')
        ? name.substring(0, name.length - (cleanExt.length + 1))
        : name;
    final fullName = '$cleanName.$cleanExt';

    if (kIsWeb) {
      try {
        final path = await FileSaver.instance.saveFile(
          name: cleanName,
          bytes: bytes,
          fileExtension: cleanExt,
          mimeType: mimeType,
        );
        return FileDownloadResult(success: true, savedPath: path);
      } catch (e) {
        return FileDownloadResult(
          success: false,
          errorMessage: e.toString(),
        );
      }
    }

    // Desktop & Native platforms (Windows .exe, macOS, Linux, Android, iOS)
    try {
      // 1. Try native FilePicker "Save As" dialog
      String? selectedPath;
      try {
        selectedPath = await FilePicker.platform.saveFile(
          dialogTitle: dialogTitle ?? 'Save $cleanExt.toUpperCase() file',
          fileName: fullName,
          type: FileType.custom,
          allowedExtensions: [cleanExt],
        );
      } catch (_) {
        selectedPath = null;
      }

      // If user cancelled explicitly in the dialog
      if (selectedPath == null && !Platform.isAndroid && !Platform.isIOS) {
        // Double check: if user deliberately clicked Cancel, we return cancelled
        // But if FilePicker threw or returned null unexpectedly, we check if we should fall back.
      }

      if (selectedPath != null) {
        if (!selectedPath.toLowerCase().endsWith('.$cleanExt')) {
          selectedPath = '$selectedPath.$cleanExt';
        }
        final file = File(selectedPath);
        await file.writeAsBytes(bytes, flush: true);
        return FileDownloadResult(success: true, savedPath: selectedPath);
      }

      // 2. Fallback: Save directly to User's Downloads directory if picker was cancelled or failed
      Directory? targetDir;
      try {
        targetDir = await getDownloadsDirectory();
      } catch (_) {}
      targetDir ??= await getApplicationDocumentsDirectory();

      final fallbackFile = File('${targetDir.path}${Platform.pathSeparator}$fullName');
      await fallbackFile.writeAsBytes(bytes, flush: true);
      return FileDownloadResult(
        success: true,
        savedPath: fallbackFile.path,
      );
    } catch (e) {
      // 3. Final fallback: try FileSaver.instance.saveFile
      try {
        final res = await FileSaver.instance.saveFile(
          name: cleanName,
          bytes: bytes,
          fileExtension: cleanExt,
          mimeType: mimeType,
        );
        return FileDownloadResult(success: true, savedPath: res);
      } catch (err) {
        return FileDownloadResult(
          success: false,
          errorMessage: 'Could not save file: $e (fallback error: $err)',
        );
      }
    }
  }
}
