import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/repository_provider.dart';
import '../../../students/domain/entities/lesson_slot.dart';
import '../../data/repositories/mock_teacher_student_relation_repository.dart';
import '../../data/repositories/remote_teacher_student_relation_repository.dart';
import '../../domain/entities/notification_setting.dart';
import '../../domain/entities/relationship_status.dart';
import '../../domain/entities/teacher_student_relation.dart';
import '../../domain/repositories/teacher_student_relation_repository.dart';

part 'relationship_providers.g.dart';

/// Repository provider - switches between Mock and Remote.
@Riverpod(keepAlive: true)
TeacherStudentRelationRepository teacherStudentRelationRepository(
  TeacherStudentRelationRepositoryRef ref,
) =>
    createRepository<TeacherStudentRelationRepository>(
      ref: ref,
      mock: () => MockTeacherStudentRelationRepository(),
      remote: (api) => RemoteTeacherStudentRelationRepository(api),
    );

/// Get relationship by ID
@riverpod
Future<TeacherStudentRelation?> relationshipById(
  RelationshipByIdRef ref,
  String id,
) async {
  final repository = ref.watch(teacherStudentRelationRepositoryProvider);
  return repository.getById(id);
}

/// Get relationship between teacher and student
@riverpod
Future<TeacherStudentRelation?> teacherStudentRelation(
  TeacherStudentRelationRef ref, {
  required String teacherId,
  required String studentId,
}) async {
  final repository = ref.watch(teacherStudentRelationRepositoryProvider);
  return repository.getRelation(teacherId, studentId);
}

/// Get all relationships for a teacher
@riverpod
Future<List<TeacherStudentRelation>> teacherRelationships(
  TeacherRelationshipsRef ref,
  String teacherId,
) async {
  final repository = ref.watch(teacherStudentRelationRepositoryProvider);
  return repository.getByTeacher(teacherId);
}

/// Get all relationships for a student
@riverpod
Future<List<TeacherStudentRelation>> studentRelationships(
  StudentRelationshipsRef ref,
  String studentId,
) async {
  final repository = ref.watch(teacherStudentRelationRepositoryProvider);
  return repository.getByStudent(studentId);
}

/// Get relationships by status for a teacher
@riverpod
Future<List<TeacherStudentRelation>> teacherRelationshipsByStatus(
  TeacherRelationshipsByStatusRef ref, {
  required String teacherId,
  required RelationshipStatus status,
}) async {
  final repository = ref.watch(teacherStudentRelationRepositoryProvider);
  return repository.getByTeacherAndStatus(teacherId, status);
}

/// Get active students for a teacher
@riverpod
Future<List<TeacherStudentRelation>> activeStudents(
  ActiveStudentsRef ref,
  String teacherId,
) async {
  final repository = ref.watch(teacherStudentRelationRepositoryProvider);
  return repository.getActiveByTeacher(teacherId);
}

/// Get expired students for a teacher (within grace period)
@riverpod
Future<List<TeacherStudentRelation>> expiredStudents(
  ExpiredStudentsRef ref,
  String teacherId,
) async {
  final repository = ref.watch(teacherStudentRelationRepositoryProvider);
  return repository.getExpiredByTeacher(teacherId);
}

/// Get past students for a teacher
@riverpod
Future<List<TeacherStudentRelation>> pastStudents(
  PastStudentsRef ref,
  String teacherId,
) async {
  final repository = ref.watch(teacherStudentRelationRepositoryProvider);
  return repository.getPastByTeacher(teacherId);
}

/// Get trial-booked students for a teacher
@riverpod
Future<List<TeacherStudentRelation>> trialBookedStudents(
  TrialBookedStudentsRef ref,
  String teacherId,
) async {
  final repository = ref.watch(teacherStudentRelationRepositoryProvider);
  return repository.getTrialBookedByTeacher(teacherId);
}

/// Get manually registered (offline) students for a teacher
@riverpod
Future<List<TeacherStudentRelation>> manuallyRegisteredStudents(
  ManuallyRegisteredStudentsRef ref,
  String teacherId,
) async {
  final repository = ref.watch(teacherStudentRelationRepositoryProvider);
  return repository.getManuallyRegisteredByTeacher(teacherId);
}

/// Get notification setting for a relationship
@riverpod
Future<NotificationSetting?> relationshipNotificationSetting(
  RelationshipNotificationSettingRef ref, {
  required String userId,
  required String targetUserId,
}) async {
  final repository = ref.watch(teacherStudentRelationRepositoryProvider);
  return repository.getNotificationSetting(userId, targetUserId);
}

// ============================================================
// Previous Schedule Providers (for re-enrollment restoration)
// ============================================================

/// Previous schedule data record
typedef PreviousSchedule =
    ({List<LessonSlot> lessonSlots, int? lessonDuration});

/// Get previous schedule for a student-teacher pair.
/// Returns the last known regular lesson schedule for re-enrollment restoration.
@riverpod
Future<PreviousSchedule?> previousSchedule(
  PreviousScheduleRef ref, {
  required String teacherId,
  required String studentId,
}) async {
  final repository = ref.watch(teacherStudentRelationRepositoryProvider);
  final result = await repository.getPreviousSchedule(
    teacherId: teacherId,
    studentId: studentId,
  );

  if (result == null || result.lessonDay == null || result.lessonTime == null) {
    return null;
  }

  return (
    lessonSlots: [
      LessonSlot(
        dayOfWeek: result.lessonDay! - 1,
        startTime: result.lessonTime!,
        endTime: '',
      ),
    ],
    lessonDuration: result.lessonDuration,
  );
}

/// Record schedule for a student-teacher relationship.
/// Call this when regular lessons are confirmed or schedule changes.
@riverpod
class ScheduleRecorder extends _$ScheduleRecorder {
  @override
  Future<void> build() async {}

  Future<void> recordSchedule({
    required String teacherId,
    required String studentId,
    required List<LessonSlot> lessonSlots,
    int? lessonDuration,
  }) async {
    if (lessonSlots.isEmpty) return;

    // Validate lessonDuration if provided
    if (lessonDuration != null && lessonDuration <= 0) {
      throw ArgumentError.value(
        lessonDuration,
        'lessonDuration',
        'Must be a positive number',
      );
    }

    final slot = lessonSlots.first;
    final lessonDay = slot.dayOfWeek + 1; // LessonSlot 0-based → repo 1-based

    final repository = ref.read(teacherStudentRelationRepositoryProvider);
    await repository.recordSchedule(
      teacherId: teacherId,
      studentId: studentId,
      lessonDay: lessonDay,
      lessonTime: slot.startTime,
      lessonDuration: lessonDuration,
    );

    ref.invalidate(
      previousScheduleProvider(teacherId: teacherId, studentId: studentId),
    );
  }
}
