import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../students/presentation/providers/lesson_class_providers.dart';
import '../../../students/presentation/providers/membership_providers.dart';
import '../../domain/entities/lesson_policy.dart';
import '../../domain/entities/subscription.dart';
import '../providers/lesson_policy_providers.dart';

/// Bottom sheet showing the applied policy for a subscription.
///
/// Combines:
/// - Subscription snapshot: rescheduleDeadlineHours + totalRescheduleAllowance (+ remaining)
/// - Teacher policy: noShow / carryover summaries (fetched via
///   [effectivePolicyProvider]; gracefully skipped if unavailable)
class SubscriptionPolicySheet extends ConsumerWidget {
  final Subscription subscription;

  const SubscriptionPolicySheet({super.key, required this.subscription});

  static Future<void> show(
    BuildContext context, {
    required Subscription subscription,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (ctx) => DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.45,
            maxChildSize: 0.7,
            minChildSize: 0.3,
            builder:
                (ctx, scrollController) => _SheetFrame(
                  scrollController: scrollController,
                  child: SubscriptionPolicySheet(subscription: subscription),
                ),
          ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membershipAsync = ref.watch(
      membershipProvider(subscription.membershipId),
    );

    return membershipAsync.when(
      loading: () => const _Loading(),
      error: (_, __) => _buildBody(policy: null),
      data: (membership) {
        if (membership == null) return _buildBody(policy: null);
        final lessonClassAsync = ref.watch(
          lessonClassProvider(membership.lessonClassId),
        );
        return lessonClassAsync.when(
          loading: () => const _Loading(),
          error: (_, __) => _buildBody(policy: null),
          data: (lessonClass) {
            if (lessonClass == null) return _buildBody(policy: null);
            final policyAsync = ref.watch(
              effectivePolicyProvider(
                teacherId: lessonClass.teacherId,
                lessonClassId: membership.lessonClassId,
              ),
            );
            return policyAsync.when(
              loading: () => const _Loading(),
              error: (_, __) => _buildBody(policy: null),
              data: (policy) => _buildBody(policy: policy),
            );
          },
        );
      },
    );
  }

  Widget _buildBody({required LessonPolicy? policy}) {
    final remaining = subscription.remainingReschedule;
    final total = subscription.totalRescheduleAllowance;
    final deadline = subscription.rescheduleDeadlineHours;
    final changeLine = '$deadline시간 전까지 · 월 $total회 (남은 $remaining회)';
    final remainingColor =
        remaining <= 0
            ? AppColors.paperAccent
            : remaining == 1
            ? AppColors.paperAccent
            : AppColors.paperAccent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.rule_rounded, size: 20, color: AppColors.paperAccent),
            const SizedBox(width: AppSpacing.space2),
            // Notebook × Score: 바텀시트 섹션 제목은 Playfair sectionTitle 로 통일 (§7.17 패턴).
            Text(
              '적용 정책',
              style: NotebookTypography.sectionTitle.copyWith(
                color: AppColors.paperAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space4),
        _PolicyItem(
          label: '변경 / 취소',
          value: changeLine,
          valueColor: remainingColor,
        ),
        if (policy != null) ...[
          _PolicyItem(label: '노쇼', value: policy.noShowPolicySummary),
          _PolicyItem(label: '이월', value: policy.carryoverPolicySummary),
        ],
        const SizedBox(height: AppSpacing.space3),
        Text(
          '수강권 발급 시점의 정책이 적용됩니다. 선생님이 이후 정책을 변경해도 이 수강권에는 영향을 주지 않습니다.',
          style: AppTypography.caption.copyWith(color: AppColors.inkTertiary),
        ),
      ],
    );
  }
}

class _SheetFrame extends StatelessWidget {
  final Widget child;
  final ScrollController scrollController;

  const _SheetFrame({required this.child, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLarge),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.space2),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.inkQuaternary,
              ),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(AppSpacing.space5),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 120,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _PolicyItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _PolicyItem({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.inkSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodyMedium.copyWith(
                color: valueColor ?? AppColors.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
