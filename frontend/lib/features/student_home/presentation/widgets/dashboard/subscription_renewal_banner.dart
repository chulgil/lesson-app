import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/app_routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../subscription/domain/entities/subscription.dart';
import '../../../../subscription/presentation/providers/subscription_providers.dart';

/// Banner showing subscription renewal CTA when subscriptions are expiring or expired.
class SubscriptionRenewalBanner extends ConsumerWidget {
  final String studentId;

  const SubscriptionRenewalBanner({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionsAsync = ref.watch(
      studentSubscriptionsProvider(studentId),
    );

    return subscriptionsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (subscriptions) {
        final expiredSubs = subscriptions
            .where((s) => s.status == SubscriptionStatus.expired)
            .toList();
        final expiringSoonSubs = subscriptions
            .where((s) => s.isExpiringSoon)
            .toList();

        if (expiredSubs.isEmpty && expiringSoonSubs.isEmpty) {
          return const SizedBox.shrink();
        }

        final hasExpired = expiredSubs.isNotEmpty;
        final bannerColor = hasExpired ? AppColors.error : AppColors.warning;
        final title = hasExpired ? '수강권이 만료되었습니다' : '수강권이 곧 만료됩니다';

        final targetSub = hasExpired ? expiredSubs.first : expiringSoonSubs.first;
        final subtitle = hasExpired
            ? '갱신 요청을 보내 레슨을 이어가세요'
            : '남은 횟수 ${targetSub.remainingLessons ?? 0}회 · ${targetSub.daysUntilExpiration ?? 0}일 남음';

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.space3),
          child: GestureDetector(
            onTap: () {
              context.push(
                '${AppRoutes.lessonRequest}?studentId=$studentId',
              );
            },
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.space4),
              decoration: BoxDecoration(
                color: bannerColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                border: Border.all(
                  color: bannerColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: bannerColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.card_membership,
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
                            color: AppColors.textSecondaryLight,
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
                    decoration: BoxDecoration(
                      color: bannerColor,
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusSmall,
                      ),
                    ),
                    child: Text(
                      '갱신 요청',
                      style: AppTypography.caption.copyWith(
                        color: Colors.white,
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
