// #415 R4 — BillingGuard 순수 로직.
//
// 결제 게이트 결정만 책임진다. UI/Provider/Repository 의존 없음.
// spec/paywall_spec.md §3 기반.

import '../entities/app_billing_snapshot.dart';

/// Free 플랜의 학생 한도.
const int freeStudentLimit = 5;

/// 학생 추가 가드 결과.
class StudentLimitDecision {
  const StudentLimitDecision({required this.allowed, required this.reason});

  /// 학생 추가가 허용되는지.
  final bool allowed;

  /// 차단 사유 (allowed=true 면 [LimitReason.withinLimit]).
  final LimitReason reason;

  bool get blocked => !allowed;
}

enum LimitReason {
  /// 한도 이내 (free + count < 5, 또는 무제한 플랜).
  withinLimit,

  /// Free 플랜에서 5명 도달.
  freeLimitReached,

  /// 플랜은 무제한이지만 status 가 expired — paywall 노출 (7일 유예 후 강등).
  planExpired,
}

/// 결제 가드 — 순수 함수 형태로 결정만 한다.
///
/// UI 가 결과를 받아 Paywall sheet 노출 여부를 결정한다.
class BillingGuard {
  const BillingGuard();

  /// 학생을 1명 추가할 때 결제 한도를 통과하는지 검사.
  ///
  /// [snapshot] 이 [BillingStatus.expired] 면 plan 과 무관하게 차단
  /// (7일 유예 종료 후 free 강등 트리거).
  StudentLimitDecision checkStudentLimit({
    required AppBillingSnapshot snapshot,
    required int currentStudentCount,
  }) {
    if (!snapshot.isActiveOrTrial) {
      return const StudentLimitDecision(
        allowed: false,
        reason: LimitReason.planExpired,
      );
    }

    if (snapshot.isUnlimited) {
      return const StudentLimitDecision(
        allowed: true,
        reason: LimitReason.withinLimit,
      );
    }

    // free + active.
    if (currentStudentCount >= freeStudentLimit) {
      return const StudentLimitDecision(
        allowed: false,
        reason: LimitReason.freeLimitReached,
      );
    }
    return const StudentLimitDecision(
      allowed: true,
      reason: LimitReason.withinLimit,
    );
  }

  /// 현재 플랜의 학생 한도 (무제한이면 null).
  int? effectiveStudentLimit(AppBillingSnapshot snapshot) {
    if (snapshot.isUnlimited) return null;
    return freeStudentLimit;
  }
}
