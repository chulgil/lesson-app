import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/repository_provider.dart';
import '../../../../features/practice/domain/entities/practice_item.dart';
import '../../../gamification/gamification_facade.dart'
    show pointAwardNotifierProvider;
import '../../../lessons/lessons_facade.dart'
    show TeachingResourceType, currentTeacherIdProvider, resourcesByIdsProvider;
import '../../data/repositories/mock_practice_item_repository.dart';
import '../../data/repositories/remote_practice_item_repository.dart';
import '../../domain/repositories/practice_item_repository.dart';
import 'practice_repertoire_repository_provider.dart';
import 'practice_repertoire_crud_provider.dart';

part 'practice_item_providers.g.dart';

/// Repository provider
@Riverpod(keepAlive: true)
PracticeItemRepository practiceItemRepository(PracticeItemRepositoryRef ref) {
  return createRepository<PracticeItemRepository>(
    ref: ref,
    mock: () => MockPracticeItemRepository(),
    remote: (api) => RemotePracticeItemRepository(api),
  );
}

/// Current student ID provider (placeholder - should come from auth/navigation)
@Riverpod(keepAlive: true)
class CurrentStudentId extends _$CurrentStudentId {
  @override
  String? build() => null;

  void setStudentId(String? studentId) {
    state = studentId;
  }
}

/// Practice items by lesson ID
@Riverpod(keepAlive: true)
Future<List<PracticeItem>> practiceItemsByLesson(
  PracticeItemsByLessonRef ref,
  String lessonId,
) async {
  final repository = ref.watch(practiceItemRepositoryProvider);
  return repository.getByLessonId(lessonId);
}

/// Practice items by student ID
@Riverpod(keepAlive: true)
Future<List<PracticeItem>> practiceItemsByStudent(
  PracticeItemsByStudentRef ref,
  String studentId,
) async {
  final repository = ref.watch(practiceItemRepositoryProvider);
  return repository.getByStudentId(studentId);
}

/// Weekly practice items for student (current week)
@Riverpod(keepAlive: true)
Future<List<PracticeItem>> weeklyPracticeItems(
  WeeklyPracticeItemsRef ref,
  String studentId,
) async {
  final repository = ref.watch(practiceItemRepositoryProvider);
  final now = DateTime.now();

  // Calculate start of week (Monday)
  final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
  // Calculate end of week (Sunday)
  final endOfWeek = startOfWeek.add(const Duration(days: 6));

  return repository.getByStudentIdAndDateRange(
    studentId,
    startOfWeek,
    endOfWeek,
  );
}

/// Incomplete practice items for student (for dashboard)
@Riverpod(keepAlive: true)
Future<List<PracticeItem>> incompletePracticeItems(
  IncompletePracticeItemsRef ref,
  String studentId,
) async {
  final repository = ref.watch(practiceItemRepositoryProvider);
  return repository.getIncompleteByStudentId(studentId);
}

/// Practice items awaiting teacher feedback
@Riverpod(keepAlive: true)
Future<List<PracticeItem>> awaitingFeedback(AwaitingFeedbackRef ref) async {
  final repository = ref.watch(practiceItemRepositoryProvider);
  final teacherId = ref.watch(currentTeacherIdProvider);
  return repository.getAwaitingFeedback(teacherId);
}

/// Single practice item by ID
@Riverpod(keepAlive: true)
Future<PracticeItem?> practiceItemById(
  PracticeItemByIdRef ref,
  String id,
) async {
  final repository = ref.watch(practiceItemRepositoryProvider);
  return repository.getById(id);
}

/// Notifier for practice item CRUD operations (lesson-based)
@Riverpod(keepAlive: true)
class PracticeItemsNotifier extends _$PracticeItemsNotifier {
  PracticeItemRepository get _repository =>
      ref.read(practiceItemRepositoryProvider);

  @override
  Future<List<PracticeItem>> build(String lessonId) async {
    return _repository.getByLessonId(lessonId);
  }

