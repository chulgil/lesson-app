import 'dart:async';

import 'package:uuid/uuid.dart';

import '../../domain/entities/class_membership.dart';
import '../../domain/entities/lesson_slot.dart';
import '../../domain/repositories/membership_repository.dart';

/// Mock implementation of MembershipRepository for development.
class MockMembershipRepository implements MembershipRepository {
  final _uuid = const Uuid();
  final List<ClassMembership> _memberships = [];
  final _controller = StreamController<List<ClassMembership>>.broadcast();

  MockMembershipRepository() {
    _initMockData();
  }

  void _initMockData() {
    final now = DateTime.now();

    _memberships.addAll([
      // Student 1 - Academy membership (teacher visits student home)
      ClassMembership(
        id: 'cm_001',
        lessonClassId: 'lc_001', // 행복음악학원
        studentId: 'student_1',
        instrument: '바이올린',
        status: MembershipStatus.active,
        level: '중급',
        monthlyFee: 200000,
        lessonsPerWeek: 1,
        lessonSlots: [LessonSlot(dayOfWeek: 0, startTime: '16:00', endTime: '17:00')],
        lessonDuration: 60,
        lessonLocationId: 'student_home_student_1',
        travelTimeMinutes: 20,
        createdAt: now.subtract(const Duration(days: 60)),
      ),
      // Student 2 - Academy membership (teacher visits)
      ClassMembership(
        id: 'cm_002',
        lessonClassId: 'lc_001', // 행복음악학원
        studentId: 'student_2',
        instrument: '피아노',
        status: MembershipStatus.active,
        level: '초급',
        monthlyFee: 180000,
        lessonsPerWeek: 1,
        lessonSlots: [LessonSlot(dayOfWeek: 1, startTime: '15:00', endTime: '16:00')],
        lessonDuration: 60,
        lessonLocationId: 'student_home_student_2',
        travelTimeMinutes: 15,
        createdAt: now.subtract(const Duration(days: 45)),
      ),
      // Student 3 - Private lesson membership
      ClassMembership(
        id: 'cm_003',
        lessonClassId: 'lc_002', // 개인레슨
        studentId: 'student_3',
        instrument: '첼로',
        status: MembershipStatus.active,
        level: '고급',
        monthlyFee: 250000,
        lessonsPerWeek: 1,
        lessonSlots: [LessonSlot(dayOfWeek: 2, startTime: '14:00', endTime: '15:00')],
        lessonDuration: 60,
        createdAt: now.subtract(const Duration(days: 30)),
      ),
      // Student 4 - Trial
      ClassMembership(
        id: 'cm_004',
        lessonClassId: 'lc_002', // 개인레슨
        studentId: 'student_4',
        instrument: '플루트',
        status: MembershipStatus.trial,
        level: '입문',
        monthlyFee: 150000,
        lessonsPerWeek: 1,
        lessonSlots: [LessonSlot(dayOfWeek: 3, startTime: '17:00', endTime: '18:00')],
        lessonDuration: 60,
        notes: '체험 레슨 진행중',
        createdAt: now.subtract(const Duration(days: 7)),
      ),
      // Student 1 - Also has private lesson (multi-membership)
      ClassMembership(
        id: 'cm_005',
        lessonClassId: 'lc_002', // 개인레슨
        studentId: 'student_1',
        instrument: '피아노',
        status: MembershipStatus.active,
        level: '초급',
        monthlyFee: 200000,
        lessonsPerWeek: 1,
        lessonSlots: [LessonSlot(dayOfWeek: 4, startTime: '16:00', endTime: '17:00')],
        lessonDuration: 60,
        notes: '바이올린 외 피아노 추가 수업',
        createdAt: now.subtract(const Duration(days: 20)),
      ),

      // Student 11 - 복수 악기 (바이올린 + 피아노)
      ClassMembership(
        id: 'cm_010',
        lessonClassId: 'lc_002', // 개인레슨
        studentId: 'student_11',
        instrument: '바이올린',
        status: MembershipStatus.active,
        level: '중급',
        monthlyFee: 200000,
        lessonsPerWeek: 1,
        lessonSlots: [LessonSlot(dayOfWeek: 1, startTime: '17:00', endTime: '18:00')],
        lessonDuration: 60,
        createdAt: now.subtract(const Duration(days: 40)),
      ),
      ClassMembership(
        id: 'cm_011',
        lessonClassId: 'lc_001', // 행복음악학원
        studentId: 'student_11',
        instrument: '피아노',
        status: MembershipStatus.active,
        level: '초급',
        monthlyFee: 160000,
        lessonsPerWeek: 1,
        lessonSlots: [LessonSlot(dayOfWeek: 3, startTime: '17:00', endTime: '18:00')],
        lessonDuration: 60,
        createdAt: now.subtract(const Duration(days: 40)),
      ),
      // Student 12 - 초급 바이올린
      ClassMembership(
        id: 'cm_012',
        lessonClassId: 'lc_002', // 개인레슨
        studentId: 'student_12',
        instrument: '바이올린',
        status: MembershipStatus.active,
        level: '입문',
        monthlyFee: 160000,
        lessonsPerWeek: 1,
        lessonSlots: [LessonSlot(dayOfWeek: 2, startTime: '18:00', endTime: '19:00')],
        lessonDuration: 60,
        createdAt: now.subtract(const Duration(days: 15)),
      ),

      // ============================================================
      // 휴식/과거 학생들 (레슨 요청 Mock 데이터용)
      // ============================================================

      // Student 5 - 과거 학생 (past status - 6개월 전 종료)
      ClassMembership(
        id: 'cm_006',
        lessonClassId: 'lc_002', // 개인레슨 (teacher_1)
        studentId: 'student_5',
        instrument: '바이올린',
        status: MembershipStatus.terminated,
        level: '중급',
        monthlyFee: 220000,
        lessonsPerWeek: 1,
        lessonSlots: [LessonSlot(dayOfWeek: 5, startTime: '14:00', endTime: '14:50')],
        lessonDuration: 50,
        notes: '6개월 전 개인 사정으로 휴식',
        createdAt: now.subtract(const Duration(days: 300)),
      ),

      // Student 6 - 과거 학생 (수강권 제안 받은 상태)
      ClassMembership(
        id: 'cm_007',
        lessonClassId: 'lc_002', // 개인레슨 (teacher_1)
        studentId: 'student_6',
        instrument: '바이올린',
        status: MembershipStatus.terminated,
        level: '고급',
        monthlyFee: 280000,
        lessonsPerWeek: 1,
        lessonSlots: [LessonSlot(dayOfWeek: 3, startTime: '17:00', endTime: '18:00')],
        lessonDuration: 60,
        notes: '3개월 전 휴식',
        createdAt: now.subtract(const Duration(days: 180)),
      ),

      // Student 7 - 과거 학생 (거절된 요청)
      ClassMembership(
        id: 'cm_008',
        lessonClassId: 'lc_002', // 개인레슨 (teacher_1)
        studentId: 'student_7',
        instrument: '피아노',
        status: MembershipStatus.terminated,
        level: '초급',
        monthlyFee: 180000,
        lessonsPerWeek: 1,
        lessonSlots: [LessonSlot(dayOfWeek: 5, startTime: '10:00', endTime: '11:00')],
        lessonDuration: 60,
        notes: '토요일 오전만 가능한 학생',
        createdAt: now.subtract(const Duration(days: 240)),
      ),

      // Student 8 - 과거 학생 (만료된 요청)
      ClassMembership(
        id: 'cm_009',
        lessonClassId: 'lc_002', // 개인레슨 (teacher_1)
        studentId: 'student_8',
        instrument: '첼로',
        status: MembershipStatus.terminated,
        level: '중급',
        monthlyFee: 200000,
        lessonsPerWeek: 1,
        lessonSlots: [LessonSlot(dayOfWeek: 2, startTime: '16:00', endTime: '16:45')],
        lessonDuration: 45,
        notes: '요청 만료됨',
        createdAt: now.subtract(const Duration(days: 200)),
      ),

      // Student 9 - 과거 학생 (수강권 만료 후 미갱신)
      ClassMembership(
        id: 'cm_013',
        lessonClassId: 'lc_002', // 개인레슨 (teacher_1)
        studentId: 'student_9',
        instrument: '피아노',
        status: MembershipStatus.terminated,
        level: '중급',
        monthlyFee: 200000,
        lessonsPerWeek: 1,
        lessonSlots: [LessonSlot(dayOfWeek: 4, startTime: '15:00', endTime: '16:00')],
        lessonDuration: 60,
        notes: '수강권 만료 후 미갱신',
        createdAt: now.subtract(const Duration(days: 150)),
      ),

      // Student 10 - 과거 학생 (이사로 인한 중단)
      ClassMembership(
        id: 'cm_014',
        lessonClassId: 'lc_002', // 개인레슨 (teacher_1)
        studentId: 'student_10',
        instrument: '첼로',
        status: MembershipStatus.terminated,
        level: '초급',
        monthlyFee: 180000,
        lessonsPerWeek: 1,
        lessonSlots: [LessonSlot(dayOfWeek: 5, startTime: '11:00', endTime: '12:00')],
        lessonDuration: 60,
        notes: '이사로 인한 중단',
        createdAt: now.subtract(const Duration(days: 120)),
      ),
    ]);
  }

