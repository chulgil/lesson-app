import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../domain/entities/entities.dart';
import '../extensions/practice_section_visuals.dart';
import '../providers/practice_note_provider.dart';
import '../providers/practice_repertoire_crud_provider.dart';
import '../widgets/notes/note_edit_dialog.dart';
import '../widgets/notes/note_list_item.dart';

/// Screen for viewing and managing practice notes for a section
class PracticeNoteListScreen extends ConsumerWidget {
  final String sectionId;
  final String sectionName; // Fallback name if section fetch fails

  const PracticeNoteListScreen({
    super.key,
    required this.sectionId,
    required this.sectionName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(sectionNotesProvider(sectionId));
    final sectionAsync = ref.watch(sectionProvider(sectionId));

    // Get repertoire info when section is available
    final section = sectionAsync.valueOrNull;
    final repertoireAsync =
        section != null
            ? ref.watch(repertoireProvider(section.repertoireId))
            : null;
    final repertoireName = repertoireAsync?.valueOrNull?.name;

    return NotebookScreenScaffold(
      appBar: NotebookDetailAppBar(
        title: AppStrings.practiceNoteTitle,
        actions: const [DetailAppBarAction.add],
        onAction: (action) {
          if (action == DetailAppBarAction.add) {
            _showAddDialog(context, ref);
          }
        },
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section info header
          Container(
            padding: const EdgeInsets.all(AppSpacing.space4),
            color: AppColors.paperDark,
            width: double.infinity,
            child: sectionAsync.when(
              data:
                  (section) =>
                      section != null
                          ? _buildSectionHeader(section, repertoireName)
                          : _buildFallbackHeader(),
              loading: () => _buildFallbackHeader(),
              error: (_, __) => _buildFallbackHeader(),
            ),
          ),

          // Notes list
          Expanded(
            child: notesAsync.when(
              data: (notes) => _buildNotesList(context, ref, notes),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _buildError(context, ref),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(PracticeSection section, String? repertoireName) {
    return Row(
      children: [
        Icon(Icons.library_music, color: AppColors.paperAccent, size: 20),
        const SizedBox(width: AppSpacing.space3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Repertoire name
              if (repertoireName != null && repertoireName.isNotEmpty) ...[
                Text(
                  repertoireName,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                ),
                const SizedBox(height: 2),
              ],
              // Piece name
              Text(
                section.pieceName,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              // Section name + range
              if (_formatSectionInfo(section).isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  _formatSectionInfo(section),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _formatSectionInfo(PracticeSection section) {
    final parts = <String>[];
    final sectionName = section.sectionName;
    if (sectionName != null && sectionName.isNotEmpty) {
      parts.add(sectionName);
    }
    final range = section.rangeText;
    if (range.isNotEmpty && range != '전체') {
      parts.add(range);
    }
    return parts.isEmpty ? '전체' : parts.join(' · ');
  }

  Widget _buildFallbackHeader() {
    return Row(
      children: [
        Icon(Icons.library_music, color: AppColors.paperAccent, size: 20),
        const SizedBox(width: AppSpacing.space2),
        Expanded(
          child: Text(
            sectionName,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesList(
    BuildContext context,
    WidgetRef ref,
    List<PracticeNote> notes,
  ) {
    if (notes.isEmpty) {
      return _buildEmpty(context, ref);
    }

    // Group notes by date
    final groupedNotes = <String, List<PracticeNote>>{};
    for (final note in notes) {
      final dateKey = note.dateText;
      groupedNotes.putIfAbsent(dateKey, () => []).add(note);
    }

    // Sort dates descending (newest first)
    final sortedDates =
        groupedNotes.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.space4),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final dateKey = sortedDates[index];
        final dateNotes = groupedNotes[dateKey]!;

        // Sort notes within date by time descending
        dateNotes.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.space2),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: AppColors.inkSecondary,
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  Text(
                    _formatDateHeader(dateNotes.first),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.inkSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Notes for this date
            ...dateNotes.map(
              (note) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.space2),
                child: NoteListItem(
                  note: note,
                  onEdit: () => _showEditDialog(context, ref, note),
                  onDelete: () => _showDeleteDialog(context, ref, note),
                ),
              ),
            ),

            if (index < sortedDates.length - 1)
              const SizedBox(height: AppSpacing.space2),
          ],
        );
      },
    );
  }

  Widget _buildEmpty(BuildContext context, WidgetRef ref) {
    return EmptyStateWidget(
      icon: Icons.edit_note,
      title: AppStrings.practiceNoteEmptyTitle,
      subtitle: AppStrings.practiceNoteEmptySubtitle,
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.paperAccent),
          const SizedBox(height: AppSpacing.space4),
          Text(
            '오류가 발생했습니다',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.paperAccent,
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          TextButton(
            onPressed: () => ref.invalidate(sectionNotesProvider(sectionId)),
            child: const Text(AppStrings.retry),
          ),
        ],
      ),
    );
  }

  String _formatDateHeader(PracticeNote note) {
    if (note.isToday) {
      return '${note.dateText} (오늘)';
    } else if (note.isYesterday) {
      return '${note.dateText} (어제)';
    }
    return note.dateText;
  }

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
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

  Future<void> _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    PracticeNote note,
  ) async {
    final content = await NoteEditDialog.show(context, existingNote: note);
    if (content == null) return;

    final updatedNote = note.copyWith(content: content);
    await ref.read(practiceNoteCrudProvider.notifier).updateNote(updatedNote);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.practiceNoteUpdatedSnack)),
      );
    }
  }

  void _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    PracticeNote note,
  ) {
    showNotebookDialog(
      context: context,
      titleWidget: const Text(AppStrings.practiceNoteDeleteTitle),
      content: const Text(AppStrings.practiceNoteDeleteConfirm),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.cancel),
        ),
        FilledButton(
          onPressed: () async {
            Navigator.of(context).pop();
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
  }
}
