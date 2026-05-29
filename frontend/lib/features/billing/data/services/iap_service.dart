// #415 R4 Phase C — In-App Purchase service.
//
// in_app_purchase 패키지를 wrap 하여 product 조회, 구매 사이클, 완료 마킹을
// 도메인 친화적인 API 로 노출. 실제 receipt 검증은 백엔드 repository 가 담당.
//
// Phase C1 범위:
//  - StoreKit2 (iOS) / PlayBilling (Android) wrap.
//  - Apple Server-to-Server validator 와 Google Play Developer API 통합은
//    Phase D 에서 추가 (백엔드 IAP_AUTO_GRANT_ON_PENDING_DEV_ONLY 플래그로 dev wiring).

import 'dart:async';
import 'dart:io' show Platform;

import 'package:in_app_purchase/in_app_purchase.dart';

/// 한 번의 구매 사이클 결과.
sealed class IapPurchaseOutcome {
  const IapPurchaseOutcome();
}

class IapPurchaseSuccess extends IapPurchaseOutcome {
  const IapPurchaseSuccess(this.purchase);
  final PurchaseDetails purchase;
}

class IapPurchaseCancelled extends IapPurchaseOutcome {
  const IapPurchaseCancelled();
}

class IapPurchaseFailure extends IapPurchaseOutcome {
  const IapPurchaseFailure(this.message);
  final String message;
}

/// IAP 서비스 계약.
///
/// 테스트는 `FakeIapService` 로 override. production 은 [StoreKitIapService].
abstract class IapService {
  /// 'apple' (iOS / macOS) 또는 'google' (Android). 백엔드 IapValidateRequest 매핑.
  String get platform;

  /// Store 사용 가능 여부.
  Future<bool> isAvailable();

  /// 주어진 product ID 의 메타 정보 조회.
  Future<List<ProductDetails>> queryProducts(Set<String> productIds);

  /// 구매 사이클 1회 (시작 → store 응답 대기 → 결과 반환).
  ///
  /// caller 는 결과의 영수증을 백엔드로 전송한 뒤 [completePurchase] 호출 필수.
  Future<IapPurchaseOutcome> purchase(ProductDetails product);

  /// 구매 완료 마킹 — 백엔드 검증 완료 후 호출. StoreKit2/PlayBilling 에 transaction
  /// finish 신호를 보낸다. 누락 시 동일 구매가 다음 부팅 시 stream 으로 재발생.
  Future<void> completePurchase(PurchaseDetails purchase);
}

/// in_app_purchase 패키지 기반 production 구현.
class StoreKitIapService implements IapService {
  StoreKitIapService([InAppPurchase? iap])
    : _iap = iap ?? InAppPurchase.instance;

  final InAppPurchase _iap;

  @override
  String get platform {
    if (Platform.isIOS) return 'apple';
    if (Platform.isAndroid) return 'google';
    // macOS/Linux/Windows 데스크톱은 in_app_purchase 미지원. 잘못된 platform
    // 태그로 백엔드 audit 가 오염되지 않도록 명시적으로 거부.
    throw UnsupportedError('iap_unsupported_platform');
  }

  @override
  Future<bool> isAvailable() async {
    if (!Platform.isIOS && !Platform.isAndroid) return false;
    return _iap.isAvailable();
  }

  @override
  Future<List<ProductDetails>> queryProducts(Set<String> productIds) async {
    final response = await _iap.queryProductDetails(productIds);
    return response.productDetails;
  }

  @override
  Future<IapPurchaseOutcome> purchase(ProductDetails product) async {
    final completer = Completer<IapPurchaseOutcome>();
    late final StreamSubscription<List<PurchaseDetails>> sub;
    sub = _iap.purchaseStream.listen((purchases) async {
      for (final p in purchases) {
        if (p.productID != product.id) continue;
        if (completer.isCompleted) continue;
        switch (p.status) {
          case PurchaseStatus.pending:
            // 사용자가 결제 sheet 진행 중 — 대기.
            break;
          case PurchaseStatus.purchased:
          case PurchaseStatus.restored:
            completer.complete(IapPurchaseSuccess(p));
          case PurchaseStatus.canceled:
            completer.complete(const IapPurchaseCancelled());
          case PurchaseStatus.error:
            completer.complete(
              IapPurchaseFailure(p.error?.message ?? 'store_error'),
            );
        }
      }
    });

    try {
      final accepted = await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
      if (!accepted) {
        return const IapPurchaseFailure('store_rejected_request');
      }
      // 60s timeout 으로 결제 시트 무한 대기 방지 (사용자가 sheet 을 그냥 두는 경우).
      return await completer.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () => const IapPurchaseFailure('store_timeout'),
      );
    } finally {
      await sub.cancel();
    }
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) =>
      _iap.completePurchase(purchase);
}
