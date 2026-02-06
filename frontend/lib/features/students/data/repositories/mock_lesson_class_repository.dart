import 'dart:async';

import 'package:uuid/uuid.dart';

import '../../domain/entities/lesson_class.dart';
import '../../domain/repositories/lesson_class_repository.dart';

/// Mock implementation of LessonClassRepository for development.
class MockLessonClassRepository implements LessonClassRepository {
  final _uuid = const Uuid();
  final List<LessonClass> _classes = [];
  final _controller = StreamController<List<LessonClass>>.broadcast();

  MockLessonClassRepository() {
    _initMockData();
  }

  void _initMockData() {
    final now = DateTime.now();

    _classes.addAll([
      LessonClass(
        id: 'lc_001',
        teacherId: 'teacher_1',
        name: '행복음악학원',
        type: LessonClassType.academy,
        paymentType: PaymentType.organization,
        contactPerson: '홍길동',
        contactPhone: '02-1234-5678',
        address: '서울시 강남구 테헤란로 123',
        sortOrder: 0,
        createdAt: now.subtract(const Duration(days: 90)),
      ),
      LessonClass(
        id: 'lc_002',
        teacherId: 'teacher_1',
        name: '개인레슨',
        type: LessonClassType.private,
        paymentType: PaymentType.parent,
        sortOrder: 1,
        createdAt: now.subtract(const Duration(days: 60)),
      ),
      LessonClass(
        id: 'lc_003',
        teacherId: 'teacher_1',
        name: '예술의전당 아카데미',
        type: LessonClassType.academy,
        paymentType: PaymentType.organization,
        contactPerson: '김예술',
        contactPhone: '02-5678-1234',
        address: '서울시 서초구 예술의전당로 123',
        sortOrder: 2,
        createdAt: now.subtract(const Duration(days: 30)),
      ),
    ]);
  }

  void _notifyListeners() {
    _controller.add(List.unmodifiable(_classes));
  }

  @override
  Future<List<LessonClass>> getByTeacherId(String teacherId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _classes
        .where((c) => c.teacherId == teacherId && !c.isArchived)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  @override
  Future<LessonClass?> getById(String id) async {
    await Future.delayed(const Duration(milliseconds: 50));
    try {
      return _classes.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<LessonClass> create(LessonClass lessonClass) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final newClass = lessonClass.copyWith(
      id: _uuid.v4(),
      createdAt: DateTime.now(),
    );
    _classes.add(newClass);
    _notifyListeners();
    return newClass;
  }

  @override
  Future<LessonClass> update(LessonClass lessonClass) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _classes.indexWhere((c) => c.id == lessonClass.id);
    if (index == -1) {
      throw Exception('LessonClass not found: ${lessonClass.id}');
    }
    final updated = lessonClass.copyWith(updatedAt: DateTime.now());
    _classes[index] = updated;
    _notifyListeners();
    return updated;
  }

  @override
  Future<void> archive(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _classes.indexWhere((c) => c.id == id);
    if (index == -1) {
      throw Exception('LessonClass not found: $id');
    }
    _classes[index] = _classes[index].copyWith(
      isArchived: true,
      updatedAt: DateTime.now(),
    );
    _notifyListeners();
  }

  @override
  Future<void> restore(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _classes.indexWhere((c) => c.id == id);
    if (index == -1) {
      throw Exception('LessonClass not found: $id');
    }
    _classes[index] = _classes[index].copyWith(
      isArchived: false,
      updatedAt: DateTime.now(),
    );
    _notifyListeners();
  }

  @override
  Future<void> reorder(List<String> orderedIds) async {
    await Future.delayed(const Duration(milliseconds: 100));
    for (var i = 0; i < orderedIds.length; i++) {
      final index = _classes.indexWhere((c) => c.id == orderedIds[i]);
      if (index != -1) {
        _classes[index] = _classes[index].copyWith(
          sortOrder: i,
          updatedAt: DateTime.now(),
        );
      }
    }
    _notifyListeners();
  }

  @override
  Stream<List<LessonClass>> watchByTeacherId(String teacherId) {
    // Emit current data immediately, then listen for changes
    Future.microtask(() async {
      final classes = await getByTeacherId(teacherId);
      _controller.add(classes);
    });
    return _controller.stream.map(
      (classes) => classes
          .where((c) => c.teacherId == teacherId && !c.isArchived)
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
    );
  }

  void dispose() {
    _controller.close();
  }
}
