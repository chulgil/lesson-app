import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/repository_provider.dart';
import '../../data/repositories/mock_lesson_repository.dart';
import '../../data/repositories/remote_lesson_repository.dart';
import '../../domain/repositories/lesson_repository.dart';

part 'lesson_repository_provider.g.dart';

/// Lesson repository provider - switches between Mock and Remote.
@Riverpod(keepAlive: true)
LessonRepository lessonRepository(LessonRepositoryRef ref) =>
    createRepository<LessonRepository>(
      ref: ref,
      mock: () => MockLessonRepository(),
      remote: (api) => RemoteLessonRepository(api),
    );
