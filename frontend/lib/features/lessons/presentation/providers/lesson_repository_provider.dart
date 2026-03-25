import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_provider.dart';
import '../../data/repositories/mock_lesson_repository.dart';
import '../../data/repositories/remote_lesson_repository.dart';
import '../../domain/repositories/lesson_repository.dart';

/// Lesson repository provider - switches between Mock and Remote.
final lessonRepositoryProvider = Provider<LessonRepository>((ref) =>
    createRepository<LessonRepository>(
      ref: ref,
      mock: () => MockLessonRepository(),
      remote: (api) => RemoteLessonRepository(api),
    ));
