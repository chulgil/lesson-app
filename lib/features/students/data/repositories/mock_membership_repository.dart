import 'dart:async';

import 'package:uuid/uuid.dart';

import '../../domain/entities/class_membership.dart';
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
      // Student 1 - Academy membership
      ClassMembership(
        id: 'cm_001',
        lessonClassId: 'lc_001', // 행복음악학원
        studentId: 'student_1',
        instrument: '바이올린',
        status: MembershipStatus.active,
        level: '중급',
        monthlyFee: 200000,
        lessonsPerWeek: 1,
        lessonDay: '월',
        lessonTime: '16:00',
        lessonDuration: 60,
        createdAt: now.subtract(const Duration(days: 60)),
      ),
      // Student 2 - Academy membership
      ClassMembership(
        id: 'cm_002',
        lessonClassId: 'lc_001', // 행복음악학원
        studentId: 'student_2',
        instrument: '피아노',
        status: MembershipStatus.active,
        level: '초급',
        monthlyFee: 180000,
        lessonsPerWeek: 1,
        lessonDay: '화',
        lessonTime: '15:00',
        lessonDuration: 60,
        createdAt: now.subtract(const Duration(days: 45)),
      ),
      // Student 3 - Private lesson membership
      ClassMembership(
        id: 'cm_003',
        lessonClassId: 'lc_002', // 개인레슨
        studentId: 'student_3',
        instrument: '바이올린',
        status: MembershipStatus.active,
        level: '고급',
        monthlyFee: 250000,
        lessonsPerWeek: 1,
        lessonDay: '수',
        lessonTime: '14:00',
        lessonDuration: 60,
        createdAt: now.subtract(const Duration(days: 30)),
      ),
      // Student 4 - Trial
      ClassMembership(
        id: 'cm_004',
        lessonClassId: 'lc_002', // 개인레슨
        studentId: 'student_4',
        instrument: '첼로',
        status: MembershipStatus.trial,
        level: '입문',
        monthlyFee: 150000,
        lessonsPerWeek: 1,
        lessonDay: '목',
        lessonTime: '17:00',
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
        lessonDay: '금',
        lessonTime: '16:00',
        lessonDuration: 60,
        notes: '바이올린 외 피아노 추가 수업',
        createdAt: now.subtract(const Duration(days: 20)),
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
