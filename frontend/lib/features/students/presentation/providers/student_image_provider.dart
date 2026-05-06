import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/providers/repository_provider.dart';
import '../../../../core/services/image_upload_service.dart';
import '../../../../core/utils/image_utils.dart';

part 'student_image_provider.g.dart';

/// Student profile image state.
@riverpod
class StudentProfileImageNotifier extends _$StudentProfileImageNotifier {
  String get _fileName => 'student_$studentId';

  @override
  Future<String?> build(String studentId) async {
    final file = await getProfileImageFile(_fileName);
    return file?.path;
  }

  /// Pick, crop (circle), save locally, and upload to server.
  Future<bool> pickAndSaveImage(
    ImageSource source,
    BuildContext context,
  ) async {
    try {
      final picked = await pickImage(source);
      if (picked == null) return false;

      if (!context.mounted) return false;
      final croppedPath = await cropProfileImage(picked.path, context);
      if (croppedPath == null) return false;

      final savedPath = await saveProfileImage(croppedPath, _fileName);

      state = AsyncData(savedPath);

      // Upload to server
      final apiClient = ref.read(apiClientProvider);
      final uploadService = ImageUploadService(
        apiClient,
        useMockData: ref.read(mockDataModeProvider),
      );
      await uploadService.uploadImage(
        filePath: savedPath,
        imageType: 'profile',
        entityType: 'student',
        entityId: studentId,
      );

      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  /// Delete and reset to initial avatar.
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
        imageType: 'profile',
        entityType: 'student',
        entityId: studentId,
      );
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

/// Student background image state.
@riverpod
class StudentBackgroundImageNotifier extends _$StudentBackgroundImageNotifier {
  String get _fileName => 'student_$studentId';

  @override
  Future<String?> build(String studentId) async {
    final file = await getBackgroundImageFile(_fileName);
    return file?.path;
  }

  /// Pick, crop (16:9), save locally, and upload to server.
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

      final savedPath = await saveBackgroundImage(croppedPath, _fileName);

      state = AsyncData(savedPath);

      // Upload to server
      final apiClient = ref.read(apiClientProvider);
      final uploadService = ImageUploadService(
        apiClient,
        useMockData: ref.read(mockDataModeProvider),
      );
      await uploadService.uploadImage(
        filePath: savedPath,
        imageType: 'background',
        entityType: 'student',
        entityId: studentId,
      );

      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  /// Delete and reset to default gradient.
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
        entityType: 'student',
        entityId: studentId,
      );
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
