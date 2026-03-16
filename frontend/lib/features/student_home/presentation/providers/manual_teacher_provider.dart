import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/mock_manual_teacher_repository.dart';
import '../../domain/entities/manual_teacher.dart';
import '../../domain/repositories/manual_teacher_repository.dart';

part 'manual_teacher_provider.g.dart';

/// Repository provider for manual teachers.
@Riverpod(keepAlive: true)
ManualTeacherRepository manualTeacherRepository(
  ManualTeacherRepositoryRef ref,
) {
  return MockManualTeacherRepository();
}

/// AsyncNotifier for manual teacher CRUD operations.
@Riverpod(keepAlive: true)
class ManualTeacherNotifier extends _$ManualTeacherNotifier {
  @override
  Future<List<ManualTeacher>> build() async {
    final repository = ref.read(manualTeacherRepositoryProvider);
    return repository.getAll();
  }

  Future<void> add(ManualTeacher teacher) async {
    final repository = ref.read(manualTeacherRepositoryProvider);
    await repository.add(teacher);
    ref.invalidateSelf();
  }

  Future<void> updateTeacher(ManualTeacher teacher) async {
    final repository = ref.read(manualTeacherRepositoryProvider);
    await repository.update(teacher);
    ref.invalidateSelf();
  }

  Future<void> delete(String id) async {
    final repository = ref.read(manualTeacherRepositoryProvider);
    await repository.delete(id);
    ref.invalidateSelf();
  }
}
