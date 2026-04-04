import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_format_utils.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/entities/subscription_usage.dart';
import '../providers/subscription_providers.dart';
import '../utils/subscription_status_colors.dart';

/// Chapter 3: Lesson progress — per-session completion/scheduled list.
/// This is the primary chapter that stays expanded.
class SubscriptionChapterLessons extends ConsumerWidget {
  final Subscription subscription;

  const SubscriptionChapterLessons({super.key, required this.subscription});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usageHistoryAsync = ref.watch(
      subscriptionUsageHistoryProvider(subscription.id),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.space2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress summary bar
          _buildProgressSummary(),

          const SizedBox(height: AppSpacing.space4),

          // Lesson list
          usageHistoryAsync.when(
            data: (usages) => _buildLessonTimeline(usages),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.space4),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (_, __) => _buildEmptyState(),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSummary() {
    final remaining = subscription.remainingLessons ?? 0;
    final total = subscription.totalLessonsForDisplay ?? 0;
    final used = subscription.usedLessons;
    final statusColor = SubscriptionStatusColors.getColor(subscription);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.usageProgress(used, total),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
              Text(
                AppStrings.remainingCount(remaining),
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: total > 0 ? used / total : 0,
              minHeight: 8,
              backgroundColor: AppColors.borderLight,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonTimeline(List<SubscriptionUsage> usages) {
    final total = subscription.totalLessonsForDisplay ?? 0;
    // Using centralized date format utilities

    // Build list: completed usages + remaining placeholder slots
    final completedCount = usages.where((u) => u.usageType == UsageType.normal).length;

    return Column(
      children: [
        // Completed lessons
        ...usages.where((u) => u.usageType == UsageType.normal).toList().asMap().entries.map((entry) {
          final index = entry.key;
          final usage = entry.value;
          return _buildLessonRow(
            sessionNumber: index + 1,
            icon: Icons.check_circle,
            iconColor: AppColors.success,
            title: AppStrings.sessionCompleted(index + 1, formatDateMDWithDay(usage.usedAt)),
            subtitle: usage.teacherName != null
                ? '${formatTimeHM(usage.usedAt)} · ${usage.teacherName}'
                : formatTimeHM(usage.usedAt),
            isLast: index + 1 == total,
          );
        }),

        // Remaining slots (placeholder)
        for (int i = completedCount; i < total; i++)
          _buildLessonRow(
            sessionNumber: i + 1,
            icon: i == completedCount ? Icons.schedule : Icons.radio_button_unchecked,
            iconColor: i == completedCount
                ? AppColors.primary
                : AppColors.textTertiaryLight,
            title: i == completedCount
                ? AppStrings.sessionScheduled(i + 1)
                : AppStrings.sessionPending(i + 1),
            subtitle: null,
            isNext: i == completedCount,
            isLast: i + 1 == total,
          ),

        // Empty state
        if (total == 0) _buildEmptyState(),
      ],
    );
  }

  Widget _buildLessonRow({
    required int sessionNumber,
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    bool isNext = false,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline connector
        SizedBox(
          width: 24,
          child: Column(
            children: [
              Icon(icon, size: 20, color: iconColor),
              if (!isLast)
                Container(
                  width: 1,
                  height: 28,
                  color: AppColors.borderLight,
                ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.space3),
        // Content
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.space2),
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.space3,
              vertical: isNext ? AppSpacing.space2 : 4,
            ),
            decoration: isNext
                ? BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                    ),
                  )
                : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: isNext ? FontWeight.w600 : FontWeight.normal,
                    color: isNext
                        ? AppColors.textPrimaryLight
                        : iconColor == AppColors.textTertiaryLight
                            ? AppColors.textTertiaryLight
                            : AppColors.textPrimaryLight,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textTertiaryLight,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space6),
        child: Column(
          children: [
            Icon(
              Icons.music_note,
              size: 40,
              color: AppColors.textTertiaryLight,
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              AppStrings.noLessonRecords,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textTertiaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
