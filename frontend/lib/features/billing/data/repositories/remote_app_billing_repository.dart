// #415 R4 — 백엔드 `/api/v1/me/billing/*` 호출 구현.

import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/entities/app_billing_snapshot.dart';
import '../../domain/entities/iap_validation_result.dart';
import '../../domain/entities/trial_activation_result.dart';
import '../../domain/repositories/app_billing_repository.dart';
import 'app_billing_dto.dart';
import 'billing_action_dto.dart';

class RemoteAppBillingRepository implements AppBillingRepository {
  RemoteAppBillingRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<AppBillingSnapshot> fetchSnapshot() async {
    try {
      final response = await _apiClient.get<dynamic>('/me/billing/plan');
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return AppBillingDto.fromJson(data);
      }
      return AppBillingSnapshot.freeFallback(userId: '');
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      // 404 = 사용자 plan row 미생성 (가입 직후) → free fallback.
      // 401 = 미인증 → free fallback (UI 가 인증 화면 라우팅 책임).
      if (statusCode == 404 || statusCode == 401) {
        return AppBillingSnapshot.freeFallback(userId: '');
      }
      rethrow;
    }
  }

  @override
  Future<TrialActivationResult> startTrial() async {
    try {
      final response = await _apiClient.post<dynamic>(
        '/me/billing/trial/start',
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return TrialActivationDto.fromJson(data);
      }
      return const TrialActivationResult(
        success: false,
        message: 'invalid_response',
      );
    } on DioException catch (error) {
      // 409 = 이미 체험 사용함. UI 에는 사유 노출.
      if (error.response?.statusCode == 409) {
        final detail = _extractErrorDetail(error.response?.data);
        return TrialActivationResult(
          success: false,
          message: detail ?? 'trial_already_used',
        );
      }
      rethrow;
    }
  }

  @override
  Future<IapValidationResult> validatePurchase({
    required String platform,
    required String receipt,
    required String productId,
  }) async {
    final response = await _apiClient.post<dynamic>(
      '/me/billing/iap/validate',
      data: {'platform': platform, 'receipt': receipt, 'product_id': productId},
    );
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return IapValidationDto.fromJson(data);
    }
    return const IapValidationResult(
      granted: false,
      message: 'invalid_response',
    );
  }

  String? _extractErrorDetail(dynamic data) {
    if (data is Map<String, dynamic>) {
      final detail = data['detail'];
      if (detail is String && detail.isNotEmpty) return detail;
    }
    return null;
  }
}
