import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../providers/practice_repertoire/practice_repertoire_crud_provider.dart';

/// Screen for adding a new practice section with measure range selection
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

  // Measure range (1-100)
  int _startMeasure = 1;
  int _endMeasure = 4;

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
  void dispose() {
    _pieceNameController.dispose();
    _sectionNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate measure range
    if (_startMeasure > _endMeasure) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('시작 마디가 끝 마디보다 클 수 없습니다'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(sectionCrudProvider.notifier).createSection(
            repertoireId: widget.repertoireId,
            pieceName: _pieceNameController.text.trim(),
            startMeasure: _startMeasure,
            endMeasure: _endMeasure,
            sectionName: _sectionNameController.text.trim().isEmpty
                ? null
                : _sectionNameController.text.trim(),
          );

      // Invalidate repertoires to refresh the list
      ref.invalidate(studentRepertoiresProvider(widget.studentId));

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
      builder: (context) => _MeasurePickerSheet(
        title: isStart ? '시작 마디' : '끝 마디',
        initialValue: initialValue,
        onSelected: (value) {
          setState(() {
            if (isStart) {
              _startMeasure = value;
              // Auto-adjust end measure if needed
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

              // Measure range section
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

              // Measure pickers
              Row(
                children: [
                  // Start measure picker
                  Expanded(
                    child: _MeasurePickerButton(
                      label: '시작 마디',
                      value: _startMeasure,
                      onTap: () => _showMeasurePicker(isStart: true),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space4),
                  // Separator
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
                  // End measure picker
                  Expanded(
                    child: _MeasurePickerButton(
                      label: '끝 마디',
                      value: _endMeasure,
                      onTap: () => _showMeasurePicker(isStart: false),
                    ),
                  ),
                ],
              ),

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
                      '섹션 이름: $_startMeasure~$_endMeasure마디',
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
                  labelText: '섹션 이름 (선택)',
                  hintText: '예: 도입부, 주제 A, 코다',
                  helperText: '비워두면 "$_startMeasure~$_endMeasure마디"로 표시됩니다',
                  prefixIcon: const Icon(Icons.label_outline),
                ),
                textInputAction: TextInputAction.done,
              ),

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
            ],
          ),
        ),
      ),
    );
  }
}

/// Button that shows the current measure value and opens the picker
class _MeasurePickerButton extends StatelessWidget {
  final String label;
  final int value;
  final VoidCallback onTap;

  const _MeasurePickerButton({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space4,
          vertical: AppSpacing.space3,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderLight),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: AppSpacing.space1),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$value',
                  style: AppTypography.headingLarge.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '마디',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet with iOS-style wheel picker for measure selection
class _MeasurePickerSheet extends StatefulWidget {
  final String title;
  final int initialValue;
  final ValueChanged<int> onSelected;

  const _MeasurePickerSheet({
    required this.title,
    required this.initialValue,
    required this.onSelected,
  });

  @override
  State<_MeasurePickerSheet> createState() => _MeasurePickerSheetState();
}

class _MeasurePickerSheetState extends State<_MeasurePickerSheet> {
  late int _selectedValue;
  late FixedExtentScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.initialValue;
    _scrollController = FixedExtentScrollController(
      initialItem: _selectedValue - 1, // 0-indexed
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 350,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLarge),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space4,
              vertical: AppSpacing.space3,
            ),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.borderLight),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('취소'),
                ),
                Text(
                  widget.title,
                  style: AppTypography.headingSmall,
                ),
                TextButton(
                  onPressed: () {
                    widget.onSelected(_selectedValue);
                    Navigator.of(context).pop();
                  },
                  child: const Text('확인'),
                ),
              ],
            ),
          ),

          // Picker
          Expanded(
            child: CupertinoPicker(
              scrollController: _scrollController,
              itemExtent: 50,
              onSelectedItemChanged: (index) {
                setState(() {
                  _selectedValue = index + 1; // 1-indexed
                });
              },
              children: List.generate(
                100,
                (index) => Center(
                  child: Text(
                    '${index + 1} 마디',
                    style: AppTypography.headingMedium,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
