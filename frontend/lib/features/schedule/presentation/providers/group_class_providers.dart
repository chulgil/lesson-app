// Group class definition providers (teacher-side CRUD)
// Bookings live in group_class_booking_providers.dart.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/repository_provider.dart';
import '../../data/repositories/mock_group_class_repository.dart';
import '../../data/repositories/remote_group_class_repository.dart';
import '../../domain/entities/group_class.dart';
import '../../domain/entities/group_class_draft.dart';
import '../../domain/entities/group_class_member.dart';
import '../../domain/entities/group_class_schedule.dart';
import '../../domain/repositories/group_class_repository.dart';

part 'group_class_providers.g.dart';

// ============================================================
// Repository Provider - switches between Mock and Remote.
// ============================================================

@Riverpod(keepAlive: true)
GroupClassRepository groupClassRepository(Ref ref) {
  return createRepository<GroupClassRepository>(
    ref: ref,
    mock: () => MockGroupClassRepository(),
    remote: (api) => RemoteGroupClassRepository(api),
  );
}

// ============================================================
// Query Providers
// ============================================================

/// Classes a teacher owns, newest first.
///
/// Deactivated classes are included so the owner still sees what they took
/// down; the backend hides them from everyone else.
@riverpod
Future<List<GroupClass>> teacherGroupClasses(
  TeacherGroupClassesRef ref,
  String teacherId,
) async {
  final repository = ref.watch(groupClassRepositoryProvider);
  return repository.getClassesForTeacher(teacherId, includeInactive: true);
}

/// Active classes a student is enrolled in (cohort roster).
///
/// Feeds the student agenda: only classes the student was assigned to, never
/// classes they could browse — discovery lives on the teacher detail screen.
@riverpod
Future<List<GroupClass>> studentGroupClasses(
  StudentGroupClassesRef ref,
  String studentId,
) async {
  final repository = ref.watch(groupClassRepositoryProvider);
  return repository.getClassesForStudent(studentId);
}

/// A single class — used by the edit form and by screens that only hold an ID.
@riverpod
Future<GroupClass?> groupClassById(
  GroupClassByIdRef ref,
  String classId,
) async {
  final repository = ref.watch(groupClassRepositoryProvider);
  return repository.getClassById(classId);
}

/// Sessions opened for a class, earliest first.
///
/// List and agenda rows hold a class but the detail/attendance screens need a
/// concrete session, so the row tap resolves one through this provider.
@riverpod
Future<List<GroupClassSchedule>> groupClassSchedules(
  GroupClassSchedulesRef ref,
  String classId,
) async {
  final repository = ref.watch(groupClassRepositoryProvider);
  return repository.getSchedulesForClass(classId);
}

/// Cohort roster of a class, oldest assignment first.
///
/// Only regular classes have one — a drop-in class is booked per session, so
/// its roster is always empty.
@riverpod
Future<List<GroupClassMember>> groupClassMembers(
  GroupClassMembersRef ref,
  String classId,
) async {
  final repository = ref.watch(groupClassRepositoryProvider);
  return repository.listMembers(classId);
}

// ============================================================
// Notifier for mutations
// ============================================================

/// Write path for class definitions. Kept apart from the read providers above
/// so a successful write always invalidates them explicitly.
@riverpod
class GroupClassFormNotifier extends _$GroupClassFormNotifier {
  @override
  AsyncValue<GroupClass?> build() => const AsyncValue.data(null);

  /// Create a class when [classId] is null, otherwise update it.
  ///
  /// A new drop-in class also gets its single session opened here: the backend
  /// expands repeat rules for regular classes, but a drop-in has none, so
  /// without this the class would exist with nothing to book.
  Future<GroupClass> save({
    required String teacherId,
    required GroupClassDraft draft,
    String? classId,
  }) async {
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(groupClassRepositoryProvider);
      final GroupClass saved;
      if (classId == null) {
        saved = await repository.createClass(draft);
        final startsAt = draft.dropInStartsAt;
        if (draft.isDropIn && startsAt != null) {
          await repository.createSchedule(
            groupClassId: saved.id,
            startTime: startsAt,
            endTime: draft.dropInEndsAt!,
          );
        }
      } else {
        saved = await repository.updateClass(classId, draft);
      }

      state = AsyncValue.data(saved);
      _invalidateReads(teacherId: teacherId, classId: saved.id);
      return saved;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Take a class down (soft delete — history keeps pointing at it).
  Future<GroupClass> deactivate({
    required String teacherId,
    required String classId,
  }) async {
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(groupClassRepositoryProvider);
      final deactivated = await repository.deactivateClass(classId);

      state = AsyncValue.data(deactivated);
      _invalidateReads(teacherId: teacherId, classId: classId);
      return deactivated;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  void _invalidateReads({required String teacherId, required String classId}) {
    ref.invalidate(teacherGroupClassesProvider(teacherId));
    ref.invalidate(groupClassByIdProvider(classId));
  }
}

/// Write path for the cohort roster. Kept apart from [groupClassMembers] so a
/// successful assign/remove always invalidates the read explicitly.
@riverpod
class GroupClassMemberNotifier extends _$GroupClassMemberNotifier {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  /// Put a student on the roster. Throws when the backend rejects it — the
  /// caller shows the server's reason (full roster, duplicate, other teacher).
  Future<void> assign({
    required String classId,
    required String studentId,
  }) async {
    await _mutate(
      classId: classId,
      action: (repository) =>
          repository.assignMember(classId: classId, studentId: studentId),
    );
  }

  /// Take a student off the roster.
  Future<void> remove({
    required String classId,
    required String studentId,
  }) async {
    await _mutate(
      classId: classId,
      action: (repository) =>
          repository.removeMember(classId: classId, studentId: studentId),
    );
  }

  Future<void> _mutate({
    required String classId,
    required Future<void> Function(GroupClassRepository) action,
  }) async {
    state = const AsyncValue.loading();

    try {
      await action(ref.read(groupClassRepositoryProvider));
      state = const AsyncValue.data(null);
      ref.invalidate(groupClassMembersProvider(classId));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}
