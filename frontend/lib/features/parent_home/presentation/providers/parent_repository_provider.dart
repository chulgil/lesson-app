import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/environment.dart';
import '../../../../core/network/api_client.dart';
import '../../../../repositories/parent_repository.dart';
import '../../data/repositories/remote_parent_repository.dart';

/// Parent repository provider - switches between Mock and Remote.
final parentRepositoryProvider = Provider<ParentRepository>((ref) {
  if (EnvironmentConfig.useMockData) {
    return MockParentRepository();
  }
  return RemoteParentRepository(ref.read(apiClientProvider));
});
