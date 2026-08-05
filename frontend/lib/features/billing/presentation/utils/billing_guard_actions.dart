// #415 R4 Phase C — Paywall 가드 + IAP/Trial 실행 헬퍼.
//
// Phase B 가 sheet 만 노출했다면, Phase C 는 "구매하기" / "체험 시작" 버튼이
// 실제 StoreKit2/PlayBilling 흐름과 백엔드 `/me/billing/*` 를 호출한다.
//
// 흐름:
//   - guardAddStudentNavigation: 한도 검사 → blocked 시 sheet 노출
//   - sheet 의 onBuyPro → handleBuyPro: store 조회 → 구매 → 영수증 검증 → 완료 마킹
//   - sheet 의 onStartTrial → handleStartTrial: repo.startTrial → 결과 안내
//
// 모든 결과는 SnackBar 로 안내하고, 성공 시 [appBillingSnapshotProvider] 를
// invalidate 해 홈/대시보드 UI 가 최신 상태를 다시 fetch 하도록 한다.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/analytics/analytics_provider.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../students/students_facade.dart';
import '../../billing_constants.dart';
import '../../data/services/iap_service.dart';
import '../../domain/entities/app_billing_snapshot.dart';
import '../../domain/entities/billing_plan.dart';
import '../../domain/entities/billing_status.dart';
import '../../domain/services/billing_guard.dart';
import '../providers/app_billing_provider.dart';
import '../widgets/feature_locked_sheet.dart';
import '../widgets/free_limit_sheet.dart';

/// 학생 추가 동작 전에 결제 한도를 확인하고 [onPass] 를 호출한다.
///
/// 한도 차단 시 [FreeLimitSheet] 를 보여주고 [onPass] 는 실행하지 않는다.
Future<void> guardAddStudentNavigation({
  required BuildContext context,
  required WidgetRef ref,
  required VoidCallback onPass,
}) async {
  AppBillingSnapshot snapshot;
  int studentCount;
  try {
    snapshot = await ref.read(appBillingSnapshotProvider.future);
    if (!context.mounted) return;
    final students = await ref.read(studentsNotifierProvider.future);
    studentCount = students.length;
  } catch (_) {
    // 데이터 로딩 실패 시 사용자 흐름을 막지 않는다 (백엔드가 server-side 한도를
    // 별도 enforce 함 — Phase A). 클라이언트 가드는 UX 안내 layer 일 뿐.
    if (!context.mounted) return;
    onPass();
    return;
  }
  if (!context.mounted) return;

  const guard = BillingGuard();
  final decision = guard.checkStudentLimit(
    snapshot: snapshot,
    currentStudentCount: studentCount,
  );

  if (decision.allowed) {
    onPass();
    return;
  }

  // #1209 퍼널 1단계 — 한도 차단으로 paywall 이 열린 순간. fire-and-forget.
  unawaited(
    ref
        .read(analyticsServiceProvider)
        .logPaywallLimitReached(
          plan: snapshot.plan.toWire(),
          studentCount: studentCount,
        ),
  );

  await showFreeLimitSheet(
    context: context,
    reason: decision.reason,
    trialAvailable: !snapshot.trialUsed,
    onBuyPro: () => handleBuyPro(context: context, ref: ref),
    onStartTrial: () => handleStartTrial(context: context, ref: ref),
  );
}

