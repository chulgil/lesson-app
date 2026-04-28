import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/app_routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../subscription/subscription_facade.dart';

/// Banner showing subscription renewal CTA when subscriptions are expiring or expired.
/// If a renewal proposal exists, navigates directly to it.
class SubscriptionRenewalBanner extends ConsumerWidget {
  final String studentId;

  const SubscriptionRenewalBanner({super.key, required this.studentId});

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
                ? '갱신 제안이 도착했어요!'
                : (hasExpired ? '수강권이 만료되었습니다' : '수강권이 곧 만료됩니다');

        final targetSub =
            hasExpired ? expiredSubs.first : expiringSoonSubs.first;
        final subtitle =
            hasRenewalProposal
                ? '선생님이 수강권 갱신을 제안했습니다'
                : (hasExpired
                    ? '갱신 요청을 보내 레슨을 이어가세요'
                    : '남은 횟수 ${targetSub.remainingLessons ?? 0}회 · ${targetSub.daysUntilExpiration ?? 0}일 남음');

        final ctaText = hasRenewalProposal ? '확인하기' : '갱신 요청';

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
                context.push('${AppRoutes.lessonRequest}?studentId=$studentId');
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
