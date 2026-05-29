// #415 R4 — 앱 결제 스냅샷 (현재 사용자의 plan + status + 만료 시간).
//
// 백엔드 `GET /api/v1/me/billing/plan` 응답을 그대로 거의 1:1 매핑.
// 학생 수/한도는 본 엔티티에 포함하지 않는다 (별도 students_provider 와 합성).

import 'billing_plan.dart';
import 'billing_status.dart';

/// 현재 선생님의 앱 결제 상태 스냅샷.
class AppBillingSnapshot {
  const AppBillingSnapshot({
    required this.id,
    required this.userId,
    required this.plan,
    required this.status,
    required this.startedAt,
    required this.expiresAt,
    required this.source,
    required this.originalTransactionId,
    required this.trialUsed,
  });

  /// 백엔드 plan row id.
  final String id;

  /// 소유자 user id.
  final String userId;

  /// 현재 활성 플랜.
  final BillingPlan plan;

  /// 플랜 활성 상태 (active/trial/expired/cancelled).
  final BillingStatus status;

  /// 플랜 시작 시각.
  final DateTime startedAt;

  /// 만료 시각. null = 영구(lifetime) 또는 free.
  final DateTime? expiresAt;

  /// 발급 출처 (`ios`/`android`/`web`/`dev_trial` 등).
  final String source;

  /// IAP 영수증의 original transaction id (영구 식별자).
  final String? originalTransactionId;

  /// 14일 무료 체험 사용 이력 — 중복 트라이얼 차단용.
  final bool trialUsed;

  /// 무료 가입 직후 (가입 = free + active) 기본 스냅샷.
  ///
  /// 백엔드가 404/회원가입 미반영 같은 과도기 상황에서 사용.
  factory AppBillingSnapshot.freeFallback({
    required String userId,
    DateTime? startedAt,
  }) {
    return AppBillingSnapshot(
      id: 'free-fallback',
      userId: userId,
      plan: BillingPlan.free,
      status: BillingStatus.active,
      startedAt: startedAt ?? DateTime.now().toUtc(),
      expiresAt: null,
      source: 'fallback',
      originalTransactionId: null,
      trialUsed: false,
    );
  }

  /// 무제한 플랜인지 여부 (학생 한도 없음).
  bool get isUnlimited =>
      plan == BillingPlan.pro ||
      plan == BillingPlan.studio ||
      plan == BillingPlan.lifetime;

  /// 활성 상태인지 (active 또는 trial).
  bool get isActiveOrTrial =>
      status == BillingStatus.active || status == BillingStatus.trial;

  AppBillingSnapshot copyWith({
    String? id,
    String? userId,
    BillingPlan? plan,
    BillingStatus? status,
    DateTime? startedAt,
    DateTime? expiresAt,
    String? source,
    String? originalTransactionId,
    bool? trialUsed,
  }) {
    return AppBillingSnapshot(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      plan: plan ?? this.plan,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      source: source ?? this.source,
      originalTransactionId:
          originalTransactionId ?? this.originalTransactionId,
      trialUsed: trialUsed ?? this.trialUsed,
    );
  }
}
