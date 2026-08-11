import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../lessons/lessons_facade.dart';
import '../../../profile/profile_facade.dart';
import '../../../schedule/schedule_facade.dart';
import '../../../subscription/subscription_facade.dart';

/// Unified "needs response" counter for the teacher dashboard.
///
/// Sums the four independent teacher-facing surfaces that already exist on
/// the dashboard — connection requests, direct-booking approvals, lesson
/// requests, and schedule-change requests — so a teacher can tell at a
/// glance whether anything is outstanding before scanning each surface
/// individually. Reuses each surface's own provider and navigation target;
/// no new backend calls or filtering logic are introduced.
///
/// Hides itself entirely when every category is 0.
class PendingActionsSummary extends ConsumerWidget {
  final String teacherId;

  const PendingActionsSummary({super.key, required this.teacherId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionCount =
        ref.watch(pendingRequestCountProvider).valueOrNull ?? 0;
    final bookingCount =
        ref.watch(pendingBookingsCountProvider(teacherId)).valueOrNull ?? 0;
    final lessonRequestCount =
        ref.watch(todayRequestsProvider(teacherId)).valueOrNull?.length ?? 0;
    final scheduleChangeCount =
        ref
            .watch(pendingScheduleChangeRequestsProvider(teacherId))
            .valueOrNull
            ?.length ??
        0;

    final total =
        connectionCount +
        bookingCount +
        lessonRequestCount +
        scheduleChangeCount;
    if (total <= 0) return const SizedBox.shrink();

    final segments = <_SummarySegment>[
      if (connectionCount > 0)
        _SummarySegment(
          label: AppStrings.pendingActionsConnectionLabel,
          count: connectionCount,
          onTap: () => context.push(AppRoutes.pendingRequests),
        ),
      if (bookingCount > 0)
        _SummarySegment(
          label: AppStrings.pendingActionsBookingLabel,
          count: bookingCount,
          onTap:
              () => context.push(
                '${AppRoutes.pendingBookings}?teacherId=$teacherId',
              ),
        ),
      if (lessonRequestCount > 0)
        _SummarySegment(
          label: AppStrings.lessonRequest,
          count: lessonRequestCount,
          onTap:
              () => context.push(
                '${AppRoutes.lessonRequests}?teacherId=$teacherId',
              ),
        ),
      if (scheduleChangeCount > 0)
        _SummarySegment(
          label: AppStrings.scheduleChange,
          count: scheduleChangeCount,
          onTap:
              () => context.push(
                '${AppRoutes.scheduleChangeRequests}?teacherId=$teacherId',
              ),
        ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: AppColors.ink, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.pendingActionsSummaryTitle(total),
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          Wrap(
            spacing: AppSpacing.space1,
            runSpacing: AppSpacing.space1,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (int i = 0; i < segments.length; i++) ...[
                if (i > 0)
                  Text(
                    '·',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.inkTertiary,
                    ),
                  ),
                segments[i],
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// One tappable category chip — reuses [AppStrings.phaseStatLabel] for the
/// "label N" format already used by the sibling phase-stat rows.
class _SummarySegment extends StatelessWidget {
  final String label;
  final int count;
  final VoidCallback onTap;

  const _SummarySegment({
    required this.label,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.space1,
          horizontal: 2,
        ),
        child: Text(
          AppStrings.phaseStatLabel(label, count),
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.ink,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.underline,
            decorationColor: AppColors.inkTertiary,
          ),
        ),
      ),
    );
  }
}
