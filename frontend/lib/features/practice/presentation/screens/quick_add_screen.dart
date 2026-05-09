import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:lessonaza/core/widgets/notebook/thin_rule.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../features/practice/practice_facade.dart';
import '../../../../core/widgets/app_date_picker.dart';
import '../widgets/section_form/date_range_section.dart';
import '../widgets/section_form/range_picker_sheet.dart';

/// Input data for a single section in quick add
class _SectionInput {
  final TextEditingController pieceNameController;
  SectionRangeType rangeType;
  int startMeasure;
  int endMeasure;
  int startLine;
  int endLine;

  _SectionInput()
    : pieceNameController = TextEditingController(),
      rangeType = SectionRangeType.full,
      startMeasure = 1,
      endMeasure = 4,
      startLine = 1,
      endLine = 2;

  void dispose() {
    pieceNameController.dispose();
  }

  String get pieceName => pieceNameController.text.trim();
  bool get isValid => pieceName.isNotEmpty;
}

/// Quick add screen for simplified repertoire + section registration
class QuickAddScreen extends ConsumerStatefulWidget {
  final String studentId;

  const QuickAddScreen({super.key, required this.studentId});

  @override
  ConsumerState<QuickAddScreen> createState() => _QuickAddScreenState();
}

class _QuickAddScreenState extends ConsumerState<QuickAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repertoireNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  // Date fields
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;

  // Sections list (starts with one section)
  final List<_SectionInput> _sections = [_SectionInput()];

  // Predefined repertoire suggestions
  final List<String> _repertoireSuggestions = [
    '스즈키 1권',
    '스즈키 2권',
    '스즈키 3권',
    '스케일/아르페지오',
    '크로이처 에튀드',
    '바흐 소나타',
  ];

  // Common piece suggestions
  static const List<String> _pieceSuggestions = [
    '1번',
    '2번',
    '3번',
    'Allegro',
    'Andante',
    'Minuet',
    'Etude No.1',
  ];

  @override
  void dispose() {
    _repertoireNameController.dispose();
    _descriptionController.dispose();
    for (final section in _sections) {
      section.dispose();
    }
    super.dispose();
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

  void _addSection() {
    setState(() {
      _sections.add(_SectionInput());
    });
  }

  void _removeSection(int index) {
    if (_sections.length > 1) {
      setState(() {
        _sections[index].dispose();
        _sections.removeAt(index);
      });
    }
  }

  Future<void> _submit() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    // Validate all sections have piece names
    for (int i = 0; i < _sections.length; i++) {
      if (!_sections[i].isValid) {
        _showErrorSnackBar('섹션 ${i + 1}의 곡명을 입력해주세요');
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      // 1. Create repertoire
      final repertoire = await ref
          .read(repertoireCrudProvider.notifier)
          .createRepertoire(
            studentId: widget.studentId,
            name: _repertoireNameController.text.trim(),
            description:
                _descriptionController.text.trim().isEmpty
                    ? null
                    : _descriptionController.text.trim(),
            startDate: _startDate,
            endDate: _endDate,
          );

      // 2. Create all sections
      for (final section in _sections) {
        await ref
            .read(sectionCrudProvider.notifier)
            .createSection(
              repertoireId: repertoire.id,
              pieceName: section.pieceName,
              rangeType: section.rangeType,
              startMeasure:
                  section.rangeType == SectionRangeType.measure
                      ? section.startMeasure
                      : 1,
              endMeasure:
                  section.rangeType == SectionRangeType.measure
                      ? section.endMeasure
                      : 1,
              startLine:
                  section.rangeType == SectionRangeType.line
                      ? section.startLine
                      : null,
              endLine:
                  section.rangeType == SectionRangeType.line
                      ? section.endLine
                      : null,
            );
      }

      // Invalidate providers to refresh
      ref.invalidate(studentRepertoiresProvider(widget.studentId));
      final today = DateTime.now();
      ref.invalidate(
        repertoiresForDateProvider(
          RepertoiresForDateParams(studentId: widget.studentId, date: today),
        ),
      );

      if (mounted) {
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('저장에 실패했습니다. 다시 시도해주세요.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.paperAccent),
    );
  }

  void _showMeasurePicker(int sectionIndex, {required bool isStart}) {
    final section = _sections[sectionIndex];
    final initialValue = isStart ? section.startMeasure : section.endMeasure;

    showNotebookModalBottomSheet<void>(
      context: context,
      builder:
          (context) => RangePickerSheet(
            title: isStart ? '시작 마디' : '끝 마디',
            unit: '마디',
            initialValue: initialValue,
            maxValue: 100,
            onSelected: (value) {
              setState(() {
                if (isStart) {
                  section.startMeasure = value;
                  if (section.endMeasure < section.startMeasure) {
                    section.endMeasure = section.startMeasure;
                  }
                } else {
                  section.endMeasure = value;
                }
              });
            },
          ),
    );
  }

  void _showLinePicker(int sectionIndex, {required bool isStart}) {
    final section = _sections[sectionIndex];
    final initialValue = isStart ? section.startLine : section.endLine;

    showNotebookModalBottomSheet<void>(
      context: context,
      builder:
          (context) => RangePickerSheet(
            title: isStart ? '시작 줄' : '끝 줄',
            unit: '줄',
            initialValue: initialValue,
            maxValue: 10,
            onSelected: (value) {
              setState(() {
                if (isStart) {
                  section.startLine = value;
                  if (section.endLine < section.startLine) {
                    section.endLine = section.startLine;
                  }
                } else {
                  section.endLine = value;
                }
              });
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return NotebookScreenScaffold(
      appBar: const NotebookDetailAppBar(title: AppStrings.practiceRepertoireAddTitle),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Repertoire name field
              TextFormField(
                controller: _repertoireNameController,
                decoration: const InputDecoration(
                  labelText: '레퍼토리 이름 *',
                  hintText: AppStrings.practiceRepertoireNameHintSuzuki,
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
              const SizedBox(height: AppSpacing.space3),

              // Quick repertoire suggestions
              Wrap(
                spacing: AppSpacing.space2,
                runSpacing: AppSpacing.space1,
                children:
                    _repertoireSuggestions.map((name) {
                      return ActionChip(
                        label: Text(name, style: AppTypography.bodySmall),
                        onPressed: () => _repertoireNameController.text = name,
                        visualDensity: VisualDensity.compact,
                      );
                    }).toList(),
              ),

              const SizedBox(height: AppSpacing.space4),

              // Description field (optional)
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: '설명 (선택)',
                  hintText: AppStrings.repertoireDescriptionHint,
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                maxLines: 1,
                textInputAction: TextInputAction.next,
              ),

              const SizedBox(height: AppSpacing.space4),

              // Practice period
              DateRangeSection(
                startDate: _startDate,
                endDate: _endDate,
                onStartDateTap: _selectStartDate,
                onEndDateTap: _selectEndDate,
                onEndDateClear: _clearEndDate,
                endDatePlaceholder: '설정 안함 (매일 반복)',
                showHintMessage: true,
              ),

              const SizedBox(height: AppSpacing.space6),

              // Section divider
              const ThinRule(),

              const SizedBox(height: AppSpacing.space4),

              // Section header
              Row(
                children: [
                  const Icon(
                    Icons.queue_music,
                    size: 20,
                    color: AppColors.paperAccent,
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  // Notebook × Score: 스크린 섹션 제목은 Playfair sectionTitle
                  // 로 통일 (§7.17).
                  Text(
                    AppStrings.practiceSectionListTitle,
                    style: NotebookTypography.sectionTitle,
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.space4),

              // Sections
              ...List.generate(_sections.length, (index) {
                return _buildSectionCard(index);
              }),

              // Add section button
              const SizedBox(height: AppSpacing.space4),
              Center(
                child: TextButton.icon(
                  onPressed: _addSection,
                  icon: const Icon(Icons.add),
                  label: const Text(AppStrings.practiceSectionAddLabel),
                ),
              ),

              const SizedBox(height: AppSpacing.space8),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isLoading ? null : _submit,
                  child:
                      _isLoading
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.paper,
                            ),
                          )
                          : const Text(AppStrings.practiceSaveButton),
                ),
              ),

              const SizedBox(height: AppSpacing.space4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(int index) {
    final section = _sections[index];

    return NotebookCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.space4),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '섹션 ${index + 1}',
                  style: AppTypography.headingSmall.copyWith(
                    color: AppColors.paperAccent,
                  ),
                ),
                if (_sections.length > 1)
                  IconButton(
                    onPressed: () => _removeSection(index),
                    icon: const Icon(Icons.close, size: 20),
                    visualDensity: VisualDensity.compact,
                    color: AppColors.inkSecondary,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.space3),

            // Piece name field
            TextFormField(
              controller: section.pieceNameController,
              decoration: const InputDecoration(
                labelText: '곡명 *',
                hintText: AppStrings.practicePieceNameHintStar,
                prefixIcon: Icon(Icons.music_note),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.space2),

            // Quick piece suggestions
            Wrap(
              spacing: AppSpacing.space1,
              runSpacing: AppSpacing.space1,
              children:
                  _pieceSuggestions.take(5).map((name) {
                    return ActionChip(
                      label: Text(name, style: AppTypography.caption),
                      onPressed: () => section.pieceNameController.text = name,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.space1,
                      ),
                    );
                  }).toList(),
            ),
            const SizedBox(height: AppSpacing.space4),

            // Range type selector (compact)
            _buildRangeTypeSelector(index),

            // Range input if not full
            if (section.rangeType != SectionRangeType.full) ...[
              const SizedBox(height: AppSpacing.space3),
              _buildRangeInput(index),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRangeTypeSelector(int index) {
    final section = _sections[index];

    return Row(
      children: [
        Text(AppStrings.practiceRangeLabel, style: AppTypography.bodyMedium),
        const SizedBox(width: AppSpacing.space3),
        Expanded(
          child: SegmentedButton<SectionRangeType>(
            segments: const [
              ButtonSegment(
                value: SectionRangeType.full,
                label: Text(
                  AppStrings.practiceRangeTypeFull,
                  style: AppTypography.bodySmall,
                ),
              ),
              ButtonSegment(
                value: SectionRangeType.line,
                label: Text(
                  AppStrings.practiceRangeTypeLine,
                  style: AppTypography.bodySmall,
                ),
              ),
              ButtonSegment(
                value: SectionRangeType.measure,
                label: Text(
                  AppStrings.practiceRangeTypeMeasure,
                  style: AppTypography.bodySmall,
                ),
              ),
            ],
            selected: {section.rangeType},
            onSelectionChanged: (selection) {
              setState(() => section.rangeType = selection.first);
            },
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
          ),
        ),
      ],
    );
  }

  Widget _buildRangeInput(int index) {
    final section = _sections[index];
    final isMeasure = section.rangeType == SectionRangeType.measure;

    return Row(
      children: [
        // Start picker
        Expanded(
          child: OutlinedButton(
            onPressed:
                () =>
                    isMeasure
                        ? _showMeasurePicker(index, isStart: true)
                        : _showLinePicker(index, isStart: true),
            child: Text(
              isMeasure ? '${section.startMeasure}마디' : '${section.startLine}줄',
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.space2),
          child: Text('~'),
        ),
        // End picker
        Expanded(
          child: OutlinedButton(
            onPressed:
                () =>
                    isMeasure
                        ? _showMeasurePicker(index, isStart: false)
                        : _showLinePicker(index, isStart: false),
            child: Text(
              isMeasure ? '${section.endMeasure}마디' : '${section.endLine}줄',
            ),
          ),
        ),
      ],
    );
  }
}
