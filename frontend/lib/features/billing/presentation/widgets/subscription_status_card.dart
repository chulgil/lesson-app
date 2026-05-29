// #415 R4 Phase C2 — 프로필 구독 상태 카드.
//
// spec: docs/specs/subscription/paywall_spec.md §6.2
//
// 변형:
//  - Free  : 학생 사용량 + Pro 업그레이드 CTA
//  - Pro/Studio/Lifetime : 갱신일 + 플랜 관리/영수증 CTA
//  - Trial : D-N 종료 + Pro 전환 CTA
//  - Expired: 7일 유예 안내 + 재결제 CTA
//
// AppBillingSnapshot + studentCount 두 값을 받아 표시. 비즈니스 로직(D-N 계산,
// 변형 선택)은 본 위젯이 담당하고, 콜백 (onUpgrade/onManage/onReceipts) 는
// 호출 측이 라우팅을 결정한다.

import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/app_billing_snapshot.dart';
import '../../domain/entities/billing_plan.dart';
import '../../domain/entities/billing_status.dart';
import '../../domain/services/billing_guard.dart';

/// 프로필 화면 상단에 노출되는 구독 상태 카드.
class SubscriptionStatusCard extends StatelessWidget {
  const SubscriptionStatusCard({
    super.key,
    required this.snapshot,
    required this.studentCount,
    required this.onUpgrade,
    required this.onManage,
    required this.onReceipts,
    DateTime? now,
  }) : _nowOverride = now;

  static const upgradeButtonKey = Key('subscription_status_card_upgrade');
  static const manageButtonKey = Key('subscription_status_card_manage');
  static const receiptsButtonKey = Key('subscription_status_card_receipts');

  final AppBillingSnapshot snapshot;
  final int studentCount;
  final VoidCallback onUpgrade;
  final VoidCallback onManage;
  final VoidCallback onReceipts;

  /// 테스트용 시계 주입. 운영 코드는 항상 [DateTime.now] 사용.
  final DateTime? _nowOverride;

  DateTime get _now => _nowOverride ?? DateTime.now();

  _Variant get _variant {
    if (snapshot.status == BillingStatus.expired) return _Variant.expired;
    if (snapshot.status == BillingStatus.trial) return _Variant.trial;
    switch (snapshot.plan) {
      case BillingPlan.free:
        return _Variant.free;
      case BillingPlan.pro:
        return _Variant.pro;
      case BillingPlan.studio:
        return _Variant.studio;
      case BillingPlan.lifetime:
        return _Variant.lifetime;
    }
  }

  /// 만료일까지 남은 일수. 음수면 0 으로 보정.
  int? get _daysToExpiry {
    final expires = snapshot.expiresAt;
    if (expires == null) return null;
    final diff = expires.difference(_now).inDays;
    return diff < 0 ? 0 : diff;
  }

  @override
  Widget build(BuildContext context) {
    final variant = _variant;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          color: AppColors.paper,
          border: Border.all(color: AppColors.inkQuaternary),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BadgeRow(variant: variant, statusLine: _statusLine(variant)),
            const SizedBox(height: AppSpacing.space2),
            Text(
              _detailLine(variant),
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.space3),
            _ActionRow(variant: variant, parent: this),
          ],
        ),
      ),
    );
  }

  String _statusLine(_Variant variant) {
    switch (variant) {
      case _Variant.free:
        // freeStudentLimit 는 domain/services/billing_guard.dart top-level const.
        return AppStrings.billingStatusFreeStudents
            .replaceAll('{used}', studentCount.toString())
            .replaceAll('{limit}', freeStudentLimit.toString());
      case _Variant.pro:
      case _Variant.studio:
        final days = _daysToExpiry;
        if (days == null) return '';
        return AppStrings.billingStatusProRenew.replaceAll(
          '{days}',
          days.toString(),
        );
      case _Variant.trial:
        final days = _daysToExpiry;
        if (days == null) return '';
        return AppStrings.billingStatusTrialEnds.replaceAll(
          '{days}',
          days.toString(),
        );
      case _Variant.lifetime:
        return '';
      case _Variant.expired:
        return '';
    }
  }

  String _detailLine(_Variant variant) {
    switch (variant) {
      case _Variant.free:
        return AppStrings.paywallProMonthlyDescription;
      case _Variant.pro:
        return AppStrings.billingStatusProDetail;
      case _Variant.studio:
        return AppStrings.billingStatusStudioDetail;
      case _Variant.lifetime:
        return AppStrings.billingStatusLifetimeDetail;
      case _Variant.trial:
        return AppStrings.billingStatusTrialDetail;
      case _Variant.expired:
        return AppStrings.billingStatusExpiredDetail;
    }
  }
}

