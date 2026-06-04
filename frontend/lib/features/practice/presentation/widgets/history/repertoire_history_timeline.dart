// Repertoire history timeline (§3.4 generated widget — §8.2 mapping).
//
// Renders the full timeline:
//   [summary card]
//   [month group header] [entry row] ... per month
//
// Entries are date-reversed (newest month first). Empty state is delegated
// to the screen; this widget assumes at least one entry. The summary
// counts (total/completed/inProgress) reflect ALL entries regardless of
// the month they appear in.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/app_routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/notebook_typography.dart';
import '../../../../../core/widgets/notebook/staff_divider.dart';
import '../../../domain/entities/repertoire_history_entry.dart';
import '../../../domain/entities/repertoire_timeline.dart';
import '../../extensions/practice_display_extensions.dart';
import '../../extensions/repertoire_history_visuals.dart';
import '../history_summary_card.dart';

/// Builds a chronological timeline of repertoire history entries, grouped
/// by start month with the newest month at the top (§3.4.1).
class RepertoireHistoryTimeline extends StatelessWidget {
  /// Pre-aggregated month groups + summary counts from
  /// [`repertoireTimelineProvider`].
  final RepertoireTimeline timeline;

  const RepertoireHistoryTimeline({super.key, required this.timeline});

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[
      const SizedBox(height: AppSpacing.space3),
      HistorySummaryCard(
        totalCount: timeline.totalCount,
        completedCount: timeline.completedCount,
        inProgressCount: timeline.inProgressCount,
      ),
      const SizedBox(height: AppSpacing.space3),
    ];

    for (final group in timeline.monthGroups) {
      final entries = group.repertoires
          .map(RepertoireHistoryEntry.fromRepertoire)
          .toList();
      items.add(
        _MonthHeader(group: group, hasInProgress: _hasOngoing(entries)),
      );
      for (final entry in entries) {
        items.add(_TimelineEntryCard(entry: entry));
      }
      items.add(const SizedBox(height: AppSpacing.space2));
    }

    items.add(const SizedBox(height: AppSpacing.space8));

    return ListView(children: items);
  }

  bool _hasOngoing(List<RepertoireHistoryEntry> entries) =>
      entries.any((e) => e.isOngoing);
}

/// Section header rendered above each month's entries.
class _MonthHeader extends StatelessWidget {
  final MonthGroup group;
  final bool hasInProgress;

  const _MonthHeader({required this.group, required this.hasInProgress});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.space3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const StaffDivider(),
          const SizedBox(height: AppSpacing.space2),
          Row(
            children: [
              Container(
                width: 3,
                height: 20,
                decoration: const BoxDecoration(color: AppColors.paperAccent),
              ),
              const SizedBox(width: AppSpacing.space2),
              Text(
                group.label,
                style: AppTypography.headingSmall.copyWith(
                  color: AppColors.ink,
                ),
              ),
              if (hasInProgress) ...[
                const SizedBox(width: AppSpacing.space2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.paperAccentSoft,
                  ),
                  child: Text(
                    RepertoireHistoryStatus.inProgress.label,
                    style: NotebookTypography.indicatorLabel,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Single repertoire row inside the timeline.
class _TimelineEntryCard extends StatelessWidget {
  final RepertoireHistoryEntry entry;

  const _TimelineEntryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.space1,
      ),
      child: InkWell(
        onTap: () {
          context.push(
            '${AppRoutes.repertoireDetail.replaceFirst(':id', entry.id)}'
            '?studentId=${entry.studentId}',
          );
        },
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.space3),
          decoration: BoxDecoration(
            color: AppColors.paper,
            border: Border.all(color: AppColors.inkQuaternary),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.name,
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  _StatusBadge(status: entry.status),
                ],
              ),
              const SizedBox(height: AppSpacing.space2),
              Text(
                _periodText(entry),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.space1),
              Text(
                _countsText(entry),
                style: AppTypography.caption.copyWith(
                  color: AppColors.inkTertiary,
                ),
              ),
              const SizedBox(height: AppSpacing.space2),
              ClipRRect(
                child: LinearProgressIndicator(
                  value: entry.completionRate.clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: AppColors.inkQuaternary,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    entry.status.badgeForeground,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Period text (e.g., "1월~ (진행 중)" or "3월~9월 (6개월)") — §3.4.3.
  String _periodText(RepertoireHistoryEntry entry) {
    final startMonth = '${entry.startDate.month}월';
    if (entry.endDate == null) {
      return '$startMonth~ (${RepertoireHistoryStatus.inProgress.label})';
    }
    final endMonth = '${entry.endDate!.month}월';
    return '$startMonth~$endMonth (${entry.durationMonths}개월)';
  }

  /// Section and recording counts text.
  String _countsText(RepertoireHistoryEntry entry) =>
      '섹션 ${entry.sectionCount}개 · 녹음 ${entry.recordingCount}개';
}

/// Status pill rendered next to the repertoire name.
class _StatusBadge extends StatelessWidget {
  final RepertoireHistoryStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: status.badgeBackground),
      child: Text(
        status.label,
        style: AppTypography.caption.copyWith(
          color: status.badgeForeground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
