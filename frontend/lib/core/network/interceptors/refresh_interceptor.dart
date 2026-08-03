import 'package:dio/dio.dart';

import '../../auth/token_storage.dart';
import '../../config/environment.dart';

/// Interceptor that handles 401 responses by refreshing the token.
///
/// Uses [QueuedInterceptor] to queue concurrent requests while refreshing.
class RefreshInterceptor extends QueuedInterceptor {
  final Dio _dio;
  final TokenStorage _tokenStorage;

  /// Test seam: builds the short-lived Dio used for the refresh call.
  /// Production default constructs one with bounded timeouts (#1118).
  final Dio Function()? _refreshDioFactory;

  RefreshInterceptor(
    this._dio,
    this._tokenStorage, {
    Dio Function()? refreshDioFactory,
  }) : _refreshDioFactory = refreshDioFactory;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    final refreshToken = await _tokenStorage.getRefreshToken();
    if (refreshToken == null) {
      await _tokenStorage.clearTokens();
      return handler.next(err);
    }

    final Response<dynamic> refreshResponse;
    try {
      // Use a separate Dio instance to avoid interceptor loops
      // #1118: a stalled /auth/token/refresh froze the whole HTTP pipeline
      // (QueuedInterceptor) for minutes — bound it with explicit timeouts.
      final refreshDio = _refreshDioFactory != null
          ? _refreshDioFactory()
          : Dio(
              BaseOptions(
                baseUrl: EnvironmentConfig.apiBaseUrl,
                connectTimeout: Duration(
                  seconds: EnvironmentConfig.requestTimeoutSeconds,
                ),
                receiveTimeout: Duration(
                  seconds: EnvironmentConfig.requestTimeoutSeconds,
                ),
                sendTimeout: Duration(
                  seconds: EnvironmentConfig.requestTimeoutSeconds,
                ),
              ),
            );

      refreshResponse = await refreshDio.post(
        '/auth/token/refresh',
        data: {'refresh_token': refreshToken},
      );
    } on DioException catch (refreshError) {
      // Clear the session ONLY when the server explicitly rejected the
      // refresh token. A network drop / timeout / 5xx (e.g. a backend worker
      // restarting mid-request) is transient — nuking tokens there silently
      // logs the user out and every subsequent request 401s with no recovery
      // (beta incident 2026-07-30). Mirrors auth_provider._tryAutoLogin,
      // which preserves tokens on network/server errors.
      final status = refreshError.response?.statusCode;
      if (status == 401 || status == 403) {
        await _tokenStorage.clearTokens();
      }
      return handler.next(err);
    }

    final newAccessToken = refreshResponse.data['access_token'] as String;
    final newRefreshToken = refreshResponse.data['refresh_token'] as String?;

    await _tokenStorage.saveTokens(
      accessToken: newAccessToken,
      refreshToken: newRefreshToken ?? refreshToken,
    );

    // Retry the original request with the new token. A retry failure is NOT
    // a session failure — the refreshed tokens are valid and saved, so
    // propagate the retry error without clearing them.
    final options = err.requestOptions;
    options.headers['Authorization'] = 'Bearer $newAccessToken';

    try {
      final retryResponse = await _dio.fetch(options);
      return handler.resolve(retryResponse);
    } on DioException catch (retryError) {
      return handler.next(retryError);
    }
  }
}