/// Pro/Studio 전용 기능 진입 가드.
///
/// 호출 패턴:
///   await guardProFeatureNavigation(
///     context: context,
///     ref: ref,
///     required: TierRequirement.pro,
///     featureName: AppStrings.featureLockedMonthlyStats,
///     onPass: () => context.push(AppRoutes.analytics),
///   );
///
/// 흐름:
/// 1. 스냅샷 로딩 실패 시 fail-open (서버가 SSOT — `guardAddStudentNavigation` 과 동일 정책).
/// 2. `BillingGuard.requireTier` 통과 → [onPass] 실행.
/// 3. tierTooLow → [FeatureLockedSheet] 노출, 사용자가 업그레이드 누르면 [handleBuyPro] (또는 Studio 의 경우 동일 CTA, M5 후속 단계에서 분기).
/// 4. planExpired → 동일 sheet 노출 (Pro 갱신 안내). 7일 유예 동안 동일 paywall UX 재사용.
Future<void> guardProFeatureNavigation({
  required BuildContext context,
  required WidgetRef ref,
  required TierRequirement required,
  required String featureName,
  required VoidCallback onPass,
}) async {
  AppBillingSnapshot snapshot;
  try {
    snapshot = await ref.read(appBillingSnapshotProvider.future);
  } catch (_) {
    // fail-open — 백엔드가 server-side enforcement 책임 (paywall_spec.md §5
    // default-deny). 클라이언트 가드는 UX 안내 layer.
    if (!context.mounted) return;
    onPass();
    return;
  }
  if (!context.mounted) return;

  const guard = BillingGuard();
  final decision = guard.requireTier(snapshot: snapshot, required: required);

  if (decision.allowed) {
    onPass();
    return;
  }

  final lockedTier = switch (required) {
    TierRequirement.pro => LockedFeatureTier.pro,
    TierRequirement.studio => LockedFeatureTier.studio,
  };

  await showFeatureLockedSheet(
    context: context,
    tier: lockedTier,
    featureName: featureName,
    onUpgrade: () => handleBuyPro(context: context, ref: ref),
  );
}

