import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../core/utils/sp_manager.dart';

final downloadAgentProvider = Provider((ref) => Dio());

final downloadManagerProvider = Provider(
  (ref) => DownloadManager(ref.read(downloadAgentProvider)),
);

enum DownloadStatus {
  started,
  downloading,
  saving,
  completed,
  failed,
  duplicate,
}

class DownloadResult {
  final DownloadStatus status;
  final String? message;
  final bool? result; // true/false for completed/failed, null otherwise

  DownloadResult({required this.status, this.message, this.result});
}

class DownloadManager {
  final Dio _dio;

  DownloadManager(this._dio);

  /// Download and save to gallery as a stream of status events (no progress)
  Stream<DownloadResult> downloadImageToGallery(String imageUrl) async* {
    try {
      yield DownloadResult(
        status: DownloadStatus.started,
        message: 'Starting download: $imageUrl',
      );

      // Get original filename from URL
      final originalFilename = _getFilenameFromUrl(imageUrl);

      // Check if file already exists to prevent duplicates
      final existingPath = await _checkForExistingFile(originalFilename);
      if (existingPath != null) {
        yield DownloadResult(
          status: DownloadStatus.duplicate,
          message: 'File already exists: $originalFilename at $existingPath',
          result: true,
        );
        return;
      }

      // Create temp file with original name
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$originalFilename');

      // Download the image
      final response = await _dio.download(imageUrl, tempFile.path);
      if (response.statusCode != 200) {
        yield DownloadResult(
          status: DownloadStatus.failed,
          message: 'Download failed: ${response.statusCode}',
          result: false,
        );
        return;
      }

      yield DownloadResult(
        status: DownloadStatus.saving,
        message: _getSavingMessage(),
      );

      // Save image based on platform
      final savedPath = await _saveImageToPlatformStorage(
        tempFile,
        originalFilename,
      );

      // Save last download info to SharedPreferences
      await _saveLastDownloadInfo(originalFilename);

      yield DownloadResult(
        status: DownloadStatus.completed,
        message: 'Saved as: $originalFilename at $savedPath',
        result: true,
      );
    } catch (e) {
      yield DownloadResult(
        status: DownloadStatus.failed,
        message: 'Error: $e',
        result: false,
      );
    }
  }

  /// Check if file already exists to prevent duplicate downloads
  Future<String?> _checkForExistingFile(String filename) async {
    try {
      // Check if this is the same as the last downloaded file
      final lastDownloadedFile = await SPManager.getLastDownloadFilename();

      if (lastDownloadedFile != null && lastDownloadedFile == filename) {
        print('🔄 File already downloaded recently: $filename');

        if (defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.macOS) {
          // For Linux & macOS, verify file still exists at expected location
          final existingPath = await _checkDesktopFileExists(filename);
          if (existingPath != null) {
            return existingPath;
          }
          // If file doesn't exist, allow re-download
        } else {
          // For platforms using gal package (Android, iOS, Windows)
          return 'molethewall album in ${_getPlatformGalleryName()} (recently downloaded)';
        }
      }

      return null; // Allow download to proceed
    } catch (e) {
      print('⚠️ Error checking for existing file: $e');
      return null;
    }
  }

  /// Check if file exists in desktop molethewall folder (Linux & macOS)
  Future<String?> _checkDesktopFileExists(String filename) async {
    try {
      // Get platform-specific base directory
      Directory baseDir;
      final homeDir = Platform.environment['HOME'];

      if (defaultTargetPlatform == TargetPlatform.macOS) {
        // macOS: Use Pictures folder
        if (homeDir != null) {
          final picturesDir = Directory(path.join(homeDir, 'Pictures'));
          if (await picturesDir.exists()) {
            baseDir = picturesDir;
          } else {
            baseDir = await getApplicationDocumentsDirectory();
          }
        } else {
          baseDir = await getApplicationDocumentsDirectory();
        }
      } else {
        // Linux: Use Pictures folder or Home folder
        if (homeDir != null) {
          final picturesDir = Directory(path.join(homeDir, 'Pictures'));
          if (await picturesDir.exists()) {
            baseDir = picturesDir;
          } else {
            baseDir = Directory(homeDir);
          }
        } else {
          baseDir = await getApplicationDocumentsDirectory();
        }
      }

      final molethewallDir = Directory(path.join(baseDir.path, 'molethewall'));
      final targetFile = File(path.join(molethewallDir.path, filename));

      if (await targetFile.exists()) {
        print('📁 File already exists: ${targetFile.path}');
        return targetFile.path;
      }

      return null;
    } catch (e) {
      print('⚠️ Error checking desktop file: $e');
      return null;
    }
  }

  /// Get platform-specific saving message
  String _getSavingMessage() {
    if (defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return 'Saving to molethewall folder...';
    } else {
      return 'Saving to molethewall album...';
    }
  }

