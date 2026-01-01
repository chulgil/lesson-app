import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../repositories/teacher_profile_repository.dart';

/// Teacher profile repository provider
final teacherProfileRepositoryProvider = Provider<TeacherProfileRepository>((ref) {
  return MockTeacherProfileRepository();
});
