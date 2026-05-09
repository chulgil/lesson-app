// Subscription plans comparison screen — Notebook × Score design.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../../core/widgets/notebook/notebook_glyph.dart';
import '../../../../core/widgets/notebook/notebook_screen_scaffold.dart';
import '../../../../core/widgets/notebook/thin_rule.dart';
import '../../data/services/iap_service.dart';
import '../../domain/entities/billing_plan.dart';
import '../providers/billing_provider.dart';

class BillingPlansScreen extends ConsumerWidget {
  const BillingPlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billingAsync = ref.watch(billingStatusNotifierProvider);
    final storeProductsAsync = ref.watch(storeProductsProvider);

    return NotebookScreenScaffold(
      appBar: const NotebookDetailAppBar(
        title: AppStrings.billingViewPlans,
      ),
      body: billingAsync.when(
        data: (status) => _BillingPlansBody(
          currentStatus: status,
          storeProducts: storeProductsAsync.valueOrNull ?? [],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            '$e',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _BillingPlansBody extends ConsumerWidget {
  final BillingStatus currentStatus;
  final List<ProductDetails> storeProducts;

  const _BillingPlansBody({
    required this.currentStatus,
    required this.storeProducts,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        // Current plan banner
        _CurrentPlanBanner(status: currentStatus),
        const SizedBox(height: AppSpacing.space5),

        // Plan cards
        _PlanCard(
          planName: 'Free',
          price: AppStrings.billingFreePrice,
          features: const [
            '학생 5명까지',
            '기본 레슨 관리',
            '스케줄 관리',
          ],
          isCurrent: currentStatus.isFree,
        ),
        const SizedBox(height: AppSpacing.space3),

        _PlanCard(
          planName: 'Pro',
          price: _getPrice(IapProductIds.proMonthly) ?? '₩9,900/월',
          yearlyPrice: _getPrice(IapProductIds.proYearly),
          features: const [
            '학생 수 무제한',
            'AI 레슨 노트',
            '녹음 기능',
            '학부모 포털',
            '연습 통계',
          ],
          isCurrent: currentStatus.planType == BillingPlanType.pro,
          isTrial: currentStatus.isTrial,
          isHighlighted: true,
          onSubscribeMonthly: currentStatus.isPaid
              ? null
              : () => _purchase(context, ref, IapProductIds.proMonthly),
          onSubscribeYearly: currentStatus.isPaid
              ? null
              : () => _purchase(context, ref, IapProductIds.proYearly),
        ),
        const SizedBox(height: AppSpacing.space3),

        _PlanCard(
          planName: 'Studio',
          price: _getPrice(IapProductIds.studioMonthly) ?? '₩29,900/월',
          features: const [
            'Pro의 모든 기능',
            '다중 선생님 관리',
            '커스텀 브랜딩',
            '분석 리포트',
          ],
          isCurrent: currentStatus.planType == BillingPlanType.studio,
          onSubscribeMonthly: currentStatus.isPaid &&
                  currentStatus.planType != BillingPlanType.pro
              ? null
              : () => _purchase(context, ref, IapProductIds.studioMonthly),
        ),
        const SizedBox(height: AppSpacing.space3),

        _PlanCard(
          planName: 'Lifetime',
          price: _getPrice(IapProductIds.lifetime) ?? '₩199,000',
          subtitle: '얼리어답터 한정 (90일)',
          features: const [
            'Pro의 모든 기능',
            '영구 이용',
            '평생 업데이트',
          ],
          isCurrent: currentStatus.planType == BillingPlanType.lifetime,
          onSubscribeMonthly: currentStatus.planType == BillingPlanType.lifetime
              ? null
              : () => _purchase(context, ref, IapProductIds.lifetime),
        ),
        const SizedBox(height: AppSpacing.space5),

        // Restore purchases
        Center(
          child: TextButton(
            onPressed: () => _restore(context, ref),
            child: Text(
              AppStrings.billingRestorePurchase,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.inkTertiary,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.space8),
      ],
    );
  }

  String? _getPrice(String productId) {
    final product = storeProducts
        .where((p) => p.id == productId)
        .firstOrNull;
    return product?.price;
  }

  Future<void> _purchase(
    BuildContext context,
    WidgetRef ref,
    String productId,
  ) async {
    final service = ref.read(iapServiceProvider);
    final products = storeProducts.where((p) => p.id == productId);

    if (products.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.paperDark,
            content: Text(
              AppStrings.billingProductNotAvailable,
              style: AppTypography.bodySmall.copyWith(color: AppColors.ink),
            ),
          ),
        );
      }
      return;
    }

    final result = await service.buySubscription(products.first);

    if (!context.mounted) return;

    switch (result) {
      case IapPurchaseSuccess(:final status):
        ref.read(billingStatusNotifierProvider.notifier).refresh();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.paperDark,
            content: Text(
              AppStrings.billingPlanActivated(status.plan),
              style: AppTypography.bodySmall.copyWith(color: AppColors.ink),
            ),
          ),
        );
      case IapPurchaseError(:final message):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.paperDark,
            content: Text(
              message,
              style: AppTypography.bodySmall.copyWith(color: AppColors.ink),
            ),
          ),
        );
      case IapPurchaseCancelled():
        break;
      case IapPurchasePending():
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.paperDark,
            content: Text(
              AppStrings.billingPurchasePending,
              style: AppTypography.bodySmall.copyWith(color: AppColors.ink),
            ),
          ),
        );
    }
  }

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    await ref.read(billingStatusNotifierProvider.notifier).restorePurchase();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.paperDark,
          content: Text(
            AppStrings.billingRestoreComplete,
            style: AppTypography.bodySmall.copyWith(color: AppColors.ink),
          ),
        ),
      );
    }
  }
}

