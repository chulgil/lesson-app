// Practice stats editor widget - reusable component for editing practice count and time

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../models/practice_repertoire.dart';

/// Reusable widget for displaying and editing practice count and time
/// Tapping on count or time opens a dialog for editing
class PracticeStatsEditor extends StatelessWidget {
  final PracticeSection section;
  final void Function(int count, int seconds) onUpdate;

  const PracticeStatsEditor({
    super.key,
    required this.section,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '연습 기록',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.space3),
            Row(
              children: [
                // Practice count
                Expanded(
                  child: _StatTile(
                    icon: Icons.repeat,
                    label: '연습 횟수',
                    value: '${section.practiceCount}회',
                    color: AppColors.primary,
                    onTap: () => _showCountEditor(context),
                  ),
                ),
                const SizedBox(width: AppSpacing.space3),
                // Total practice time
                Expanded(
                  child: _StatTile(
                    icon: Icons.timer,
                    label: '총 연습 시간',
                    value: section.formattedTotalTime,
                    color: AppColors.info,
                    onTap: () => _showTimeEditor(context),
                  ),
                ),
              ],
            ),
            // Target progress hint
            if (section.hasTargetPracticeTime) ...[
              const SizedBox(height: AppSpacing.space2),
              Text(
                '1회 목표: ${section.formattedTargetTime}',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textTertiaryLight,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showCountEditor(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _CountEditorSheet(
        currentCount: section.practiceCount,
        targetSeconds: section.targetPracticeSeconds,
        onConfirm: (count) {
          // Calculate time based on target if available
          int seconds = section.totalPracticeSeconds;
          if (section.hasTargetPracticeTime && count > section.practiceCount) {
            final addedCount = count - section.practiceCount;
            seconds += section.targetPracticeSeconds! * addedCount;
          }
          onUpdate(count, seconds);
        },
      ),
    );
  }

  void _showTimeEditor(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _TimeEditorSheet(
        currentSeconds: section.totalPracticeSeconds,
        onConfirm: (seconds) {
          onUpdate(section.practiceCount, seconds);
        },
      ),
    );
  }
}

/// Individual stat tile widget
class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback onTap;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 14, color: color),
                  const SizedBox(width: AppSpacing.space1),
                  Expanded(
                    child: Text(
                      label,
                      style: AppTypography.caption.copyWith(color: color),
                    ),
                  ),
                  Icon(
                    Icons.edit,
                    size: 12,
                    color: color.withValues(alpha: 0.5),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space1),
              Text(
                value,
                style: AppTypography.headingSmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet for editing practice count
class _CountEditorSheet extends StatefulWidget {
  final int currentCount;
  final int? targetSeconds;
  final void Function(int count) onConfirm;

  const _CountEditorSheet({
    required this.currentCount,
    this.targetSeconds,
    required this.onConfirm,
  });

  @override
  State<_CountEditorSheet> createState() => _CountEditorSheetState();
}

class _CountEditorSheetState extends State<_CountEditorSheet> {
  late int _count;

  @override
  void initState() {
    super.initState();
    _count = widget.currentCount;
  }

  @override
  Widget build(BuildContext context) {
    final addedCount = _count - widget.currentCount;
    final addedMinutes = widget.targetSeconds != null && addedCount > 0
        ? (widget.targetSeconds! * addedCount / 60).round()
        : 0;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.space4,
        right: AppSpacing.space4,
        top: AppSpacing.space4,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.space4,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSpacing.space4),

          Text(
            '연습 횟수 설정',
            style: AppTypography.headingSmall,
          ),
          const SizedBox(height: AppSpacing.space4),

          // Count selector
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filled(
                onPressed: _count > 0 ? () => setState(() => _count--) : null,
                icon: const Icon(Icons.remove),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  foregroundColor: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.space4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space6,
                  vertical: AppSpacing.space3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                ),
                child: Text(
                  '$_count회',
                  style: AppTypography.displayMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.space4),
              IconButton.filled(
                onPressed: () => setState(() => _count++),
                icon: const Icon(Icons.add),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  foregroundColor: AppColors.primary,
                ),
              ),
            ],
          ),

          // Added time hint
          if (widget.targetSeconds != null && addedCount > 0) ...[
            const SizedBox(height: AppSpacing.space3),
            Text(
              '+$addedCount회 → +$addedMinutes분 추가',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.success,
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.space4),

          // Confirm button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                widget.onConfirm(_count);
                Navigator.pop(context);
              },
              child: const Text('확인'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet for editing practice time
class _TimeEditorSheet extends StatefulWidget {
  final int currentSeconds;
  final void Function(int seconds) onConfirm;

  const _TimeEditorSheet({
    required this.currentSeconds,
    required this.onConfirm,
  });

  @override
  State<_TimeEditorSheet> createState() => _TimeEditorSheetState();
}

class _TimeEditorSheetState extends State<_TimeEditorSheet> {
  late TextEditingController _hoursController;
  late TextEditingController _minutesController;

  @override
  void initState() {
    super.initState();
    final hours = widget.currentSeconds ~/ 3600;
    final minutes = (widget.currentSeconds % 3600) ~/ 60;
    _hoursController = TextEditingController(text: hours.toString());
    _minutesController = TextEditingController(text: minutes.toString());
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _minutesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.space4,
        right: AppSpacing.space4,
        top: AppSpacing.space4,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.space4,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSpacing.space4),

          Text(
            '총 연습 시간 설정',
            style: AppTypography.headingSmall,
          ),
          const SizedBox(height: AppSpacing.space4),

          // Time input
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Hours
              SizedBox(
                width: 80,
                child: TextField(
                  controller: _hoursController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.center,
                  style: AppTypography.headingMedium,
                  decoration: InputDecoration(
                    suffixText: '시간',
                    suffixStyle: AppTypography.bodyMedium,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusSmall),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              // Minutes
              SizedBox(
                width: 80,
                child: TextField(
                  controller: _minutesController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.center,
                  style: AppTypography.headingMedium,
                  decoration: InputDecoration(
                    suffixText: '분',
                    suffixStyle: AppTypography.bodyMedium,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusSmall),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.space4),

          // Confirm button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                final hours = int.tryParse(_hoursController.text) ?? 0;
                final minutes = int.tryParse(_minutesController.text) ?? 0;
                final seconds = hours * 3600 + minutes * 60;
                widget.onConfirm(seconds);
                Navigator.pop(context);
              },
              child: const Text('확인'),
            ),
          ),
        ],
      ),
    );
  }
}
