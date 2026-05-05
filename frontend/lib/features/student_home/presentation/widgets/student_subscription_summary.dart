import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../subscription/presentation/widgets/subscription_membership_card.dart';
import '../providers/student_home_subscription_summary_provider.dart';

/// Widget showing student's subscription summary on dashboard.
class StudentSubscriptionSummary extends ConsumerWidget {
  final String studentId;
  final VoidCallback? onViewAll;

  const StudentSubscriptionSummary({
    super.key,
    required this.studentId,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summariesAsync = ref.watch(
      studentHomeSubscriptionSummariesProvider(studentId),
    );

    return summariesAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return _buildEmptyState(context);
        }

        return _buildContent(context, items);
      },
      loading: () => _buildLoadingState(),
      error: (_, __) => _buildErrorState(),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<StudentHomeSubscriptionSummaryItem> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppStrings.studentHomeMySubscriptions,
              style: NotebookTypography.sectionTitle,
            ),
            if (onViewAll != null)
              TextButton(
                onPressed: onViewAll,
                child: const Text(AppStrings.studentHomeViewAllSpaced),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.space3),

        // Subscription cards
        ...items.map((item) {
          final subscription = item.subscription;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.space3),
            child: SubscriptionMembershipCard(
              subscription: subscription,
              classNameAsync: AsyncData(item.className),
              instrument: item.instrument,
              onTap:
                  subscription.id.isNotEmpty
                      ? () {
                        context.push(
                          AppRoutes.subscriptionDetail.replaceFirst(
                            ':id',
                            subscription.id,
                          ),
                          extra: {'viewerRole': 'student'},
                        );
                      }
                      : null,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Column(
        children: [
          Icon(
            Icons.confirmation_number_outlined,
            size: 48,
            color: AppColors.inkTertiary,
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            '등록된 수강권이 없습니다',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(
            '선생님에게 수강권 발급을 요청하세요',
            style: AppTypography.caption.copyWith(color: AppColors.inkTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(color: AppColors.paper),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(color: AppColors.paper),
      child: Text(
        '수강권 정보를 불러올 수 없습니다',
        style: AppTypography.bodyMedium.copyWith(color: AppColors.inkSecondary),
      ),
    );
  }
}
