import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../../auth/auth_facade.dart';
import '../../domain/entities/notification_preferences.dart';
import '../providers/notification_preferences_provider.dart';
import '../providers/subscription_expiry_providers.dart';

// ignore: widget-smoke-test
/// Notification settings screen: master toggle + per-category toggles + DND.
///
/// Smoke test lives at:
/// `test/features/notifications/notification_settings_screen_test.dart`
class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(notificationPreferencesNotifierProvider);
    final notifier = ref.read(notificationPreferencesNotifierProvider.notifier);
    final isTeacher = ref.watch(currentUserRoleProvider) == UserRole.teacher;

    return NotebookScreenScaffold(
      appBar: const NotebookDetailAppBar(
        title: AppStrings.notificationSettingsTitle,
      ),
      body: ListView(
        children: [
          _MasterToggleSection(
            enabled: prefs.masterEnabled,
            onChanged: notifier.toggleMaster,
          ),
          const SizedBox(height: AppSpacing.space2),
          _SectionHeader(AppStrings.notificationCategoryHeader),
          _CategoryTile(
            title: AppStrings.notificationLesson,
            subtitle: AppStrings.notificationLessonDesc,
            enabled: prefs.lessonEnabled,
            masterEnabled: prefs.masterEnabled,
            onChanged:
                (v) => notifier.toggleCategory(NotificationCategory.lesson, v),
          ),
          // Spec §2.2: lessonStarting/lessonCancelled bypass all toggles.
          const _BypassHint(AppStrings.notifCategoryLessonBypassHint),
          _CategoryTile(
            title: AppStrings.notificationSchedule,
            subtitle: AppStrings.notificationScheduleDesc,
            enabled: prefs.scheduleEnabled,
            masterEnabled: prefs.masterEnabled,
            onChanged:
                (v) =>
                    notifier.toggleCategory(NotificationCategory.schedule, v),
          ),
          _CategoryTile(
            title: AppStrings.notificationSubscription,
            subtitle: AppStrings.notificationSubscriptionDesc,
            enabled: prefs.subscriptionEnabled,
            masterEnabled: prefs.masterEnabled,
            onChanged:
                (v) => notifier.toggleCategory(
                  NotificationCategory.subscription,
                  v,
                ),
          ),
          _CategoryTile(
            title: AppStrings.notificationAnnouncement,
            subtitle: AppStrings.notificationAnnouncementDesc,
            enabled: prefs.announcementEnabled,
            masterEnabled: prefs.masterEnabled,
            onChanged:
                (v) => notifier.toggleCategory(
                  NotificationCategory.announcement,
                  v,
                ),
          ),
          _CategoryTile(
            title: AppStrings.notificationPractice,
            subtitle: AppStrings.notificationPracticeDesc,
            enabled: prefs.practiceEnabled,
            masterEnabled: prefs.masterEnabled,
            onChanged:
                (v) =>
                    notifier.toggleCategory(NotificationCategory.practice, v),
          ),
          _CategoryTile(
            title: AppStrings.notificationMarketing,
            subtitle: AppStrings.notificationMarketingDesc,
            enabled: prefs.marketingEnabled,
            masterEnabled: prefs.masterEnabled,
            onChanged:
                (v) =>
                    notifier.toggleCategory(NotificationCategory.marketing, v),
          ),
          // Teacher-only: subscription expiry auto reminders (D-14/D-7/D-1/D-0)
          // Spec: docs/specs/student/enrollment_management_ux_spec.md §3.4
          if (isTeacher) ...[
            const SizedBox(height: AppSpacing.space2),
            _SectionHeader(
              AppStrings.notificationSettingsExpiryAutoSectionTeacher,
            ),
            _TeacherExpirySection(masterEnabled: prefs.masterEnabled),
          ],
          const SizedBox(height: AppSpacing.space2),
          _SectionHeader(AppStrings.quietHoursTitle),
          _QuietHoursSection(
            startHour: prefs.quietStartHour,
            endHour: prefs.quietEndHour,
            onChanged:
                ({required int? startHour, required int? endHour}) => notifier
                    .setQuietHours(startHour: startHour, endHour: endHour),
          ),
          // Spec §2.2: urgent lesson notifications bypass quiet hours.
          const _BypassHint(AppStrings.notifQuietHoursBypassHint),
          const SizedBox(height: AppSpacing.space8),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Master toggle section
// ---------------------------------------------------------------------------

class _MasterToggleSection extends StatelessWidget {
  const _MasterToggleSection({required this.enabled, required this.onChanged});

  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.paper,
      child: SwitchListTile(
        value: enabled,
        onChanged: onChanged,
        activeThumbColor: AppColors.ink,
        title: Text(
          AppStrings.notificationMasterToggle,
          style: AppTypography.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding,
          vertical: AppSpacing.space1,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section header
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.space3,
        AppSpacing.screenPadding,
        AppSpacing.space2,
      ),
      child: Text(
        title,
        style: AppTypography.caption.copyWith(color: AppColors.inkSecondary),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Category toggle tile
// ---------------------------------------------------------------------------

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.masterEnabled,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool enabled;
  final bool masterEnabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final effectiveEnabled = masterEnabled && enabled;
    return SwitchListTile(
      value: enabled,
      onChanged: masterEnabled ? onChanged : null,
      activeThumbColor: AppColors.ink,
      title: Text(
        title,
        style: AppTypography.bodyMedium.copyWith(
          color: effectiveEnabled ? AppColors.ink : AppColors.inkTertiary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.bodySmall.copyWith(color: AppColors.inkTertiary),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// DND bypass hint
// ---------------------------------------------------------------------------

class _BypassHint extends StatelessWidget {
  const _BypassHint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        0,
        AppSpacing.screenPadding,
        AppSpacing.space2,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 14, color: AppColors.inkTertiary),
          const SizedBox(width: AppSpacing.space1),
          Expanded(
            child: Text(
              text,
              style: AppTypography.captionSmall.copyWith(
                color: AppColors.inkTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Teacher-only: subscription expiry auto reminder toggles
// ---------------------------------------------------------------------------

class _TeacherExpirySection extends ConsumerWidget {
  const _TeacherExpirySection({required this.masterEnabled});

  /// Global push master switch — gates the whole section.
  final bool masterEnabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expiry = ref.watch(
      subscriptionExpiryReminderSettingsNotifierProvider,
    );
    final notifier = ref.read(
      subscriptionExpiryReminderSettingsNotifierProvider.notifier,
    );
    final sectionOn = masterEnabled && expiry.enabled;

    return Column(
      children: [
        _CategoryTile(
          title: AppStrings.notificationExpiryAutoMasterTitle,
          subtitle: AppStrings.notificationExpiryAutoMasterSubtitle,
          enabled: expiry.enabled,
          masterEnabled: masterEnabled,
          onChanged: notifier.toggleEnabled,
        ),
        _CategoryTile(
          title: AppStrings.notificationExpiryD14Title,
          subtitle: AppStrings.notificationExpiryD14Subtitle,
          enabled: expiry.remindAtD14,
          masterEnabled: sectionOn,
          onChanged: notifier.toggleD14,
        ),
        _CategoryTile(
          title: AppStrings.notificationExpiryD7Title,
          subtitle: AppStrings.notificationExpiryD7Subtitle,
          enabled: expiry.remindAtD7,
          masterEnabled: sectionOn,
          onChanged: notifier.toggleD7,
        ),
        _CategoryTile(
          title: AppStrings.notificationExpiryD1Title,
          subtitle: AppStrings.notificationExpiryD1Subtitle,
          enabled: expiry.remindAtD1,
          masterEnabled: sectionOn,
          onChanged: notifier.toggleD1,
        ),
        _CategoryTile(
          title: AppStrings.notificationExpiryD0Title,
          subtitle: AppStrings.notificationExpiryD0Subtitle,
          enabled: expiry.remindAtD0,
          masterEnabled: sectionOn,
          onChanged: notifier.toggleD0,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Quiet hours section
// ---------------------------------------------------------------------------

class _QuietHoursSection extends StatelessWidget {
  const _QuietHoursSection({
    required this.startHour,
    required this.endHour,
    required this.onChanged,
  });

  final int? startHour;
  final int? endHour;
  final void Function({required int? startHour, required int? endHour})
  onChanged;

  @override
  Widget build(BuildContext context) {
    final isDndEnabled = startHour != null && endHour != null;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.space2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.quietHoursEnabledLabel,
                style: AppTypography.bodyMedium.copyWith(color: AppColors.ink),
              ),
              Switch(
                value: isDndEnabled,
                activeThumbColor: AppColors.ink,
                onChanged: (v) {
                  if (v) {
                    onChanged(startHour: 22, endHour: 8);
                  } else {
                    onChanged(startHour: null, endHour: null);
                  }
                },
              ),
            ],
          ),
          if (isDndEnabled) ...[
            const SizedBox(height: AppSpacing.space3),
            Row(
              children: [
                Expanded(
                  child: _HourPickerButton(
                    label: AppStrings.quietHoursStartLabel,
                    hour: startHour!,
                    onChanged: (h) => onChanged(startHour: h, endHour: endHour),
                  ),
                ),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: _HourPickerButton(
                    label: AppStrings.quietHoursEndLabel,
                    hour: endHour!,
                    onChanged:
                        (h) => onChanged(startHour: startHour, endHour: h),
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

// ---------------------------------------------------------------------------
// Hour picker button
// ---------------------------------------------------------------------------

class _HourPickerButton extends StatelessWidget {
  const _HourPickerButton({
    required this.label,
    required this.hour,
    required this.onChanged,
  });

  final String label;
  final int hour;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _pickHour(context),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space3,
          vertical: AppSpacing.space2,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.inkQuaternary),
          color: AppColors.paperDark,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.captionSmall.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.space1),
            Text(
              '${hour.toString().padLeft(2, '0')}:00',
              style: AppTypography.headingSmall.copyWith(color: AppColors.ink),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickHour(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: hour, minute: 0),
      initialEntryMode: TimePickerEntryMode.input,
      builder:
          (ctx, child) => MediaQuery(
            data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
            child: child!,
          ),
    );
    if (picked != null) {
      onChanged(picked.hour);
    }
  }
}
