import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/providers/repository_provider.dart';
import '../../../../core/services/image_upload_service.dart';
import '../../../../core/utils/image_utils.dart';

part 'background_image_provider.g.dart';

/// Background image state — holds the current local file path.
@riverpod
class BackgroundImageNotifier extends _$BackgroundImageNotifier {
  @override
  Future<String?> build(String userId) async {
    final file = await getBackgroundImageFile(userId);
    return file?.path;
  }

  /// Pick image from source, crop to 16:9, save locally, and upload to server.
  Future<bool> pickAndSaveImage(
    ImageSource source,
    BuildContext context,
  ) async {
    try {
      final picked = await pickImage(source);
      if (picked == null) return false;

      if (!context.mounted) return false;
      final croppedPath = await cropBackgroundImage(picked.path, context);
      if (croppedPath == null) return false;

      final savedPath = await saveBackgroundImage(croppedPath, userId);

      state = AsyncData(savedPath);

      // Upload to server (non-blocking)
      final apiClient = ref.read(apiClientProvider);
      final uploadService = ImageUploadService(
        apiClient,
        useMockData: ref.read(mockDataModeProvider),
      );
      await uploadService.uploadImage(
        filePath: savedPath,
        imageType: 'background',
        entityType: 'teacher',
      );

      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  /// Delete background image and reset to default.
  Future<void> removeImage() async {
    try {
      final currentPath = state.valueOrNull;
      if (currentPath != null) {
        await deleteProfileImage(currentPath);
      }
      state = const AsyncData(null);

      final apiClient = ref.read(apiClientProvider);
      final uploadService = ImageUploadService(
        apiClient,
        useMockData: ref.read(mockDataModeProvider),
      );
      await uploadService.deleteImage(
        imageType: 'background',
        entityType: 'teacher',
      );
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
