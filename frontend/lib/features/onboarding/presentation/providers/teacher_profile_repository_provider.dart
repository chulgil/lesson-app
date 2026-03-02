import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/environment.dart';
import '../../../../repositories/teacher_profile_repository.dart';

/// Teacher profile repository provider - switches between Mock and Remote.
final teacherProfileRepositoryProvider = Provider<TeacherProfileRepository>((
  ref,
) {
  if (EnvironmentConfig.useMockData) {
    return MockTeacherProfileRepository();
  }
  // No remote API yet — use empty mock to avoid dummy data
  return MockTeacherProfileRepository(empty: true);
});
