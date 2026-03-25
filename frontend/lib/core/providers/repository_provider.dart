import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/environment.dart';
import '../network/api_client.dart';

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
