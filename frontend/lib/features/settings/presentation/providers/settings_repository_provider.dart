import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/repository_provider.dart';
import '../../data/repositories/mock_settings_repository.dart';
import '../../data/repositories/remote_settings_repository.dart';
import '../../domain/repositories/settings_repository.dart';

part 'settings_repository_provider.g.dart';

/// Settings repository provider - switches between Mock and Remote.
@Riverpod(keepAlive: true)
SettingsRepository settingsRepository(SettingsRepositoryRef ref) =>
    createRepository<SettingsRepository>(
      ref: ref,
      mock: () => MockSettingsRepository(),
      remote: (api) => RemoteSettingsRepository(api),
    );
