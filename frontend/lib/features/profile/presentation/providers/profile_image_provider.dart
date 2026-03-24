import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/services/image_upload_service.dart';
import '../../../../core/utils/image_utils.dart';

part 'profile_image_provider.g.dart';

/// Profile image state — holds the current local file path.
@riverpod
class ProfileImageNotifier extends _$ProfileImageNotifier {
  @override
  Future<String?> build(String userId) async {
    // Try to find existing saved profile image
    final file = await getProfileImageFile(userId);
    return file?.path;
  }

  /// Pick image from source, crop, save locally, and upload to server.
  Future<bool> pickAndSaveImage(
    ImageSource source,
    BuildContext context,
  ) async {
    // 1. Pick
    final picked = await pickImage(source);
    if (picked == null) return false;

    // 2. Crop
    if (!context.mounted) return false;
    final croppedPath = await cropProfileImage(picked.path, context);
    if (croppedPath == null) return false;

    // 3. Save locally
    final savedPath = await saveProfileImage(croppedPath, userId);

    // 4. Update state (immediate — local-first)
    state = AsyncData(savedPath);

    // 5. Upload to server (non-blocking)
    final apiClient = ref.read(apiClientProvider);
    final uploadService = ImageUploadService(apiClient);
    await uploadService.uploadImage(
      filePath: savedPath,
      imageType: 'profile',
      entityType: 'teacher',
    );

    return true;
  }

  /// Delete profile image and reset to initial avatar.
  Future<void> removeImage() async {
    final currentPath = state.valueOrNull;
    if (currentPath != null) {
      await deleteProfileImage(currentPath);
    }
    state = const AsyncData(null);

    // Delete from server
    final apiClient = ref.read(apiClientProvider);
    final uploadService = ImageUploadService(apiClient);
    await uploadService.deleteImage(
      imageType: 'profile',
      entityType: 'teacher',
    );
  }
}
