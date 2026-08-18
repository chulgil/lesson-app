// Mock implementation of GroupClassRepository

import 'package:uuid/uuid.dart';

import '../../domain/entities/group_class.dart';
import '../../domain/entities/group_class_draft.dart';
import '../../domain/entities/group_class_schedule.dart';
import '../../domain/repositories/group_class_repository.dart';

/// In-memory group class store for mock mode and widget tests.
///
/// Seeded with one regular class and one drop-in class so the list screen shows
/// both shapes without a backend.
class MockGroupClassRepository implements GroupClassRepository {
  MockGroupClassRepository({
    this.ownerTeacherId = 'teacher_1',
    bool seed = true,
  }) {
    if (seed) _seed();
  }

  /// Owner stamped on classes created through this mock — the server would
  /// derive it from the authenticated teacher.
  final String ownerTeacherId;

  final _uuid = const Uuid();
  final Map<String, GroupClass> _classes = {};
  final Map<String, GroupClassSchedule> _schedules = {};

  /// Cohort roster: student id -> class ids they are enrolled in. The backend
  /// keeps this in `group_class_members`; the mock holds it in memory.
  final Map<String, Set<String>> _roster = {};

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
    _roster['student_1'] = {ensemble.id};

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
    final enrolled = _roster[studentId] ?? const <String>{};
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

  /// Enrol a student in a class — test seam for the agenda row, mirroring
  /// `POST /groups/classes/{id}/members`.
  void enrol({required String studentId, required String classId}) {
    _roster.putIfAbsent(studentId, () => <String>{}).add(classId);
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
