import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/app_routes.dart';
import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../subscription/subscription_facade.dart';

/// Banner showing subscription renewal CTA when subscriptions are expiring or expired.
/// If a renewal proposal exists, navigates directly to it.
class SubscriptionRenewalBanner extends ConsumerWidget {
  final String studentId;

  const SubscriptionRenewalBanner({super.key, required this.studentId});

  /// Opens the student's lesson-request list to start a renewal request.
  /// Kept on a single line so the route-integrity scanner can resolve it.
  void _openLessonRequests(BuildContext context) {
    context.push('${AppRoutes.myLessonRequests}?studentId=$studentId');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionsAsync = ref.watch(
      studentSubscriptionsProvider(studentId),
    );
    final renewalProposalAsync = ref.watch(
      pendingRenewalProposalProvider(studentId),
    );

    return subscriptionsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (subscriptions) {
        final expiredSubs =
            subscriptions
                .where((s) => s.status == SubscriptionStatus.expired)
                .toList();
        final expiringSoonSubs =
            subscriptions.where((s) => s.isExpiringSoon).toList();

        if (expiredSubs.isEmpty && expiringSoonSubs.isEmpty) {
          return const SizedBox.shrink();
        }

        final hasExpired = expiredSubs.isNotEmpty;
        final renewalProposal = renewalProposalAsync.valueOrNull;
        final hasRenewalProposal = renewalProposal != null;

        final bannerColor =
            hasRenewalProposal
                ? AppColors.ink
                : (hasExpired
                    ? AppColors.paperAccent
                    : AppColors.paperHighlight);

        final title =
            hasRenewalProposal
                ? AppStrings.renewalBannerProposalArrivedTitle
                : (hasExpired ? AppStrings.subscriptionExpiredTitle : AppStrings.subscriptionExpiringSoonTitle);

        final targetSub =
            hasExpired ? expiredSubs.first : expiringSoonSubs.first;
        final subtitle =
            hasRenewalProposal
                ? AppStrings.renewalBannerProposalSubtitle
                : (hasExpired
                    ? AppStrings.renewalBannerSendRequestSubtitle
                    : AppStrings.renewalBannerRemainingSubtitle(targetSub.remainingLessons ?? 0, targetSub.daysUntilExpiration ?? 0));

        final ctaText = hasRenewalProposal ? AppStrings.renewalBannerCheckCta : AppStrings.subscriptionRenewalAction;

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.space3),
          child: GestureDetector(
            onTap: () {
              if (hasRenewalProposal) {
                context.push(
                  AppRoutes.renewalDetail.replaceFirst(
                    ':id',
                    renewalProposal.id,
                  ),
                );
              } else {
                _openLessonRequests(context);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.space4),
              decoration: BoxDecoration(
                color: bannerColor.withValues(alpha: 0.1),
                border: Border.all(color: bannerColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  // §7.132: round → 사각 아이콘 컨테이너 (Notebook 메타포).
                  // bannerColor 는 동적이므로 alpha 변형 유지 (paperAccent 외 팔레트).
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.space2),
                    decoration: BoxDecoration(
                      color: bannerColor.withValues(alpha: 0.2),
                    ),
                    child: Icon(
                      hasRenewalProposal
                          ? Icons.autorenew
                          : Icons.card_membership,
                      color: bannerColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.inkSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space3,
                      vertical: AppSpacing.space2,
                    ),
                    decoration: BoxDecoration(color: bannerColor),
                    child: Text(
                      ctaText,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.paper,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
