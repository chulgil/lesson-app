import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/environment.dart';
import '../../../../core/network/api_client.dart';
import '../../../../repositories/settings_repository.dart';
import '../../data/repositories/remote_settings_repository.dart';

/// Settings repository provider - switches between Mock and Remote.
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  if (EnvironmentConfig.useMockData) {
    return MockSettingsRepository();
  }
  return RemoteSettingsRepository(ref.read(apiClientProvider));
});
