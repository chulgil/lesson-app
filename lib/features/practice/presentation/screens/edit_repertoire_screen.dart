import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../providers/practice_repertoire/practice_repertoire_crud_provider.dart';
import '../../../../shared/widgets/app_date_picker.dart';
import '../../domain/entities/practice_repertoire.dart';
import '../widgets/section_form/date_range_section.dart';

/// Screen for editing an existing repertoire
class EditRepertoireScreen extends ConsumerStatefulWidget {
  final String repertoireId;
  final String studentId;

  const EditRepertoireScreen({
    super.key,
    required this.repertoireId,
    required this.studentId,
  });

  @override
  ConsumerState<EditRepertoireScreen> createState() => _EditRepertoireScreenState();
}

class _EditRepertoireScreenState extends ConsumerState<EditRepertoireScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;
  bool _isInitialized = false;

  // Date fields
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _initializeFromRepertoire(PracticeRepertoire repertoire) {
    if (_isInitialized) return;
    _isInitialized = true;

    _nameController.text = repertoire.name;
    _descriptionController.text = repertoire.description ?? '';
    _startDate = repertoire.startDate;
    _endDate = repertoire.endDate;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final currentRepertoire = await ref.read(repertoireProvider(widget.repertoireId).future);
      if (currentRepertoire == null) throw Exception('Repertoire not found');

      final updatedRepertoire = currentRepertoire.copyWith(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
        clearEndDate: _endDate == null,
        updatedAt: DateTime.now(),
      );

      await ref.read(repertoireCrudProvider.notifier).updateRepertoire(updatedRepertoire);

      if (mounted) {
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('레퍼토리 수정에 실패했습니다: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _archive() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('아카이브'),
        content: const Text('이 레퍼토리를 아카이브하시겠습니까?\n아카이브된 레퍼토리는 목록에서 숨겨집니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('아카이브'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final currentRepertoire = await ref.read(repertoireProvider(widget.repertoireId).future);
      if (currentRepertoire == null) throw Exception('Repertoire not found');

      final archivedRepertoire = currentRepertoire.copyWith(
        isArchived: true,
        archivedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ref.read(repertoireCrudProvider.notifier).updateRepertoire(archivedRepertoire);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('레퍼토리가 아카이브되었습니다')),
        );
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('아카이브에 실패했습니다: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('레퍼토리 삭제'),
        content: const Text('이 레퍼토리를 삭제하시겠습니까?\n연결된 모든 섹션과 녹음이 함께 삭제됩니다.\n이 작업은 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(repertoireCrudProvider.notifier).deleteRepertoire(
            widget.repertoireId,
            widget.studentId,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('레퍼토리가 삭제되었습니다')),
        );
        // Pop twice to go back to the list
        context.pop();
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('삭제에 실패했습니다: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectStartDate() async {
    final picked = await AppDatePicker.show(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: '시작일 선택',
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        // If end date is before start date, clear it
        if (_endDate != null && _endDate!.isBefore(_startDate)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await AppDatePicker.show(
      context: context,
      initialDate: _endDate ?? _startDate,
      firstDate: _startDate,
      lastDate: DateTime(2030),
      helpText: '종료일 선택',
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  void _clearEndDate() {
    setState(() => _endDate = null);
  }

  @override
  Widget build(BuildContext context) {
    final repertoireAsync = ref.watch(repertoireProvider(widget.repertoireId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('레퍼토리 편집'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _submit,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('저장'),
          ),
        ],
      ),
      body: repertoireAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('오류: $e')),
        data: (repertoire) {
          if (repertoire == null) {
            return const Center(child: Text('레퍼토리를 찾을 수 없습니다'));
          }

          _initializeFromRepertoire(repertoire);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name field
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: '레퍼토리 이름 *',
                      hintText: '예: 스즈키 6권, 바흐 협주곡',
                      prefixIcon: Icon(Icons.library_music),
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '레퍼토리 이름을 입력해주세요';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: AppSpacing.space4),

                  // Description field
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: '설명 (선택)',
                      hintText: '예: Bach Violin Concerto in A minor',
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 2,
                    textInputAction: TextInputAction.done,
                  ),

                  const SizedBox(height: AppSpacing.space6),

                  // Period section using DateRangeSection
                  DateRangeSection(
                    startDate: _startDate,
                    endDate: _endDate,
                    onStartDateTap: _selectStartDate,
                    onEndDateTap: _selectEndDate,
                    onEndDateClear: _clearEndDate,
                    endDatePlaceholder: '설정 안함 (매일 반복)',
                    showHintMessage: true,
                  ),

                  const SizedBox(height: AppSpacing.space8),

                  // Danger zone
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.space4),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '관리',
                          style: AppTypography.headingSmall.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.space3),

                        // Archive button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _isLoading ? null : _archive,
                            icon: const Icon(Icons.archive_outlined),
                            label: const Text('아카이브'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.warning,
                              side: const BorderSide(color: AppColors.warning),
                            ),
                          ),
                        ),

                        const SizedBox(height: AppSpacing.space2),

                        // Delete button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _isLoading ? null : _delete,
                            icon: const Icon(Icons.delete_forever),
                            label: const Text('레퍼토리 삭제'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
