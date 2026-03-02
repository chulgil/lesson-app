import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/environment.dart';
import '../../../../core/network/api_client.dart';
import '../../data/repositories/mock_lesson_repository.dart';
import '../../data/repositories/remote_lesson_repository.dart';
import '../../domain/repositories/lesson_repository.dart';

/// Lesson repository provider - switches between Mock and Remote.
final lessonRepositoryProvider = Provider<LessonRepository>((ref) {
  if (EnvironmentConfig.useMockData) {
    return MockLessonRepository();
  }
  return RemoteLessonRepository(ref.read(apiClientProvider));
});
