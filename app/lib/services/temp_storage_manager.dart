import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// TempStorageManager — handles all temporary file lifecycle.
///
/// RULES:
///   1. All uploads go to app sandbox temp directory ONLY
///   2. OCR text is kept in memory, NOT persisted to disk
///   3. After scoring is complete, ALL temp files are deleted
///   4. Failsafe cleanup on app close, crash recovery, and timeout
///
/// PRIVACY: No raw documents ever leave the device.
class TempStorageManager {
  // Singleton
  static final TempStorageManager _instance = TempStorageManager._internal();
  factory TempStorageManager() => _instance;
  TempStorageManager._internal();

  /// Tracked temp files for cleanup
  final Set<String> _trackedFiles = {};

  /// Timestamp when first file was added (for timeout cleanup)
  DateTime? _firstFileTime;

  /// Maximum age before auto-cleanup (10 minutes)
  static const Duration maxAge = Duration(minutes: 10);

  /// Get the app's secure temp directory
  Future<Directory> get _tempDir async {
    final appDir = await getApplicationDocumentsDirectory();
    final tempDir = Directory('${appDir.path}/temp');
    if (!await tempDir.exists()) {
      await tempDir.create(recursive: true);
    }
    return tempDir;
  }

  /// Save a file to the secure temp directory and track it.
  /// Returns the path to the saved file.
  Future<String> saveTemp(File sourceFile, String filename) async {
    final dir = await _tempDir;
    final destPath = '${dir.path}/$filename';
    final dest = await sourceFile.copy(destPath);

    _trackedFiles.add(dest.path);
    _firstFileTime ??= DateTime.now();

    return dest.path;
  }

  /// Track an existing temp file for cleanup
  void track(String filePath) {
    _trackedFiles.add(filePath);
    _firstFileTime ??= DateTime.now();
  }

  /// Check if timeout cleanup is needed
  bool get isExpired {
    if (_firstFileTime == null) return false;
    return DateTime.now().difference(_firstFileTime!) > maxAge;
  }

  /// MANDATORY: Clean up ALL temp files after scoring is complete.
  /// Called after score generation, on app close, and on crash recovery.
  Future<int> cleanupAll() async {
    int deleted = 0;

    // Delete all tracked files
    for (final path in _trackedFiles.toList()) {
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
          deleted++;
        }
      } catch (_) {
        // Silently continue — best effort cleanup
      }
    }
    _trackedFiles.clear();

    // Also sweep the entire temp directory for any orphaned files
    try {
      final dir = await _tempDir;
      if (await dir.exists()) {
        await for (final entity in dir.list()) {
          try {
            if (entity is File) {
              await entity.delete();
              deleted++;
            }
          } catch (_) {}
        }
      }
    } catch (_) {}

    // sweep the image_picker temporary cache directory
    try {
      final cacheDir = await getTemporaryDirectory();
      if (await cacheDir.exists()) {
        await for (final entity in cacheDir.list(recursive: true)) {
          try {
            if (entity is File && 
               (entity.path.contains('image_picker') || 
                entity.path.endsWith('.jpg') || 
                entity.path.endsWith('.png'))) {
              await entity.delete();
              deleted++;
            }
          } catch (_) {}
        }
      }
    } catch (_) {}

    _firstFileTime = null;
    return deleted;
  }

  /// Check and perform timeout-based cleanup if files are older than 10 mins
  Future<void> checkTimeout() async {
    if (isExpired) {
      await cleanupAll();
    }
  }

  /// Get count of currently tracked files
  int get trackedCount => _trackedFiles.length;

  /// Check if any sensitive data remains on disk
  Future<bool> hasRemainingFiles() async {
    try {
      final dir = await _tempDir;
      if (!await dir.exists()) return false;
      final files = await dir.list().toList();
      return files.whereType<File>().isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
