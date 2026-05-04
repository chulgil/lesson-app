import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../../../features/practice/presentation/providers/practice_repertoire_crud_provider.dart';
import '../../domain/entities/practice_repertoire.dart';
import '../widgets/section_form/add_section_widgets.dart';
import '../widgets/section_form/range_picker_sheet.dart';

/// Screen for editing an existing practice section
class EditSectionScreen extends ConsumerStatefulWidget {
  final String sectionId;
  final String repertoireId;
  final String studentId;

  const EditSectionScreen({
    super.key,
    required this.sectionId,
    required this.repertoireId,
    required this.studentId,
  });

  @override
  ConsumerState<EditSectionScreen> createState() => _EditSectionScreenState();
}

class _EditSectionScreenState extends ConsumerState<EditSectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pieceNameController = TextEditingController();
  final _sectionNameController = TextEditingController();
  bool _isLoading = false;
  bool _isInitialized = false;

  // Original section for comparison
  PracticeSection? _originalSection;

  // Repertoire info for context display
  PracticeRepertoire? _repertoire;

  // Range type selection
  SectionRangeType _rangeType = SectionRangeType.measure;

  // Measure range (1-100)
  int _startMeasure = 1;
  int _endMeasure = 4;

  // Line range (1-10)
  int _startLine = 1;
  int _endLine = 2;

  // Repeat settings (N회 반복)
  int? _repeatCount;

  // Target practice time in minutes (null = no target)
  int? _targetPracticeMinutes;

  @override
  void initState() {
    super.initState();
    _loadSectionData();
  }

  Future<void> _loadSectionData() async {
    // Load repertoire data for context display
    final repertoire = await ref.read(
      repertoireProvider(widget.repertoireId).future,
    );

    // Load section data
    final section = await ref.read(sectionProvider(widget.sectionId).future);
    if (section != null && mounted) {
      _repertoire = repertoire;
      setState(() {
        _originalSection = section;
        _pieceNameController.text = section.pieceName;
        _sectionNameController.text = section.sectionName ?? '';
        _rangeType = section.rangeType;
        _startMeasure = section.startMeasure;
        _endMeasure = section.endMeasure;
        _startLine = section.startLine ?? 1;
        _endLine = section.endLine ?? 2;
        _repeatCount = section.repeatCount;
        _targetPracticeMinutes =
            section.targetPracticeSeconds != null
                ? (section.targetPracticeSeconds! / 60).round()
                : null;
        _isInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _pieceNameController.dispose();
    _sectionNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_originalSection == null) return;

    // Validate range based on type
    if (_rangeType == SectionRangeType.measure) {
      if (_startMeasure > _endMeasure) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.practiceStartMeasureGreaterError),
            backgroundColor: AppColors.paperAccent,
          ),
        );
        return;
      }
    } else {
      if (_startLine > _endLine) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.practiceStartLineGreaterError),
            backgroundColor: AppColors.paperAccent,
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final updatedSection = _originalSection!.copyWith(
        pieceName: _pieceNameController.text.trim(),
        rangeType: _rangeType,
        startMeasure:
            _rangeType == SectionRangeType.measure ? _startMeasure : 1,
        endMeasure: _rangeType == SectionRangeType.measure ? _endMeasure : 1,
        startLine: _rangeType == SectionRangeType.line ? _startLine : null,
        endLine: _rangeType == SectionRangeType.line ? _endLine : null,
        clearStartLine: _rangeType != SectionRangeType.line,
        clearEndLine: _rangeType != SectionRangeType.line,
        sectionName:
            _sectionNameController.text.trim().isEmpty
                ? null
                : _sectionNameController.text.trim(),
        isRepeat: true, // 섹션은 레퍼토리 기간 동안 매일 반복
        repeatCount: _repeatCount,
        clearRepeatCount: _repeatCount == null,
        clearStartDate: true, // 섹션 날짜는 레퍼토리에서 상속
        clearEndDate: true,
        targetPracticeSeconds:
            _targetPracticeMinutes != null
                ? _targetPracticeMinutes! * 60
                : null,
        clearTargetPracticeSeconds: _targetPracticeMinutes == null,
        updatedAt: DateTime.now(),
      );

      await ref
          .read(sectionCrudProvider.notifier)
          .updateSection(updatedSection, studentId: widget.studentId);

      // Invalidate providers to refresh
      ref.invalidate(sectionProvider(widget.sectionId));
      ref.invalidate(repertoireProvider(widget.repertoireId));
      ref.invalidate(studentRepertoiresProvider(widget.studentId));
      // Also invalidate date-based provider
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(AppStrings.practiceSectionUpdateFailedRetry),
            backgroundColor: AppColors.paperAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMeasurePicker({required bool isStart}) {
    final initialValue = isStart ? _startMeasure : _endMeasure;

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
                  _startMeasure = value;
                  if (_endMeasure < _startMeasure) {
                    _endMeasure = _startMeasure;
                  }
                } else {
                  _endMeasure = value;
                }
              });
            },
          ),
    );
  }

  void _showLinePicker({required bool isStart}) {
    final initialValue = isStart ? _startLine : _endLine;

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
                  _startLine = value;
                  if (_endLine < _startLine) {
                    _endLine = _startLine;
                  }
                } else {
                  _endLine = value;
                }
              });
            },
          ),
    );
  }

  String _getRangePreviewText() {
    if (_rangeType == SectionRangeType.measure) {
      return '$_startMeasure~$_endMeasure마디';
    } else {
      return '$_startLine~$_endLine줄';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return NotebookScreenScaffold(
        appBar: AppBar(title: const Text(AppStrings.practiceSectionEditTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return NotebookScreenScaffold(
      appBar: AppBar(title: const Text(AppStrings.practiceSectionEditTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ========================================
              // 📚 레퍼토리 정보 (읽기 전용)
              // ========================================
              if (_repertoire != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.space4),
                  decoration: BoxDecoration(
                    color: AppColors.paperAccentSoft,
                    border: Border.all(color: AppColors.paperAccentSoft),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.library_music,
                        color: AppColors.paperAccent,
                        size: 24,
                      ),
                      const SizedBox(width: AppSpacing.space3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _repertoire!.name,
                              style: AppTypography.headingSmall.copyWith(
                                color: AppColors.paperAccent,
                              ),
                            ),
                            if (_repertoire!.description != null &&
                                _repertoire!.description!.isNotEmpty)
                              Text(
                                _repertoire!.description!,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.inkSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.space6),
              ],

              // Piece name field
              TextFormField(
                controller: _pieceNameController,
                decoration: const InputDecoration(
                  labelText: '곡/연습곡 이름 *',
                  hintText: AppStrings.practicePieceNameHint,
                  prefixIcon: Icon(Icons.music_note),
                ),
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '곡 이름을 입력해주세요';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppSpacing.space6),

              // Range type selector (전체/줄/마디)
              // Notebook × Score: 폼 섹션 라벨은 Playfair sectionTitle
              // 로 통일 (§7.17).
              Text(
                AppStrings.practiceRangeTypeTitle,
                style: NotebookTypography.sectionTitle,
              ),
              const SizedBox(height: AppSpacing.space2),
              SegmentedButton<SectionRangeType>(
                segments: const [
                  ButtonSegment(
                    value: SectionRangeType.full,
                    label: Text(AppStrings.practiceRangeTypeFull),
                    icon: Icon(Icons.select_all),
                  ),
                  ButtonSegment(
                    value: SectionRangeType.line,
                    label: Text(AppStrings.practiceRangeTypeLine),
                    icon: Icon(Icons.format_line_spacing),
                  ),
                  ButtonSegment(
                    value: SectionRangeType.measure,
                    label: Text(AppStrings.practiceRangeTypeMeasure),
                    icon: Icon(Icons.straighten),
                  ),
                ],
                selected: {_rangeType},
                onSelectionChanged: (selection) {
                  setState(() {
                    _rangeType = selection.first;
                  });
                },
              ),

              // Range input based on type (hidden when 'full' is selected)
              if (_rangeType == SectionRangeType.measure) ...[
                const SizedBox(height: AppSpacing.space4),
                // Notebook × Score: 폼 섹션 라벨은 Playfair sectionTitle
                // 로 통일 (§7.17).
                Text(
                  AppStrings.practiceMeasureRangeTitle,
                  style: NotebookTypography.sectionTitle,
                ),
                const SizedBox(height: AppSpacing.space1),
                Text(
                  '연습할 마디 구간을 선택하세요',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.space4),
                RangePickers(
                  startValue: _startMeasure,
                  endValue: _endMeasure,
                  startLabel: '시작 마디',
                  endLabel: '끝 마디',
                  unit: '마디',
                  onStartTap: () => _showMeasurePicker(isStart: true),
                  onEndTap: () => _showMeasurePicker(isStart: false),
                ),
              ] else if (_rangeType == SectionRangeType.line) ...[
                const SizedBox(height: AppSpacing.space4),
                // Notebook × Score: 폼 섹션 라벨은 Playfair sectionTitle
                // 로 통일 (§7.17).
                Text(
                  AppStrings.practiceLineRangeTitle,
                  style: NotebookTypography.sectionTitle,
                ),
                const SizedBox(height: AppSpacing.space1),
                Text(
                  '연습할 줄 구간을 선택하세요 (1~10줄)',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.space4),
                RangePickers(
                  startValue: _startLine,
                  endValue: _endLine,
                  startLabel: '시작 줄',
                  endLabel: '끝 줄',
                  unit: '줄',
                  onStartTap: () => _showLinePicker(isStart: true),
                  onEndTap: () => _showLinePicker(isStart: false),
                ),
              ],
              // When 'full' is selected, no range input is shown

              // Section name preview and alias field (only for line/measure types)
              if (_rangeType != SectionRangeType.full) ...[
                const SizedBox(height: AppSpacing.space2),

                // Auto-generated section name preview
                RangePreviewBox(rangeText: _getRangePreviewText()),

                const SizedBox(height: AppSpacing.space6),

                // Optional section name field
                TextFormField(
                  controller: _sectionNameController,
                  decoration: InputDecoration(
                    labelText: '섹션 별칭 (선택)',
                    hintText: AppStrings.practiceSectionAliasHint,
                    helperText: '비워두면 "${_getRangePreviewText()}"로 표시됩니다',
                    prefixIcon: const Icon(Icons.label_outline),
                  ),
                  textInputAction: TextInputAction.done,
                ),
              ],

              const SizedBox(height: AppSpacing.space8),

              // ========================================
              // 🐾 N회 반복 설정 (선택)
              // ========================================
              RepeatCountSection(
                repeatCount: _repeatCount,
                onChanged: (value) => setState(() => _repeatCount = value),
              ),

              const SizedBox(height: AppSpacing.space8),

              // ========================================
              // ⏱️ 목표 연습시간 설정 (선택)
              // ========================================
              TargetTimeSection(
                targetMinutes: _targetPracticeMinutes,
                onChanged:
                    (value) => setState(() => _targetPracticeMinutes = value),
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
                          : const Text(AppStrings.practiceSaveChanges),
                ),
              ),

              const SizedBox(height: AppSpacing.space4),
            ],
          ),
        ),
      ),
    );
  }
}
