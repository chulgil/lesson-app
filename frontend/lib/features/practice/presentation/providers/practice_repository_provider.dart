import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/environment.dart';
import '../../../../core/network/api_client.dart';
import '../../data/repositories/mock_practice_repository.dart';
import '../../data/repositories/remote_practice_repository.dart';
import '../../domain/repositories/practice_repository.dart';

/// Practice repository provider - switches between Mock and Remote.
final practiceRepositoryProvider = Provider<PracticeRepository>((ref) {
  if (EnvironmentConfig.useMockData) {
    return MockPracticeRepository();
  }
  return RemotePracticeRepository(ref.read(apiClientProvider));
});
