import 'package:hive/hive.dart';

import '../models/manual_teacher_hive_model.dart';
import '../../domain/entities/manual_teacher.dart';
import '../../domain/repositories/manual_teacher_repository.dart';

/// Hive-based repository for manually registered teachers.
class MockManualTeacherRepository implements ManualTeacherRepository {
  static const _boxName = 'manual_teachers';

  Future<Box<ManualTeacherHiveModel>> _openBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      return Hive.openBox<ManualTeacherHiveModel>(_boxName);
    }
    return Hive.box<ManualTeacherHiveModel>(_boxName);
  }

  /// Get all manual teachers sorted by creation date (newest first).
  @override
  Future<List<ManualTeacher>> getAll() async {
    final box = await _openBox();
    final teachers =
        box.values.map((teacher) => teacher.toDomain()).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return teachers;
  }

  /// Get a single manual teacher by ID.
  @override
  Future<ManualTeacher?> getById(String id) async {
    final box = await _openBox();
    try {
      return box.values.firstWhere((t) => t.id == id).toDomain();
    } catch (_) {
      return null;
    }
  }

  /// Add a new manual teacher.
  @override
  Future<void> add(ManualTeacher teacher) async {
    final box = await _openBox();
    await box.put(teacher.id, ManualTeacherHiveModel.fromDomain(teacher));
  }

  /// Update an existing manual teacher.
  @override
  Future<void> update(ManualTeacher teacher) async {
    final box = await _openBox();
    await box.put(teacher.id, ManualTeacherHiveModel.fromDomain(teacher));
  }

  /// Delete a manual teacher by ID.
  @override
  Future<void> delete(String id) async {
    final box = await _openBox();
    await box.delete(id);
  }
}
