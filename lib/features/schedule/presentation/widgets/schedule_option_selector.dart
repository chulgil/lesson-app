import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/lesson_booking.dart';
import 'schedule_option_card.dart';

/// Type of lesson for option selector
enum ScheduleOptionType {
  /// Single lesson (trial or one-time)
  singleLesson,

  /// Regular weekly lesson
  regularLesson,

  /// Regular weekly 2x lesson
  regularLesson2x,
}

/// A widget for selecting 1-3 schedule options with priority
class ScheduleOptionSelector extends StatefulWidget {
  final ScheduleOptionType type;
  final List<ScheduleOption> initialOptions;
  final int lessonDuration;
  final ValueChanged<List<ScheduleOption>> onOptionsChanged;
  final Future<void> Function(ScheduleOption option, int index)? onEditOption;
  final int maxOptions;
  final int minOptions;

  const ScheduleOptionSelector({
    super.key,
    required this.type,
    this.initialOptions = const [],
    this.lessonDuration = 60,
    required this.onOptionsChanged,
    this.onEditOption,
    this.maxOptions = 3,
    this.minOptions = 1,
  });

  @override
  State<ScheduleOptionSelector> createState() => _ScheduleOptionSelectorState();
}

class _ScheduleOptionSelectorState extends State<ScheduleOptionSelector> {
  late List<ScheduleOption> _options;
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _options = List.from(widget.initialOptions);
  }

  @override
  void didUpdateWidget(ScheduleOptionSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialOptions != oldWidget.initialOptions) {
      _options = List.from(widget.initialOptions);
    }
  }

  void _addOption() {
    if (_options.length >= widget.maxOptions) return;

    final newPriority = _options.length + 1;
    final newOption = ScheduleOption(
      id: _uuid.v4(),
      priority: newPriority,
    );

    setState(() {
      _options.add(newOption);
    });

    // Trigger edit for the new option
    if (widget.onEditOption != null) {
      widget.onEditOption!(newOption, _options.length - 1);
    }

    widget.onOptionsChanged(_options);
  }

  void _removeOption(int index) {
    if (_options.length <= widget.minOptions) return;

    setState(() {
      _options.removeAt(index);
      // Reorder priorities
      for (int i = 0; i < _options.length; i++) {
        _options[i] = _options[i].copyWith(priority: i + 1);
      }
    });

    widget.onOptionsChanged(_options);
  }

  void _editOption(int index) {
    if (widget.onEditOption != null) {
      widget.onEditOption!(_options[index], index);
    }
  }

  void updateOption(int index, ScheduleOption updatedOption) {
    if (index < 0 || index >= _options.length) return;

    setState(() {
      _options[index] = updatedOption;
    });

    widget.onOptionsChanged(_options);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Text(
              '희망 일정 선택',
              style: AppTypography.headingSmall,
            ),
            const SizedBox(width: AppSpacing.space2),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space2,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
              ),
              child: Text(
                '최대 ${widget.maxOptions}개',
                style: AppTypography.caption.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.space3),

        // Options list
        ...List.generate(_options.length, (index) {
          final option = _options[index];
          return Padding(
            padding: EdgeInsets.only(
              bottom: index < _options.length - 1
                  ? AppSpacing.space3
                  : AppSpacing.space2,
            ),
            child: ScheduleOptionCard(
              option: option,
              mode: ScheduleOptionCardMode.student,
              onTap: () => _editOption(index),
              onEdit: () => _editOption(index),
              onDelete: _options.length > widget.minOptions
                  ? () => _removeOption(index)
                  : null,
            ),
          );
        }),

        // Add option button
        if (_options.length < widget.maxOptions)
          AddScheduleOptionButton(
            optionNumber: _options.length + 1,
            onTap: _addOption,
          ),

        const SizedBox(height: AppSpacing.space3),

        // Tip
        Container(
          padding: const EdgeInsets.all(AppSpacing.space3),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          ),
          child: Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 20,
                color: AppColors.info,
              ),
              const SizedBox(width: AppSpacing.space2),
              Expanded(
                child: Text(
                  '여러 일정을 제안하면 빠르게 확정될 확률이 높아요',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.info,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A simplified selector that returns the options directly
class SimpleScheduleOptionSelector extends StatelessWidget {
  final List<ScheduleOption> options;
  final ValueChanged<List<ScheduleOption>> onOptionsChanged;
  final Function(int index) onEditOption;
  final int maxOptions;
  final int minOptions;

  const SimpleScheduleOptionSelector({
    super.key,
    required this.options,
    required this.onOptionsChanged,
    required this.onEditOption,
    this.maxOptions = 3,
    this.minOptions = 1,
  });

  void _removeOption(int index) {
    if (options.length <= minOptions) return;

    final newOptions = List<ScheduleOption>.from(options);
    newOptions.removeAt(index);

    // Reorder priorities
    for (int i = 0; i < newOptions.length; i++) {
      newOptions[i] = newOptions[i].copyWith(priority: i + 1);
    }

    onOptionsChanged(newOptions);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Text(
              '희망 일정 선택',
              style: AppTypography.headingSmall,
            ),
            const SizedBox(width: AppSpacing.space2),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space2,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
              ),
              child: Text(
                '최대 $maxOptions개',
                style: AppTypography.caption.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.space3),

        // Options list
        ...List.generate(options.length, (index) {
          final option = options[index];
          return Padding(
            padding: EdgeInsets.only(
              bottom: index < options.length - 1
                  ? AppSpacing.space3
                  : AppSpacing.space2,
            ),
            child: ScheduleOptionCard(
              option: option,
              mode: ScheduleOptionCardMode.student,
              onTap: () => onEditOption(index),
              onEdit: () => onEditOption(index),
              onDelete: options.length > minOptions
                  ? () => _removeOption(index)
                  : null,
            ),
          );
        }),

        // Add option button
        if (options.length < maxOptions)
          AddScheduleOptionButton(
            optionNumber: options.length + 1,
            onTap: () => onEditOption(options.length),
          ),

        const SizedBox(height: AppSpacing.space3),

        // Tip
        Container(
          padding: const EdgeInsets.all(AppSpacing.space3),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          ),
          child: Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 20,
                color: AppColors.info,
              ),
              const SizedBox(width: AppSpacing.space2),
              Expanded(
                child: Text(
                  '여러 일정을 제안하면 빠르게 확정될 확률이 높아요',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.info,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
