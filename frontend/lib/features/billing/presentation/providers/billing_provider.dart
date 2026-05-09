// Billing providers for IAP subscription status and guard logic.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/repository_provider.dart';
import '../../../students/students_facade.dart';
import '../../data/repositories/mock_billing_repository.dart';
import '../../data/repositories/remote_billing_repository.dart';
import '../../data/services/iap_service.dart';
import '../../domain/entities/billing_plan.dart';
import '../../domain/repositories/billing_repository.dart';

part 'billing_provider.g.dart';

@Riverpod(keepAlive: true)
BillingRepository billingRepository(Ref ref) =>
    createRepository<BillingRepository>(
      ref: ref,
      mock: MockBillingRepository.new,
      remote: (api) => RemoteBillingRepository(api),
    );

/// Current billing status — cached and refreshable.
@Riverpod(keepAlive: true)
class BillingStatusNotifier extends _$BillingStatusNotifier {
  @override
  Future<BillingStatus> build() async {
    final repo = ref.read(billingRepositoryProvider);
    return repo.getStatus();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(billingRepositoryProvider).getStatus(),
    );
  }

  Future<void> startTrial() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(billingRepositoryProvider).startTrial(),
    );
  }

  Future<void> verifyPurchase({
    required String storePlatform,
    required String productId,
    required String transactionId,
    required String receiptData,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(billingRepositoryProvider).verifyPurchase(
            storePlatform: storePlatform,
            productId: productId,
            transactionId: transactionId,
            receiptData: receiptData,
          ),
    );
  }

  Future<void> restorePurchase() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(billingRepositoryProvider).restorePurchase(),
    );
  }
}

/// Whether the current teacher has exceeded the free plan student limit.
///
/// Returns `true` when:
/// - Plan is "free" AND student count >= studentLimit (5)
///
/// Used by [BillingGuard] to trigger the paywall/trial sheet.
@riverpod
bool billingLimitReached(Ref ref) {
  final billingAsync = ref.watch(billingStatusNotifierProvider);
  final studentsAsync = ref.watch(studentsNotifierProvider);

  final billing = billingAsync.valueOrNull;
  final students = studentsAsync.valueOrNull;

  if (billing == null || students == null) return false;
  if (!billing.isFree) return false;

  final limit = billing.studentLimit ?? 5;
  return students.length >= limit;
}

/// Available IAP products from the store.
@riverpod
Future<List<BillingProduct>> billingProducts(Ref ref) async {
  final repo = ref.read(billingRepositoryProvider);
  return repo.getProducts();
}

/// IAP service singleton — manages store interactions.
@Riverpod(keepAlive: true)
IapService iapService(Ref ref) {
  final repo = ref.read(billingRepositoryProvider);
  final service = IapService(billingRepository: repo);
  service.initialize();
  ref.onDispose(service.dispose);
  return service;
}

/// Store product details with real prices from App Store / Google Play.
@riverpod
Future<List<ProductDetails>> storeProducts(Ref ref) async {
  final service = ref.read(iapServiceProvider);
  final available = await service.isAvailable();
  if (!available) return [];
  return service.queryProducts();
}
