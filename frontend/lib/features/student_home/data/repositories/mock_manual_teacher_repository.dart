import 'package:hive/hive.dart';

import '../../domain/entities/manual_teacher.dart';

/// Hive-based repository for manually registered teachers.
class MockManualTeacherRepository {
  static const _boxName = 'manual_teachers';

  Future<Box<ManualTeacher>> _openBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      return Hive.openBox<ManualTeacher>(_boxName);
    }
    return Hive.box<ManualTeacher>(_boxName);
  }

  /// Get all manual teachers sorted by creation date (newest first).
  Future<List<ManualTeacher>> getAll() async {
    final box = await _openBox();
    final teachers = box.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return teachers;
  }

  /// Get a single manual teacher by ID.
  Future<ManualTeacher?> getById(String id) async {
    final box = await _openBox();
    try {
      return box.values.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Add a new manual teacher.
  Future<void> add(ManualTeacher teacher) async {
    final box = await _openBox();
    await box.put(teacher.id, teacher);
  }

  /// Update an existing manual teacher.
  Future<void> update(ManualTeacher teacher) async {
    final box = await _openBox();
    await box.put(teacher.id, teacher);
  }

  /// Delete a manual teacher by ID.
  Future<void> delete(String id) async {
    final box = await _openBox();
    await box.delete(id);
  }
}
