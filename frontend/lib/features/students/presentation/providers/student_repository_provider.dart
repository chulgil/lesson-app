import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../repositories/student_repository.dart';

/// Student repository provider
final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  return MockStudentRepository();
});
