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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../students/students_facade.dart';
import '../../billing_constants.dart';
import '../../data/services/iap_service.dart';
import '../../domain/entities/app_billing_snapshot.dart';
import '../../domain/services/billing_guard.dart';
import '../providers/app_billing_provider.dart';
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

  await showFreeLimitSheet(
    context: context,
    reason: decision.reason,
    trialAvailable: !snapshot.trialUsed,
    onBuyPro: () => handleBuyPro(context: context, ref: ref),
    onStartTrial: () => handleStartTrial(context: context, ref: ref),
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
    case IapPurchaseFailure():
      _showSnack(messenger, AppStrings.paywallPurchaseFailed);
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
