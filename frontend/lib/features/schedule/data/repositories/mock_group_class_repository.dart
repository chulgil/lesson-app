// Mock implementation of GroupClassRepository

import 'package:uuid/uuid.dart';

import '../../domain/entities/group_class.dart';
import '../../domain/entities/group_class_draft.dart';
import '../../domain/entities/group_class_member.dart';
import '../../domain/entities/group_class_schedule.dart';
import '../../domain/repositories/group_class_repository.dart';

/// In-memory group class store for mock mode and widget tests.
///
/// Seeded with one regular class and one drop-in class so the list screen shows
/// both shapes without a backend.
class MockGroupClassRepository implements GroupClassRepository {
  MockGroupClassRepository({
    this.ownerTeacherId = 'teacher_1',
    this.studentNames = const {},
    bool seed = true,
  }) {
    if (seed) _seed();
  }

  /// Owner stamped on classes created through this mock — the server would
  /// derive it from the authenticated teacher.
  final String ownerTeacherId;

  /// Student id -> display name. The backend joins the student row to stamp
  /// `student_name` on roster responses; the mock has no student table, so
  /// callers that care about the name supply it here.
  final Map<String, String> studentNames;

  final _uuid = const Uuid();
  final Map<String, GroupClass> _classes = {};
  final Map<String, GroupClassSchedule> _schedules = {};

  /// Cohort roster rows keyed by member id. The backend keeps these in
  /// `group_class_members`; the mock holds them in memory.
  final Map<String, GroupClassMember> _members = {};

  void _seed() {
    final now = DateTime.now();
    final ensemble = GroupClass(
      id: 'group_class_1',
      teacherId: ownerTeacherId,
      name: '목요일 앙상블반',
      description: '4명이 함께 합주하는 정규 반입니다.',
      type: GroupClassType.regular,
      maxCapacity: 4,
      durationMinutes: 60,
      repeatDaysOfWeek: const [4],
      repeatTimeOfDay: '17:00',
      instrument: '바이올린',
      pricePerSession: 35000,
      createdAt: now.subtract(const Duration(days: 30)),
    );
    final masterclass = GroupClass(
      id: 'group_class_2',
      teacherId: ownerTeacherId,
      name: '원데이 보잉 특강',
      type: GroupClassType.dropIn,
      maxCapacity: 6,
      durationMinutes: 90,
      noShowPolicy: NoShowPolicy.noDeduction,
      instrument: '바이올린',
      pricePerSession: 50000,
      createdAt: now.subtract(const Duration(days: 3)),
    );
    _classes[ensemble.id] = ensemble;
    _classes[masterclass.id] = masterclass;
    _assign(classId: ensemble.id, studentId: 'student_1');

    // One upcoming session per class so the list rows have something concrete
    // to open. The backend expands regular repeat rules server-side.
    for (final groupClass in [ensemble, masterclass]) {
      final startTime = now.add(const Duration(days: 3));
      final schedule = GroupClassSchedule(
        id: 'schedule_${groupClass.id}',
        groupClassId: groupClass.id,
        startTime: startTime,
        endTime: startTime.add(Duration(minutes: groupClass.durationMinutes)),
        maxCapacity: groupClass.maxCapacity,
        waitlistCapacity: groupClass.waitlistCapacity,
        createdAt: now,
      );
      _schedules[schedule.id] = schedule;
    }
  }

