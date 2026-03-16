import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/environment.dart';
import '../../../../core/network/api_client.dart';
import '../../../../repositories/teacher_profile_repository.dart';
import '../../data/repositories/remote_teacher_profile_repository.dart';

/// Teacher profile repository provider - switches between Mock and Remote.
final teacherProfileRepositoryProvider = Provider<TeacherProfileRepository>((
  ref,
) {
  if (EnvironmentConfig.useMockData) {
    return MockTeacherProfileRepository();
  }
  return RemoteTeacherProfileRepository(ref.read(apiClientProvider));
});
