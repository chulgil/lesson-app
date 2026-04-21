import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';
import '../../../../features/practice/domain/entities/piece.dart';

/// Get color for difficulty level
Color getDifficultyColor(String? difficulty) {
  switch (difficulty) {
    case '초급':
      return AppColors.success;
    case '초중급':
      return AppColors.profileGreen;
    case '중급':
      return AppColors.amber;
    case '중상급':
      return AppColors.warning;
    case '상급':
      return AppColors.error;
    default:
      return AppColors.textSecondaryLight;
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
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: '곡 제목 또는 작곡가 검색',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              ),
              contentPadding: const EdgeInsets.symmetric(
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
                  label: Text(selectedDifficulty ?? '난이도'),
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
                  label: Text(selectedComposer ?? '작곡가'),
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
                    label: const Text('필터 초기화'),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.library_music,
            size: 64,
            color: AppColors.textTertiaryLight,
          ),
          const SizedBox(height: AppSpacing.space4),
          Text(
            hasFilters ? '검색 결과가 없습니다' : '등록된 곡이 없습니다',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            '곡을 추가하여 레퍼토리를 관리하세요',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textTertiaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

/// Card widget for displaying a piece
class PieceCard extends StatelessWidget {
  final Piece piece;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAssign;

  const PieceCard({
    super.key,
    required this.piece,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.space3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
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
                  borderRadius: BorderRadius.circular(2),
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
                          color: AppColors.textSecondaryLight,
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
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusSmall,
                          ),
                        ),
                        child: Text(
                          piece.opus!,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.primary,
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
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                  ),
                  child: Text(
                    piece.difficulty!,
                    style: AppTypography.caption.copyWith(
                      color: getDifficultyColor(piece.difficulty),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

              const SizedBox(width: AppSpacing.space2),

              // Actions
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      onEdit();
                      break;
                    case 'delete':
                      onDelete();
                      break;
                    case 'assign':
                      onAssign();
                      break;
                  }
                },
                itemBuilder:
                    (context) => [
                      const PopupMenuItem(
                        value: 'assign',
                        child: Row(
                          children: [
                            Icon(Icons.person_add),
                            SizedBox(width: AppSpacing.space2),
                            Text('학생에게 할당'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: AppSpacing.space2),
                            Text(AppStrings.modify),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: AppColors.error),
                            SizedBox(width: AppSpacing.space2),
                            Text(
                              '삭제',
                              style: TextStyle(color: AppColors.error),
                            ),
                          ],
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

    return AlertDialog(
      title: Text(isEditing ? '곡 수정' : '곡 추가'),
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
                  labelText: '곡 제목 *',
                  hintText: '예: 봄의 소리 왈츠',
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
                  labelText: '작곡가',
                  hintText: '예: J. Strauss II',
                ),
              ),
              const SizedBox(height: AppSpacing.space3),

              // Opus
              TextFormField(
                controller: _opusController,
                decoration: const InputDecoration(
                  labelText: '작품번호',
                  hintText: '예: Op. 410',
                ),
              ),
              const SizedBox(height: AppSpacing.space3),

              // Movement
              TextFormField(
                controller: _movementController,
                decoration: const InputDecoration(
                  labelText: '악장',
                  hintText: '예: 1악장',
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
                                  : AppColors.textPrimaryLight,
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
                  labelText: '메모',
                  hintText: '특이사항이나 연습 포인트',
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
        FilledButton(onPressed: _save, child: const Text('저장')),
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

  showModalBottomSheet(
    context: context,
    builder:
        (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('난이도 선택', style: AppTypography.headingSmall),
              ),
              const Divider(),
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
                title: const Text('선택 해제'),
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
  showModalBottomSheet(
    context: context,
    builder:
        (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('작곡가 선택', style: AppTypography.headingSmall),
              ),
              const Divider(),
              if (composers.isEmpty)
                const ListTile(title: Text('등록된 작곡가가 없습니다'))
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
                title: const Text('선택 해제'),
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
  showModalBottomSheet(
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
                          color: AppColors.textSecondaryLight,
                        ),
                      ),

                    const SizedBox(height: AppSpacing.space4),

                    // Details
                    if (piece.difficulty != null)
                      _PieceDetailRow(label: '난이도', value: piece.difficulty!),
                    if (piece.opus != null)
                      _PieceDetailRow(label: '작품번호', value: piece.opus!),
                    if (piece.movement != null)
                      _PieceDetailRow(label: '악장', value: piece.movement!),
                    if (piece.notes != null && piece.notes!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.space4),
                      Text(
                        '메모',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space2),
                      Text(piece.notes!, style: AppTypography.bodyMedium),
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
                            label: const Text('학생에게 할당'),
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
              color: AppColors.textSecondaryLight,
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
  showDialog(
    context: context,
    builder:
        (dialogContext) => AlertDialog(
          title: const Text('곡 삭제'),
          content: Text('${piece.title}을(를) 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(AppStrings.cancel),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                onConfirm();
              },
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text(AppStrings.delete),
            ),
          ],
        ),
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
  showDialog(
    context: context,
    builder:
        (dialogContext) => AlertDialog(
          title: const Text('학생에게 곡 할당'),
          content: studentsAsync.when(
            data: (students) {
              if (students.isEmpty) {
                return const Text('등록된 학생이 없습니다');
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
                        backgroundColor: AppColors.primary.withValues(
                          alpha: 0.1,
                        ),
                        child: Text(
                          student.name[0],
                          style: TextStyle(color: AppColors.primary),
                        ),
                      ),
                      title: Text(student.name),
                      subtitle: Text(student.instrument),
                      onTap: () async {
                        Navigator.pop(dialogContext);
                        await onAssign(student.id);
                      },
                    );
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Text('오류가 발생했습니다.'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(AppStrings.cancel),
            ),
          ],
        ),
  );
}
