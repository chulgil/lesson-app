import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/repository_provider.dart';
import '../../data/repositories/mock_student_repository.dart';
import '../../data/repositories/remote_student_repository.dart';
import '../../data/repositories/sync_aware_student_repository.dart';
import '../../domain/repositories/student_repository.dart';

part 'student_repository_provider.g.dart';

/// Student repository provider - switches between Mock and SyncAware (Remote with offline queue).
@Riverpod(keepAlive: true)
StudentRepository studentRepository(StudentRepositoryRef ref) =>
    createSyncAwareRepository<StudentRepository>(
      ref: ref,
      mock: () => MockStudentRepository(),
      syncAware: (api, queue) => SyncAwareStudentRepository(
        remote: RemoteStudentRepository(api),
        queue: queue,
      ),
    );
