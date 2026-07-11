import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/utils/date_format_utils.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../../../core/widgets/notebook/thin_rule.dart';
import '../../domain/entities/recording_feedback.dart';
import '../../domain/entities/student_practice_overview.dart';
import '../providers/recording_feedback_provider.dart';

/// Bottom sheet where a teacher reviews a shared recording and leaves feedback.
class TeacherFeedbackSheet extends ConsumerStatefulWidget {
  const TeacherFeedbackSheet({
    super.key,
    required this.recording,
    required this.studentId,
    required this.teacherId,
  });

  final SharedRecording recording;
  final String studentId;
  final String teacherId;

  static Future<void> show(
    BuildContext context, {
    required SharedRecording recording,
    required String studentId,
    required String teacherId,
  }) {
    return showNotebookModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder:
          (_) => TeacherFeedbackSheet(
            recording: recording,
            studentId: studentId,
            teacherId: teacherId,
          ),
    );
  }

  @override
  ConsumerState<TeacherFeedbackSheet> createState() =>
      _TeacherFeedbackSheetState();
}

class _TeacherFeedbackSheetState extends ConsumerState<TeacherFeedbackSheet> {
  final TextEditingController _controller = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _submitting) return;

    setState(() => _submitting = true);
    await ref
        .read(
          recordingFeedbackListProvider(widget.recording.recordingId).notifier,
        )
        .add(
          teacherId: widget.teacherId,
          content: text,
          studentId: widget.studentId,
          repertoireName: widget.recording.repertoireName,
        );

    if (!mounted) return;
    _controller.clear();
    setState(() => _submitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(AppStrings.recordingFeedbackSaved),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final feedbacks = ref.watch(
      recordingFeedbackListProvider(widget.recording.recordingId),
    );
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder:
          (context, scrollController) => Container(
            decoration: const BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.zero,
            ),
            padding: EdgeInsets.only(bottom: bottomInset),
            child: Column(
              children: [
                const BottomSheetHandle(
                  margin: EdgeInsets.symmetric(vertical: AppSpacing.space3),
                ),
                _Header(recording: widget.recording),
                const ThinRule(),
                Expanded(
                  child: _FeedbackList(
                    feedbacks: feedbacks,
                    scrollController: scrollController,
                  ),
                ),
                _InputBar(
                  controller: _controller,
                  submitting: _submitting,
                  onSave: _save,
                ),
              ],
            ),
          ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.recording});

  final SharedRecording recording;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        0,
        AppSpacing.screenPadding,
        AppSpacing.space4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Notebook × Score: BottomSheetHandle + 상단 제목 조합은 §7.27
          // 패턴. Playfair appBarTitle 로 통일.
          Text(
            AppStrings.recordingFeedbackTitle,
            style: NotebookTypography.appBarTitle,
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            recording.repertoireName,
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.space1),
          Row(
            children: [
              Text(
                recording.sectionName,
                style: AppTypography.caption.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              Text(
                '· ${recording.formattedDuration}',
                style: AppTypography.caption.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),
              if (recording.bpm != null) ...[
                const SizedBox(width: AppSpacing.space2),
                Text(
                  '· ${recording.bpm} BPM',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            formatDateYMD(recording.sharedAt),
            style: AppTypography.caption.copyWith(color: AppColors.inkTertiary),
          ),
        ],
      ),
    );
  }
}

class _FeedbackList extends StatelessWidget {
  const _FeedbackList({
    required this.feedbacks,
    required this.scrollController,
  });

  final List<RecordingFeedback> feedbacks;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    if (feedbacks.isEmpty) {
      return ListView(
        controller: scrollController,
        children: [
          const SizedBox(height: AppSpacing.space8),
          Icon(
            Icons.chat_bubble_outline,
            size: 40,
            color: AppColors.inkTertiary,
          ),
          const SizedBox(height: AppSpacing.space3),
          Text(
            AppStrings.recordingFeedbackEmpty,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            AppStrings.recordingFeedbackDescription,
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(color: AppColors.inkTertiary),
          ),
        ],
      );
    }

    final sorted = [...feedbacks]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.space3,
      ),
      itemCount: sorted.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.space3),
      itemBuilder: (_, i) => _FeedbackBubble(feedback: sorted[i]),
    );
  }
}

class _FeedbackBubble extends StatelessWidget {
  const _FeedbackBubble({required this.feedback});

  final RecordingFeedback feedback;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Text(
            // Notebook × Score: 선생님 피드백 본문 = Gaegu 손글씨 주석 (§1.1 · §7.101).
            feedback.content,
            style: NotebookTypography.hand,
          ),
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

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.submitting,
    required this.onSave,
  });

  final TextEditingController controller;
  final bool submitting;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space3),
        decoration: const BoxDecoration(
          color: AppColors.paper,
          border: Border(top: BorderSide(color: AppColors.inkQuaternary)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: AppStrings.recordingFeedbackHint,
                  hintStyle: AppTypography.bodyMedium.copyWith(
                    color: AppColors.inkTertiary,
                  ),
                  filled: true,
                  fillColor: AppColors.paperDark,
                  border: const OutlineInputBorder(borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space3,
                    vertical: AppSpacing.space2,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.space2),
            FilledButton(
              onPressed: submitting ? null : onSave,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.paperAccent,
                // 테마 minimumSize=Size(∞,h) 가 Row 의 loose 폭과 충돌하므로 override.
                minimumSize: const Size(0, AppSpacing.buttonHeight),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space4,
                  vertical: AppSpacing.space3,
                ),
                shape: const RoundedRectangleBorder(),
              ),
              child: Text(
                AppStrings.recordingFeedbackSave,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.paper,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
