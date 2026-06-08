import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/notebook_typography.dart';
import '../../../../../core/widgets/notebook/notebook_alert_dialog.dart';
import '../../../../../core/widgets/swipe_action_tile.dart';
import '../../../domain/entities/entities.dart';
import '../../providers/practice_note_provider.dart';
import '../notes/note_edit_dialog.dart';

/// 학생 홈 연습 탭에 노출되는 단일 섹션 노트 카드. (§2.4 학생 홈 통합 / #492)
///
/// - 섹션(곡 + 마디 범위)을 헤더로, 최근 노트 3개를 인라인으로 표시.
/// - 노트 행은 [SwipeActionTile] 로 편집/삭제 액션 노출 (ux-rules: trailing 아이콘
///   중복 배치 금지).
/// - 헤더 + 버튼으로 즉시 노트 추가 다이얼로그를 띄운다.
/// - 노트가 [maxInlineNotes] 보다 많으면 "전체보기" 링크로 [PracticeNoteListScreen]
///   진입.
class PracticeNoteCard extends ConsumerWidget {
  const PracticeNoteCard({
    super.key,
    required this.sectionId,
    required this.sectionTitle,
    this.sectionSubtitle,
    this.maxInlineNotes = 3,
  });

  /// 노트가 묶일 섹션 id.
  final String sectionId;

  /// 헤더 메인 텍스트 (보통 곡명).
  final String sectionTitle;

  /// 헤더 보조 텍스트 (마디 범위 등). null 이면 한 줄만 표시.
  final String? sectionSubtitle;

  /// 카드에 인라인 표시할 노트 최대 개수.
  final int maxInlineNotes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(sectionNotesProvider(sectionId));

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(context, ref),
          notesAsync.when(
            data: (notes) => _body(context, ref, notes),
            loading: () => Padding(
              padding: const EdgeInsets.all(AppSpacing.space3),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.inkTertiary,
                    ),
                  ),
                ),
              ),
            ),
            error: (_, __) => _emptyBody(),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space3,
        AppSpacing.space3,
        AppSpacing.space2,
        AppSpacing.space2,
      ),
      child: Row(
        children: [
          Icon(Icons.edit_note, color: AppColors.paperAccent, size: 20),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sectionTitle, style: NotebookTypography.pieceTitle),
                if (sectionSubtitle != null && sectionSubtitle!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      sectionSubtitle!,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.inkSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _addNote(context, ref),
            icon: const Icon(Icons.add, color: AppColors.ink, size: 20),
            tooltip: AppStrings.practiceNoteAddTooltip,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, WidgetRef ref, List<PracticeNote> notes) {
    if (notes.isEmpty) {
      return _emptyBody();
    }

    final visible = notes.take(maxInlineNotes).toList();
    final hasMore = notes.length > maxInlineNotes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final note in visible)
          _NoteRow(
            note: note,
            onEdit: () => _editNote(context, ref, note),
            onDelete: () => _confirmDelete(context, ref, note),
          ),
        if (hasMore)
          InkWell(
            onTap: () => _openFullList(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space3,
                vertical: AppSpacing.space2,
              ),
              child: Row(
                children: [
                  Text(
                    AppStrings.practiceNoteShowMore,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.paperAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space1),
                  Icon(
                    Icons.chevron_right,
                    color: AppColors.paperAccent,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _emptyBody() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space3,
        0,
        AppSpacing.space3,
        AppSpacing.space3,
      ),
      child: Text(
        AppStrings.practiceNoteHomeEmpty,
        style: AppTypography.bodySmall.copyWith(color: AppColors.inkSecondary),
      ),
    );
  }

  Future<void> _addNote(BuildContext context, WidgetRef ref) async {
    final content = await NoteEditDialog.show(context);
    if (content == null) return;
    await ref
        .read(practiceNoteCrudProvider.notifier)
        .createNote(sectionId: sectionId, content: content);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.practiceNoteAddedSnack)),
      );
    }
  }

  Future<void> _editNote(
    BuildContext context,
    WidgetRef ref,
    PracticeNote note,
  ) async {
    final content = await NoteEditDialog.show(context, existingNote: note);
    if (content == null) return;
    final updated = note.copyWith(content: content);
    await ref.read(practiceNoteCrudProvider.notifier).updateNote(updated);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.practiceNoteUpdatedSnack)),
      );
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, PracticeNote note) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return NotebookAlertDialog(
          title: AppStrings.practiceNoteDeleteTitle,
          content: const Text(AppStrings.practiceNoteDeleteConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(AppStrings.cancel),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await ref
                    .read(practiceNoteCrudProvider.notifier)
                    .deleteNote(note.id, sectionId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(AppStrings.practiceNoteDeletedSnack),
                    ),
                  );
                }
              },
              child: const Text(AppStrings.delete),
            ),
          ],
        );
      },
    );
  }

  void _openFullList(BuildContext context) {
    context.push(
      '${AppRoutes.practiceNotes.replaceFirst(':sectionId', sectionId)}'
      '?name=${Uri.encodeComponent(sectionTitle)}',
    );
  }
}

class _NoteRow extends StatelessWidget {
  const _NoteRow({
    required this.note,
    required this.onEdit,
    required this.onDelete,
  });

  final PracticeNote note;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.inkQuaternary)),
      ),
      child: SwipeActionTile(
        actions: [
          SwipeAction(
            label: AppStrings.swipeActionEdit,
            icon: Icons.edit_outlined,
            onPressed: onEdit,
          ),
          SwipeAction(
            label: AppStrings.delete,
            icon: Icons.delete_outline,
            tone: SwipeActionTone.destructive,
            onPressed: onDelete,
          ),
        ],
        child: InkWell(
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space3,
              vertical: AppSpacing.space2,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space2,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(color: AppColors.paperAccentSoft),
                  child: Text(
                    note.timeText,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.paperAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.space2),
                Expanded(
                  child: Text(
                    note.content,
                    style: NotebookTypography.handMedium.copyWith(
color: AppColors.ink,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
