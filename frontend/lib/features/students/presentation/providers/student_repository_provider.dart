import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_provider.dart';
import '../../data/repositories/mock_student_repository.dart';
import '../../data/repositories/remote_student_repository.dart';
import '../../domain/repositories/student_repository.dart';

/// Student repository provider - switches between Mock and Remote.
final studentRepositoryProvider = Provider<StudentRepository>((ref) =>
    createRepository<StudentRepository>(
      ref: ref,
      mock: () => MockStudentRepository(),
      remote: (api) => RemoteStudentRepository(api),
    ));
