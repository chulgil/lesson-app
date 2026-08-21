import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:lessonaza/core/widgets/notebook/thin_rule.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';
import '../../../../core/widgets/swipe_action_tile.dart';
import '../../../../features/practice/domain/entities/piece.dart';
import 'piece_actions_bottom_sheet.dart';
import '../../../../core/l10n/generated/app_localizations.dart';

/// Difficulty tier color — SSOT for the 5 difficulty labels, collapsed to
/// 3 tiers (초급/초중급 · 중급/중상급 · 상급) to satisfy the "3색 이하" UX rule.
Color getDifficultyColor(String? difficulty) {
  switch (difficulty) {
    case '초급':
    case '초중급':
      return AppColors.paperOk;
    case '중급':
    case '중상급':
      return AppColors.paperAccent;
    case '상급':
      return AppColors.inkSecondary;
    default:
      return AppColors.inkSecondary;
  }
}

/// Search and filter section for repertoire
class RepertoireSearchAndFilter extends StatelessWidget {
  final ValueChanged<String> onSearchChanged;
  final String? selectedDifficulty;
  final String? selectedComposer;
  final VoidCallback onDifficultyTap;
  final VoidCallback onComposerTap;
  final VoidCallback? onClearFilters;

  const RepertoireSearchAndFilter({
    super.key,
    required this.onSearchChanged,
    this.selectedDifficulty,
    this.selectedComposer,
    required this.onDifficultyTap,
    required this.onComposerTap,
    this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      decoration: const BoxDecoration(color: AppColors.paper),
      child: Column(
        children: [
          // Search bar
          TextField(
            onChanged: onSearchChanged,
            decoration: const InputDecoration(
              hintText: AppStrings.profileRepertoireSearchHint,
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                horizontal: AppSpacing.space4,
                vertical: AppSpacing.space3,
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.space3),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Difficulty filter
                FilterChip(
                  label: Text(
                    selectedDifficulty ??
                        AppStrings.profileRepertoireDifficultyLabel,
                  ),
                  selected: selectedDifficulty != null,
                  onSelected: (_) => onDifficultyTap(),
                  avatar:
                      selectedDifficulty != null
                          ? const Icon(Icons.check, size: 16)
                          : const Icon(Icons.tune, size: 16),
                ),
                const SizedBox(width: AppSpacing.space2),

                // Composer filter
                FilterChip(
                  label: Text(
                    selectedComposer ??
                        AppStrings.profileRepertoireComposerLabel,
                  ),
                  selected: selectedComposer != null,
                  onSelected: (_) => onComposerTap(),
                  avatar:
                      selectedComposer != null
                          ? const Icon(Icons.check, size: 16)
                          : const Icon(Icons.person, size: 16),
                ),

                if (selectedDifficulty != null || selectedComposer != null) ...[
                  const SizedBox(width: AppSpacing.space2),
                  ActionChip(
                    label: const Text(AppStrings.profileRepertoireFilterReset),
                    avatar: const Icon(Icons.clear, size: 16),
                    onPressed: onClearFilters,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty state for repertoire list
class RepertoireEmptyState extends StatelessWidget {
  final bool hasFilters;

  const RepertoireEmptyState({super.key, required this.hasFilters});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.library_music,
      title:
          hasFilters
              ? AppStrings.searchNoResults
              : AppStrings.repertoireEmptyTitle,
      subtitle: AppStrings.repertoireEmptyHint,
    );
  }
}

/// Card widget for displaying a piece.
///
/// Swipe consistency audit #668 D4 — row tap opens [PieceActionsBottomSheet]
/// with [편집][배정][삭제]; swipe reveals the destructive [삭제] shortcut.
class PieceCard extends StatelessWidget {
  final Piece piece;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAssign;

  const PieceCard({
    super.key,
    required this.piece,
    required this.onEdit,
    required this.onDelete,
    required this.onAssign,
  });

  /// Confirm + perform delete via [showNotebookDialog].
  ///
  /// Swipe consistency audit #668 D4 — destructive always wraps in a
  /// confirmation dialog before invoking [onDelete].
  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showNotebookDialog<bool>(
      context: context,
      title: AppStrings.swipeActionDeletePieceConfirmTitle,
      content: const Text(AppStrings.swipeActionDeletePieceConfirmBody),
      confirmLabel: AppStrings.delete,
      cancelLabel: AppStrings.cancel,
      isDestructive: true,
      onConfirm: () => Navigator.pop(context, true),
      onCancel: () => Navigator.pop(context, false),
    );
    if (confirmed == true) {
      onDelete();
    }
  }

  Future<void> _openActions(BuildContext context) async {
    final result = await PieceActionsBottomSheet.show(context);
    if (result == null) return;
    switch (result) {
      case PieceActionResult.edit:
        onEdit();
        break;
      case PieceActionResult.assign:
        onAssign();
        break;
      case PieceActionResult.delete:
        if (context.mounted) {
          await _confirmDelete(context);
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final card = NotebookCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.space3),
      child: InkWell(
        onTap: () => _openActions(context),
        borderRadius: BorderRadius.zero,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space4),
          child: Row(
            children: [
              // Difficulty indicator
              Container(
                width: 4,
                height: 60,
                decoration: BoxDecoration(
                  color: getDifficultyColor(piece.difficulty),
                ),
              ),
              const SizedBox(width: AppSpacing.space3),

              // Piece info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      piece.title,
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space1),
                    if (piece.composer != null)
                      Text(
                        piece.composer!,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.inkSecondary,
                        ),
                      ),
                    if (piece.opus != null) ...[
                      const SizedBox(height: AppSpacing.space1),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.paperAccentSoft,
                        ),
                        child: Text(
                          piece.opus!,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.paperAccent,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Difficulty badge
              if (piece.difficulty != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: getDifficultyColor(
                      piece.difficulty,
                    ).withValues(alpha: 0.1),
                  ),
                  child: Text(
                    piece.difficulty!,
                    style: AppTypography.caption.copyWith(
                      color: getDifficultyColor(piece.difficulty),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    return SwipeActionTile(
      actions: [
        SwipeAction(
          label: AppStrings.swipeActionDelete,
          icon: Icons.delete_outline,
          tone: SwipeActionTone.destructive,
          onPressed: () => _confirmDelete(context),
        ),
      ],
      startActions: [
        SwipeAction(
          label: AppStrings.swipeActionAssign,
          icon: Icons.assignment_outlined,
          tone: SwipeActionTone.convenience,
          onPressed: onAssign,
        ),
      ],
      child: card,
    );
  }
}

/// Dialog for adding/editing a piece
class PieceDialog extends StatefulWidget {
  final Piece? existingPiece;
  final void Function(Piece) onSave;

  const PieceDialog({super.key, this.existingPiece, required this.onSave});

  @override
  State<PieceDialog> createState() => _PieceDialogState();
}

class _PieceDialogState extends State<PieceDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _composerController;
  late TextEditingController _opusController;
  late TextEditingController _movementController;
  late TextEditingController _notesController;
  String? _difficulty;

  static const _difficulties = ['초급', '초중급', '중급', '중상급', '상급'];

  @override
  void initState() {
    super.initState();
    final piece = widget.existingPiece;
    _titleController = TextEditingController(text: piece?.title ?? '');
    _composerController = TextEditingController(text: piece?.composer ?? '');
    _opusController = TextEditingController(text: piece?.opus ?? '');
    _movementController = TextEditingController(text: piece?.movement ?? '');
    _notesController = TextEditingController(text: piece?.notes ?? '');
    _difficulty = piece?.difficulty;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _composerController.dispose();
    _opusController.dispose();
    _movementController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingPiece != null;

    return NotebookAlertDialog(
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(),
      titleTextStyle: NotebookTypography.pieceTitle,
      title: Text(
        isEditing
            ? AppStrings.profileRepertoirePieceEditTitle
            : AppStrings.profileRepertoirePieceAddTitle,
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: AppStrings.profileRepertoirePieceTitleLabel,
                  hintText: AppStrings.profileRepertoireHintTitle,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '곡 제목을 입력하세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.space3),

              // Composer
              TextFormField(
                controller: _composerController,
                decoration: const InputDecoration(
                  labelText: AppStrings.profileRepertoireComposerLabel,
                  hintText: AppStrings.profileRepertoireHintComposer,
                ),
              ),
              const SizedBox(height: AppSpacing.space3),

              // Opus
              TextFormField(
                controller: _opusController,
                decoration: const InputDecoration(
                  labelText: AppStrings.profileRepertoireOpusLabel,
                  hintText: AppStrings.profileRepertoireHintOpus,
                ),
              ),
              const SizedBox(height: AppSpacing.space3),

              // Movement
              TextFormField(
                controller: _movementController,
                decoration: const InputDecoration(
                  labelText: AppStrings.profileRepertoireMovementLabel,
                  hintText: AppStrings.profileRepertoireHintMovement,
                ),
              ),
              const SizedBox(height: AppSpacing.space4),

              // Difficulty
              Text(
                '난이도',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.space2),
              Wrap(
                spacing: AppSpacing.space2,
                runSpacing: AppSpacing.space2,
                children:
                    _difficulties.map((difficulty) {
                      final isSelected = _difficulty == difficulty;
                      return ChoiceChip(
                        label: Text(difficulty),
                        selected: isSelected,
                        onSelected:
                            (_) => setState(() => _difficulty = difficulty),
                        selectedColor: getDifficultyColor(
                          difficulty,
                        ).withValues(alpha: 0.2),
                        labelStyle: TextStyle(
                          color:
                              isSelected
                                  ? getDifficultyColor(difficulty)
                                  : AppColors.ink,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      );
                    }).toList(),
              ),
              const SizedBox(height: AppSpacing.space3),

              // Notes
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: AppStrings.memoLabel,
                  hintText: AppStrings.profileRepertoireHintNotes,
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(AppStrings.cancel),
        ),
        FilledButton(onPressed: _save, child: const Text(AppStrings.save)),
      ],
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final piece = Piece(
      id:
          widget.existingPiece?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      composer:
          _composerController.text.trim().isNotEmpty
              ? _composerController.text.trim()
              : null,
      opus:
          _opusController.text.trim().isNotEmpty
              ? _opusController.text.trim()
              : null,
      movement:
          _movementController.text.trim().isNotEmpty
              ? _movementController.text.trim()
              : null,
      difficulty: _difficulty,
      notes:
          _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
      createdAt: widget.existingPiece?.createdAt ?? now,
      updatedAt: widget.existingPiece != null ? now : null,
    );

    widget.onSave(piece);
    Navigator.pop(context);
  }
}

/// Show difficulty filter bottom sheet
void showDifficultyFilter({
  required BuildContext context,
  required String? selectedDifficulty,
  required ValueChanged<String?> onSelected,
}) {
  final difficulties = ['초급', '초중급', '중급', '중상급', '상급'];

  showNotebookModalBottomSheet<void>(
    context: context,
    builder:
        (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                // Notebook × Score: 모달 시트 타이틀은 Playfair appBarTitle
                // (§7.27). '난이도 선택' 은 정적 명사 헤더.
                title: Text(
                  AppStrings.profileRepertoireDifficultySelect,
                  style: NotebookTypography.appBarTitle,
                ),
              ),
              const ThinRule(),
              ...difficulties.map(
                (difficulty) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: getDifficultyColor(difficulty),
                    radius: 12,
                  ),
                  title: Text(difficulty),
                  selected: selectedDifficulty == difficulty,
                  onTap: () {
                    onSelected(difficulty);
                    Navigator.pop(context);
                  },
                ),
              ),
              ListTile(
                leading: const Icon(Icons.clear),
                title: const Text(AppStrings.profileRepertoireDeselect),
                onTap: () {
                  onSelected(null);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
  );
}

/// Show composer filter bottom sheet
void showComposerFilter({
  required BuildContext context,
  required List<String> composers,
  required String? selectedComposer,
  required ValueChanged<String?> onSelected,
}) {
  showNotebookModalBottomSheet<void>(
    context: context,
    builder:
        (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                // Notebook × Score: 모달 시트 타이틀은 Playfair appBarTitle
                // (§7.27). '작곡가 선택' 은 정적 명사 헤더.
                title: Text(
                  AppStrings.profileRepertoireComposerSelect,
                  style: NotebookTypography.appBarTitle,
                ),
              ),
              const ThinRule(),
              if (composers.isEmpty)
                const ListTile(
                  title: Text(AppStrings.profileRepertoireNoComposers),
                )
              else
                ...composers.map(
                  (composer) => ListTile(
                    title: Text(composer),
                    selected: selectedComposer == composer,
                    onTap: () {
                      onSelected(composer);
                      Navigator.pop(context);
                    },
                  ),
                ),
              ListTile(
                leading: const Icon(Icons.clear),
                title: const Text(AppStrings.profileRepertoireDeselect),
                onTap: () {
                  onSelected(null);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
  );
}

/// Show piece details bottom sheet
void showPieceDetails({
  required BuildContext context,
  required Piece piece,
  required VoidCallback onEdit,
  required VoidCallback onAssign,
}) {
  showNotebookModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder:
        (context) => DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder:
              (context, scrollController) => SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle
                    const Center(
                      child: BottomSheetHandle(margin: EdgeInsets.zero),
                    ),
                    const SizedBox(height: AppSpacing.space4),

                    // Title and composer
                    Text(piece.title, style: AppTypography.headingLarge),
                    const SizedBox(height: AppSpacing.space1),
                    if (piece.composer != null)
                      Text(
                        piece.composer!,
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.inkSecondary,
                        ),
                      ),

                    const SizedBox(height: AppSpacing.space4),

                    // Details
                    if (piece.difficulty != null)
                      _PieceDetailRow(
                        label: AppStrings.profileRepertoireDifficultyLabel,
                        value: piece.difficulty!,
                      ),
                    if (piece.opus != null)
                      _PieceDetailRow(
                        label: AppStrings.profileRepertoireOpusLabel,
                        value: piece.opus!,
                      ),
                    if (piece.movement != null)
                      _PieceDetailRow(
                        label: AppStrings.profileRepertoireMovementLabel,
                        value: piece.movement!,
                      ),
                    if (piece.notes != null && piece.notes!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.space4),
                      Text(
                        '메모',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space2),
                      // 곡 메모 = 선생님 자필 노트 → Tier 1 Gaegu hand
                      // (README §1.1 4계층, §7.127 Gaegu 누락 보완).
                      Text(piece.notes!, style: NotebookTypography.hand),
                    ],

                    const SizedBox(height: AppSpacing.space6),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              onEdit();
                            },
                            icon: const Icon(Icons.edit),
                            label: const Text(AppStrings.modify),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.space3),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              onAssign();
                            },
                            icon: const Icon(Icons.person_add),
                            label: const Text(
                              AppStrings.profileRepertoireAssignStudent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
        ),
  );
}

class _PieceDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _PieceDetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space2),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
          Text(value, style: AppTypography.bodyMedium),
        ],
      ),
    );
  }
}

