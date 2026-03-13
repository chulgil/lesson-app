import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Profile image dimensions (square).
const int kProfileImageSize = 500;

/// JPEG compression quality (0-100).
const int kProfileImageQuality = 80;

/// Profile images subdirectory name.
const String kProfileImageDir = 'profile_images';

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
        toolbarColor: const Color(0xFF6B5B95),
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

/// Save a profile image to the app's documents directory.
///
/// Returns the saved file path.
Future<String> saveProfileImage(String sourcePath, String fileName) async {
  final dir = await getApplicationDocumentsDirectory();
  final profileDir = Directory('${dir.path}/$kProfileImageDir');
  if (!await profileDir.exists()) {
    await profileDir.create(recursive: true);
  }

  final ext = sourcePath.split('.').last.toLowerCase();
  final targetPath = '${profileDir.path}/$fileName.$ext';

  // Copy to profile directory
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
