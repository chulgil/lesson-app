// Practice reminder settings bottom sheet.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';
import '../providers/practice_reminder_provider.dart';

/// Bottom sheet for configuring practice reminder time and days.
class PracticeReminderSheet extends ConsumerWidget {
  const PracticeReminderSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PracticeReminderSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(practiceReminderProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.zero,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              const Center(child: BottomSheetHandle(margin: EdgeInsets.zero)),

              const SizedBox(height: AppSpacing.space5),

              // Title — Notebook × Score: 시트 헤더는 Playfair sectionTitle (§7.87-f / §7.27).
              Text('연습 리마인더', style: NotebookTypography.sectionTitle),

              const SizedBox(height: AppSpacing.space2),

              Text(
                '설정한 시간에 연습 알림을 받습니다',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),

              const SizedBox(height: AppSpacing.space6),

              // Enable/Disable toggle
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space4,
                  vertical: AppSpacing.space3,
                ),
                decoration: BoxDecoration(color: AppColors.paperDark),
                child: Row(
                  children: [
                    Icon(
                      Icons.alarm,
                      color:
                          settings.isEnabled
                              ? AppColors.paperAccent
                              : AppColors.inkTertiary,
                    ),
                    const SizedBox(width: AppSpacing.space3),
                    Expanded(
                      child: Text(
                        '리마인더 활성화',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Switch(
                      value: settings.isEnabled,
                      onChanged:
                          (value) => ref
                              .read(practiceReminderProvider.notifier)
                              .toggleEnabled(value),
                      activeThumbColor: AppColors.paperAccent,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.space5),

              // Time selector
              Text(
                '알림 시간',
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.inkSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.space2),
              GestureDetector(
                onTap:
                    settings.isEnabled
                        ? () => _selectTime(
                          context,
                          ref,
                          settings.hour,
                          settings.minute,
                        )
                        : null,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.space4),
                  decoration: BoxDecoration(
                    color: AppColors.paperDark,
                    border: Border.all(color: AppColors.inkQuaternary),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        color:
                            settings.isEnabled
                                ? AppColors.paperAccent
                                : AppColors.inkTertiary,
                      ),
                      const SizedBox(width: AppSpacing.space3),
                      Text(
                        settings.formattedTime,
                        style: AppTypography.headingMedium.copyWith(
                          color:
                              settings.isEnabled
                                  ? AppColors.ink
                                  : AppColors.inkTertiary,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.edit_outlined,
                        size: 20,
                        color:
                            settings.isEnabled
                                ? AppColors.inkSecondary
                                : AppColors.inkTertiary,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.space5),

              // Days selector
              Text(
                '알림 요일',
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.inkSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.space2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(7, (index) {
                  final days = ['월', '화', '수', '목', '금', '토', '일'];
                  final isSelected = settings.selectedDays.contains(index);
                  return GestureDetector(
                    onTap:
                        settings.isEnabled
                            ? () => ref
                                .read(practiceReminderProvider.notifier)
                                .toggleDay(index)
                            : null,
                    // §7.132: round → 사각 day-of-week 셀 (Notebook 메타포).
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color:
                            isSelected && settings.isEnabled
                                ? AppColors.paperAccent
                                : AppColors.paperDark,
                        border: Border.all(
                          color:
                              isSelected && settings.isEnabled
                                  ? AppColors.paperAccent
                                  : AppColors.inkQuaternary,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          days[index],
                          style: AppTypography.bodySmall.copyWith(
                            color:
                                isSelected && settings.isEnabled
                                    ? AppColors.paper
                                    : settings.isEnabled
                                    ? AppColors.inkSecondary
                                    : AppColors.inkTertiary,
                            fontWeight:
                                isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: AppSpacing.space6),

              // Info banner
              Container(
                padding: const EdgeInsets.all(AppSpacing.space3),
                decoration: BoxDecoration(
                  color: AppColors.ink.withValues(alpha: 0.08),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: AppColors.ink),
                    const SizedBox(width: AppSpacing.space2),
                    Expanded(
                      child: Text(
                        '푸시 알림은 준비 중입니다. 설정은 저장되며 기능 활성화 시 자동 적용됩니다.',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.space4),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectTime(
    BuildContext context,
    WidgetRef ref,
    int currentHour,
    int currentMinute,
  ) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: currentHour, minute: currentMinute),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppColors.paperAccent),
          ),
          child: child!,
        );
      },
    );
    if (time != null) {
      ref
          .read(practiceReminderProvider.notifier)
          .setTime(time.hour, time.minute);
    }
  }
}
