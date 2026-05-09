// IAP service wrapping the in_app_purchase plugin.
//
// Handles store product queries, purchases, and restoration.
// Receipt verification is delegated to the backend via BillingRepository.

import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:in_app_purchase/in_app_purchase.dart';

import '../../domain/entities/billing_plan.dart';
import '../../domain/repositories/billing_repository.dart';

/// Store product IDs — must match App Store Connect / Google Play Console.
class IapProductIds {
  IapProductIds._();

  static const proMonthly = 'pro_monthly';
  static const proYearly = 'pro_yearly';
  static const studioMonthly = 'studio_monthly';
  static const lifetime = 'lifetime';

  static const all = {proMonthly, proYearly, studioMonthly, lifetime};
}

/// Purchase result returned to the UI.
sealed class IapPurchaseResult {}

class IapPurchaseSuccess extends IapPurchaseResult {
  final BillingStatus status;
  IapPurchaseSuccess(this.status);
}

class IapPurchaseError extends IapPurchaseResult {
  final String message;
  IapPurchaseError(this.message);
}

class IapPurchaseCancelled extends IapPurchaseResult {}

class IapPurchasePending extends IapPurchaseResult {}

/// Service that wraps [InAppPurchase] plugin and coordinates with the backend.
class IapService {
  final InAppPurchase _iap;
  final BillingRepository _billingRepository;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  Completer<IapPurchaseResult>? _pendingPurchase;

  IapService({required BillingRepository billingRepository, InAppPurchase? iap})
    : _billingRepository = billingRepository,
      _iap = iap ?? InAppPurchase.instance;

  /// Initialize the purchase stream listener. Call once at app startup.
  void initialize() {
    _purchaseSubscription?.cancel();
    _purchaseSubscription = _iap.purchaseStream.listen(
      _onPurchaseUpdated,
      onError: (Object error) {
        developer.log('IAP stream error', error: error, name: 'IapService');
        _completePending(IapPurchaseError('$error'));
      },
    );
  }

  /// Dispose the purchase stream. Call on app shutdown.
  void dispose() {
    _purchaseSubscription?.cancel();
    _purchaseSubscription = null;
  }

  /// Whether the store is available on this device.
  Future<bool> isAvailable() => _iap.isAvailable();

  /// Query product details from the store.
  ///
  /// Returns products with real prices from App Store / Google Play.
  Future<List<ProductDetails>> queryProducts() async {
    final response = await _iap.queryProductDetails(IapProductIds.all);
    if (response.error != null) {
      developer.log(
        'IAP query error',
        error: response.error,
        name: 'IapService',
      );
    }
    return response.productDetails;
  }

  /// Initiate a subscription purchase.
  ///
  /// Returns a [Future] that resolves when the purchase completes,
  /// fails, or is cancelled by the user.
  Future<IapPurchaseResult> buySubscription(ProductDetails product) async {
    _pendingPurchase = Completer<IapPurchaseResult>();

    final purchaseParam = PurchaseParam(productDetails: product);

    // Subscriptions and lifetime are non-consumable
    final started = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    if (!started) {
      _pendingPurchase = null;
      return IapPurchaseError('구매를 시작할 수 없습니다');
    }

    return _pendingPurchase!.future;
  }

  /// Restore previous purchases (device change / reinstall).
  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  // ── Private ──────────────────────────────────────────────────

  Future<void> _onPurchaseUpdated(
    List<PurchaseDetails> purchaseDetailsList,
  ) async {
    for (final purchase in purchaseDetailsList) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          _completePending(IapPurchasePending());

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _verifyAndDeliver(purchase);

        case PurchaseStatus.error:
          _completePending(
            IapPurchaseError(purchase.error?.message ?? '구매 처리 중 오류가 발생했습니다'),
          );

        case PurchaseStatus.canceled:
          _completePending(IapPurchaseCancelled());
      }

      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  Future<void> _verifyAndDeliver(PurchaseDetails purchase) async {
    try {
      final storePlatform = Platform.isIOS ? 'apple' : 'google';
      final receiptData = purchase.verificationData.serverVerificationData;

      final status = await _billingRepository.verifyPurchase(
        storePlatform: storePlatform,
        productId: purchase.productID,
        transactionId: purchase.purchaseID ?? '',
        receiptData: receiptData,
      );

      _completePending(IapPurchaseSuccess(status));
    } catch (e) {
      _completePending(IapPurchaseError('영수증 검증 실패: $e'));
    }
  }

  void _completePending(IapPurchaseResult result) {
    if (_pendingPurchase != null && !_pendingPurchase!.isCompleted) {
      _pendingPurchase!.complete(result);
    }
    _pendingPurchase = null;
  }
}