enum _Variant { free, pro, studio, lifetime, trial, expired }

class _BadgeRow extends StatelessWidget {
  const _BadgeRow({required this.variant, required this.statusLine});

  final _Variant variant;
  final String statusLine;

  String get _label {
    switch (variant) {
      case _Variant.free:
        return AppStrings.billingBadgeFree;
      case _Variant.pro:
        return AppStrings.billingBadgePro;
      case _Variant.studio:
        return AppStrings.billingBadgeStudio;
      case _Variant.lifetime:
        return AppStrings.billingBadgeLifetime;
      case _Variant.trial:
        return AppStrings.billingBadgeTrial;
      case _Variant.expired:
        return AppStrings.billingBadgeExpired;
    }
  }

  Color get _badgeBg {
    switch (variant) {
      case _Variant.pro:
      case _Variant.studio:
      case _Variant.lifetime:
        return AppColors.paperAccent;
      case _Variant.trial:
        return AppColors.paperAccentSoft;
      case _Variant.expired:
      case _Variant.free:
        return AppColors.inkQuaternary;
    }
  }

  Color get _badgeFg {
    switch (variant) {
      case _Variant.pro:
      case _Variant.studio:
      case _Variant.lifetime:
        return AppColors.paper;
      case _Variant.trial:
        return AppColors.paperAccent;
      case _Variant.expired:
      case _Variant.free:
        return AppColors.inkSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space2,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: _badgeBg,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          ),
          child: Text(
            _label,
            style: AppTypography.caption.copyWith(
              color: _badgeFg,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
        if (statusLine.isNotEmpty) ...[
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: Text(
              statusLine,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.variant, required this.parent});

  final _Variant variant;
  final SubscriptionStatusCard parent;

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case _Variant.free:
        return _PrimaryButton(
          key: SubscriptionStatusCard.upgradeButtonKey,
          label: AppStrings.billingFreeUpgradeCta,
          onPressed: parent.onUpgrade,
        );
      case _Variant.expired:
        return _PrimaryButton(
          key: SubscriptionStatusCard.upgradeButtonKey,
          label: AppStrings.paywallProBuyCta,
          onPressed: parent.onUpgrade,
        );
      case _Variant.trial:
        return _PrimaryButton(
          key: SubscriptionStatusCard.upgradeButtonKey,
          label: AppStrings.billingTrialConvertCta,
          onPressed: parent.onUpgrade,
        );
      case _Variant.pro:
      case _Variant.studio:
      case _Variant.lifetime:
        return Row(
          children: [
            Expanded(
              child: _SecondaryButton(
                key: SubscriptionStatusCard.manageButtonKey,
                label: AppStrings.billingManagePlanCta,
                onPressed: parent.onManage,
              ),
            ),
            const SizedBox(width: AppSpacing.space2),
            Expanded(
              child: _SecondaryButton(
                key: SubscriptionStatusCard.receiptsButtonKey,
                label: AppStrings.billingReceiptsCta,
                onPressed: parent.onReceipts,
              ),
            ),
          ],
        );
    }
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.paperAccent,
          foregroundColor: AppColors.paper,
          minimumSize: const Size(0, AppSpacing.buttonHeightSmall),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        side: const BorderSide(color: AppColors.inkTertiary),
        minimumSize: const Size(0, AppSpacing.buttonHeightSmall),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        ),
      ),
      child: Text(label),
    );
  }
}
