import 'package:dio/dio.dart';

import '../../auth/token_storage.dart';
import '../../config/environment.dart';

/// Interceptor that handles 401 responses by refreshing the token.
///
/// Uses [QueuedInterceptor] to queue concurrent requests while refreshing.
class RefreshInterceptor extends QueuedInterceptor {
  final Dio _dio;
  final TokenStorage _tokenStorage;

  RefreshInterceptor(this._dio, this._tokenStorage);

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

    try {
      // Use a separate Dio instance to avoid interceptor loops
      final refreshDio = Dio(
        BaseOptions(baseUrl: EnvironmentConfig.apiBaseUrl),
      );

      final response = await refreshDio.post(
        '/auth/token/refresh',
        data: {'refresh_token': refreshToken},
      );

      final newAccessToken = response.data['access_token'] as String;
      final newRefreshToken = response.data['refresh_token'] as String?;

      await _tokenStorage.saveTokens(
        accessToken: newAccessToken,
        refreshToken: newRefreshToken ?? refreshToken,
      );

      // Retry the original request with new token
      final options = err.requestOptions;
      options.headers['Authorization'] = 'Bearer $newAccessToken';

      final retryResponse = await _dio.fetch(options);
      return handler.resolve(retryResponse);
    } on DioException {
      // Refresh failed - clear tokens and propagate the original error
      await _tokenStorage.clearTokens();
      return handler.next(err);
    }
  }
}