/// Pro 월간 구매 흐름. sheet 이 닫힌 뒤 caller 의 [context] 위에서 호출된다.
///
/// 1. IapService 가용성 확인
/// 2. 상품 정보 조회 ([proMonthlyProductId])
/// 3. buyNonConsumable → outcome 분기
/// 4. Success → 백엔드 `/me/billing/iap/validate` 호출 → completePurchase
/// 5. snapshot invalidate + SnackBar 안내
Future<void> handleBuyPro({
  required BuildContext context,
  required WidgetRef ref,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final iap = ref.read(iapServiceProvider);
  final repo = ref.read(appBillingRepositoryProvider);
  // #1209 — 구매 직전 상태를 캡처해야 trial→유료 전환과 직접 구매를 구분할 수
  // 있다 (구매 후에는 snapshot 이 invalidate 되어 pro/active 로 바뀐다).
  final fromTrial =
      ref.read(appBillingSnapshotProvider).valueOrNull?.status ==
      BillingStatus.trial;

  final available = await iap.isAvailable();
  if (!available) {
    _showSnack(messenger, AppStrings.paywallStoreUnavailable);
    return;
  }

  final products = await iap.queryProducts({proMonthlyProductId});
  final product = products
      .where((p) => p.id == proMonthlyProductId)
      .toList(growable: false);
  if (product.isEmpty) {
    _showSnack(messenger, AppStrings.paywallProductNotFound);
    return;
  }

  final outcome = await iap.purchase(product.first);

  switch (outcome) {
    case IapPurchaseCancelled():
      _showSnack(messenger, AppStrings.paywallPurchaseCancelled);
    case IapPurchaseFailure(:final message):
      _showSnack(messenger, classifyPurchaseFailureMessage(message));
    case IapPurchaseSuccess(:final purchase):
      try {
        final result = await repo.validatePurchase(
          platform: iap.platform,
          receipt: purchase.verificationData.serverVerificationData,
          productId: proMonthlyProductId,
        );
        // store transaction finish — 백엔드 검증 결과와 무관하게 호출해야
        // 동일 구매가 다음 부팅 시 stream 으로 재발생하지 않는다.
        await iap.completePurchase(purchase);
        ref.invalidate(appBillingSnapshotProvider);
        if (result.granted) {
          // #1209 퍼널 3단계 — 영수증 검증까지 통과해 plan 이 실제 활성화된 경우만.
          unawaited(
            ref
                .read(analyticsServiceProvider)
                .logSubscriptionUpgraded(
                  plan: BillingPlan.pro.toWire(),
                  fromTrial: fromTrial,
                ),
          );
        }
        _showSnack(
          messenger,
          result.granted
              ? AppStrings.paywallPurchaseSuccess
              : AppStrings.paywallPurchasePending,
        );
      } catch (_) {
        // 백엔드 검증 실패 — 구매 자체는 store 가 확정했으므로 completePurchase
        // 는 호출하지 않는다 (다음 부팅 시 재시도 기회를 남긴다).
        _showSnack(messenger, AppStrings.paywallPurchaseFailed);
      }
  }
}

/// IapPurchaseFailure.message 를 사용자 친화 SnackBar 문구로 분류. #415 Phase B3.
///
/// 알려진 패턴:
/// - network / connection / internet / timeout → 네트워크 안내
/// - payment / card / declined / denied → 결제 거절 안내
/// - 그 외 (store_error / store_rejected_request / 알 수 없는 store 메시지) → store 일반 오류
@visibleForTesting
String classifyPurchaseFailureMessage(String message) {
  final lower = message.toLowerCase();
  if (lower.contains('network') ||
      lower.contains('connection') ||
      lower.contains('internet') ||
      lower.contains('timeout')) {
    return AppStrings.paywallPurchaseFailedNetwork;
  }
  if (lower.contains('payment') ||
      lower.contains('card') ||
      lower.contains('declined') ||
      lower.contains('denied')) {
    return AppStrings.paywallPurchaseFailedPaymentDeclined;
  }
  return AppStrings.paywallPurchaseFailedStore;
}

/// Lifetime 1회 결제 흐름 — M5 출시 후 90일 한정 얼리어답터.
///
/// handleBuyPro 와 동일한 구조: store 가용성 → 상품 조회 → 구매 → 백엔드 검증 →
/// completePurchase → snapshot invalidate. productId 와 안내 문구만 다르다.
Future<void> handleBuyLifetime({
  required BuildContext context,
  required WidgetRef ref,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final iap = ref.read(iapServiceProvider);
  final repo = ref.read(appBillingRepositoryProvider);

  final available = await iap.isAvailable();
  if (!available) {
    _showSnack(messenger, AppStrings.paywallLifetimeStoreUnavailable);
    return;
  }

  final products = await iap.queryProducts({lifetimeProductId});
  final product = products
      .where((p) => p.id == lifetimeProductId)
      .toList(growable: false);
  if (product.isEmpty) {
    _showSnack(messenger, AppStrings.paywallLifetimeProductNotFound);
    return;
  }

  final outcome = await iap.purchase(product.first);

  switch (outcome) {
    case IapPurchaseCancelled():
      _showSnack(messenger, AppStrings.paywallLifetimePurchaseCancelled);
    case IapPurchaseFailure(:final message):
      _showSnack(messenger, classifyPurchaseFailureMessage(message));
    case IapPurchaseSuccess(:final purchase):
      try {
        final result = await repo.validatePurchase(
          platform: iap.platform,
          receipt: purchase.verificationData.serverVerificationData,
          productId: lifetimeProductId,
        );
        await iap.completePurchase(purchase);
        ref.invalidate(appBillingSnapshotProvider);
        _showSnack(
          messenger,
          result.granted
              ? AppStrings.paywallLifetimePurchaseSuccess
              : AppStrings.paywallLifetimePurchasePending,
        );
      } catch (_) {
        _showSnack(messenger, AppStrings.paywallLifetimePurchaseFailed);
      }
  }
}

/// 14일 Pro 체험 시작 흐름.
///
/// 백엔드가 409 를 돌려주면 (이미 사용) result.message 를 살펴 안내한다.
Future<void> handleStartTrial({
  required BuildContext context,
  required WidgetRef ref,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final repo = ref.read(appBillingRepositoryProvider);

  try {
    final result = await repo.startTrial();
    if (result.success) {
      ref.invalidate(appBillingSnapshotProvider);
      // #1209 퍼널 2단계 — trial 은 별도 tier 가 아니라 (tier=pro, status=trial).
      unawaited(
        ref
            .read(analyticsServiceProvider)
            .logTrialStarted(plan: BillingPlan.pro.toWire()),
      );
      _showSnack(messenger, AppStrings.paywallTrialStarted);
    } else if (result.message.contains('trial_already_used') ||
        result.message.contains('already')) {
      _showSnack(messenger, AppStrings.paywallTrialAlreadyUsed);
    } else {
      _showSnack(messenger, AppStrings.paywallTrialFailed);
    }
  } catch (_) {
    _showSnack(messenger, AppStrings.paywallTrialFailed);
  }
}

void _showSnack(ScaffoldMessengerState messenger, String message) {
  messenger.showSnackBar(SnackBar(content: Text(message)));
}
