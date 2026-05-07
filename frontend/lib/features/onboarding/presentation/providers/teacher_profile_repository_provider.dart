import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/repository_provider.dart';
import '../../../profile/data/repositories/mock_teacher_profile_repository.dart';
import '../../../profile/domain/repositories/teacher_profile_repository.dart';
import '../../data/repositories/remote_teacher_profile_repository.dart';

part 'teacher_profile_repository_provider.g.dart';

/// Teacher profile repository provider - switches between Mock and Remote.
@Riverpod(keepAlive: true)
TeacherProfileRepository teacherProfileRepository(
  TeacherProfileRepositoryRef ref,
) => createRepository<TeacherProfileRepository>(
  ref: ref,
  mock: () => MockTeacherProfileRepository(),
  remote: (api) => RemoteTeacherProfileRepository(api),
);
