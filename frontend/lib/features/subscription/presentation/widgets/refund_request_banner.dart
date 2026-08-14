import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../students/students_facade.dart';
import '../../domain/entities/refund_request.dart';
import '../../domain/entities/subscription.dart';
import '../providers/lesson_policy_providers.dart';
import '../providers/refund_request_providers.dart';
import '../utils/refund_estimate_calculator.dart';
import 'refund_action_box.dart';
import 'refund_request_sheet.dart';
import 'refund_status_badge.dart';

/// Role-aware refund request surface for the subscription detail screen
/// (#1271) — teacher sees the actionable processing box, student sees the
/// entry CTA or the status of their existing request.
///
/// Resolves the latest refund request first and only reaches for
/// membership/lessonClass/policy (needed for teacherId + the reference
/// estimate) inside the specific branches that actually render something —
/// most subscription-detail renders hit neither branch and stay on this
/// single lightweight lookup.
class RefundRequestBanner extends ConsumerWidget {
  final Subscription subscription;
  final String viewerRole;
  final String studentName;

  const RefundRequestBanner({
    super.key,
    required this.subscription,
    required this.viewerRole,
    required this.studentName,
  });

  bool get _isTeacher => viewerRole == 'teacher';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latestAsync = ref.watch(
      refundRequestForSubscriptionProvider(
        subscriptionId: subscription.id,
        asTeacher: _isTeacher,
      ),
    );

    return latestAsync.when(
      data: (latest) {
        if (_isTeacher) {
          if (latest == null || !latest.isRequested) {
            return const SizedBox.shrink();
          }
          return _TeacherActionBoxHost(
            subscription: subscription,
            request: latest,
          );
        }

        if (latest != null) {
          return _StudentStatusRow(request: latest);
        }

        final remaining = subscription.remainingLessons;
        if (remaining == null || remaining <= 0) {
          return const SizedBox.shrink();
        }
        return _StudentEntryHost(
          subscription: subscription,
          studentName: studentName,
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// Resolves the reference estimate (membership -> lessonClass ->
/// effectivePolicy) only once a teacher-actionable request actually exists.
class _TeacherActionBoxHost extends ConsumerWidget {
  final Subscription subscription;
  final RefundRequest request;

  const _TeacherActionBoxHost({
    required this.subscription,
    required this.request,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estimatedAmount = _watchEstimate(ref, subscription);
    return RefundActionBox(request: request, estimatedAmount: estimatedAmount);
  }
}

/// Resolves teacherId (for request creation) and the reference estimate
/// only once the entry CTA is actually about to render (student, no active
/// request, remaining lessons > 0).
class _StudentEntryHost extends ConsumerWidget {
  final Subscription subscription;
  final String studentName;

  const _StudentEntryHost({
    required this.subscription,
    required this.studentName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membershipAsync = ref.watch(
      membershipProvider(subscription.membershipId),
    );
    final membership = membershipAsync.valueOrNull;
    if (membership == null) return const SizedBox.shrink();

    final lessonClassAsync = ref.watch(
      lessonClassProvider(membership.lessonClassId),
    );
    final lessonClass = lessonClassAsync.valueOrNull;
    if (lessonClass == null) return const SizedBox.shrink();

    final estimatedAmount = _watchEstimate(ref, subscription);

    return _StudentEntryRow(
      subscription: subscription,
      teacherId: lessonClass.teacherId,
      studentName: studentName,
      estimatedAmount: estimatedAmount,
    );
  }
}

/// Shared reference-estimate lookup — reads the effective policy for
/// [subscription]'s teacher/class and feeds [estimateRefundAmount]. Returns
/// null while loading/unavailable; both consumers treat that as "참고용
/// 계산 불가" rather than blocking render.
int? _watchEstimate(WidgetRef ref, Subscription subscription) {
  final membershipAsync = ref.watch(
    membershipProvider(subscription.membershipId),
  );
  final membership = membershipAsync.valueOrNull;
  if (membership == null) return null;

  final lessonClassAsync = ref.watch(
    lessonClassProvider(membership.lessonClassId),
  );
  final lessonClass = lessonClassAsync.valueOrNull;
  if (lessonClass == null) return null;

  final policyAsync = ref.watch(
    effectivePolicyProvider(
      teacherId: lessonClass.teacherId,
      lessonClassId: membership.lessonClassId,
    ),
  );
  final policy = policyAsync.valueOrNull;
  if (policy == null) return null;

  return estimateRefundAmount(subscription: subscription, policy: policy);
}

class _StudentStatusRow extends StatelessWidget {
  final RefundRequest request;

  const _StudentStatusRow({required this.request});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.space2,
      ),
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.paperDark,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Row(
        children: [
          RefundStatusBadge(request: request),
          const SizedBox(width: AppSpacing.space2),
          if (request.isRejected &&
              request.rejectReason != null &&
              request.rejectReason!.isNotEmpty)
            Expanded(
              child: Text(
                request.rejectReason!,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StudentEntryRow extends StatelessWidget {
  final Subscription subscription;
  final String teacherId;
  final String studentName;
  final int? estimatedAmount;

  const _StudentEntryRow({
    required this.subscription,
    required this.teacherId,
    required this.studentName,
    required this.estimatedAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.space2,
      ),
      child: OutlinedButton(
        onPressed:
            () => RefundRequestSheet.show(
              context,
              subscriptionId: subscription.id,
              studentId: subscription.studentId,
              teacherId: teacherId,
              studentName: studentName,
              estimatedAmount: estimatedAmount,
            ),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(
            double.infinity,
            AppSpacing.buttonHeightSmall,
          ),
          foregroundColor: AppColors.inkSecondary,
          side: const BorderSide(color: AppColors.inkQuaternary),
        ),
        child: const Text(AppStrings.refundRequestCta),
      ),
    );
  }
}
