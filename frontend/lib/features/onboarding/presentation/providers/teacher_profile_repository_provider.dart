import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_provider.dart';
import '../../../profile/domain/repositories/teacher_profile_repository.dart';
import '../../data/repositories/remote_teacher_profile_repository.dart';

/// Teacher profile repository provider - switches between Mock and Remote.
final teacherProfileRepositoryProvider = Provider<TeacherProfileRepository>((
  ref,
) =>
    createRepository<TeacherProfileRepository>(
      ref: ref,
      mock: () => MockTeacherProfileRepository(),
      remote: (api) => RemoteTeacherProfileRepository(api),
    ));
