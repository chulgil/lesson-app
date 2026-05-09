import '../../../../core/network/api_client.dart';
import '../../domain/entities/billing_plan.dart';
import '../../domain/repositories/billing_repository.dart';

/// Remote implementation of [BillingRepository] using FastAPI backend.
class RemoteBillingRepository implements BillingRepository {
  final ApiClient _apiClient;

  RemoteBillingRepository(this._apiClient);

  @override
  Future<BillingStatus> getStatus() async {
    final response = await _apiClient.get('/billing/status');
    return BillingStatus.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<BillingStatus> startTrial() async {
    final response = await _apiClient.post('/billing/trial/start');
    // Trial response has plan + trial_ends_at; re-fetch full status
    final _ = response.data;
    return getStatus();
  }

  @override
  Future<BillingStatus> verifyPurchase({
    required String storePlatform,
    required String productId,
    required String transactionId,
    required String receiptData,
  }) async {
    await _apiClient.post(
      '/billing/verify-purchase',
      data: {
        'store_platform': storePlatform,
        'product_id': productId,
        'transaction_id': transactionId,
        'receipt_data': receiptData,
      },
    );
    return getStatus();
  }

  @override
  Future<BillingStatus> restorePurchase() async {
    await _apiClient.post('/billing/restore');
    return getStatus();
  }

  @override
  Future<List<BillingProduct>> getProducts() async {
    final response = await _apiClient.get('/billing/products');
    final list = response.data as List<dynamic>;
    return list
        .map((e) => BillingProduct.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