  /// Save image to appropriate storage based on platform
  Future<String> _saveImageToPlatformStorage(
    File tempFile,
    String filename,
  ) async {
    if (defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      // Linux & macOS: Use custom file system approach
      return await _saveToDesktopFolder(tempFile, filename);
    } else {
      // Mobile platforms (Android, iOS) & Windows: Use gal package
      await _ensureGalleryPermissions();
      await Gal.putImage(tempFile.path, album: 'molethewall');
      return 'molethewall album in ${_getPlatformGalleryName()}';
    }
  }

  /// Ensure gallery permissions for platforms that support gal package
  Future<void> _ensureGalleryPermissions() async {
    try {
      final hasAccess = await Gal.hasAccess(toAlbum: true);
      if (!hasAccess) {
        print('📱 Requesting gallery album permissions...');
        await Gal.requestAccess(toAlbum: true);
      }
    } catch (e) {
      print('⚠️ Permission check failed: $e');
      // Continue anyway - some platforms may not support this check
    }
  }

  /// Get platform-specific gallery name
  String _getPlatformGalleryName() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'Google Photos';
      case TargetPlatform.iOS:
        return 'Photos app';
      case TargetPlatform.macOS:
        return 'Photos app';
      case TargetPlatform.windows:
        return 'Photos app';
      default:
        return 'gallery';
    }
  }

  /// Save image to desktop folder (Linux & macOS)
  Future<String> _saveToDesktopFolder(File tempFile, String filename) async {
    try {
      // Get platform-specific base directory
      Directory baseDir;
      final homeDir = Platform.environment['HOME'];

      if (defaultTargetPlatform == TargetPlatform.macOS) {
        // macOS: Use Pictures folder
        if (homeDir != null) {
          final picturesDir = Directory(path.join(homeDir, 'Pictures'));
          if (await picturesDir.exists()) {
            baseDir = picturesDir;
          } else {
            baseDir = await getApplicationDocumentsDirectory();
          }
        } else {
          baseDir = await getApplicationDocumentsDirectory();
        }
      } else {
        // Linux: Use Pictures folder or Home folder
        if (homeDir != null) {
          final picturesDir = Directory(path.join(homeDir, 'Pictures'));
          if (await picturesDir.exists()) {
            baseDir = picturesDir;
          } else {
            baseDir = Directory(homeDir);
          }
        } else {
          baseDir = await getApplicationDocumentsDirectory();
        }
      }

      // Create molethewall subdirectory
      final molethewallDir = Directory(path.join(baseDir.path, 'molethewall'));
      if (!await molethewallDir.exists()) {
        await molethewallDir.create(recursive: true);
        print('📁 Created molethewall directory: ${molethewallDir.path}');
      }

      // Copy file to final location
      final finalFile = File(path.join(molethewallDir.path, filename));
      await tempFile.copy(finalFile.path);

      final platformName = defaultTargetPlatform == TargetPlatform.macOS
          ? 'macOS'
          : 'Linux';
      print('✅ Saved to $platformName folder: ${finalFile.path}');
      return finalFile.path;
    } catch (e) {
      final platformName = defaultTargetPlatform == TargetPlatform.macOS
          ? 'macOS'
          : 'Linux';
      print('❌ Error saving to $platformName folder: $e');
      // Fallback: save to application documents directory
      final documentsDir = await getApplicationDocumentsDirectory();
      final molethewallDir = Directory(
        path.join(documentsDir.path, 'molethewall'),
      );
      if (!await molethewallDir.exists()) {
        await molethewallDir.create(recursive: true);
      }
      final finalFile = File(path.join(molethewallDir.path, filename));
      await tempFile.copy(finalFile.path);
      return finalFile.path;
    }
  }

  /// Save last download information to SharedPreferences
  Future<void> _saveLastDownloadInfo(String filename) async {
    try {
      final now = DateTime.now();

      // Save last download datetime and filename
      await SPManager.setLastDownloadDateTime(now);
      await SPManager.setLastDownloadFilename(filename);

      print(
        '💾 Saved last download info: $filename at ${now.toIso8601String()}',
      );
    } catch (e) {
      print('❌ Error saving last download info: $e');
    }
  }

  /// Extract original filename from URL
  static String _getFilenameFromUrl(String imageUrl) {
    try {
      final uri = Uri.parse(imageUrl);
      String filename = uri.pathSegments.last;

      // If filename is empty or has no extension, add .jpg
      if (filename.isEmpty || !filename.contains('.')) {
        filename = filename.isEmpty ? 'image' : filename;
        filename += '.jpg';
      }

      return filename;
    } catch (e) {
      // Fallback filename
      return 'image.jpg';
    }
  }
}