  @override
  Future<List<GroupClass>> getClassesForTeacher(
    String teacherId, {
    bool includeInactive = false,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final owned = _classes.values.where((c) => c.teacherId == teacherId);
    final visible = includeInactive ? owned : owned.where((c) => c.isActive);
    return visible.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<List<GroupClass>> getClassesForStudent(String studentId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final enrolled = _members.values
        .where((m) => m.studentId == studentId)
        .map((m) => m.groupClassId)
        .toSet();
    return enrolled
        .map((id) => _classes[id])
        .nonNulls
        .where((c) => c.isActive)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<GroupClass?> getClassById(String classId) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _classes[classId];
  }

  @override
  Future<List<GroupClassSchedule>> getSchedulesForClass(String classId) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return schedulesFor(classId)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  /// Enrol a student in a class — synchronous seam for tests that need a
  /// seeded roster, mirroring `POST /groups/classes/{id}/members`.
  void enrol({required String studentId, required String classId}) {
    _assign(classId: classId, studentId: studentId);
  }

  @override
  Future<List<GroupClassMember>> listMembers(String classId) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _membersOf(classId)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  @override
  Future<GroupClassMember> assignMember({
    required String classId,
    required String studentId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _assign(classId: classId, studentId: studentId);
  }

  @override
  Future<void> removeMember({
    required String classId,
    required String studentId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _members.removeWhere(
      (_, member) =>
          member.groupClassId == classId && member.studentId == studentId,
    );
  }

  List<GroupClassMember> _membersOf(String classId) =>
      _members.values.where((m) => m.groupClassId == classId).toList();

  /// Mirrors the backend guards: unknown class, duplicate assignment and
  /// over-capacity all reject rather than silently growing the roster.
  GroupClassMember _assign({
    required String classId,
    required String studentId,
  }) {
    final groupClass = _classes[classId];
    if (groupClass == null) {
      throw StateError('Group class not found: $classId');
    }
    final current = _membersOf(classId);
    if (current.any((m) => m.studentId == studentId)) {
      throw StateError('Student already assigned: $studentId');
    }
    if (current.length >= groupClass.maxCapacity) {
      throw StateError('Group class is full: $classId');
    }
    final member = GroupClassMember(
      id: _uuid.v4(),
      groupClassId: classId,
      studentId: studentId,
      studentName: studentNames[studentId],
      createdAt: DateTime.now(),
    );
    _members[member.id] = member;
    return member;
  }

  @override
  Future<GroupClass> createClass(GroupClassDraft draft) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final created = GroupClass(
      id: _uuid.v4(),
      teacherId: ownerTeacherId,
      name: draft.name,
      description: draft.description,
      type: draft.type,
      maxCapacity: draft.maxCapacity,
      waitlistCapacity: draft.waitlistCapacity,
      durationMinutes: draft.durationMinutes,
      bookingDeadlineMinutes: draft.bookingDeadlineMinutes,
      cancelDeadlineMinutes: draft.cancelDeadlineMinutes,
      noShowPolicy: draft.noShowPolicy,
      repeatDaysOfWeek: draft.isDropIn ? null : draft.repeatDaysOfWeek,
      repeatTimeOfDay: draft.isDropIn ? null : draft.repeatTimeOfDay,
      instrument: draft.instrument,
      pricePerSession: draft.pricePerSession,
      createdAt: DateTime.now(),
    );
    _classes[created.id] = created;
    return created;
  }

  @override
  Future<GroupClass> updateClass(String classId, GroupClassDraft draft) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final existing = _classes[classId];
    if (existing == null) {
      throw StateError('Group class not found: $classId');
    }
    final updated = existing.copyWith(
      name: draft.name,
      description: draft.description,
      type: draft.type,
      maxCapacity: draft.maxCapacity,
      waitlistCapacity: draft.waitlistCapacity,
      durationMinutes: draft.durationMinutes,
      bookingDeadlineMinutes: draft.bookingDeadlineMinutes,
      cancelDeadlineMinutes: draft.cancelDeadlineMinutes,
      noShowPolicy: draft.noShowPolicy,
      repeatDaysOfWeek: draft.isDropIn ? null : draft.repeatDaysOfWeek,
      repeatTimeOfDay: draft.isDropIn ? null : draft.repeatTimeOfDay,
      instrument: draft.instrument,
      pricePerSession: draft.pricePerSession,
      updatedAt: DateTime.now(),
    );
    _classes[classId] = updated;
    return updated;
  }

  @override
  Future<GroupClass> deactivateClass(String classId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final existing = _classes[classId];
    if (existing == null) {
      throw StateError('Group class not found: $classId');
    }
    final deactivated = existing.copyWith(
      isActive: false,
      updatedAt: DateTime.now(),
    );
    _classes[classId] = deactivated;
    return deactivated;
  }

  @override
  Future<GroupClassSchedule> createSchedule({
    required String groupClassId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final groupClass = _classes[groupClassId];
    if (groupClass == null) {
      throw StateError('Group class not found: $groupClassId');
    }
    final schedule = GroupClassSchedule(
      id: _uuid.v4(),
      groupClassId: groupClassId,
      startTime: startTime,
      endTime: endTime,
      // Capacity is inherited from the class — the session never owns it (P1-0).
      maxCapacity: groupClass.maxCapacity,
      waitlistCapacity: groupClass.waitlistCapacity,
      createdAt: DateTime.now(),
    );
    _schedules[schedule.id] = schedule;
    return schedule;
  }

  /// Classes currently held, without awaiting — widget tests run in a fake
  /// async zone where awaiting a repository future outside `pump` deadlocks.
  List<GroupClass> get storedClasses => _classes.values.toList();

  /// Sessions opened through this mock, for tests that assert on drop-in wiring.
  List<GroupClassSchedule> schedulesFor(String groupClassId) =>
      _schedules.values.where((s) => s.groupClassId == groupClassId).toList();
}
