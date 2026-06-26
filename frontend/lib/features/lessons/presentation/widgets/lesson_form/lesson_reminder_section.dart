import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/notebook/thin_rule.dart';
import '../../../../../core/theme/app_typography.dart';

/// Reminder settings section
class LessonReminderSection extends StatelessWidget {
  final bool enableReminder;
  final ValueChanged<bool> onReminderChanged;
  final int reminderMinutes;
  final ValueChanged<int> onReminderTimeChanged;

  const LessonReminderSection({
    super.key,
    required this.enableReminder,
    required this.onReminderChanged,
    required this.reminderMinutes,
    required this.onReminderTimeChanged,
  });

  static const List<(int, String)> reminderOptions = [
    (10, '10분 전'),
    (30, '30분 전'),
    (60, '1시간 전'),
    (1440, '하루 전'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Column(
        children: [
          // Toggle reminder
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.paperOk.withValues(alpha: 0.1),
                ),
                child: const Icon(
                  Icons.notifications_active,
                  color: AppColors.paperOk,
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '레슨 알림',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '레슨 시작 전 알림 받기',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.inkSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(value: enableReminder, onChanged: onReminderChanged),
            ],
          ),

          if (enableReminder) ...[
            const SizedBox(height: AppSpacing.space3),
            const ThinRule(),
            const SizedBox(height: AppSpacing.space3),
            Row(
              children: [
                Text(
                  '알림 시간',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                ),
                const SizedBox(width: AppSpacing.space2),
                // 좁은 폭(375)에서 시간 칩이 넘치면 우측 정렬 + 가로 스크롤.
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    child: _ReminderTimeSelector(
                      selectedMinutes: reminderMinutes,
                      onChanged: onReminderTimeChanged,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ReminderTimeSelector extends StatelessWidget {
  final int selectedMinutes;
  final ValueChanged<int> onChanged;

  const _ReminderTimeSelector({
    required this.selectedMinutes,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppColors.paperDark),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children:
            LessonReminderSection.reminderOptions.map((option) {
              final isSelected = selectedMinutes == option.$1;
              return GestureDetector(
                onTap: () => onChanged(option.$1),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isSelected ? AppColors.paperAccent : Colors.transparent,
                  ),
                  child: Text(
                    option.$2,
                    style: AppTypography.caption.copyWith(
                      // Notebook × Score §7.50: selected chip foreground = paper (Vermillion bg).
                      color:
                          isSelected ? AppColors.paper : AppColors.inkSecondary,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }
}
