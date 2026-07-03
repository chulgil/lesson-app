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
import '../sync/presentation/providers/revalidation_events_provider.dart';
import '../sync/presentation/providers/stale_data_provider.dart';

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
  // observes the final (post-refresh) response and the terminal error. Gated
  // per-domain by ResponseCachePolicy.active's allowlist (grows per batch).
  // Skipped when the cache box is not open (e.g. unit tests without bootstrap).
  if (Hive.isBoxOpen(ResponseCacheStore.boxName)) {
    dio.interceptors.add(
      ResponseCacheInterceptor(
        store: ResponseCacheStore(
          box: Hive.box<String>(ResponseCacheStore.boxName),
        ),
        policy: ResponseCachePolicy.active,
        // D2: feed the staleness banner with the served entry's cachedAt.
        onCacheServed:
            (cachedAt) => ref
                .read(lastServedFromCacheAtProvider.notifier)
                .record(cachedAt),
        // G-06: a live allowlisted read reached a caller → data is fresh, so
        // clear the staleness marker (hides the slow-network banner).
        onFreshServed:
            () => ref.read(lastServedFromCacheAtProvider.notifier).clear(),
        // G-04/SN-1: publish background-revalidation refreshes so subscribed
        // read providers (ref.autoRevalidate) update live on slow networks.
        onRevalidated:
            (path) => ref.read(revalidationEventsProvider.notifier).emit(path),
        // Stale-while-revalidate: re-issue the read as a background request
        // (flagged so it skips the cache-first shortcut) to refresh the store.
        revalidate:
            (options) => dio.get<dynamic>(
              options.path,
              queryParameters: options.queryParameters,
              options: Options(
                extra: const {ResponseCacheInterceptor.swrBackgroundKey: true},
              ),
            ),
      ),
    );
  }

  return ApiClient(dio);
}
