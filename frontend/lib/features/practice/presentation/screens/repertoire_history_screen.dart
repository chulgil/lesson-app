// Repertoire history timeline screen (§3.4).
//
// Thin wiring layer: reads `repertoireTimelineProvider`, delegates the
// timeline rendering to `RepertoireHistoryTimeline`, and shows empty /
// error states. All UI strings live in `AppStrings`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../providers/repertoire_history_provider.dart';
import '../widgets/history/repertoire_history_timeline.dart';

/// Screen displaying the full repertoire history grouped by month.
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
            return const _EmptyState();
          }
          return RepertoireHistoryTimeline(timeline: timeline);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _ErrorState(
          onRetry: () => ref.invalidate(repertoireTimelineProvider(studentId)),
        ),
      ),
    );
  }
}

/// Empty state — reuses `EmptyStateWidget` (§3.4.6 edge case).
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const EmptyStateWidget(
      icon: Icons.library_music_outlined,
      title: AppStrings.practiceRepertoireHistoryEmptyTitle,
      subtitle: AppStrings.practiceRepertoireHistoryEmptySubtitle,
    );
  }
}

/// Error state with retry action.
class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.paperAccent,
          ),
          const SizedBox(height: AppSpacing.space4),
          Text(
            AppStrings.errorOccurred,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.paperAccent,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          TextButton(onPressed: onRetry, child: const Text(AppStrings.retry)),
        ],
      ),
    );
  }
}