/// Show delete confirmation dialog
void showDeletePieceConfirmation({
  required BuildContext context,
  required Piece piece,
  required VoidCallback onConfirm,
}) {
  showNotebookDialog(
    context: context,
    title: AppStrings.profileRepertoirePieceDeleteTitle,
    content: Text(
      AppLocalizations.of(context).repertoireDeleteConfirmBody(piece.title),
    ),
    confirmLabel: AppStrings.delete,
    cancelLabel: AppStrings.cancel,
    isDestructive: true,
    onConfirm: () {
      Navigator.pop(context);
      onConfirm();
    },
  );
}

/// Show assign to student dialog
void showAssignToStudentDialog({
  required BuildContext context,
  required WidgetRef ref,
  required Piece piece,
  required AsyncValue studentsAsync,
  required Future<void> Function(String studentId) onAssign,
}) {
  showNotebookDialog(
    context: context,
    titleWidget: const Text(AppStrings.profileRepertoireAssignTitle),
    content: studentsAsync.when(
      data: (students) {
        if (students.isEmpty) {
          return const Text(AppStrings.profileRepertoireNoStudents);
        }
        return SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: students.length,
            itemBuilder: (listContext, index) {
              final student = students[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.paperAccentSoft,
                  child: Text(
                    student.name[0],
                    style: TextStyle(color: AppColors.paperAccent),
                  ),
                ),
                title: Text(student.name),
                subtitle: Text(student.instrument),
                onTap: () async {
                  Navigator.pop(context);
                  await onAssign(student.id);
                },
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Text(AppStrings.genericError),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text(AppStrings.cancel),
      ),
    ],
  );
}
