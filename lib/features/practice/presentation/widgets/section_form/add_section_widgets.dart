import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import 'range_picker_button.dart';

/// Section header widget with emoji icon, title and subtitle
class SectionHeader extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;

  const SectionHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
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
}

/// Row with start and end range pickers
class RangePickers extends StatelessWidget {
  final int startValue;
  final int endValue;
  final String startLabel;
  final String endLabel;
  final String unit;
  final VoidCallback onStartTap;
  final VoidCallback onEndTap;

  const RangePickers({
    super.key,
    required this.startValue,
    required this.endValue,
    required this.startLabel,
    required this.endLabel,
    required this.unit,
    required this.onStartTap,
    required this.onEndTap,
  });

  @override
  Widget build(BuildContext context) {
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

/// Section header row with emoji, title and optional label
class SettingSectionHeader extends StatelessWidget {
  final String icon;
  final String title;
  final String? trailingLabel;
  final String? description;

  const SettingSectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.trailingLabel,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: AppSpacing.space2),
            Text(title, style: AppTypography.headingSmall),
            const Spacer(),
            if (trailingLabel != null)
              Text(
                trailingLabel!,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
          ],
        ),
        if (description != null) ...[
          const SizedBox(height: AppSpacing.space2),
          Text(
            description!,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ],
    );
  }
}

/// N회 반복 설정 섹션
class RepeatCountSection extends StatelessWidget {
  final int? repeatCount;
  final ValueChanged<int?> onChanged;

  const RepeatCountSection({
    super.key,
    required this.repeatCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingSectionHeader(
          icon: '🐾',
          title: 'N회 반복',
          trailingLabel: '선택',
          description: '하루에 여러 번 연습해야 하는 경우 설정하세요',
        ),
        const SizedBox(height: AppSpacing.space3),

        // Repeat count dropdown
        DropdownButtonFormField<int?>(
          value: repeatCount,
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
          onChanged: onChanged,
        ),

        if (repeatCount != null) ...[
          const SizedBox(height: AppSpacing.space2),
          _RepeatCountHint(repeatCount: repeatCount!),
        ],
      ],
    );
  }
}

/// Hint message for repeat count
class _RepeatCountHint extends StatelessWidget {
  final int repeatCount;

  const _RepeatCountHint({required this.repeatCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
      ),
      child: Row(
        children: [
          const Text('🐾', style: TextStyle(fontSize: 18)),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: Text(
              '매일 $repeatCount회 연습을 완료하면 모든 발바닥이 채워집니다',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textPrimaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 목표 연습시간 설정 섹션
class TargetTimeSection extends StatelessWidget {
  final int? targetMinutes;
  final ValueChanged<int?> onChanged;

  const TargetTimeSection({
    super.key,
    required this.targetMinutes,
    required this.onChanged,
  });

  static const List<int> _presetMinutes = [5, 10, 15, 20, 30, 45, 60, 90, 120];

  String _formatMinutes(int minutes) {
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return mins > 0 ? '$hours시간 $mins분' : '$hours시간';
    }
    return '$minutes분';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingSectionHeader(
          icon: '⏱️',
          title: '목표 연습시간',
          trailingLabel: '선택',
          description: '이 섹션의 목표 연습시간을 설정하세요',
        ),
        const SizedBox(height: AppSpacing.space3),

        // Target time dropdown
        DropdownButtonFormField<int?>(
          value: targetMinutes,
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
            ..._presetMinutes.map(
              (minutes) => DropdownMenuItem(
                value: minutes,
                child: Text(_formatMinutes(minutes)),
              ),
            ),
          ],
          onChanged: onChanged,
        ),

        if (targetMinutes != null) ...[
          const SizedBox(height: AppSpacing.space2),
          const _TargetTimeHint(),
        ],
      ],
    );
  }
}

/// Hint message for target time
class _TargetTimeHint extends StatelessWidget {
  const _TargetTimeHint();

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

/// Range preview info box
class RangePreviewBox extends StatelessWidget {
  final String rangeText;

  const RangePreviewBox({
    super.key,
    required this.rangeText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            '섹션 이름: $rangeText',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Piece suggestions chips
class PieceSuggestionChips extends StatelessWidget {
  final List<String> suggestions;
  final ValueChanged<String> onSelected;
  final int maxItems;

  const PieceSuggestionChips({
    super.key,
    required this.suggestions,
    required this.onSelected,
    this.maxItems = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.space2,
      runSpacing: AppSpacing.space1,
      children: suggestions.take(maxItems).map((name) {
        return ActionChip(
          label: Text(name, style: const TextStyle(fontSize: 12)),
          onPressed: () => onSelected(name),
          visualDensity: VisualDensity.compact,
        );
      }).toList(),
    );
  }
}
