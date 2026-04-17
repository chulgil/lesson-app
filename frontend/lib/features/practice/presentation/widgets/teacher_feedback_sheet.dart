import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_format_utils.dart';
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
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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
    ref
        .read(
          recordingFeedbackListProvider(widget.recording.recordingId).notifier,
        )
        .add(teacherId: widget.teacherId, content: text);

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
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: EdgeInsets.only(bottom: bottomInset),
            child: Column(
              children: [
                _DragHandle(),
                _Header(recording: widget.recording),
                const Divider(height: 1, color: AppColors.borderLight),
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

class _DragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.borderLight,
        borderRadius: BorderRadius.circular(2),
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
          Text(
            AppStrings.recordingFeedbackTitle,
            style: AppTypography.headingSmall,
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
                  color: AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              Text(
                '· ${recording.formattedDuration}',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
              if (recording.bpm != null) ...[
                const SizedBox(width: AppSpacing.space2),
                Text(
                  '· ${recording.bpm} BPM',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            formatDateYMD(recording.sharedAt),
            style: AppTypography.caption.copyWith(
              color: AppColors.textTertiaryLight,
            ),
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
            color: AppColors.textTertiaryLight,
          ),
          const SizedBox(height: AppSpacing.space3),
          Text(
            AppStrings.recordingFeedbackEmpty,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            AppStrings.recordingFeedbackDescription,
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(
              color: AppColors.textTertiaryLight,
            ),
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
        color: AppColors.primaryLight.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.space3),
        border: Border.all(
          color: AppColors.primaryLight.withValues(alpha: 0.24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(feedback.content, style: AppTypography.bodyMedium),
          const SizedBox(height: AppSpacing.space2),
          Text(
            _formatTimestamp(feedback.createdAt),
            style: AppTypography.caption.copyWith(
              color: AppColors.textTertiaryLight,
            ),
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
          color: AppColors.surfaceLight,
          border: Border(top: BorderSide(color: AppColors.borderLight)),
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
                    color: AppColors.textTertiaryLight,
                  ),
                  filled: true,
                  fillColor: AppColors.backgroundLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.space3),
                    borderSide: BorderSide.none,
                  ),
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
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space4,
                  vertical: AppSpacing.space3,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.space3),
                ),
              ),
              child: Text(
                AppStrings.recordingFeedbackSave,
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white,
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
