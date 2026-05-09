import '../entities/billing_plan.dart';

/// Repository interface for app billing (IAP subscription).
abstract class BillingRepository {
  /// Get current billing status for the authenticated teacher.
  Future<BillingStatus> getStatus();

  /// Start a 14-day Pro trial (once per teacher).
  Future<BillingStatus> startTrial();

  /// Verify a store receipt and activate the corresponding plan.
  Future<BillingStatus> verifyPurchase({
    required String storePlatform,
    required String productId,
    required String transactionId,
    required String receiptData,
  });

  /// Restore purchases from the store (device change).
  Future<BillingStatus> restorePurchase();

  /// List available IAP products.
  Future<List<BillingProduct>> getProducts();
}
