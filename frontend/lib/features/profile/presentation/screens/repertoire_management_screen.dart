import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../features/practice/domain/entities/piece.dart';
import '../../../practice/presentation/providers/piece_crud_provider.dart';
import '../../../students/presentation/providers/student_crud_provider.dart';
import '../widgets/repertoire_management_widgets.dart';

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
          RepertoireSearchAndFilter(
            onSearchChanged:
                (value) =>
                    ref.read(pieceSearchQueryProvider.notifier).state = value,
            selectedDifficulty: _selectedDifficulty,
            selectedComposer: _selectedComposer,
            onDifficultyTap: _showDifficultyFilter,
            onComposerTap: _showComposerFilter,
            onClearFilters: () {
              setState(() {
                _selectedDifficulty = null;
                _selectedComposer = null;
              });
            },
          ),

          // Pieces list
          Expanded(
            child: piecesAsync.when(
              data: (pieces) => _buildPiecesList(pieces, searchQuery),
              loading: () => const Center(child: CircularProgressIndicator()),
              error:
                  (_, __) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: AppSpacing.space4),
                        const Text('오류가 발생했습니다.'),
                        const SizedBox(height: AppSpacing.space4),
                        FilledButton(
                          onPressed:
                              () =>
                                  ref
                                      .read(piecesNotifierProvider.notifier)
                                      .refresh(),
                          child: const Text(AppStrings.retry),
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

  Widget _buildPiecesList(List<Piece> allPieces, String searchQuery) {
    // Apply filters
    var filteredPieces =
        allPieces.where((piece) {
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

          if (_selectedComposer != null &&
              piece.composer != _selectedComposer) {
            return false;
          }

          return true;
        }).toList();

    // Sort by title
    filteredPieces.sort((a, b) => a.title.compareTo(b.title));

    if (filteredPieces.isEmpty) {
      return RepertoireEmptyState(
        hasFilters:
            searchQuery.isNotEmpty ||
            _selectedDifficulty != null ||
            _selectedComposer != null,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      itemCount: filteredPieces.length,
      itemBuilder: (context, index) {
        final piece = filteredPieces[index];
        return PieceCard(
          piece: piece,
          onTap: () => _showPieceDetails(piece),
          onEdit: () => _showEditPieceDialog(piece),
          onDelete: () => _showDeleteConfirmation(piece),
          onAssign: () => _showAssignToStudentDialog(piece),
        );
      },
    );
  }

  void _showDifficultyFilter() {
    showDifficultyFilter(
      context: context,
      selectedDifficulty: _selectedDifficulty,
      onSelected: (difficulty) {
        setState(() => _selectedDifficulty = difficulty);
      },
    );
  }

  void _showComposerFilter() {
    final pieces = ref.read(piecesNotifierProvider).value ?? [];
    final composers =
        pieces
            .map((p) => p.composer)
            .where((c) => c != null)
            .cast<String>()
            .toSet()
            .toList()
          ..sort();

    showComposerFilter(
      context: context,
      composers: composers,
      selectedComposer: _selectedComposer,
      onSelected: (composer) {
        setState(() => _selectedComposer = composer);
      },
    );
  }

  void _showPieceDetails(Piece piece) {
    showPieceDetails(
      context: context,
      piece: piece,
      onEdit: () => _showEditPieceDialog(piece),
      onAssign: () => _showAssignToStudentDialog(piece),
    );
  }

  void _showAddPieceDialog() {
    showDialog(
      context: context,
      builder:
          (dialogContext) => PieceDialog(
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
      builder:
          (dialogContext) => PieceDialog(
            existingPiece: piece,
            onSave: (updatedPiece) async {
              await ref
                  .read(piecesNotifierProvider.notifier)
                  .updatePiece(updatedPiece);
              if (!mounted) return;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('곡 정보가 수정되었습니다')));
            },
          ),
    );
  }

  void _showDeleteConfirmation(Piece piece) {
    showDeletePieceConfirmation(
      context: context,
      piece: piece,
      onConfirm: () async {
        await ref.read(piecesNotifierProvider.notifier).deletePiece(piece.id);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('${piece.title}이(가) 삭제되었습니다')));
        }
      },
    );
  }

  void _showAssignToStudentDialog(Piece piece) {
    final studentsAsync = ref.read(studentsNotifierProvider);

    showAssignToStudentDialog(
      context: context,
      ref: ref,
      piece: piece,
      studentsAsync: studentsAsync,
      onAssign: (studentId) async {
        await ref
            .read(studentRepertoireNotifierProvider(studentId).notifier)
            .assignPiece(piece.id);
        if (mounted) {
          final students = ref.read(studentsNotifierProvider).value ?? [];
          final student = students.firstWhere((s) => s.id == studentId);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${piece.title}이(가) ${student.name}에게 할당되었습니다'),
            ),
          );
        }
      },
    );
  }
}
