import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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

  /// Pick image from source, crop to 16:9, save, and update state.
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
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
