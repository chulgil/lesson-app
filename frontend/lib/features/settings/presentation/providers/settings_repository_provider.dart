import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/environment.dart';
import '../../../../repositories/settings_repository.dart';

/// Settings repository provider - switches between Mock and Remote.
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  if (EnvironmentConfig.useMockData) {
    return MockSettingsRepository();
  }
  // TODO: Replace with Remote repository when API is ready
  return MockSettingsRepository();
});
