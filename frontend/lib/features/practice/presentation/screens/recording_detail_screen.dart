import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/utils/date_format_utils.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../../core/widgets/notebook/notebook_screen_scaffold.dart';
import '../../../../core/widgets/notebook/section_header.dart';
import '../../domain/entities/recording.dart';
import '../../domain/entities/recording_feedback.dart';
import '../providers/recording_feedback_provider.dart';
import '../providers/recording_provider.dart';
import '../widgets/recording_player_sheet.dart';

/// Student-facing recording detail — playback + teacher feedback.
///
/// Deep-link target for the "선생님 피드백 도착" push notification
/// ([AppRoutes.recordingDetail], actionUrl `/recordings/$recordingId` —
/// see recording_feedback_provider.dart `_notifyStudent`). The recording is
/// looked up by id alone via [recordingByIdProvider], since the deep link
/// carries no repertoireId/studentId.
class RecordingDetailScreen extends ConsumerWidget {
  const RecordingDetailScreen({super.key, required this.recordingId});

  final String recordingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordingAsync = ref.watch(recordingByIdProvider(recordingId));

    return NotebookScreenScaffold(
      appBar: NotebookDetailAppBar(title: AppStrings.recordingDetailTitle),
      body: recordingAsync.when(
        data: (recording) {
          if (recording == null) {
            return const _RecordingNotFound();
          }
          return _RecordingDetailBody(
            recording: recording,
            recordingId: recordingId,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (_, _) => _ErrorView(
              onRetry: () => ref.invalidate(recordingByIdProvider(recordingId)),
            ),
      ),
    );
  }
}

/// Playback (reused [RecordingPlayerSheet]) + read-only feedback thread.
class _RecordingDetailBody extends ConsumerWidget {
  const _RecordingDetailBody({
    required this.recording,
    required this.recordingId,
  });

  final Recording recording;
  final String recordingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedbacks = ref.watch(recordingFeedbackListProvider(recordingId));
    final sorted = [...feedbacks]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.space8),
      children: [
        RecordingPlayerSheet(
          recording: recording,
          repertoireId: recording.repertoireId,
          studentId: recording.studentId,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.space4,
            AppSpacing.screenPadding,
            AppSpacing.space2,
          ),
          child: const NotebookSectionHeader(
            label: AppStrings.recordingDetailFeedbackSectionTitle,
          ),
        ),
        if (sorted.isEmpty)
          const _FeedbackEmpty()
        else
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
            ),
            child: Column(
              children: [
                for (final feedback in sorted) ...[
                  _FeedbackBubble(feedback: feedback),
                  const SizedBox(height: AppSpacing.space3),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _FeedbackEmpty extends StatelessWidget {
  const _FeedbackEmpty();

  @override
  Widget build(BuildContext context) {
    return const EmptyStateWidget(
      icon: Icons.chat_bubble_outline,
      title: AppStrings.recordingFeedbackEmpty,
      subtitle: AppStrings.recordingFeedbackDescription,
    );
  }
}

class _FeedbackBubble extends StatelessWidget {
  const _FeedbackBubble({required this.feedback});

  final RecordingFeedback feedback;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.paperAccentSoft.withValues(alpha: 0.08),
        border: Border.all(
          color: AppColors.paperAccentSoft.withValues(alpha: 0.24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Notebook × Score: 선생님 피드백 본문 = Gaegu 손글씨 주석 (§1.1 · §7.101).
          Text(feedback.content, style: NotebookTypography.hand),
          const SizedBox(height: AppSpacing.space2),
          Text(
            _formatTimestamp(feedback.createdAt),
            style: AppTypography.caption.copyWith(color: AppColors.inkTertiary),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${formatDateYMD(dt)} $h:$m';
  }
}

class _RecordingNotFound extends StatelessWidget {
  const _RecordingNotFound();

  @override
  Widget build(BuildContext context) {
    return const EmptyStateWidget(
      icon: Icons.music_off_outlined,
      title: AppStrings.recordingDetailNotFound,
    );
  }
}

/// 에러 상태 — 재시도 (C7 공통 패턴).
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        ErrorStateWidget(
          title: AppStrings.loadDataFailed,
          actionLabel: AppStrings.retry,
          onAction: onRetry,
        ),
      ],
    );
  }
}
