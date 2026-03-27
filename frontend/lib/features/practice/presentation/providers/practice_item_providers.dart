import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/practice/domain/entities/practice_item.dart';
import '../../domain/repositories/practice_item_repository.dart';
import '../../../lessons/domain/entities/teaching_resource.dart';
import '../../../lessons/presentation/providers/teaching_resource_providers.dart';
import 'practice_repertoire_repository_provider.dart';
import 'practice_repertoire_crud_provider.dart';

import '../../../lessons/presentation/providers/tip_template_providers.dart' show currentTeacherIdProvider;

/// Repository provider
final practiceItemRepositoryProvider = Provider<PracticeItemRepository>((ref) {
  return MockPracticeItemRepository();
});

/// Current student ID provider (placeholder - should come from auth/navigation)
final currentStudentIdProvider = StateProvider<String?>((ref) {
  return null;
});

/// Practice items by lesson ID
final practiceItemsByLessonProvider =
    FutureProvider.family<List<PracticeItem>, String>((ref, lessonId) async {
  final repository = ref.watch(practiceItemRepositoryProvider);
  return repository.getByLessonId(lessonId);
});

/// Practice items by student ID
final practiceItemsByStudentProvider =
    FutureProvider.family<List<PracticeItem>, String>((ref, studentId) async {
  final repository = ref.watch(practiceItemRepositoryProvider);
  return repository.getByStudentId(studentId);
});

/// Weekly practice items for student (current week)
final weeklyPracticeItemsProvider =
    FutureProvider.family<List<PracticeItem>, String>((ref, studentId) async {
  final repository = ref.watch(practiceItemRepositoryProvider);
  final now = DateTime.now();

  // Calculate start of week (Monday)
  final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
  // Calculate end of week (Sunday)
  final endOfWeek = startOfWeek.add(const Duration(days: 6));

  return repository.getByStudentIdAndDateRange(studentId, startOfWeek, endOfWeek);
});

/// Incomplete practice items for student (for dashboard)
final incompletePracticeItemsProvider =
    FutureProvider.family<List<PracticeItem>, String>((ref, studentId) async {
  final repository = ref.watch(practiceItemRepositoryProvider);
  return repository.getIncompleteByStudentId(studentId);
});

/// Practice items awaiting teacher feedback
final awaitingFeedbackProvider = FutureProvider<List<PracticeItem>>((ref) async {
  final repository = ref.watch(practiceItemRepositoryProvider);
  final teacherId = ref.watch(currentTeacherIdProvider);
  return repository.getAwaitingFeedback(teacherId);
});

/// Single practice item by ID
final practiceItemByIdProvider =
    FutureProvider.family<PracticeItem?, String>((ref, id) async {
  final repository = ref.watch(practiceItemRepositoryProvider);
  return repository.getById(id);
});

/// Notifier for practice item CRUD operations (lesson-based)
class PracticeItemsNotifier extends FamilyAsyncNotifier<List<PracticeItem>, String> {
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
      lessonId: arg,
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

      // Auto-create section in student's practice repertoire
      await _syncToStudentRepertoire(
        studentId: studentId,
        teacherId: teacherId,
        practiceItemId: newItem.id,
        title: title,
        description: description,
        resourceIds: resourceIds,
      );

      state = await AsyncValue.guard(() => _repository.getByLessonId(arg));
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
      state = await AsyncValue.guard(() => _repository.getByLessonId(arg));
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
      state = await AsyncValue.guard(() => _repository.getByLessonId(arg));
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
      state = await AsyncValue.guard(() => _repository.getByLessonId(arg));
      // Invalidate related providers
      ref.invalidate(practiceItemsByStudentProvider(studentId));
      ref.invalidate(weeklyPracticeItemsProvider(studentId));
      ref.invalidate(incompletePracticeItemsProvider(studentId));
      ref.invalidate(awaitingFeedbackProvider);
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
      state = await AsyncValue.guard(() => _repository.getByLessonId(arg));
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
      state = await AsyncValue.guard(() => _repository.getByLessonId(arg));
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
      state = await AsyncValue.guard(() => _repository.getByLessonId(arg));
      ref.invalidate(practiceItemsByStudentProvider(studentId));
      ref.invalidate(weeklyPracticeItemsProvider(studentId));
      return updated;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Sync practice item to student's repertoire as a PracticeSection
  Future<void> _syncToStudentRepertoire({
    required String studentId,
    required String teacherId,
    required String practiceItemId,
    required String title,
    String? description,
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
          final resources =
              await ref.read(resourcesByIdsProvider(resourceIds).future);
          final youtubeResource = resources
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

      await repertoireRepo.createSectionFromAssignment(
        studentId: studentId,
        pieceName: title,
        sectionName: description,
        youtubeUrl: youtubeUrl,
        youtubeVideoId: youtubeVideoId,
        youtubeStartSeconds: youtubeStartSeconds,
        youtubeEndSeconds: youtubeEndSeconds,
        teachingResourceIds: resourceIds,
        assignedByTeacherId: teacherId,
        practiceItemId: practiceItemId,
      );

      // Invalidate repertoire providers to refresh student's practice tab
      ref.invalidate(studentRepertoiresProvider(studentId));
    } catch (e, st) {
      // Assignment created successfully but repertoire sync failed.
      // Don't fail the main operation — student can still see the assignment
      // via PracticeItem, just not in the repertoire tab.
      FlutterError.reportError(FlutterErrorDetails(
        exception: e,
        stack: st,
        library: 'practice_item_providers',
        context: ErrorDescription('Failed to sync assignment to student repertoire'),
      ));
    }
  }
}

final practiceItemsNotifierProvider = AsyncNotifierProvider.family<
    PracticeItemsNotifier, List<PracticeItem>, String>(
  PracticeItemsNotifier.new,
);

/// Notifier for student's practice items (student-based operations)
class StudentPracticeNotifier extends FamilyAsyncNotifier<List<PracticeItem>, String> {
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
      state = await AsyncValue.guard(() => _repository.getByStudentId(arg));
      // Invalidate related providers
      ref.invalidate(weeklyPracticeItemsProvider(arg));
      ref.invalidate(incompletePracticeItemsProvider(arg));
      ref.invalidate(awaitingFeedbackProvider);
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
      state = await AsyncValue.guard(() => _repository.getByStudentId(arg));
      ref.invalidate(weeklyPracticeItemsProvider(arg));
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
      state = await AsyncValue.guard(() => _repository.getByStudentId(arg));
      ref.invalidate(weeklyPracticeItemsProvider(arg));
      return updated;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final studentPracticeNotifierProvider = AsyncNotifierProvider.family<
    StudentPracticeNotifier, List<PracticeItem>, String>(
  StudentPracticeNotifier.new,
);
