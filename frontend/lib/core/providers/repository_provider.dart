import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../config/environment.dart';
import '../network/api_client.dart';

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
