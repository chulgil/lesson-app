import 'package:dio/dio.dart';

import '../../auth/token_storage.dart';

/// Interceptor that attaches Bearer token to every request.
///
/// Skips token injection if the request already has an Authorization header
/// (e.g., retries from RefreshInterceptor with a fresh token).
class AuthInterceptor extends Interceptor {
  final TokenStorage _tokenStorage;

  AuthInterceptor(this._tokenStorage);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip if Authorization is already set (retry after refresh)
    if (options.headers['Authorization'] != null) {
      handler.next(options);
      return;
    }
    final accessToken = await _tokenStorage.getAccessToken();
    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    handler.next(options);
  }
}
