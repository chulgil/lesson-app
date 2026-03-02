import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/environment.dart';
import '../../../../repositories/settings_repository.dart';

/// Settings repository provider - switches between Mock and Remote.
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  if (EnvironmentConfig.useMockData) {
    return MockSettingsRepository();
  }
  // Settings defaults are reasonable starting values for any teacher
  return MockSettingsRepository();
});
