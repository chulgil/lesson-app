import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/repository_provider.dart';
import '../../../../core/sync/presentation/providers/revalidation_events_provider.dart';
import '../../data/repositories/mock_manual_teacher_repository.dart';
import '../../data/repositories/remote_manual_teacher_repository.dart';
import '../../domain/entities/manual_teacher.dart';
import '../../domain/repositories/manual_teacher_repository.dart';

part 'manual_teacher_provider.g.dart';

/// Repository provider for manual teachers — switches between Mock and Remote.
@Riverpod(keepAlive: true)
ManualTeacherRepository manualTeacherRepository(
  ManualTeacherRepositoryRef ref,
) => createRepository<ManualTeacherRepository>(
  ref: ref,
  mock: () => MockManualTeacherRepository(),
  remote: (api) => RemoteManualTeacherRepository(api),
);

/// AsyncNotifier for manual teacher CRUD operations.
@Riverpod(keepAlive: true)
class ManualTeacherNotifier extends _$ManualTeacherNotifier {
  @override
  Future<List<ManualTeacher>> build() async {
    ref.autoRevalidate('/manual-teachers');
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
