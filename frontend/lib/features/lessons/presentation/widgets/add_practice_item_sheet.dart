import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';
import '../../../../features/practice/domain/entities/practice_repertoire.dart';
import '../../../practice/presentation/providers/practice_item_providers.dart';
import '../../../practice/presentation/providers/practice_repertoire_crud_provider.dart';
import '../providers/tip_template_providers.dart';
import 'resource_attachment_section.dart';

/// Range type for practice sections
enum RangeType {
  measure,
  line;

  String get label {
    switch (this) {
      case RangeType.measure:
        return '마디';
      case RangeType.line:
        return '줄';
    }
  }
}

/// A single practice range entry
class PracticeRangeEntry {
  RangeType type;
  final TextEditingController startController;
  final TextEditingController endController;

  PracticeRangeEntry({
    this.type = RangeType.measure,
    String? start,
    String? end,
  }) : startController = TextEditingController(text: start),
       endController = TextEditingController(text: end);

  void dispose() {
    startController.dispose();
    endController.dispose();
  }

  bool get isValid {
    final start = int.tryParse(startController.text.trim());
    final end = int.tryParse(endController.text.trim());
    return start != null && end != null && start <= end;
  }

  String toDisplayString() {
    final start = startController.text.trim();
    final end = endController.text.trim();
    return '$start~$end${type.label}';
  }
}

/// Bottom sheet for adding new practice item
class AddPracticeItemSheet extends ConsumerStatefulWidget {
  final String lessonId;
  final String studentId;

  const AddPracticeItemSheet({
    super.key,
    required this.lessonId,
    required this.studentId,
  });

  @override
  ConsumerState<AddPracticeItemSheet> createState() =>
      _AddPracticeItemSheetState();
}

class _AddPracticeItemSheetState extends ConsumerState<AddPracticeItemSheet> {
  final _descriptionController = TextEditingController();
  final _pieceNameController = TextEditingController();
  final _newRepertoireNameController = TextEditingController();

  // Multiple practice ranges
  final List<PracticeRangeEntry> _practiceRanges = [];

  bool _isSubmitting = false;
  List<String> _resourceIds = [];

  // Repertoire selection state
  PracticeRepertoire? _selectedRepertoire;
  bool _isCreatingNewRepertoire = false;

  @override
  void initState() {
    super.initState();
    // Start with one empty range
    _practiceRanges.add(PracticeRangeEntry());
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _pieceNameController.dispose();
    _newRepertoireNameController.dispose();
    for (final range in _practiceRanges) {
      range.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Fetch student's existing repertoires
    final repertoiresAsync = ref.watch(
      studentRepertoiresProvider(widget.studentId),
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXLarge),
        ),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              const Center(
                child: BottomSheetHandle(
                  margin: EdgeInsets.only(bottom: AppSpacing.space4),
                ),
              ),

              // Notebook × Score §7.27: 바텀시트 제목 Playfair.
              Text('연습 추가', style: NotebookTypography.sectionTitle),
              const SizedBox(height: AppSpacing.space4),

              // Repertoire-based form (all practice items are repertoire-based)
              _buildRepertoireSection(repertoiresAsync),

              // Description
              Text(
                '설명 (선택)',
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.space2),
              TextField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: '예: 메트로놈 60으로 정확하게!',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppSpacing.radiusMedium,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.space4),

