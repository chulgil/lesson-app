import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../repositories/lesson_repository.dart';

/// Lesson repository provider
final lessonRepositoryProvider = Provider<LessonRepository>((ref) {
  return MockLessonRepository();
});
