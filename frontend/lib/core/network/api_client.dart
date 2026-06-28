import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../auth/token_storage.dart';
import '../config/environment.dart';
import 'api_exceptions.dart';
import 'cache/response_cache_policy.dart';
import 'cache/response_cache_store.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/logging_interceptor.dart';
import 'interceptors/refresh_interceptor.dart';
import 'interceptors/response_cache_interceptor.dart';

part 'api_client.g.dart';

/// Central API client wrapping Dio with interceptors.
class ApiClient {
  final Dio _dio;

  ApiClient(this._dio);

  Dio get dio => _dio;

  /// GET request.
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _extractApiException(e);
    }
  }

  /// POST request.
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _extractApiException(e);
    }
  }

  /// PUT request.
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _extractApiException(e);
    }
  }

  /// PATCH request.
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _extractApiException(e);
    }
  }

  /// DELETE request.
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _extractApiException(e);
    }
  }

  /// Extract [ApiException] from [DioException].
  ApiException _extractApiException(DioException e) {
    if (e.error is ApiException) {
      return e.error as ApiException;
    }
    return ApiException(
      message: e.message ?? '알 수 없는 오류가 발생했습니다.',
      statusCode: e.response?.statusCode,
    );
  }
}

/// Singleton TokenStorage provider.
@Riverpod(keepAlive: true)
TokenStorage tokenStorage(TokenStorageRef ref) {
  return TokenStorage();
}

/// Singleton ApiClient provider.
@Riverpod(keepAlive: true)
ApiClient apiClient(ApiClientRef ref) {
  final tokenStorage = ref.read(tokenStorageProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: EnvironmentConfig.apiBaseUrl,
      connectTimeout: Duration(
        seconds: EnvironmentConfig.requestTimeoutSeconds,
      ),
      receiveTimeout: Duration(
        seconds: EnvironmentConfig.requestTimeoutSeconds,
      ),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // Order matters: logging → auth → error → refresh
  dio.interceptors.addAll([
    LoggingInterceptor(),
    AuthInterceptor(tokenStorage),
    ErrorInterceptor(),
    RefreshInterceptor(dio, tokenStorage),
  ]);

  // Offline read cache (offline-first plan §3 option A) — added LAST so it
  // observes the final (post-refresh) response and the terminal error. Gated by
  // an empty allowlist in batch 0 (runtime no-op). Skipped when the cache box is
  // not open (e.g. unit tests without app bootstrap).
  if (Hive.isBoxOpen(ResponseCacheStore.boxName)) {
    dio.interceptors.add(
      ResponseCacheInterceptor(
        store: ResponseCacheStore(
          box: Hive.box<String>(ResponseCacheStore.boxName),
        ),
        policy: const ResponseCachePolicy(),
      ),
    );
  }

  return ApiClient(dio);
}
