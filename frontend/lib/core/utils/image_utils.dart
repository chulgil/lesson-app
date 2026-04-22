import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../theme/app_colors.dart';

/// Profile image dimensions (square).
const int kProfileImageSize = 500;

/// Background image dimensions (16:9).
const int kBackgroundImageWidth = 1080;
const int kBackgroundImageHeight = 608;

/// JPEG compression quality (0-100).
const int kProfileImageQuality = 80;

/// Profile images subdirectory name.
const String kProfileImageDir = 'profile_images';

/// Background images subdirectory name.
const String kBackgroundImageDir = 'background_images';

const Set<String> _allowedExtensions = {'jpg', 'jpeg', 'png'};

/// Sanitize a file name by removing path separators and '..' sequences.
String _sanitizeFileName(String name) {
  return name.replaceAll(RegExp(r'[/\\]'), '_').replaceAll('..', '_');
}

/// Extract and validate image file extension. Returns 'jpg' if invalid.
String _safeExtension(String path) {
  final ext = path.split('.').last.toLowerCase();
  return _allowedExtensions.contains(ext) ? ext : 'jpg';
}

/// Delete all image files for a given fileName in a directory (across all extensions).
Future<void> _deleteExistingFiles(String dirPath, String fileName) async {
  for (final ext in _allowedExtensions) {
    final file = File('$dirPath/$fileName.$ext');
    if (await file.exists()) {
      await file.delete();
    }
  }
}

/// Pick an image from gallery or camera.
///
/// Returns the picked [XFile] or null if cancelled.
Future<XFile?> pickImage(ImageSource source) async {
  final picker = ImagePicker();
  return picker.pickImage(
    source: source,
    maxWidth: 1024,
    maxHeight: 1024,
    imageQuality: 90,
  );
}

/// Crop an image to a square circle style.
///
/// Returns the cropped file path or null if cancelled.
Future<String?> cropProfileImage(
  String sourcePath,
  BuildContext context,
) async {
  final croppedFile = await ImageCropper().cropImage(
    sourcePath: sourcePath,
    aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
    compressQuality: kProfileImageQuality,
    maxWidth: kProfileImageSize,
    maxHeight: kProfileImageSize,
    uiSettings: [
      AndroidUiSettings(
        toolbarTitle: '프로필 사진 편집',
        toolbarColor: AppColors.paperAccent,
        toolbarWidgetColor: Colors.white,
        cropStyle: CropStyle.circle,
        lockAspectRatio: true,
        hideBottomControls: false,
        aspectRatioPresets: [CropAspectRatioPreset.square],
      ),
      IOSUiSettings(
        title: '프로필 사진 편집',
        cropStyle: CropStyle.circle,
        aspectRatioLockEnabled: true,
        resetAspectRatioEnabled: false,
        aspectRatioPresets: [CropAspectRatioPreset.square],
      ),
    ],
  );
  return croppedFile?.path;
}

/// Crop an image to a 16:9 rectangle for background.
///
/// Returns the cropped file path or null if cancelled.
Future<String?> cropBackgroundImage(
  String sourcePath,
  BuildContext context,
) async {
  final croppedFile = await ImageCropper().cropImage(
    sourcePath: sourcePath,
    aspectRatio: const CropAspectRatio(ratioX: 16, ratioY: 9),
    compressQuality: kProfileImageQuality,
    maxWidth: kBackgroundImageWidth,
    maxHeight: kBackgroundImageHeight,
    uiSettings: [
      AndroidUiSettings(
        toolbarTitle: '배경 사진 편집',
        toolbarColor: AppColors.paperAccent,
        toolbarWidgetColor: Colors.white,
        cropStyle: CropStyle.rectangle,
        lockAspectRatio: true,
        hideBottomControls: false,
        aspectRatioPresets: [CropAspectRatioPreset.ratio16x9],
      ),
      IOSUiSettings(
        title: '배경 사진 편집',
        cropStyle: CropStyle.rectangle,
        aspectRatioLockEnabled: true,
        resetAspectRatioEnabled: false,
        aspectRatioPresets: [CropAspectRatioPreset.ratio16x9],
      ),
    ],
  );
  return croppedFile?.path;
}

/// Save a background image to the app's documents directory.
///
/// Returns the saved file path.
Future<String> saveBackgroundImage(String sourcePath, String fileName) async {
  final safeName = _sanitizeFileName(fileName);
  final dir = await getApplicationDocumentsDirectory();
  final bgDir = Directory('${dir.path}/$kBackgroundImageDir');
  if (!await bgDir.exists()) {
    await bgDir.create(recursive: true);
  }

  // Delete any existing files for this name to prevent orphans
  await _deleteExistingFiles(bgDir.path, safeName);

  final ext = _safeExtension(sourcePath);
  final targetPath = '${bgDir.path}/$safeName.$ext';

  final sourceFile = File(sourcePath);
  await sourceFile.copy(targetPath);

  return targetPath;
}

/// Get the saved background image file, or null if it doesn't exist.
Future<File?> getBackgroundImageFile(String fileName) async {
  final dir = await getApplicationDocumentsDirectory();
  for (final ext in ['jpg', 'jpeg', 'png']) {
    final file = File('${dir.path}/$kBackgroundImageDir/$fileName.$ext');
    if (await file.exists()) {
      return file;
    }
  }
  return null;
}

/// Save a profile image to the app's documents directory.
///
/// Returns the saved file path.
Future<String> saveProfileImage(String sourcePath, String fileName) async {
  final safeName = _sanitizeFileName(fileName);
  final dir = await getApplicationDocumentsDirectory();
  final profileDir = Directory('${dir.path}/$kProfileImageDir');
  if (!await profileDir.exists()) {
    await profileDir.create(recursive: true);
  }

  // Delete any existing files for this name to prevent orphans
  await _deleteExistingFiles(profileDir.path, safeName);

  final ext = _safeExtension(sourcePath);
  final targetPath = '${profileDir.path}/$safeName.$ext';

  final sourceFile = File(sourcePath);
  await sourceFile.copy(targetPath);

  return targetPath;
}

/// Delete a profile image.
Future<void> deleteProfileImage(String path) async {
  final file = File(path);
  if (await file.exists()) {
    await file.delete();
  }
}

/// Get the saved profile image file, or null if it doesn't exist.
Future<File?> getProfileImageFile(String fileName) async {
  final dir = await getApplicationDocumentsDirectory();
  // Check common extensions
  for (final ext in ['jpg', 'jpeg', 'png']) {
    final file = File('${dir.path}/$kProfileImageDir/$fileName.$ext');
    if (await file.exists()) {
      return file;
    }
  }
  return null;
}
