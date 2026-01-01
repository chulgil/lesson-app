import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/piece.dart';
import '../../../../providers/providers.dart';

/// Screen for managing piece library
class RepertoireManagementScreen extends ConsumerStatefulWidget {
  const RepertoireManagementScreen({super.key});

  @override
  ConsumerState<RepertoireManagementScreen> createState() =>
      _RepertoireManagementScreenState();
}

class _RepertoireManagementScreenState
    extends ConsumerState<RepertoireManagementScreen> {
  String? _selectedDifficulty;
  String? _selectedComposer;

  @override
  Widget build(BuildContext context) {
    final piecesAsync = ref.watch(piecesNotifierProvider);
    final searchQuery = ref.watch(pieceSearchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('레퍼토리 관리'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddPieceDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filter section
          _buildSearchAndFilter(),

          // Pieces list
          Expanded(
            child: piecesAsync.when(
              data: (pieces) => _buildPiecesList(pieces, searchQuery),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: AppSpacing.space4),
                    Text('오류가 발생했습니다: $error'),
                    const SizedBox(height: AppSpacing.space4),
                    FilledButton(
                      onPressed: () =>
                          ref.read(piecesNotifierProvider.notifier).refresh(),
                      child: const Text('다시 시도'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddPieceDialog,
        icon: const Icon(Icons.add),
        label: const Text('곡 추가'),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
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
            onChanged: (value) =>
                ref.read(pieceSearchQueryProvider.notifier).state = value,
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
                  label: Text(_selectedDifficulty ?? '난이도'),
                  selected: _selectedDifficulty != null,
                  onSelected: (_) => _showDifficultyFilter(),
                  avatar: _selectedDifficulty != null
                      ? const Icon(Icons.check, size: 16)
                      : const Icon(Icons.tune, size: 16),
                ),
                const SizedBox(width: AppSpacing.space2),

                // Composer filter
                FilterChip(
                  label: Text(_selectedComposer ?? '작곡가'),
                  selected: _selectedComposer != null,
                  onSelected: (_) => _showComposerFilter(),
                  avatar: _selectedComposer != null
                      ? const Icon(Icons.check, size: 16)
                      : const Icon(Icons.person, size: 16),
                ),

                if (_selectedDifficulty != null || _selectedComposer != null) ...[
                  const SizedBox(width: AppSpacing.space2),
                  ActionChip(
                    label: const Text('필터 초기화'),
                    avatar: const Icon(Icons.clear, size: 16),
                    onPressed: () {
                      setState(() {
                        _selectedDifficulty = null;
                        _selectedComposer = null;
                      });
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPiecesList(List<Piece> allPieces, String searchQuery) {
    // Apply filters
    var filteredPieces = allPieces.where((piece) {
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        if (!piece.title.toLowerCase().contains(query) &&
            !(piece.composer?.toLowerCase().contains(query) ?? false)) {
          return false;
        }
      }

      if (_selectedDifficulty != null &&
          piece.difficulty != _selectedDifficulty) {
        return false;
      }

      if (_selectedComposer != null && piece.composer != _selectedComposer) {
        return false;
      }

      return true;
    }).toList();

    // Sort by title
    filteredPieces.sort((a, b) => a.title.compareTo(b.title));

    if (filteredPieces.isEmpty) {
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
              searchQuery.isNotEmpty || _selectedDifficulty != null || _selectedComposer != null
                  ? '검색 결과가 없습니다'
                  : '등록된 곡이 없습니다',
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

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      itemCount: filteredPieces.length,
      itemBuilder: (context, index) {
        final piece = filteredPieces[index];
        return _buildPieceCard(piece);
      },
    );
  }

  Widget _buildPieceCard(Piece piece) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.space3),
      child: InkWell(
        onTap: () => _showPieceDetails(piece),
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
                  color: _getDifficultyColor(piece.difficulty),
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
                          borderRadius: BorderRadius.circular(4),
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
                    color: _getDifficultyColor(piece.difficulty)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                  ),
                  child: Text(
                    piece.difficulty!,
                    style: AppTypography.caption.copyWith(
                      color: _getDifficultyColor(piece.difficulty),
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
                      _showEditPieceDialog(piece);
                      break;
                    case 'delete':
                      _showDeleteConfirmation(piece);
                      break;
                    case 'assign':
                      _showAssignToStudentDialog(piece);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'assign',
                    child: Row(
                      children: [
                        Icon(Icons.person_add),
                        SizedBox(width: 8),
                        Text('학생에게 할당'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit),
                        SizedBox(width: 8),
                        Text('수정'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: AppColors.error),
                        SizedBox(width: 8),
                        Text('삭제', style: TextStyle(color: AppColors.error)),
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

  Color _getDifficultyColor(String? difficulty) {
    switch (difficulty) {
      case '초급':
        return Colors.green;
      case '초중급':
        return Colors.lightGreen;
      case '중급':
        return Colors.amber;
      case '중상급':
        return Colors.orange;
      case '상급':
        return Colors.red;
      default:
        return AppColors.textSecondaryLight;
    }
  }

  void _showDifficultyFilter() {
    final difficulties = ['초급', '초중급', '중급', '중상급', '상급'];

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                '난이도 선택',
                style: AppTypography.headingSmall,
              ),
            ),
            const Divider(),
            ...difficulties.map((difficulty) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getDifficultyColor(difficulty),
                    radius: 12,
                  ),
                  title: Text(difficulty),
                  selected: _selectedDifficulty == difficulty,
                  onTap: () {
                    setState(() => _selectedDifficulty = difficulty);
                    Navigator.pop(context);
                  },
                )),
            ListTile(
              leading: const Icon(Icons.clear),
              title: const Text('선택 해제'),
              onTap: () {
                setState(() => _selectedDifficulty = null);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showComposerFilter() {
    final pieces = ref.read(piecesNotifierProvider).value ?? [];
    final composers = pieces
        .map((p) => p.composer)
        .where((c) => c != null)
        .cast<String>()
        .toSet()
        .toList()
      ..sort();

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                '작곡가 선택',
                style: AppTypography.headingSmall,
              ),
            ),
            const Divider(),
            if (composers.isEmpty)
              const ListTile(
                title: Text('등록된 작곡가가 없습니다'),
              )
            else
              ...composers.map((composer) => ListTile(
                    title: Text(composer),
                    selected: _selectedComposer == composer,
                    onTap: () {
                      setState(() => _selectedComposer = composer);
                      Navigator.pop(context);
                    },
                  )),
            ListTile(
              leading: const Icon(Icons.clear),
              title: const Text('선택 해제'),
              onTap: () {
                setState(() => _selectedComposer = null);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPieceDetails(Piece piece) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
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
                _buildDetailRow('난이도', piece.difficulty!),
              if (piece.opus != null) _buildDetailRow('작품번호', piece.opus!),
              if (piece.movement != null)
                _buildDetailRow('악장', piece.movement!),
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
                        _showEditPieceDialog(piece);
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('수정'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space3),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showAssignToStudentDialog(piece);
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

  Widget _buildDetailRow(String label, String value) {
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

  void _showAddPieceDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => _PieceDialog(
        onSave: (piece) async {
          await ref.read(piecesNotifierProvider.notifier).addPiece(piece);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${piece.title}이(가) 추가되었습니다')),
          );
        },
      ),
    );
  }

  void _showEditPieceDialog(Piece piece) {
    showDialog(
      context: context,
      builder: (dialogContext) => _PieceDialog(
        existingPiece: piece,
        onSave: (updatedPiece) async {
          await ref.read(piecesNotifierProvider.notifier).updatePiece(updatedPiece);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('곡 정보가 수정되었습니다')),
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(Piece piece) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('곡 삭제'),
        content: Text('${piece.title}을(를) 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await ref.read(piecesNotifierProvider.notifier).deletePiece(piece.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${piece.title}이(가) 삭제되었습니다')),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  void _showAssignToStudentDialog(Piece piece) {
    // Get students list
    final studentsAsync = ref.read(studentsNotifierProvider);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: Text(
                        student.name[0],
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ),
                    title: Text(student.name),
                    subtitle: Text(student.instrument),
                    onTap: () async {
                      Navigator.pop(dialogContext);
                      await ref
                          .read(studentRepertoireNotifierProvider(student.id)
                              .notifier)
                          .assignPiece(piece.id);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${piece.title}이(가) ${student.name}에게 할당되었습니다',
                            ),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Text('오류: $error'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }
}

class _PieceDialog extends StatefulWidget {
  final Piece? existingPiece;
  final void Function(Piece) onSave;

  const _PieceDialog({
    this.existingPiece,
    required this.onSave,
  });

  @override
  State<_PieceDialog> createState() => _PieceDialogState();
}

class _PieceDialogState extends State<_PieceDialog> {
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
                children: _difficulties.map((difficulty) {
                  final isSelected = _difficulty == difficulty;
                  return ChoiceChip(
                    label: Text(difficulty),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _difficulty = difficulty),
                    selectedColor: _getDifficultyColor(difficulty)
                        .withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? _getDifficultyColor(difficulty)
                          : AppColors.textPrimaryLight,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('저장'),
        ),
      ],
    );
  }

  Color _getDifficultyColor(String? difficulty) {
    switch (difficulty) {
      case '초급':
        return Colors.green;
      case '초중급':
        return Colors.lightGreen;
      case '중급':
        return Colors.amber;
      case '중상급':
        return Colors.orange;
      case '상급':
        return Colors.red;
      default:
        return AppColors.textSecondaryLight;
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final piece = Piece(
      id: widget.existingPiece?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      composer: _composerController.text.trim().isNotEmpty
          ? _composerController.text.trim()
          : null,
      opus: _opusController.text.trim().isNotEmpty
          ? _opusController.text.trim()
          : null,
      movement: _movementController.text.trim().isNotEmpty
          ? _movementController.text.trim()
          : null,
      difficulty: _difficulty,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
      createdAt: widget.existingPiece?.createdAt ?? now,
      updatedAt: widget.existingPiece != null ? now : null,
    );

    widget.onSave(piece);
    Navigator.pop(context);
  }
}
