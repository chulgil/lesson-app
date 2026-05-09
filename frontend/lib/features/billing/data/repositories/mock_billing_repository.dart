import '../../domain/entities/billing_plan.dart';
import '../../domain/repositories/billing_repository.dart';

/// Mock implementation of [BillingRepository] for dev-login mode.
class MockBillingRepository implements BillingRepository {
  BillingStatus _currentStatus = BillingStatus.defaultFree;

  @override
  Future<BillingStatus> getStatus() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _currentStatus;
  }

  @override
  Future<BillingStatus> startTrial() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final trialEnd = DateTime.now().add(const Duration(days: 14));
    _currentStatus = BillingStatus(
      plan: 'trial_pro',
      isActive: true,
      studentLimit: null,
      trialEndsAt: trialEnd,
      daysRemaining: 14,
      features: const {
        'ai_notes': true,
        'recording': true,
        'parent_portal': true,
        'practice_stats': true,
        'multi_teacher': false,
        'custom_branding': false,
        'analytics_report': false,
      },
    );
    return _currentStatus;
  }

  @override
  Future<BillingStatus> verifyPurchase({
    required String storePlatform,
    required String productId,
    required String transactionId,
    required String receiptData,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final plan = _productToPlan(productId);
    _currentStatus = BillingStatus(
      plan: plan,
      isActive: true,
      studentLimit: null,
      expiresAt: plan == 'lifetime'
          ? null
          : DateTime.now().add(
              productId.contains('yearly')
                  ? const Duration(days: 365)
                  : const Duration(days: 30),
            ),
      daysRemaining: plan == 'lifetime' ? null : 30,
      features: const {
        'ai_notes': true,
        'recording': true,
        'parent_portal': true,
        'practice_stats': true,
        'multi_teacher': false,
        'custom_branding': false,
        'analytics_report': false,
      },
    );
    return _currentStatus;
  }

  @override
  Future<BillingStatus> restorePurchase() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _currentStatus;
  }

  @override
  Future<List<BillingProduct>> getProducts() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return const [
      BillingProduct(
        productId: 'pro_monthly',
        plan: 'pro',
        description: 'Pro 월간 구독',
      ),
      BillingProduct(
        productId: 'pro_yearly',
        plan: 'pro',
        description: 'Pro 연간 구독',
      ),
      BillingProduct(
        productId: 'studio_monthly',
        plan: 'studio',
        description: 'Studio 월간 구독',
      ),
      BillingProduct(
        productId: 'lifetime',
        plan: 'lifetime',
        description: 'Lifetime (영구)',
      ),
    ];
  }

  String _productToPlan(String productId) {
    switch (productId) {
      case 'pro_monthly':
      case 'pro_yearly':
        return 'pro';
      case 'studio_monthly':
        return 'studio';
      case 'lifetime':
        return 'lifetime';
      default:
        return 'free';
    }
  }
}
