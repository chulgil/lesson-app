import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../config/environment.dart';
import '../network/api_client.dart';
import '../sync/application/mutation_queue_helper.dart';
import '../sync/presentation/providers/sync_provider.dart';

part 'repository_provider.g.dart';

/// App-wide data mode boundary.
///
/// UI/application code should read this provider instead of importing
/// [EnvironmentConfig] directly, so environment branching stays centralized.
@Riverpod(keepAlive: true)
bool mockDataMode(Ref ref) {
  return EnvironmentConfig.useMockData;
}

/// Creates a repository provider that switches between Mock and Remote
/// implementations based on [EnvironmentConfig.useMockData].
///
/// Eliminates the repeated `if (useMockData) { return Mock(); } return Remote();`
/// boilerplate found in 30+ provider files.
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
  if (EnvironmentConfig.useMockData) {
    return mock();
  }
  final apiClient = ref.read(apiClientProvider);
  return remote(apiClient);
}

/// Creates a repository with offline-queue support via [MutationQueueHelper].
///
/// In mock mode, bypasses sync entirely and returns the mock directly.
/// In remote mode, injects both [ApiClient] and [MutationQueueHelper].
///
/// Usage:
/// ```dart
/// @Riverpod(keepAlive: true)
/// LessonRepository lessonRepository(Ref ref) =>
///     createSyncAwareRepository<LessonRepository>(
///       ref: ref,
///       mock: () => MockLessonRepository(),
///       syncAware: (apiClient, queue) => SyncAwareLessonRepository(
///         remote: RemoteLessonRepository(apiClient),
///         queue: queue,
///       ),
///     );
/// ```
T createSyncAwareRepository<T>({
  required Ref ref,
  required T Function() mock,
  required T Function(ApiClient apiClient, MutationQueueHelper queue) syncAware,
}) {
  if (EnvironmentConfig.useMockData) {
    return mock();
  }
  final apiClient = ref.read(apiClientProvider);
  final queue = MutationQueueHelper(
    connectivity: ref.read(connectivityServiceProvider),
    syncService: ref.read(syncServiceProvider),
  );
  return syncAware(apiClient, queue);
}

/// Creates a repository provider for features that do not have a remote API yet.
///
/// Keeps mock-mode branching centralized while allowing production builds to use
/// a local empty/fallback implementation until a real remote adapter exists.
T createLocalFallbackRepository<T>({
  required T Function() mock,
  required T Function() fallback,
}) {
  if (EnvironmentConfig.useMockData) {
    return mock();
  }
  return fallback();
}
