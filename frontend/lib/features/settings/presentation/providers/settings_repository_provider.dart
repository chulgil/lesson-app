import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_provider.dart';
import '../../../../repositories/settings_repository.dart';
import '../../data/repositories/remote_settings_repository.dart';

/// Settings repository provider - switches between Mock and Remote.
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) =>
    createRepository<SettingsRepository>(
      ref: ref,
      mock: () => MockSettingsRepository(),
      remote: (api) => RemoteSettingsRepository(api),
    ));
