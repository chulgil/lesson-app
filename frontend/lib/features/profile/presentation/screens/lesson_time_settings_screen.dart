import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../features/profile/domain/entities/teacher_settings.dart';
import '../../../../core/booking/entities/time_slot.dart';
import '../../../settings/presentation/providers/teacher_settings_provider.dart';
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
        error:
            (_, __) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppColors.paperAccent,
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  const Text('오류가 발생했습니다.'),
                  const SizedBox(height: AppSpacing.space4),
                  FilledButton(
                    onPressed:
                        () =>
                            ref
                                .read(teacherSettingsNotifierProvider.notifier)
                                .refresh(),
                    child: const Text(AppStrings.retry),
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

          // Booking settings section
          _buildBookingSettingsSection(context, ref),

          const SizedBox(height: AppSpacing.space6),

          // Available time slots section
          _buildTimeSlotsSection(context, ref),

          const SizedBox(height: AppSpacing.space6),

          // Booking guidance message
          _buildGuidanceMessageSection(context, ref),

          const SizedBox(height: AppSpacing.space6),

          // Trial lesson free toggle
          _buildTrialLessonSection(context, ref),

          const SizedBox(height: AppSpacing.space6),

          // Lesson price table
          _buildPriceTableSection(context, ref),

          const SizedBox(height: AppSpacing.space6),
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
          onAddPressed:
              () => showAddCustomDurationDialog(
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
            color: AppColors.inkSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.space4),

        // Duration list with switches
        Container(
          decoration: BoxDecoration(
            color: AppColors.paperDark,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          ),
          child: RadioGroup<int>(
            groupValue: settings.defaultLessonDuration,
            onChanged: (value) {
              if (value != null) _updateDefaultDuration(ref, value);
            },
            child: Column(
              children:
                  allDurations.asMap().entries.map((entry) {
                    final index = entry.key;
                    final duration = entry.value;
                    final isDefault =
                        settings.defaultLessonDuration == duration;
                    final isDisabled = settings.isDurationDisabled(duration);
                    final isCustom = settings.customLessonDurations.contains(
                      duration,
                    );
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
                          onDelete:
                              isCustom
                                  ? () => showDeleteDurationDialog(
                                    context: context,
                                    duration: duration,
                                    onConfirm: () {
                                      ref
                                          .read(
                                            teacherSettingsNotifierProvider
                                                .notifier,
                                          )
                                          .removeCustomDuration(duration);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '${LessonDurations.format(duration)} 삭제됨',
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                  : null,
                          onToggle:
                              (value) => _toggleDuration(ref, duration, value),
                        ),
                        if (index < allDurations.length - 1)
                          const Divider(height: 1, indent: 16, endIndent: 16),
                      ],
                    );
                  }).toList(),
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.space2),
        Text(
          '최소 1개의 시간은 활성화 상태여야 합니다',
          style: AppTypography.caption.copyWith(color: AppColors.inkTertiary),
        ),
      ],
    );
  }

  void _toggleDuration(WidgetRef ref, int duration, bool isActive) {
    ref
        .read(teacherSettingsNotifierProvider.notifier)
        .toggleDuration(duration, isActive);
  }

  Widget _buildBookingSettingsSection(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Notebook × Score: 페이지 섹션 제목은 Playfair sectionTitle 로 통일 (§7.17).
        Text('예약 설정', style: NotebookTypography.sectionTitle),
        const SizedBox(height: AppSpacing.space2),
        Text(
          '레슨 예약 관련 설정을 지정하세요',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.inkSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.space4),

        Container(
          decoration: BoxDecoration(
            color: AppColors.paperDark,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          ),
          child: Column(
            children: [
              // Break time setting
              _BookingSettingItem(
                icon: Icons.coffee_outlined,
                title: '레슨 간 휴식 시간',
                subtitle: '${settings.breakTimeBetweenLessons}분',
                onTap: () => _showBreakTimeDialog(context, ref),
              ),
              const Divider(height: 1, indent: 56, endIndent: 16),
              // Minimum booking hours setting
              _BookingSettingItem(
                icon: Icons.schedule_outlined,
                title: '최소 예약 가능 시간',
                subtitle: '${settings.minBookingHours}시간 전',
                onTap: () => _showMinBookingHoursDialog(context, ref),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showBreakTimeDialog(BuildContext context, WidgetRef ref) {
    final options = [0, 5, 10, 15, 20, 30];
    final current = settings.breakTimeBetweenLessons;

    showModalBottomSheet(
      context: context,
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: AppSpacing.space4),
                // Notebook × Score: 바텀시트 섹션 제목은 Playfair sectionTitle 로 통일 (§7.17).
                Text('레슨 간 휴식 시간', style: NotebookTypography.sectionTitle),
                const SizedBox(height: AppSpacing.space2),
                Text(
                  '레슨과 레슨 사이의 휴식 시간을 설정합니다',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.space4),
                ...options.map(
                  (minutes) => ListTile(
                    leading: Icon(
                      current == minutes
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color:
                          current == minutes
                              ? AppColors.paperAccent
                              : AppColors.inkTertiary,
                    ),
                    title: Text(minutes == 0 ? '없음' : '$minutes분'),
                    onTap: () {
                      ref
                          .read(teacherSettingsNotifierProvider.notifier)
                          .updateBreakTime(minutes);
                      Navigator.pop(context);
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.space4),
              ],
            ),
          ),
    );
  }

  void _showMinBookingHoursDialog(BuildContext context, WidgetRef ref) {
    final options = [1, 2, 3, 6, 12, 24, 48, 72];
    final current = settings.minBookingHours;

    showModalBottomSheet(
      context: context,
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: AppSpacing.space4),
                // Notebook × Score: 바텀시트 섹션 제목은 Playfair sectionTitle 로 통일 (§7.17).
                Text('최소 예약 가능 시간', style: NotebookTypography.sectionTitle),
                const SizedBox(height: AppSpacing.space2),
                Text(
                  '레슨 시작 몇 시간 전까지 예약 가능한지 설정합니다',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.space4),
                ...options.map(
                  (hours) => ListTile(
                    leading: Icon(
                      current == hours
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color:
                          current == hours
                              ? AppColors.paperAccent
                              : AppColors.inkTertiary,
                    ),
                    title: Text(_formatHours(hours)),
                    onTap: () {
                      ref
                          .read(teacherSettingsNotifierProvider.notifier)
                          .updateMinBookingHours(hours);
                      Navigator.pop(context);
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.space4),
              ],
            ),
          ),
    );
  }

  String _formatHours(int hours) {
    if (hours < 24) {
      return '$hours시간 전';
    } else {
      final days = hours ~/ 24;
      return '$days일 전';
    }
  }

  Widget _buildTimeSlotsSection(BuildContext context, WidgetRef ref) {
    final slotsByDay = <int, List<TimeSlot>>{};
    for (final slot in settings.availableSlots) {
      slotsByDay.putIfAbsent(slot.dayOfWeek, () => []).add(slot);
    }

    // Sort slots within each day
    for (final slots in slotsByDay.values) {
      slots.sort(
        (a, b) =>
            a.startTime.hour * 60 +
            a.startTime.minute -
            (b.startTime.hour * 60 + b.startTime.minute),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LessonTimeSettingsSectionTitle(
          title: '운영 시간대',
          onAddPressed:
              () => showAddTimeSlotDialog(
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
            color: AppColors.inkSecondary,
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
              onToggleSlot:
                  (slot) => _toggleTimeSlot(ref, slot.id, !slot.isActive),
              onEditSlot:
                  (slot) => showEditTimeSlotDialog(
                    context: context,
                    slot: slot,
                    onSave: (updatedSlot) {
                      ref
                          .read(teacherSettingsNotifierProvider.notifier)
                          .updateTimeSlot(updatedSlot);
                    },
                  ),
              onAddSlot:
                  () => showAddTimeSlotDialog(
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

  Widget _buildGuidanceMessageSection(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LessonTimeSettingsSectionTitle(title: '레슨 요청 안내'),
        const SizedBox(height: AppSpacing.space2),
        Container(
          padding: const EdgeInsets.all(AppSpacing.space4),
          decoration: BoxDecoration(
            color: AppColors.paperDark,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '학생에게 표시할 안내 메시지',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.space2),
              TextField(
                controller: TextEditingController(
                  text: settings.bookingGuidanceMessage ?? '',
                ),
                maxLength: 100,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: TeacherSettings.defaultGuidanceMessage,
                  hintStyle: AppTypography.bodySmall.copyWith(
                    color: AppColors.inkTertiary,
                  ),
                  filled: true,
                  fillColor: AppColors.paperDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppSpacing.radiusMedium,
                    ),
                    borderSide: const BorderSide(
                      color: AppColors.inkQuaternary,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppSpacing.radiusMedium,
                    ),
                    borderSide: const BorderSide(
                      color: AppColors.inkQuaternary,
                    ),
                  ),
                  counterText: '',
                ),
                onChanged: (value) {
                  ref
                      .read(teacherSettingsNotifierProvider.notifier)
                      .updateBookingGuidanceMessage(value);
                },
              ),
              const SizedBox(height: AppSpacing.space2),
              Text(
                '비우면 기본 메시지가 표시됩니다',
                style: AppTypography.caption.copyWith(
                  color: AppColors.inkTertiary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrialLessonSection(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LessonTimeSettingsSectionTitle(title: '체험레슨 설정'),
        const SizedBox(height: AppSpacing.space2),
        Container(
          decoration: BoxDecoration(
            color: AppColors.paperDark,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          ),
          child: SwitchListTile(
            title: const Text('체험레슨 무료'),
            subtitle: Text(
              settings.trialLessonFree
                  ? '시간 확정 시 바로 예약 완료'
                  : '시간 확정 후 수강권 제안 필요',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
            value: settings.trialLessonFree,
            onChanged: (value) {
              ref
                  .read(teacherSettingsNotifierProvider.notifier)
                  .updateTrialLessonFree(value);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPriceTableSection(BuildContext context, WidgetRef ref) {
    final instruments = settings.instruments;
    const levels = ['beginner', 'intermediate', 'advanced'];
    const levelLabels = {
      'beginner': '초급',
      'intermediate': '중급',
      'advanced': '고급',
    };

    if (instruments.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LessonTimeSettingsSectionTitle(title: '레슨 가격표'),
          const SizedBox(height: AppSpacing.space2),
          Text(
            '악기를 먼저 설정하면 가격표를 입력할 수 있습니다.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LessonTimeSettingsSectionTitle(title: '레슨 가격표'),
        const SizedBox(height: AppSpacing.space2),
        Text(
          '악기별 레벨에 따른 1회 레슨 가격을 설정하세요.',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.inkSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.space4),
        Container(
          decoration: BoxDecoration(
            color: AppColors.paperDark,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          ),
          padding: const EdgeInsets.all(AppSpacing.space3),
          child: Column(
            children: [
              Row(
                children: [
                  const SizedBox(width: 80),
                  ...levels.map(
                    (level) => Expanded(
                      child: Center(
                        child: Text(
                          levelLabels[level]!,
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.inkSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space2),
              const Divider(height: 1),
              ...instruments.map(
                (instrument) => Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.space2),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 80,
                        child: Text(
                          instrument,
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      ...levels.map((level) {
                        final price = settings.getPrice(instrument, level);
                        return Expanded(
                          child: GestureDetector(
                            onTap:
                                () => _showPriceEditDialog(
                                  context,
                                  ref,
                                  instrument,
                                  level,
                                  levelLabels[level]!,
                                  price,
                                ),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color:
                                    price != null
                                        ? AppColors.paperAccentSoft.withValues(
                                          alpha: 0.1,
                                        )
                                        : null,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color:
                                      price != null
                                          ? AppColors.paperAccent.withValues(
                                            alpha: 0.3,
                                          )
                                          : AppColors.inkQuaternary,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  price != null
                                      ? '${(price / 10000).toStringAsFixed(price % 10000 == 0 ? 0 : 1)}만'
                                      : '—',
                                  style: AppTypography.caption.copyWith(
                                    color:
                                        price != null
                                            ? AppColors.paperAccent
                                            : AppColors.inkTertiary,
                                    fontWeight:
                                        price != null
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showPriceEditDialog(
    BuildContext context,
    WidgetRef ref,
    String instrument,
    String level,
    String levelLabel,
    int? currentPrice,
  ) async {
    final controller = TextEditingController(
      text: currentPrice != null ? currentPrice.toString() : '',
    );

    final result = await showDialog<int?>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('$instrument $levelLabel 가격'),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: '1회 레슨 가격 (원)',
                hintText: '예: 50000',
              ),
              autofocus: true,
            ),
            actions: [
              if (currentPrice != null)
                TextButton(
                  onPressed: () => Navigator.pop(context, -1),
                  child: Text(
                    '삭제',
                    style: TextStyle(color: AppColors.paperAccent),
                  ),
                ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(AppStrings.cancel),
              ),
              FilledButton(
                onPressed: () {
                  final value = int.tryParse(controller.text);
                  if (value != null && value > 0) {
                    Navigator.pop(context, value);
                  }
                },
                child: const Text(AppStrings.save),
              ),
            ],
          ),
    );
    controller.dispose();

    if (!context.mounted || result == null) return;

    final priceTable = Map<String, Map<String, int>>.from(
      settings.lessonPriceTable ?? {},
    );
    if (result == -1) {
      priceTable[instrument]?.remove(level);
      if (priceTable[instrument]?.isEmpty ?? false) {
        priceTable.remove(instrument);
      }
    } else {
      priceTable[instrument] = Map<String, int>.from(
        priceTable[instrument] ?? {},
      )..[level] = result;
    }
    ref
        .read(teacherSettingsNotifierProvider.notifier)
        .updatePriceTable(priceTable);
  }
}

/// A single setting item in the booking settings section
class _BookingSettingItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _BookingSettingItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space4,
          vertical: AppSpacing.space3,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.paperAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
              ),
              child: Icon(icon, color: AppColors.paperAccent, size: 20),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.bodyMedium),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.inkSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.inkTertiary),
          ],
        ),
      ),
    );
  }
}
