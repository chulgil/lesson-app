// Practice reminder settings bottom sheet.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
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
        color: AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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

              // Title
              Text(
                '연습 리마인더',
                style: AppTypography.headingMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: AppSpacing.space2),

              Text(
                '설정한 시간에 연습 알림을 받습니다',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),

              const SizedBox(height: AppSpacing.space6),

              // Enable/Disable toggle
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space4,
                  vertical: AppSpacing.space3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.alarm,
                      color:
                          settings.isEnabled
                              ? AppColors.primary
                              : AppColors.textTertiaryLight,
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
                      activeColor: AppColors.primary,
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
                  color: AppColors.textSecondaryLight,
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
                    color: AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(
                      AppSpacing.radiusMedium,
                    ),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        color:
                            settings.isEnabled
                                ? AppColors.primary
                                : AppColors.textTertiaryLight,
                      ),
                      const SizedBox(width: AppSpacing.space3),
                      Text(
                        settings.formattedTime,
                        style: AppTypography.headingMedium.copyWith(
                          color:
                              settings.isEnabled
                                  ? AppColors.textPrimaryLight
                                  : AppColors.textTertiaryLight,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.edit_outlined,
                        size: 20,
                        color:
                            settings.isEnabled
                                ? AppColors.textSecondaryLight
                                : AppColors.textTertiaryLight,
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
                  color: AppColors.textSecondaryLight,
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
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color:
                            isSelected && settings.isEnabled
                                ? AppColors.primary
                                : AppColors.backgroundLight,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color:
                              isSelected && settings.isEnabled
                                  ? AppColors.primary
                                  : AppColors.borderLight,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          days[index],
                          style: AppTypography.bodySmall.copyWith(
                            color:
                                isSelected && settings.isEnabled
                                    ? Colors.white
                                    : settings.isEnabled
                                    ? AppColors.textSecondaryLight
                                    : AppColors.textTertiaryLight,
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
                  color: AppColors.info.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: AppColors.info),
                    const SizedBox(width: AppSpacing.space2),
                    Expanded(
                      child: Text(
                        '푸시 알림은 준비 중입니다. 설정은 저장되며 기능 활성화 시 자동 적용됩니다.',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.info,
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
            colorScheme: ColorScheme.light(primary: AppColors.primary),
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
