import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/environment.dart';
import '../../../../core/network/api_client.dart';
import '../../data/repositories/mock_student_repository.dart';
import '../../data/repositories/remote_student_repository.dart';
import '../../domain/repositories/student_repository.dart';

/// Student repository provider - switches between Mock and Remote.
final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  if (EnvironmentConfig.useMockData) {
    return MockStudentRepository();
  }
  return RemoteStudentRepository(ref.read(apiClientProvider));
});