  void _notifyListeners() {
    _controller.add(List.unmodifiable(_memberships));
  }

  @override
  Future<List<ClassMembership>> getByClassId(String classId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _memberships.where((m) => m.lessonClassId == classId).toList();
  }

  @override
  Future<List<ClassMembership>> getByStudentId(String studentId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _memberships.where((m) => m.studentId == studentId).toList();
  }

  @override
  Future<ClassMembership?> getById(String id) async {
    await Future.delayed(const Duration(milliseconds: 50));
    try {
      return _memberships.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<ClassMembership> create(ClassMembership membership) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final newMembership = membership.copyWith(
      id: _uuid.v4(),
      createdAt: DateTime.now(),
    );
    _memberships.add(newMembership);
    _notifyListeners();
    return newMembership;
  }

  @override
  Future<ClassMembership> update(ClassMembership membership) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _memberships.indexWhere((m) => m.id == membership.id);
    if (index == -1) {
      throw Exception('ClassMembership not found: ${membership.id}');
    }
    final updated = membership.copyWith(updatedAt: DateTime.now());
    _memberships[index] = updated;
    _notifyListeners();
    return updated;
  }

  @override
  Future<void> updateStatus(String id, MembershipStatus status) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _memberships.indexWhere((m) => m.id == id);
    if (index == -1) {
      throw Exception('ClassMembership not found: $id');
    }
    _memberships[index] = _memberships[index].copyWith(
      status: status,
      updatedAt: DateTime.now(),
    );
    _notifyListeners();
  }

  @override
  Future<void> delete(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _memberships.removeWhere((m) => m.id == id);
    _notifyListeners();
  }

  @override
  Stream<List<ClassMembership>> watchByClassId(String classId) {
    Future.microtask(() async {
      final memberships = await getByClassId(classId);
      _controller.add(memberships);
    });
    return _controller.stream
        .map((list) => list.where((m) => m.lessonClassId == classId).toList());
  }

  @override
  Stream<List<ClassMembership>> watchByStudentId(String studentId) {
    Future.microtask(() async {
      final memberships = await getByStudentId(studentId);
      _controller.add(memberships);
    });
    return _controller.stream
        .map((list) => list.where((m) => m.studentId == studentId).toList());
  }

  void dispose() {
    _controller.close();
  }
}
