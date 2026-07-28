import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/notebook_typography.dart';
import '../../../../../core/utils/date_format_utils.dart';
import '../../../../../features/lessons/domain/entities/lesson.dart';
import '../../providers/lesson_note_providers.dart';

/// Read-only reference to the same student's previous lesson notes, shown
/// while this lesson's note is being written (#1215).
///
/// Collapsed by default: shows a one-line preview of the latest prior note and
/// expands to at most [maxNotes] entries. The full archive stays in the lesson
/// note history screen.
class PreviousLessonNotesCard extends ConsumerStatefulWidget {
  /// The lesson currently being written — excluded from the reference.
  final Lesson lesson;

  /// Max prior notes surfaced as reference.
  static const int maxNotes = 2;

  const PreviousLessonNotesCard({super.key, required this.lesson});

  @override
  ConsumerState<PreviousLessonNotesCard> createState() =>
      _PreviousLessonNotesCardState();
}

class _PreviousLessonNotesCardState
    extends ConsumerState<PreviousLessonNotesCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(
      studentLessonNotesProvider(widget.lesson.studentId),
    );

    return notesAsync.when(
      data: (notes) {
        final priorNotes = _priorNotes(notes);
        if (priorNotes.isEmpty) return const SizedBox.shrink();
        return _buildCard(priorNotes);
      },
      loading:
          () => const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.space3),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
      // Supplementary reference: a failed lookup must not interrupt writing,
      // so it stays silent instead of pushing an error card above the editor.
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  /// Notes from lessons strictly before this one, newest first.
  ///
  /// The provider already sorts newest first and keeps only lessons that carry
  /// note content, so this narrows to written feedback the teacher can read
  /// back while writing.
  List<Lesson> _priorNotes(List<Lesson> notes) {
    return notes
        .where(
          (l) =>
              l.id != widget.lesson.id &&
              l.date.isBefore(widget.lesson.date) &&
              (l.feedback?.trim().isNotEmpty ?? false),
        )
        .take(PreviousLessonNotesCard.maxNotes)
        .toList();
  }

  Widget _buildCard(List<Lesson> priorNotes) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.space3),
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.paperDark,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: AppSpacing.space2),
          if (_isExpanded)
            ..._buildExpandedNotes(priorNotes)
          else
            _buildCollapsedPreview(priorNotes.first),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return InkWell(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: Row(
        children: [
          Icon(Icons.history, size: 16, color: AppColors.inkTertiary),
          const SizedBox(width: AppSpacing.space2),
          Text(
            AppStrings.previousLessonNotesTitle,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.inkSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Icon(
            _isExpanded ? Icons.expand_less : Icons.expand_more,
            size: 18,
            color: AppColors.inkTertiary,
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsedPreview(Lesson latest) {
    // Notebook × Score: 선생님이 쓴 노트이므로 손글씨(Gaegu)로 렌더.
    return Text(
      latest.feedback!.trim(),
      style: NotebookTypography.handSmall.copyWith(
        color: AppColors.paperPencil,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  List<Widget> _buildExpandedNotes(List<Lesson> priorNotes) {
    return priorNotes.map((lesson) {
      final isLast = lesson == priorNotes.last;
      return Padding(
        padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.space3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              formatDateYMDWithDay(lesson.date),
              style: AppTypography.caption.copyWith(
                color: AppColors.inkTertiary,
              ),
            ),
            const SizedBox(height: AppSpacing.space1),
            Text(
              lesson.feedback!.trim(),
              style: NotebookTypography.handSmall.copyWith(
                color: AppColors.paperPencil,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}
