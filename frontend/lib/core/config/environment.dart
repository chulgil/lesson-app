/// Environment configuration using --dart-define flags.
///
/// Usage:
///   flutter run --dart-define=USE_MOCK=false --dart-define=API_BASE_URL=http://localhost:8000/api/v1
///
/// Defaults:
///   USE_MOCK=true (mock data), API_BASE_URL=http://localhost:8000/api/v1
class EnvironmentConfig {
  EnvironmentConfig._();

  /// Whether to use mock repositories instead of remote API.
  static const bool useMockData = bool.fromEnvironment(
    'USE_MOCK',
    defaultValue: true,
  );

  /// Base URL for the API server.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000/api/v1',
  );

  /// Request timeout in seconds.
  static const int requestTimeoutSeconds = int.fromEnvironment(
    'REQUEST_TIMEOUT',
    defaultValue: 30,
  );

  /// Whether the app is running in debug/development mode.
  static const bool isDebug = bool.fromEnvironment('DEBUG', defaultValue: true);

  /// Google OAuth Web Client ID (for serverAuthCode exchange).
  /// Set via `--dart-define=GOOGLE_SERVER_CLIENT_ID=your-web-client-id`
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '',
  );

  /// Google OAuth iOS Client ID.
  /// Set via `--dart-define=GOOGLE_IOS_CLIENT_ID=your-ios-client-id`
  static const String googleIosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
    defaultValue: '',
  );

  /// App version string (synced with pubspec.yaml version).
  static const String appVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '1.0.0',
  );
}
