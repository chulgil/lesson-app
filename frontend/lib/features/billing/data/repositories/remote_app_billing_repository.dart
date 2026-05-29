// #415 R4 — 백엔드 `/api/v1/me/billing/plan` 호출 구현.

import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/entities/app_billing_snapshot.dart';
import '../../domain/repositories/app_billing_repository.dart';
import 'app_billing_dto.dart';

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
}