// ── Current plan banner ──────────────────────────────────────

class _CurrentPlanBanner extends StatelessWidget {
  final BillingStatus status;
  const _CurrentPlanBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    final label = switch (status.planType) {
      BillingPlanType.free => 'Free',
      BillingPlanType.trialPro => AppStrings.billingTrialBadge,
      BillingPlanType.pro => AppStrings.billingProBadge,
      BillingPlanType.studio => AppStrings.billingStudioBadge,
      BillingPlanType.lifetime => AppStrings.billingLifetimeBadge,
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: const BoxDecoration(
        color: AppColors.paperDark,
        border: Border(
          top: BorderSide(color: AppColors.ink, width: 2),
          bottom: BorderSide(color: AppColors.inkQuaternary),
        ),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: NotebookTypography.sectionTitle.copyWith(
              color: AppColors.paperAccent,
            ),
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Text(
              _statusText(),
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _statusText() {
    if (status.isTrial && status.daysRemaining != null) {
      return AppStrings.billingTrialDaysLeft(status.daysRemaining!);
    }
    if (status.isPaid && status.daysRemaining != null) {
      return AppStrings.billingDaysLeft(status.daysRemaining!);
    }
    if (status.planType == BillingPlanType.lifetime) {
      return '영구 이용';
    }
    return '현재 플랜';
  }
}

// ── Plan card — Notebook style ──────────────────────────────

class _PlanCard extends StatelessWidget {
  final String planName;
  final String price;
  final String? yearlyPrice;
  final String? subtitle;
  final List<String> features;
  final bool isCurrent;
  final bool isTrial;
  final bool isHighlighted;
  final VoidCallback? onSubscribeMonthly;
  final VoidCallback? onSubscribeYearly;

  const _PlanCard({
    required this.planName,
    required this.price,
    required this.features,
    required this.isCurrent,
    this.yearlyPrice,
    this.subtitle,
    this.isTrial = false,
    this.isHighlighted = false,
    this.onSubscribeMonthly,
    this.onSubscribeYearly,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(
          color: isCurrent ? AppColors.paperAccent : AppColors.inkQuaternary,
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.space4),
            decoration: BoxDecoration(
              color: isHighlighted
                  ? AppColors.paperAccentSoft
                  : AppColors.paperDark,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      planName,
                      style: NotebookTypography.sectionTitle.copyWith(
                        color: AppColors.ink,
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: AppSpacing.space2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.space2,
                          vertical: 2,
                        ),
                        decoration: const BoxDecoration(
                          color: AppColors.paperAccent,
                        ),
                        child: Text(
                          isTrial ? '체험 중' : '현재',
                          style: AppTypography.captionSmall.copyWith(
                            color: AppColors.paper,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.space1),
                Text(
                  price,
                  style: AppTypography.headingMedium.copyWith(
                    color: AppColors.ink,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.space1),
                  Text(
                    subtitle!,
                    style: AppTypography.captionSmall.copyWith(
                      color: AppColors.paperTrial,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const ThinRule(),

          // Features
          Padding(
            padding: const EdgeInsets.all(AppSpacing.space4),
            child: Column(
              children: [
                for (final feature in features)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.space2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        NotebookGlyph(
                          NotebookGlyph.check,
                          size: 14,
                          color: AppColors.paperOk,
                        ),
                        const SizedBox(width: AppSpacing.space2),
                        Expanded(
                          child: Text(
                            feature,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Action buttons
          if (onSubscribeMonthly != null || onSubscribeYearly != null) ...[
            const ThinRule(),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.space4),
              child: Column(
                children: [
                  if (onSubscribeMonthly != null)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: onSubscribeMonthly,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.paperAccent,
                          foregroundColor: AppColors.paper,
                          minimumSize: const Size(
                            double.infinity,
                            AppSpacing.buttonHeightSmall,
                          ),
                          shape: const RoundedRectangleBorder(),
                        ),
                        child: Text(
                          planName == 'Lifetime'
                              ? AppStrings.billingBuyLifetime
                              : AppStrings.billingSubscribeMonthly,
                        ),
                      ),
                    ),
                  if (onSubscribeYearly != null) ...[
                    const SizedBox(height: AppSpacing.space2),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: onSubscribeYearly,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.ink,
                          side: const BorderSide(color: AppColors.inkQuaternary),
                          minimumSize: const Size(
                            double.infinity,
                            AppSpacing.buttonHeightSmall,
                          ),
                          shape: const RoundedRectangleBorder(),
                        ),
                        child: Text(
                          '${AppStrings.billingSubscribeYearly} ${yearlyPrice ?? ''}',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
