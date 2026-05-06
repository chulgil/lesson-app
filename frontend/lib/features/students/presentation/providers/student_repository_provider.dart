import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/repository_provider.dart';
import '../../data/repositories/mock_student_repository.dart';
import '../../data/repositories/remote_student_repository.dart';
import '../../domain/repositories/student_repository.dart';

part 'student_repository_provider.g.dart';

/// Student repository provider - switches between Mock and Remote.
@Riverpod(keepAlive: true)
StudentRepository studentRepository(StudentRepositoryRef ref) =>
    createRepository<StudentRepository>(
      ref: ref,
      mock: () => MockStudentRepository(),
      remote: (api) => RemoteStudentRepository(api),
    );