  /// Add a new practice item
  Future<PracticeItem> addItem({
    required String studentId,
    required String teacherId,
    PracticeType type = PracticeType.repertoire,
    required String title,
    String? description,
    String? repertoireId,
    String? sectionId,
    PracticePriority priority = PracticePriority.should,
    List<String> resourceIds = const [],
  }) async {
    final item = PracticeItem(
      id: '',
      lessonId: lessonId,
      studentId: studentId,
      teacherId: teacherId,
      type: type,
      title: title,
      description: description,
      repertoireId: repertoireId,
      sectionId: sectionId,
      priority: priority,
      resourceIds: resourceIds,
      createdAt: DateTime.now(),
    );

    state = const AsyncValue.loading();
    try {
      final newItem = await _repository.create(item);

      // #611·612 — sheet 가 만든 명시 섹션(마디범위 보유)에 과제 메타데이터
      // (YouTube·리소스·교사·역참조)를 부착. 기본 레퍼토리 중복 생성(범위 소실) 제거.
      if (sectionId != null) {
        await _attachAssignmentToSection(
          studentId: studentId,
          sectionId: sectionId,
          teacherId: teacherId,
          practiceItemId: newItem.id,
          resourceIds: resourceIds,
        );
      }

      state = await AsyncValue.guard(() => _repository.getByLessonId(lessonId));
      // Invalidate related providers
      ref.invalidate(practiceItemsByStudentProvider(studentId));
      ref.invalidate(weeklyPracticeItemsProvider(studentId));
      ref.invalidate(incompletePracticeItemsProvider(studentId));
      return newItem;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Update practice item
  Future<PracticeItem> updateItem(PracticeItem item) async {
    state = const AsyncValue.loading();
    try {
      final updated = await _repository.update(item);
      state = await AsyncValue.guard(() => _repository.getByLessonId(lessonId));
      // Invalidate related providers
      ref.invalidate(practiceItemsByStudentProvider(item.studentId));
      ref.invalidate(weeklyPracticeItemsProvider(item.studentId));
      return updated;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Delete practice item
  Future<void> deleteItem(String id, String studentId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.delete(id);
      state = await AsyncValue.guard(() => _repository.getByLessonId(lessonId));
      // Invalidate related providers
      ref.invalidate(practiceItemsByStudentProvider(studentId));
      ref.invalidate(weeklyPracticeItemsProvider(studentId));
      ref.invalidate(incompletePracticeItemsProvider(studentId));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Toggle completion status
  Future<PracticeItem> toggleComplete(String id, String studentId) async {
    try {
      final updated = await _repository.toggleComplete(id);
      state = await AsyncValue.guard(() => _repository.getByLessonId(lessonId));
      // Invalidate related providers
      ref.invalidate(practiceItemsByStudentProvider(studentId));
      ref.invalidate(weeklyPracticeItemsProvider(studentId));
      ref.invalidate(incompletePracticeItemsProvider(studentId));
      ref.invalidate(awaitingFeedbackProvider);
      // Award points when item is toggled to completed
      if (updated.isCompleted) {
        ref
            .read(pointAwardNotifierProvider.notifier)
            .awardTaskComplete(studentId, updated.title);
      }
      return updated;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Toggle like (teacher feedback)
  Future<PracticeItem> toggleLike(String id, String studentId) async {
    try {
      final updated = await _repository.toggleLike(id);
      state = await AsyncValue.guard(() => _repository.getByLessonId(lessonId));
      // Invalidate related providers
      ref.invalidate(practiceItemsByStudentProvider(studentId));
      ref.invalidate(weeklyPracticeItemsProvider(studentId));
      ref.invalidate(awaitingFeedbackProvider);
      return updated;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Increment practice count
  Future<PracticeItem> incrementCount(String id, String studentId) async {
    try {
      final updated = await _repository.incrementCount(id);
      state = await AsyncValue.guard(() => _repository.getByLessonId(lessonId));
      ref.invalidate(practiceItemsByStudentProvider(studentId));
      ref.invalidate(weeklyPracticeItemsProvider(studentId));
      return updated;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Decrement practice count
  Future<PracticeItem> decrementCount(String id, String studentId) async {
    try {
      final updated = await _repository.decrementCount(id);
      state = await AsyncValue.guard(() => _repository.getByLessonId(lessonId));
      ref.invalidate(practiceItemsByStudentProvider(studentId));
      ref.invalidate(weeklyPracticeItemsProvider(studentId));
      return updated;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Sync practice item to student's repertoire as a PracticeSection
  /// #611·612 — sheet 가 만든 명시 섹션(마디범위 보유)에 과제 메타데이터를 부착한다.
  /// 기본('선생님 과제') 레퍼토리에 두 번째 full 섹션을 만들던 중복(범위 소실)을 대체.
  Future<void> _attachAssignmentToSection({
    required String studentId,
    required String sectionId,
    required String teacherId,
    required String practiceItemId,
    List<String> resourceIds = const [],
  }) async {
    try {
      final repertoireRepo = ref.read(practiceRepertoireRepositoryProvider);

      // Extract YouTube info from attached teaching resources
      String? youtubeUrl;
      String? youtubeVideoId;
      int? youtubeStartSeconds;
      int? youtubeEndSeconds;

      if (resourceIds.isNotEmpty) {
        try {
          final resources = await ref.read(
            resourcesByIdsProvider(resourceIds).future,
          );
          final youtubeResource =
              resources
                  .where((r) => r.type == TeachingResourceType.youtube)
                  .firstOrNull;
          if (youtubeResource != null) {
            youtubeUrl = youtubeResource.youtubeUrl;
            youtubeVideoId = youtubeResource.youtubeVideoId;
            youtubeStartSeconds = youtubeResource.youtubeStartSeconds;
            youtubeEndSeconds = youtubeResource.youtubeEndSeconds;
          }
        } catch (_) {
          // Teaching resource lookup failed — continue without YouTube info
        }
      }

      // 명시 섹션은 이미 마디범위를 보유. 과제 출처·YouTube·리소스만 보강한다.
      final section = await repertoireRepo.getSection(sectionId);
      if (section == null) return;
      await repertoireRepo.updateSection(
        section.copyWith(
          youtubeUrl: youtubeUrl,
          youtubeVideoId: youtubeVideoId,
          youtubeStartSeconds: youtubeStartSeconds,
          youtubeEndSeconds: youtubeEndSeconds,
          teachingResourceIds: resourceIds,
          assignedByTeacherId: teacherId,
          practiceItemId: practiceItemId,
        ),
      );

      // Invalidate repertoire providers to refresh student's practice tab
      ref.invalidate(studentRepertoiresProvider(studentId));
    } catch (e, st) {
      // Assignment created successfully but repertoire sync failed.
      // Don't fail the main operation — student can still see the assignment
      // via PracticeItem, just not in the repertoire tab.
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: e,
          stack: st,
          library: 'practice_item_providers',
          context: ErrorDescription(
            'Failed to attach assignment metadata to section',
          ),
        ),
      );
    }
  }
}

/// Notifier for student's practice items (student-based operations)
@Riverpod(keepAlive: true)
class StudentPracticeNotifier extends _$StudentPracticeNotifier {
  PracticeItemRepository get _repository =>
      ref.read(practiceItemRepositoryProvider);

  @override
  Future<List<PracticeItem>> build(String studentId) async {
    return _repository.getByStudentId(studentId);
  }

  /// Toggle completion status (for student)
  Future<PracticeItem> toggleComplete(String id) async {
    try {
      final updated = await _repository.toggleComplete(id);
      state = await AsyncValue.guard(
        () => _repository.getByStudentId(studentId),
      );
      // Invalidate related providers
      ref.invalidate(weeklyPracticeItemsProvider(studentId));
      ref.invalidate(incompletePracticeItemsProvider(studentId));
      ref.invalidate(awaitingFeedbackProvider);
      // Award points when item is toggled to completed
      if (updated.isCompleted) {
        ref
            .read(pointAwardNotifierProvider.notifier)
            .awardTaskComplete(studentId, updated.title);
      }
      return updated;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Increment practice count (for student)
  Future<PracticeItem> incrementCount(String id) async {
    try {
      final updated = await _repository.incrementCount(id);
      state = await AsyncValue.guard(
        () => _repository.getByStudentId(studentId),
      );
      ref.invalidate(weeklyPracticeItemsProvider(studentId));
      return updated;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Decrement practice count (for student)
  Future<PracticeItem> decrementCount(String id) async {
    try {
      final updated = await _repository.decrementCount(id);
      state = await AsyncValue.guard(
        () => _repository.getByStudentId(studentId),
      );
      ref.invalidate(weeklyPracticeItemsProvider(studentId));
      return updated;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}
