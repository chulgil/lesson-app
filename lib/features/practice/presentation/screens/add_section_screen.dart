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
import '../widgets/section_form/range_picker_button.dart';
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
  bool _isLoading = false;

  // Range type selection (default: 전체)
  SectionRangeType _rangeType = SectionRangeType.full;

  // Measure range (1-100)
  int _startMeasure = 1;
  int _endMeasure = 4;

  // Line range (1-10)
  int _startLine = 1;
  int _endLine = 2;

  // Active period (within repertoire dates)
  DateTime? _startDate;
  DateTime? _endDate;

  // Repeat settings (isRepeat is derived from endDate: null = repeat)
  int? _repeatCount; // null = 없음, 2~10

  // Target practice time in minutes (null = no target)
  int? _targetPracticeMinutes;

  // Repertoire date constraints
  DateTime? _repertoireStartDate;
  DateTime? _repertoireEndDate;

  // Common piece suggestions based on repertoire
  final List<String> _pieceSuggestions = [
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
    _loadRepertoireDates();
  }

  Future<void> _loadRepertoireDates() async {
    final repertoire =
        await ref.read(repertoireProvider(widget.repertoireId).future);
    if (repertoire != null && mounted) {
      setState(() {
        _repertoireStartDate = repertoire.startDate;
        _repertoireEndDate = repertoire.endDate;
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
    // Prevent duplicate submissions
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    // Validate range based on type
    if (_rangeType == SectionRangeType.measure) {
      if (_startMeasure > _endMeasure) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('시작 마디가 끝 마디보다 클 수 없습니다'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    } else {
      if (_startLine > _endLine) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('시작 줄이 끝 줄보다 클 수 없습니다'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    // Validate date range if set
    if (_startDate != null && _endDate != null) {
      if (_startDate!.isAfter(_endDate!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('시작일이 종료일보다 늦을 수 없습니다'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    // Check for duplicate section (same name + range)
    final repertoire =
        await ref.read(repertoireProvider(widget.repertoireId).future);
    if (repertoire != null) {
      final pieceName = _pieceNameController.text.trim();
      final isDuplicate = repertoire.sections.any((section) {
        if (section.pieceName != pieceName) return false;

        // Check range based on type
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

      if (isDuplicate) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('동일한 곡명과 범위의 섹션이 이미 존재합니다'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(sectionCrudProvider.notifier).createSection(
            repertoireId: widget.repertoireId,
            pieceName: _pieceNameController.text.trim(),
            rangeType: _rangeType,
            startMeasure:
                _rangeType == SectionRangeType.measure ? _startMeasure : 1,
            endMeasure:
                _rangeType == SectionRangeType.measure ? _endMeasure : 1,
            startLine:
                _rangeType == SectionRangeType.line ? _startLine : null,
            endLine: _rangeType == SectionRangeType.line ? _endLine : null,
            sectionName: _sectionNameController.text.trim().isEmpty
                ? null
                : _sectionNameController.text.trim(),
            isRepeat: _endDate == null, // 종료일 없으면 매일 반복
            repeatCount: _repeatCount,
            startDate: _startDate,
            endDate: _endDate,
            targetPracticeSeconds: _targetPracticeMinutes != null
                ? _targetPracticeMinutes! * 60
                : null,
          );

      // Invalidate repertoires to refresh the list
      ref.invalidate(studentRepertoiresProvider(widget.studentId));
      // Also invalidate date-based provider for practice tab
      final today = DateTime.now();
      ref.invalidate(repertoiresForDateProvider(
        RepertoiresForDateParams(studentId: widget.studentId, date: today),
      ));

      if (mounted) {
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('섹션 추가에 실패했습니다: $e'),
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

  void _showMeasurePicker({required bool isStart}) {
    final initialValue = isStart ? _startMeasure : _endMeasure;

    showModalBottomSheet(
      context: context,
      builder: (context) => RangePickerSheet(
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
      builder: (context) => RangePickerSheet(
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

  Future<void> _showDatePicker({required bool isStart}) async {
    final now = DateTime.now();
    final firstDate = _repertoireStartDate ?? now;
    final lastDate =
        _repertoireEndDate ?? now.add(const Duration(days: 365 * 2));

    final initialDate = isStart
        ? (_startDate ?? firstDate)
        : (_endDate ?? _startDate ?? firstDate);

    final picked = await AppDatePicker.show(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: isStart ? '시작일 선택' : '종료일 선택',
    );

    if (picked != null && mounted) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          // Auto-adjust end date if needed
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = picked;
          }
        } else {
          _endDate = picked;
        }
      });
    }
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('섹션 추가'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ========================================
              // 📋 기본 정보 섹션
              // ========================================
              _buildSectionHeader(
                icon: '📋',
                title: '기본 정보',
                subtitle: '곡명, 범위, 별칭 설정',
              ),
              const SizedBox(height: AppSpacing.space4),

              // Piece name field
              TextFormField(
                controller: _pieceNameController,
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

              const SizedBox(height: AppSpacing.space3),

              // Quick piece selection
              Wrap(
                spacing: AppSpacing.space2,
                runSpacing: AppSpacing.space1,
                children: _pieceSuggestions.take(8).map((name) {
                  return ActionChip(
                    label: Text(name, style: const TextStyle(fontSize: 12)),
                    onPressed: () => _pieceNameController.text = name,
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),

              const SizedBox(height: AppSpacing.space6),

              // ========================================
              // 📅 연습 기간 섹션 (공통 위젯 사용)
              // ========================================
              DateRangeSection(
                startDate: _startDate,
                endDate: _endDate,
                onStartDateTap: () => _showDatePicker(isStart: true),
                onEndDateTap: () => _showDatePicker(isStart: false),
                onEndDateClear: () => setState(() => _endDate = null),
                startDatePlaceholder: '레퍼토리 시작일 사용',
                endDatePlaceholder: '설정 안함 (매일 반복)',
                showHintMessage: true,
              ),

              const SizedBox(height: AppSpacing.space6),

              // Range type selector (전체/줄/마디)
              Text(
                '범위 유형',
                style: AppTypography.headingSmall,
              ),
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
                  setState(() {
                    _rangeType = selection.first;
                  });
                },
              ),

              // Range input based on type (hidden when 'full' is selected)
              if (_rangeType == SectionRangeType.measure) ...[
                const SizedBox(height: AppSpacing.space4),
                Text(
                  '마디 범위 *',
                  style: AppTypography.headingSmall,
                ),
                const SizedBox(height: AppSpacing.space1),
                Text(
                  '연습할 마디 구간을 선택하세요',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: AppSpacing.space4),
                _buildRangePickers(
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
                Text(
                  '줄 범위 *',
                  style: AppTypography.headingSmall,
                ),
                const SizedBox(height: AppSpacing.space1),
                Text(
                  '연습할 줄 구간을 선택하세요 (1~10줄)',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: AppSpacing.space4),
                _buildRangePickers(
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
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.space3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppSpacing.space2),
                      Text(
                        '섹션 이름: ${_getRangePreviewText()}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

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

              const SizedBox(height: AppSpacing.space8),

              // ========================================
              // 🐾 N회 반복 설정 (선택)
              // ========================================
              Row(
                children: [
                  const Text('🐾', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: AppSpacing.space2),
                  Text('N회 반복', style: AppTypography.headingSmall),
                  const Spacer(),
                  Text(
                    '선택',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space2),
              Text(
                '하루에 여러 번 연습해야 하는 경우 설정하세요',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: AppSpacing.space3),

              // Repeat count dropdown
              DropdownButtonFormField<int?>(
                value: _repeatCount,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.repeat),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.space4,
                    vertical: AppSpacing.space3,
                  ),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('없음'),
                  ),
                  ...List.generate(
                    9,
                    (index) => DropdownMenuItem(
                      value: index + 2,
                      child: Text('${index + 2}회 🐾'),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _repeatCount = value;
                  });
                },
              ),

              if (_repeatCount != null) ...[
                const SizedBox(height: AppSpacing.space2),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.space3),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusSmall),
                  ),
                  child: Row(
                    children: [
                      const Text('🐾', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: AppSpacing.space2),
                      Expanded(
                        child: Text(
                          '매일 $_repeatCount회 연습을 완료하면 모든 발바닥이 채워집니다',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textPrimaryLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.space8),

              // ========================================
              // ⏱️ 목표 연습시간 설정 (선택)
              // ========================================
              Row(
                children: [
                  const Text('⏱️', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: AppSpacing.space2),
                  Text('목표 연습시간', style: AppTypography.headingSmall),
                  const Spacer(),
                  Text(
                    '선택',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space2),
              Text(
                '이 섹션의 목표 연습시간을 설정하세요',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: AppSpacing.space3),

              // Target practice time dropdown
              DropdownButtonFormField<int?>(
                value: _targetPracticeMinutes,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.timer_outlined),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.space4,
                    vertical: AppSpacing.space3,
                  ),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('설정 안함'),
                  ),
                  ...[5, 10, 15, 20, 30, 45, 60, 90, 120].map(
                    (minutes) => DropdownMenuItem(
                      value: minutes,
                      child: Text(minutes >= 60
                          ? '${minutes ~/ 60}시간${minutes % 60 > 0 ? ' ${minutes % 60}분' : ''}'
                          : '$minutes분'),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _targetPracticeMinutes = value;
                  });
                },
              ),

              if (_targetPracticeMinutes != null) ...[
                const SizedBox(height: AppSpacing.space2),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.space3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppSpacing.space2),
                      Expanded(
                        child: Text(
                          '목표시간 달성 시 진행률이 100%로 표시됩니다',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.space8),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
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

  Widget _buildSectionHeader({
    required String icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space3,
        vertical: AppSpacing.space2,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.headingSmall,
                ),
                Text(
                  subtitle,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRangePickers({
    required int startValue,
    required int endValue,
    required String startLabel,
    required String endLabel,
    required String unit,
    required VoidCallback onStartTap,
    required VoidCallback onEndTap,
  }) {
    return Row(
      children: [
        Expanded(
          child: RangePickerButton(
            label: startLabel,
            value: startValue,
            unit: unit,
            onTap: onStartTap,
          ),
        ),
        const SizedBox(width: AppSpacing.space4),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space3,
            vertical: AppSpacing.space2,
          ),
          child: Text(
            '~',
            style: AppTypography.headingMedium.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.space4),
        Expanded(
          child: RangePickerButton(
            label: endLabel,
            value: endValue,
            unit: unit,
            onTap: onEndTap,
          ),
        ),
      ],
    );
  }
}
