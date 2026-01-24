import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/teacher_settings.dart';
import '../../../../models/time_slot.dart';
import '../../../../providers/providers.dart';
import '../widgets/lesson_time_settings_widgets.dart';

/// Screen for configuring lesson time settings
class LessonTimeSettingsScreen extends ConsumerWidget {
  const LessonTimeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(teacherSettingsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('레슨 시간 설정'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: settingsAsync.when(
        data: (settings) => _LessonTimeSettingsContent(settings: settings),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: AppSpacing.space4),
              Text('오류가 발생했습니다: $error'),
              const SizedBox(height: AppSpacing.space4),
              FilledButton(
                onPressed: () =>
                    ref.read(teacherSettingsNotifierProvider.notifier).refresh(),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LessonTimeSettingsContent extends ConsumerWidget {
  final TeacherSettings settings;

  const _LessonTimeSettingsContent({required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Default lesson duration section
          _buildDefaultDurationSection(context, ref),

          const SizedBox(height: AppSpacing.space6),

          // Available time slots section
          _buildTimeSlotsSection(context, ref),
        ],
      ),
    );
  }

  Widget _buildDefaultDurationSection(BuildContext context, WidgetRef ref) {
    final allDurations = settings.allConfiguredDurations;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LessonTimeSettingsSectionTitle(
          title: '레슨 시간 옵션',
          onAddPressed: () => showAddCustomDurationDialog(
            context: context,
            ref: ref,
            existingDurations: settings.allLessonDurations,
            onSave: (duration) async {
              ref
                  .read(teacherSettingsNotifierProvider.notifier)
                  .addCustomDuration(duration);
            },
          ),
        ),
        const SizedBox(height: AppSpacing.space2),
        Text(
          '사용할 레슨 시간을 선택하세요. 체크된 시간이 기본값입니다.',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: AppSpacing.space4),

        // Duration list with switches
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceSecondaryLight,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          ),
          child: Column(
            children: allDurations.asMap().entries.map((entry) {
              final index = entry.key;
              final duration = entry.value;
              final isDefault = settings.defaultLessonDuration == duration;
              final isDisabled = settings.isDurationDisabled(duration);
              final isCustom = settings.customLessonDurations.contains(duration);
              final isOnlyActive =
                  settings.allLessonDurations.length == 1 && !isDisabled;

              return Column(
                children: [
                  DurationOptionItem(
                    duration: duration,
                    isDefault: isDefault,
                    isDisabled: isDisabled,
                    isCustom: isCustom,
                    isOnlyActive: isOnlyActive,
                    onTap: () => _updateDefaultDuration(ref, duration),
                    onDelete: isCustom
                        ? () => showDeleteDurationDialog(
                              context: context,
                              duration: duration,
                              onConfirm: () {
                                ref
                                    .read(teacherSettingsNotifierProvider.notifier)
                                    .removeCustomDuration(duration);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        '${LessonDurations.format(duration)} 삭제됨'),
                                  ),
                                );
                              },
                            )
                        : null,
                    onToggle: (value) => _toggleDuration(ref, duration, value),
                  ),
                  if (index < allDurations.length - 1)
                    const Divider(height: 1, indent: 16, endIndent: 16),
                ],
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: AppSpacing.space2),
        Text(
          '최소 1개의 시간은 활성화 상태여야 합니다',
          style: AppTypography.caption.copyWith(
            color: AppColors.textTertiaryLight,
          ),
        ),
      ],
    );
  }

  void _toggleDuration(WidgetRef ref, int duration, bool isActive) {
    ref
        .read(teacherSettingsNotifierProvider.notifier)
        .toggleDuration(duration, isActive);
  }

  Widget _buildTimeSlotsSection(BuildContext context, WidgetRef ref) {
    final slotsByDay = <int, List<TimeSlot>>{};
    for (final slot in settings.availableSlots) {
      slotsByDay.putIfAbsent(slot.dayOfWeek, () => []).add(slot);
    }

    // Sort slots within each day
    for (final slots in slotsByDay.values) {
      slots.sort((a, b) =>
          a.startTime.hour * 60 +
          a.startTime.minute -
          (b.startTime.hour * 60 + b.startTime.minute));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LessonTimeSettingsSectionTitle(
          title: '운영 시간대',
          onAddPressed: () => showAddTimeSlotDialog(
            context: context,
            onSave: (slot) {
              ref
                  .read(teacherSettingsNotifierProvider.notifier)
                  .updateTimeSlot(slot);
            },
          ),
        ),
        const SizedBox(height: AppSpacing.space2),
        Text(
          '레슨 가능한 요일과 시간대를 설정하세요',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: AppSpacing.space4),

        // Time slots by day
        if (settings.availableSlots.isEmpty)
          const TimeSlotsEmptyState()
        else
          ...List.generate(7, (index) {
            final dayOfWeek = index + 1;
            final slots = slotsByDay[dayOfWeek] ?? [];
            return DaySectionCard(
              dayOfWeek: dayOfWeek,
              slots: slots,
              onToggleSlot: (slot) => _toggleTimeSlot(ref, slot.id, !slot.isActive),
              onEditSlot: (slot) => showEditTimeSlotDialog(
                context: context,
                slot: slot,
                onSave: (updatedSlot) {
                  ref
                      .read(teacherSettingsNotifierProvider.notifier)
                      .updateTimeSlot(updatedSlot);
                },
              ),
              onAddSlot: () => showAddTimeSlotDialog(
                context: context,
                preselectedDay: dayOfWeek,
                onSave: (slot) {
                  ref
                      .read(teacherSettingsNotifierProvider.notifier)
                      .updateTimeSlot(slot);
                },
              ),
            );
          }),
      ],
    );
  }

  void _updateDefaultDuration(WidgetRef ref, int duration) {
    ref
        .read(teacherSettingsNotifierProvider.notifier)
        .updateDefaultDuration(duration);
  }

  void _toggleTimeSlot(WidgetRef ref, String slotId, bool isActive) {
    ref
        .read(teacherSettingsNotifierProvider.notifier)
        .toggleTimeSlot(slotId, isActive);
  }
}
