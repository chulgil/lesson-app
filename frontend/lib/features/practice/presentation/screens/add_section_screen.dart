import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../features/practice/presentation/providers/practice_repertoire_crud_provider.dart';
import '../../domain/entities/practice_repertoire.dart';
import '../widgets/section_form/add_section_widgets.dart';
import '../widgets/section_form/range_picker_sheet.dart';

/// Screen for adding a new practice section with measure/line range selection
class AddSectionScreen extends ConsumerStatefulWidget {
  final String repertoireId;
  final String studentId;

  const AddSectionScreen({
    super.key,
    required this.repertoireId,
    required this.studentId,
  });

  @override
  ConsumerState<AddSectionScreen> createState() => _AddSectionScreenState();
}

class _AddSectionScreenState extends ConsumerState<AddSectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pieceNameController = TextEditingController();
  final _sectionNameController = TextEditingController();
  final _pieceNameFocusNode = FocusNode();
  bool _isLoading = false;
  bool _isInitialized = false;
  bool _isPieceNameFocused = false;

  // Repertoire info for context display
  PracticeRepertoire? _repertoire;

  // Range type selection (default: 전체)
  SectionRangeType _rangeType = SectionRangeType.full;

  // Measure range (1-100)
  int _startMeasure = 1;
  int _endMeasure = 4;

  // Line range (1-10)
  int _startLine = 1;
  int _endLine = 2;

  // Repeat settings (N회 반복)
  int? _repeatCount; // null = 없음, 2~10

  // Target practice time in minutes (null = no target)
  int? _targetPracticeMinutes;

  // Common piece suggestions based on repertoire
  static const List<String> _pieceSuggestions = [
    '1번',
    '2번',
    '3번',
    '4번',
    '5번',
    'Allegro',
    'Andante',
    'Minuet',
    'Gavotte',
    'Etude No.1',
    'Etude No.2',
    'Scale C Major',
  ];

  @override
  void initState() {
    super.initState();
    _loadRepertoireData();
    _pieceNameFocusNode.addListener(() {
      setState(() => _isPieceNameFocused = _pieceNameFocusNode.hasFocus);
    });
  }

  Future<void> _loadRepertoireData() async {
    final repertoire = await ref.read(
      repertoireProvider(widget.repertoireId).future,
    );
    if (mounted) {
      setState(() {
        _repertoire = repertoire;
        _isInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _pieceNameController.dispose();
    _sectionNameController.dispose();
    _pieceNameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Prevent duplicate submissions
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    // Validate range based on type
    if (_rangeType == SectionRangeType.measure) {
      if (_startMeasure > _endMeasure) {
        _showErrorSnackBar('시작 마디가 끝 마디보다 클 수 없습니다');
        return;
      }
    } else if (_rangeType == SectionRangeType.line) {
      if (_startLine > _endLine) {
        _showErrorSnackBar('시작 줄이 끝 줄보다 클 수 없습니다');
        return;
      }
    }

    // Check for duplicate section (same name + range)
    final repertoire = await ref.read(
      repertoireProvider(widget.repertoireId).future,
    );
    if (repertoire != null && _isDuplicateSection(repertoire)) {
      if (!mounted) return;
      _showErrorSnackBar('동일한 곡명과 범위의 섹션이 이미 존재합니다');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref
          .read(sectionCrudProvider.notifier)
          .createSection(
            repertoireId: widget.repertoireId,
            pieceName: _pieceNameController.text.trim(),
            rangeType: _rangeType,
            startMeasure:
                _rangeType == SectionRangeType.measure ? _startMeasure : 1,
            endMeasure:
                _rangeType == SectionRangeType.measure ? _endMeasure : 1,
            startLine: _rangeType == SectionRangeType.line ? _startLine : null,
            endLine: _rangeType == SectionRangeType.line ? _endLine : null,
            sectionName:
                _sectionNameController.text.trim().isEmpty
                    ? null
                    : _sectionNameController.text.trim(),
            isRepeat: true, // 섹션은 레퍼토리 기간 동안 매일 반복
            repeatCount: _repeatCount,
            startDate: null, // 섹션 날짜는 레퍼토리에서 상속
            endDate: null,
            targetPracticeSeconds:
                _targetPracticeMinutes != null
                    ? _targetPracticeMinutes! * 60
                    : null,
          );

      // Invalidate providers to refresh
      _invalidateProviders();

      if (mounted) {
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('섹션 추가에 실패했습니다. 다시 시도해주세요.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _isDuplicateSection(PracticeRepertoire repertoire) {
    final pieceName = _pieceNameController.text.trim();
    return repertoire.sections.any((section) {
      if (section.pieceName != pieceName) return false;

      switch (_rangeType) {
        case SectionRangeType.full:
          return section.rangeType == SectionRangeType.full;
        case SectionRangeType.measure:
          return section.rangeType == SectionRangeType.measure &&
              section.startMeasure == _startMeasure &&
              section.endMeasure == _endMeasure;
        case SectionRangeType.line:
          return section.rangeType == SectionRangeType.line &&
              section.startLine == _startLine &&
              section.endLine == _endLine;
      }
    });
  }

  void _invalidateProviders() {
    ref.invalidate(studentRepertoiresProvider(widget.studentId));
    final today = DateTime.now();
    ref.invalidate(
      repertoiresForDateProvider(
        RepertoiresForDateParams(studentId: widget.studentId, date: today),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.paperAccent),
    );
  }

  void _showMeasurePicker({required bool isStart}) {
    final initialValue = isStart ? _startMeasure : _endMeasure;

    showModalBottomSheet(
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

    showModalBottomSheet(
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
      return Scaffold(
        appBar: AppBar(title: const Text('섹션 추가')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('섹션 추가')),
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
                    color: AppColors.paperAccent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                    border: Border.all(
                      color: AppColors.paperAccent.withValues(alpha: 0.2),
                    ),
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
                focusNode: _pieceNameFocusNode,
                decoration: const InputDecoration(
                  labelText: '곡/연습곡 이름 *',
                  hintText: '예: 1번, Allegro, Etude No.1',
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

              // Quick piece selection (only visible when piece name is focused)
              if (_isPieceNameFocused) ...[
                const SizedBox(height: AppSpacing.space3),
                PieceSuggestionChips(
                  suggestions: _pieceSuggestions,
                  onSelected: (name) => _pieceNameController.text = name,
                ),
              ],
              const SizedBox(height: AppSpacing.space6),

              // Range type selector
              _buildRangeTypeSelector(),

              // Range input based on type
              _buildRangeInput(),

              const SizedBox(height: AppSpacing.space8),

              // N회 반복 설정
              RepeatCountSection(
                repeatCount: _repeatCount,
                onChanged: (value) => setState(() => _repeatCount = value),
              ),
              const SizedBox(height: AppSpacing.space8),

              // 목표 연습시간 설정
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
                              color: Colors.white,
                            ),
                          )
                          : const Text('섹션 추가'),
                ),
              ),
              const SizedBox(height: AppSpacing.space4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRangeTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Notebook × Score: 폼 섹션 라벨은 Playfair sectionTitle
        // 로 통일 (§7.17).
        Text('범위 유형', style: NotebookTypography.sectionTitle),
        const SizedBox(height: AppSpacing.space2),
        SegmentedButton<SectionRangeType>(
          segments: const [
            ButtonSegment(
              value: SectionRangeType.full,
              label: Text('전체'),
              icon: Icon(Icons.select_all),
            ),
            ButtonSegment(
              value: SectionRangeType.line,
              label: Text('줄'),
              icon: Icon(Icons.format_line_spacing),
            ),
            ButtonSegment(
              value: SectionRangeType.measure,
              label: Text('마디'),
              icon: Icon(Icons.straighten),
            ),
          ],
          selected: {_rangeType},
          onSelectionChanged: (selection) {
            setState(() => _rangeType = selection.first);
          },
        ),
      ],
    );
  }

  Widget _buildRangeInput() {
    if (_rangeType == SectionRangeType.full) {
      return const SizedBox.shrink();
    }

    final isMeasure = _rangeType == SectionRangeType.measure;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.space4),
        // Notebook × Score: 폼 섹션 라벨은 Playfair sectionTitle
        // 로 통일. ternary 는 라벨 텍스트만 분기 (§7.17).
        Text(
          isMeasure ? '마디 범위 *' : '줄 범위 *',
          style: NotebookTypography.sectionTitle,
        ),
        const SizedBox(height: AppSpacing.space1),
        Text(
          isMeasure ? '연습할 마디 구간을 선택하세요' : '연습할 줄 구간을 선택하세요 (1~10줄)',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.inkSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.space4),
        RangePickers(
          startValue: isMeasure ? _startMeasure : _startLine,
          endValue: isMeasure ? _endMeasure : _endLine,
          startLabel: isMeasure ? '시작 마디' : '시작 줄',
          endLabel: isMeasure ? '끝 마디' : '끝 줄',
          unit: isMeasure ? '마디' : '줄',
          onStartTap:
              isMeasure
                  ? () => _showMeasurePicker(isStart: true)
                  : () => _showLinePicker(isStart: true),
          onEndTap:
              isMeasure
                  ? () => _showMeasurePicker(isStart: false)
                  : () => _showLinePicker(isStart: false),
        ),
        const SizedBox(height: AppSpacing.space2),

        // Auto-generated section name preview
        RangePreviewBox(rangeText: _getRangePreviewText()),
        const SizedBox(height: AppSpacing.space6),

        // Optional section name field
        TextFormField(
          controller: _sectionNameController,
          decoration: InputDecoration(
            labelText: '섹션 별칭 (선택)',
            hintText: '예: 도입부, 주제 A, 코다',
            helperText: '비워두면 "${_getRangePreviewText()}"로 표시됩니다',
            prefixIcon: const Icon(Icons.label_outline),
          ),
          textInputAction: TextInputAction.done,
        ),
      ],
    );
  }
}
