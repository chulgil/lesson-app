import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../repositories/settings_repository.dart';

/// Settings repository provider
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return MockSettingsRepository();
});
