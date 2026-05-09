// Subscription plans comparison screen with IAP purchase flow.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/services/iap_service.dart';
import '../../domain/entities/billing_plan.dart';
import '../providers/billing_provider.dart';

class BillingPlansScreen extends ConsumerWidget {
  const BillingPlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billingAsync = ref.watch(billingStatusNotifierProvider);
    final storeProductsAsync = ref.watch(storeProductsProvider);

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: const Text(AppStrings.billingViewPlans),
        backgroundColor: AppColors.paper,
        foregroundColor: AppColors.ink,
        elevation: 0,
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
            style: TextStyle(color: AppColors.inkSecondary),
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
      padding: const EdgeInsets.all(AppSpacing.space4),
      children: [
        // Current plan banner
        _CurrentPlanBanner(status: currentStatus),
        const SizedBox(height: AppSpacing.space6),

        // Plan cards
        _PlanCard(
          planName: 'Free',
          price: '무료',
          features: const [
            '학생 5명까지',
            '기본 레슨 관리',
            '스케줄 관리',
          ],
          isCurrent: currentStatus.isFree,
          accentColor: AppColors.inkTertiary,
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
          accentColor: AppColors.paperAccent,
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
          accentColor: AppColors.profilePurple,
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
          accentColor: AppColors.amber,
          onSubscribeMonthly: currentStatus.planType == BillingPlanType.lifetime
              ? null
              : () => _purchase(context, ref, IapProductIds.lifetime),
        ),
        const SizedBox(height: AppSpacing.space6),

        // Restore purchases
        Center(
          child: TextButton(
            onPressed: () => _restore(context, ref),
            child: const Text(
              AppStrings.billingRestorePurchase,
              style: TextStyle(color: AppColors.inkTertiary),
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
          const SnackBar(content: Text('상품 정보를 불러올 수 없습니다')),
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
            content: Text('${status.plan} 플랜이 활성화되었습니다'),
          ),
        );
      case IapPurchaseError(:final message):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      case IapPurchaseCancelled():
        break;
      case IapPurchasePending():
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('결제가 처리 중입니다')),
        );
    }
  }

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    await ref.read(billingStatusNotifierProvider.notifier).restorePurchase();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('구매 복원이 완료되었습니다')),
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
    final (label, color) = switch (status.planType) {
      BillingPlanType.free => ('Free', AppColors.inkTertiary),
      BillingPlanType.trialPro => (AppStrings.billingTrialBadge, AppColors.paperTrial),
      BillingPlanType.pro => (AppStrings.billingProBadge, AppColors.paperAccent),
      BillingPlanType.studio => (AppStrings.billingStudioBadge, AppColors.profilePurple),
      BillingPlanType.lifetime => (AppStrings.billingLifetimeBadge, AppColors.amber),
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space3,
              vertical: AppSpacing.space1,
            ),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Text(
              _statusText(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.ink,
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

// ── Plan card ──────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  final String planName;
  final String price;
  final String? yearlyPrice;
  final String? subtitle;
  final List<String> features;
  final bool isCurrent;
  final bool isTrial;
  final Color accentColor;
  final VoidCallback? onSubscribeMonthly;
  final VoidCallback? onSubscribeYearly;

  const _PlanCard({
    required this.planName,
    required this.price,
    this.yearlyPrice,
    this.subtitle,
    required this.features,
    required this.isCurrent,
    this.isTrial = false,
    required this.accentColor,
    this.onSubscribeMonthly,
    this.onSubscribeYearly,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(
          color: isCurrent ? accentColor : AppColors.inkQuaternary,
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
              color: accentColor.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSpacing.radiusMedium),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      planName,
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: accentColor,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: AppSpacing.space2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.space2,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusSmall,
                          ),
                        ),
                        child: Text(
                          isTrial ? '체험 중' : '현재',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color: Colors.white,
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
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.space1),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.paperTrial,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ],
            ),
          ),

          // Features
          Padding(
            padding: const EdgeInsets.all(AppSpacing.space4),
            child: Column(
              children: [
                for (final feature in features)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.space2),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline_rounded,
                          size: 18,
                          color: accentColor,
                        ),
                        const SizedBox(width: AppSpacing.space2),
                        Expanded(
                          child: Text(
                            feature,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppColors.ink),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Action buttons
          if (onSubscribeMonthly != null || onSubscribeYearly != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.space4,
                0,
                AppSpacing.space4,
                AppSpacing.space4,
              ),
              child: Column(
                children: [
                  if (onSubscribeMonthly != null)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: onSubscribeMonthly,
                        style: FilledButton.styleFrom(
                          backgroundColor: accentColor,
                          minimumSize: const Size(
                            double.infinity,
                            AppSpacing.buttonHeightSmall,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMedium,
                            ),
                          ),
                        ),
                        child: Text(
                          planName == 'Lifetime' ? '구매하기' : '월간 구독',
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
                          side: BorderSide(color: accentColor),
                          minimumSize: const Size(
                            double.infinity,
                            AppSpacing.buttonHeightSmall,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMedium,
                            ),
                          ),
                        ),
                        child: Text(
                          '연간 구독 ${yearlyPrice ?? ''}',
                          style: TextStyle(color: accentColor),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
