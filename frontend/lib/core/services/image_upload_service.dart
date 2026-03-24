import 'dart:io';

import 'package:dio/dio.dart';

import '../config/environment.dart';
import '../network/api_client.dart';

/// Service to upload profile/background images to the backend.
///
/// Local-first: images are always saved locally first, then
/// uploaded to the server when not in mock mode.
class ImageUploadService {
  final ApiClient _apiClient;

  ImageUploadService(this._apiClient);

  /// Upload an image file to the backend.
  ///
  /// Returns the remote URL on success, null on failure or mock mode.
  Future<String?> uploadImage({
    required String filePath,
    required String imageType,
    String entityType = 'teacher',
    String? entityId,
  }) async {
    if (EnvironmentConfig.useMockData) return null;

    try {
      final file = File(filePath);
      if (!file.existsSync()) return null;

      final fileName = filePath.split('/').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
        'image_type': imageType,
        'entity_type': entityType,
        if (entityId != null) 'entity_id': entityId,
      });

      final response = await _apiClient.post(
        '/profile-images/upload',
        data: formData,
      );

      final data = response.data as Map<String, dynamic>;
      return data['image_url'] as String?;
    } catch (_) {
      // Upload failure is non-blocking — local image is still available
      return null;
    }
  }

  /// Delete an image from the backend.
  Future<void> deleteImage({
    required String imageType,
    String entityType = 'teacher',
    String? entityId,
  }) async {
    if (EnvironmentConfig.useMockData) return;

    try {
      await _apiClient.delete(
        '/profile-images',
        queryParameters: {
          'image_type': imageType,
          'entity_type': entityType,
          if (entityId != null) 'entity_id': entityId,
        },
      );
    } catch (_) {
      // Deletion failure is non-blocking
    }
  }
}
