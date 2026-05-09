// Repertoire history timeline screen

import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/repertoire_history_provider.dart';
import '../widgets/history_summary_card.dart';
import '../widgets/month_group_header.dart';
import '../widgets/repertoire_timeline_card.dart';

/// Screen displaying the full repertoire history grouped by month
class RepertoireHistoryScreen extends ConsumerWidget {
  final String studentId;

  const RepertoireHistoryScreen({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timelineAsync = ref.watch(repertoireTimelineProvider(studentId));

    return NotebookScreenScaffold(
      appBar: const NotebookDetailAppBar(
        title: AppStrings.practiceRepertoireHistoryTitle,
      ),
      body: timelineAsync.when(
        data: (timeline) {
          if (timeline.totalCount == 0) {
            return _buildEmptyState();
          }
          return _buildTimeline(timeline);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(ref, error),
      ),
    );
  }

  /// Build the timeline content with summary card and month groups
  Widget _buildTimeline(timeline) {
    // Build a flat list of widgets: summary + (header + cards) per month
    final items = <Widget>[];

    // Summary card at top
    items.add(
      Padding(
        padding: const EdgeInsets.only(top: AppSpacing.space3),
        child: HistorySummaryCard(
          totalCount: timeline.totalCount,
          completedCount: timeline.completedCount,
          inProgressCount: timeline.inProgressCount,
        ),
      ),
    );

    items.add(const SizedBox(height: AppSpacing.space3));

    // Month groups
    for (final monthGroup in timeline.monthGroups) {
      items.add(MonthGroupHeader(monthGroup: monthGroup));
      for (final repertoire in monthGroup.repertoires) {
        items.add(RepertoireTimelineCard(repertoire: repertoire));
      }
      items.add(const SizedBox(height: AppSpacing.space2));
    }

    // Bottom padding
    items.add(const SizedBox(height: AppSpacing.space8));

    return ListView(children: items);
  }

  /// Empty state when no repertoires exist
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.library_music_outlined,
            size: 64,
            color: AppColors.inkSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.space4),
          Text(
            '아직 레퍼토리가 없습니다',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// Error state
  Widget _buildErrorState(WidgetRef ref, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.paperAccent),
          const SizedBox(height: AppSpacing.space4),
          Text(
            AppStrings.practiceErrorOccurred,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.paperAccent,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          TextButton(
            onPressed:
                () => ref.invalidate(repertoireTimelineProvider(studentId)),
            child: const Text(AppStrings.retry),
          ),
        ],
      ),
    );
  }
}