              // Teaching resources attachment
              ResourceAttachmentEditor(
                resourceIds: _resourceIds,
                onChanged: (ids) => setState(() => _resourceIds = ids),
              ),
              const SizedBox(height: AppSpacing.space6),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child:
                      _isSubmitting
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text('추가'),
                ),
              ),
              const SizedBox(height: AppSpacing.space4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRepertoireSection(
    AsyncValue<List<PracticeRepertoire>> repertoiresAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Repertoire selection
        Text(
          '레퍼토리',
          style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.space2),

        repertoiresAsync.when(
          data: (repertoires) => _buildRepertoireSelector(repertoires),
          loading:
              () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.space4),
                  child: CircularProgressIndicator(),
                ),
              ),
          error:
              (_, __) => Container(
                padding: const EdgeInsets.all(AppSpacing.space3),
                decoration: BoxDecoration(
                  color: AppColors.paperAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                ),
                child: Text(
                  '레퍼토리를 불러올 수 없습니다',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.paperAccent,
                  ),
                ),
              ),
        ),
        const SizedBox(height: AppSpacing.space4),

        // New repertoire name input (if creating new)
        if (_isCreatingNewRepertoire) ...[
          Text(
            '새 레퍼토리 이름',
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          TextField(
            controller: _newRepertoireNameController,
            decoration: InputDecoration(
              hintText: '예: 스즈키 5권',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
        ],

        // Piece name
        Text(
          '곡명',
          style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.space2),
        TextField(
          controller: _pieceNameController,
          decoration: InputDecoration(
            hintText: '예: 라폴리아',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.space4),

        // Practice ranges (multiple)
        Text(
          '연습 구간',
          style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.space2),
        _buildPracticeRanges(),
        const SizedBox(height: AppSpacing.space4),
      ],
    );
  }

  Widget _buildRepertoireSelector(List<PracticeRepertoire> repertoires) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.inkQuaternary),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      ),
      child: Column(
        children: [
          // Existing repertoires
          ...repertoires.map((repertoire) {
            final isSelected =
                _selectedRepertoire?.id == repertoire.id &&
                !_isCreatingNewRepertoire;
            return InkWell(
              onTap:
                  () => setState(() {
                    _selectedRepertoire = repertoire;
                    _isCreatingNewRepertoire = false;
                  }),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.space3),
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? AppColors.paperAccent.withValues(alpha: 0.1)
                          : null,
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.inkQuaternary,
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color:
                              isSelected
                                  ? AppColors.paperAccent
                                  : AppColors.inkQuaternary,
                          width: 2,
                        ),
                        color:
                            isSelected
                                ? AppColors.paperAccent
                                : Colors.transparent,
                      ),
                      child:
                          isSelected
                              ? const Icon(
                                Icons.check,
                                size: 14,
                                color: Colors.white,
                              )
                              : null,
                    ),
                    const SizedBox(width: AppSpacing.space3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            repertoire.name,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight:
                                  isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                            ),
                          ),
                          if (repertoire.sections.isNotEmpty)
                            Text(
                              '${repertoire.sections.length}개 섹션',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.inkSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          // Create new repertoire option
          InkWell(
            onTap:
                () => setState(() {
                  _selectedRepertoire = null;
                  _isCreatingNewRepertoire = true;
                }),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.space3),
              decoration: BoxDecoration(
                color:
                    _isCreatingNewRepertoire
                        ? AppColors.paperAccent.withValues(alpha: 0.1)
                        : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            _isCreatingNewRepertoire
                                ? AppColors.paperAccent
                                : AppColors.inkQuaternary,
                        width: 2,
                      ),
                      color:
                          _isCreatingNewRepertoire
                              ? AppColors.paperAccent
                              : Colors.transparent,
                    ),
                    child:
                        _isCreatingNewRepertoire
                            ? const Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.white,
                            )
                            : null,
                  ),
                  const SizedBox(width: AppSpacing.space3),
                  Icon(
                    Icons.add_circle_outline,
                    size: 20,
                    color:
                        _isCreatingNewRepertoire
                            ? AppColors.paperAccent
                            : AppColors.inkSecondary,
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  Text(
                    '새 레퍼토리 만들기',
                    style: AppTypography.bodyMedium.copyWith(
                      color:
                          _isCreatingNewRepertoire
                              ? AppColors.paperAccent
                              : AppColors.inkSecondary,
                      fontWeight:
                          _isCreatingNewRepertoire
                              ? FontWeight.w600
                              : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPracticeRanges() {
    return Column(
      children: [
        // Range entries
        ...List.generate(_practiceRanges.length, (index) {
          return _buildRangeEntry(index);
        }),

        // Add range button (styled differently from main submit button)
        const SizedBox(height: AppSpacing.space2),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () {
              setState(() {
                _practiceRanges.add(PracticeRangeEntry());
              });
            },
            icon: Icon(Icons.add, size: 18, color: AppColors.inkSecondary),
            label: Text(
              '구간 추가',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space2,
                vertical: AppSpacing.space1,
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRangeEntry(int index) {
    final range = _practiceRanges[index];
    final canDelete = _practiceRanges.length > 1;

    return Container(
      margin: EdgeInsets.only(
        bottom: index < _practiceRanges.length - 1 ? AppSpacing.space2 : 0,
      ),
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.paperDark,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Row(
        children: [
          // Type dropdown (마디/줄)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space2),
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
              border: Border.all(color: AppColors.inkQuaternary),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<RangeType>(
                value: range.type,
                isDense: true,
                items:
                    RangeType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.label, style: AppTypography.bodySmall),
                      );
                    }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      range.type = value;
                    });
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.space2),

          // Start input
          Expanded(
            child: SizedBox(
              height: 40,
              child: TextField(
                controller: range.startController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: '시작',
                  hintStyle: AppTypography.bodySmall.copyWith(
                    color: AppColors.inkTertiary,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space2,
                    vertical: AppSpacing.space2,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                  ),
                  filled: true,
                  fillColor: AppColors.paper,
                ),
                style: AppTypography.bodySmall,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space1),
            child: Text('~', style: AppTypography.bodyMedium),
          ),

          // End input
          Expanded(
            child: SizedBox(
              height: 40,
              child: TextField(
                controller: range.endController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: '끝',
                  hintStyle: AppTypography.bodySmall.copyWith(
                    color: AppColors.inkTertiary,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space2,
                    vertical: AppSpacing.space2,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                  ),
                  filled: true,
                  fillColor: AppColors.paper,
                ),
                style: AppTypography.bodySmall,
              ),
            ),
          ),

          // Delete button
          const SizedBox(width: AppSpacing.space2),
          if (canDelete)
            InkWell(
              onTap: () {
                setState(() {
                  _practiceRanges[index].dispose();
                  _practiceRanges.removeAt(index);
                });
              },
              borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.space1),
                child: Icon(
                  Icons.close,
                  size: 20,
                  color: AppColors.inkTertiary,
                ),
              ),
            )
          else
            const SizedBox(width: 28), // Placeholder for alignment
        ],
      ),
    );
  }

  Future<void> _submit() async {
    // Validate repertoire selection
    if (!_isCreatingNewRepertoire && _selectedRepertoire == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('레퍼토리를 선택해주세요')));
      return;
    }
    if (_isCreatingNewRepertoire &&
        _newRepertoireNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('새 레퍼토리 이름을 입력해주세요')));
      return;
    }
    if (_pieceNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('곡명을 입력해주세요')));
      return;
    }
    // Validate all practice ranges
    for (int i = 0; i < _practiceRanges.length; i++) {
      final range = _practiceRanges[i];
      final start = int.tryParse(range.startController.text.trim());
      final end = int.tryParse(range.endController.text.trim());
      if (start == null || end == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('구간 ${i + 1}의 시작/끝 번호를 입력해주세요')));
        return;
      }
      if (start > end) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('구간 ${i + 1}의 시작 번호가 끝 번호보다 클 수 없습니다')),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      final teacherId = ref.read(currentTeacherIdProvider);
      final pieceName = _pieceNameController.text.trim();

      // Create or get repertoire
      PracticeRepertoire repertoire;
      if (_isCreatingNewRepertoire) {
        repertoire = await ref
            .read(repertoireCrudProvider.notifier)
            .createRepertoire(
              studentId: widget.studentId,
              name: _newRepertoireNameController.text.trim(),
            );
      } else {
        repertoire = _selectedRepertoire!;
      }
      final repertoireId = repertoire.id;

      // Create section for first range (primary section)
      final firstRange = _practiceRanges.first;
      final startMeasure = int.parse(firstRange.startController.text.trim());
      final endMeasure = int.parse(firstRange.endController.text.trim());

      final section = await ref
          .read(sectionCrudProvider.notifier)
          .createSection(
            repertoireId: repertoireId,
            pieceName: pieceName,
            startMeasure: startMeasure,
            endMeasure: endMeasure,
          );
      final sectionId = section.id;

      // Build title: "곡명 시작~끝마디, 시작~끝줄, ..."
      final rangeStrings = _practiceRanges
          .map((r) => r.toDisplayString())
          .join(', ');
      final title = '$pieceName $rangeStrings';

      // Create practice item (always repertoire type)
      await ref
          .read(practiceItemsNotifierProvider(widget.lessonId).notifier)
          .addItem(
            studentId: widget.studentId,
            teacherId: teacherId,
            title: title,
            description:
                _descriptionController.text.trim().isNotEmpty
                    ? _descriptionController.text.trim()
                    : null,
            repertoireId: repertoireId,
            sectionId: sectionId,
            resourceIds: _resourceIds,
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('연습이 추가되었습니다')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('오류가 발생했습니다. 다시 시도해주세요.')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
