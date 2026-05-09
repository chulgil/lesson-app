import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../config/environment.dart';
import '../network/api_client.dart';
import '../sync/application/mutation_queue_helper.dart';
import '../sync/presentation/providers/sync_provider.dart';

part 'repository_provider.g.dart';

/// Runtime data mode — determines mock vs remote repository selection.
///
/// Initial value comes from [EnvironmentConfig.useMockData] (compile-time default).
/// Changed at login time:
/// - DEV account login → `true` (mock repositories)
/// - Social login (Google/Kakao/Apple) → `false` (remote repositories)
///
/// All repository providers watch this via [createRepository] / [createSyncAwareRepository],
/// so changing this triggers automatic provider rebuilds.
@Riverpod(keepAlive: true)
class DataMode extends _$DataMode {
  @override
  bool build() => EnvironmentConfig.useMockData;

  void setMockMode(bool value) => state = value;
}

/// Convenience read-only alias for the current data mode.
///
/// UI code should watch this to show/hide mock-specific elements.
@Riverpod(keepAlive: true)
bool mockDataMode(Ref ref) {
  return ref.watch(dataModeProvider);
}

/// Creates a repository provider that switches between Mock and Remote
/// implementations based on runtime data mode.
///
/// Usage:
/// ```dart
/// @Riverpod(keepAlive: true)
/// StudentRepository studentRepository(Ref ref) =>
///     createRepository<StudentRepository>(
///       ref: ref,
///       mock: () => MockStudentRepository(),
///       remote: (apiClient) => RemoteStudentRepository(apiClient),
///     );
/// ```
T createRepository<T>({
  required Ref ref,
  required T Function() mock,
  required T Function(ApiClient apiClient) remote,
}) {
  final useMock = ref.watch(mockDataModeProvider);
  if (useMock) {
    return mock();
  }
  final apiClient = ref.read(apiClientProvider);
  return remote(apiClient);
}

/// Creates a repository with offline-queue support via [MutationQueueHelper].
///
/// In mock mode, bypasses sync entirely and returns the mock directly.
/// In remote mode, injects both [ApiClient] and [MutationQueueHelper].
T createSyncAwareRepository<T>({
  required Ref ref,
  required T Function() mock,
  required T Function(ApiClient apiClient, MutationQueueHelper queue) syncAware,
}) {
  final useMock = ref.watch(mockDataModeProvider);
  if (useMock) {
    return mock();
  }
  final apiClient = ref.read(apiClientProvider);
  final queue = MutationQueueHelper(
    connectivity: ref.read(connectivityServiceProvider),
    syncService: ref.read(syncServiceProvider),
  );
  return syncAware(apiClient, queue);
}

/// Creates a repository for features without a remote API yet.
///
/// In mock mode: returns [mock] (full mock data).
/// In remote mode: returns [fallback] (empty/stub — no mock data for real users).
T createLocalFallbackRepository<T>({
  required Ref ref,
  required T Function() mock,
  required T Function() fallback,
}) {
  final useMock = ref.watch(mockDataModeProvider);
  if (useMock) {
    return mock();
  }
  return fallback();
}
