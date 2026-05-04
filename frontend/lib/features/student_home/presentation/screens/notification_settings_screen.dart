// Notification settings screen with per-category toggle switches.

import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/providers/user_role_provider.dart';
import '../../../notifications/presentation/providers/subscription_expiry_providers.dart';
import '../providers/notification_settings_provider.dart';

/// Notification settings screen with category-based ON/OFF switches.
class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(notificationSettingsProvider);
    final role = ref.watch(currentUserRoleProvider);
    final isTeacher = role == UserRole.teacher;

    return NotebookScreenScaffold(
      appBar: AppBar(
        title: const Text(AppStrings.notificationSettingsAppBarTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          // Master toggle
          _buildSection(
            title: AppStrings.notificationSettingsMasterSection,
            children: [
              _SwitchTile(
                title: AppStrings.notificationToggleAllTitle,
                subtitle: AppStrings.notificationToggleAllSubtitle,
                value: settings.allNotifications,
                onChanged:
                    (value) => ref
                        .read(notificationSettingsProvider.notifier)
                        .toggleAll(value),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.space4),

          // Lesson notifications
          _buildSection(
            title: AppStrings.notificationSettingsLessonSection,
            children: [
              _SwitchTile(
                title: AppStrings.notificationLessonStartTitle,
                subtitle: AppStrings.notificationLessonStartSubtitle,
                value: settings.lessonReminder,
                enabled: settings.allNotifications,
                onChanged:
                    (value) => ref
                        .read(notificationSettingsProvider.notifier)
                        .toggleLessonReminder(value),
              ),
              _SwitchTile(
                title: AppStrings.notificationLessonChangeTitle,
                subtitle: AppStrings.notificationLessonChangeSubtitle,
                value: settings.lessonChange,
                enabled: settings.allNotifications,
                onChanged:
                    (value) => ref
                        .read(notificationSettingsProvider.notifier)
                        .toggleLessonChange(value),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.space4),

          // Subscription notifications
          _buildSection(
            title: AppStrings.notificationSettingsSubscriptionSection,
            children: [
              _SwitchTile(
                title: AppStrings.notificationSubscriptionProposalTitle,
                subtitle: AppStrings.notificationSubscriptionProposalSubtitle,
                value: settings.subscriptionProposal,
                enabled: settings.allNotifications,
                onChanged:
                    (value) => ref
                        .read(notificationSettingsProvider.notifier)
                        .toggleSubscriptionProposal(value),
              ),
              _SwitchTile(
                title: AppStrings.notificationSubscriptionExpiryTitle,
                subtitle: AppStrings.notificationSubscriptionExpirySubtitle,
                value: settings.subscriptionExpiry,
                enabled: settings.allNotifications,
                onChanged:
                    (value) => ref
                        .read(notificationSettingsProvider.notifier)
                        .toggleSubscriptionExpiry(value),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.space4),

          // Teacher-only: Subscription expiry reminders (D-14 / D-7 / D-1 / D-0)
          // Spec: docs/specs/student/enrollment_management_ux_spec.md §3.4
          if (isTeacher) ...[
            _buildSubscriptionExpirySection(
              ref,
              enabled: settings.allNotifications,
            ),
            const SizedBox(height: AppSpacing.space4),
          ],

          // Practice notifications
          _buildSection(
            title: AppStrings.notificationSettingsPracticeSection,
            children: [
              _SwitchTile(
                title: AppStrings.notificationPracticeReminderTitle,
                subtitle: AppStrings.notificationPracticeReminderSubtitle,
                value: settings.practiceReminder,
                enabled: settings.allNotifications,
                onChanged:
                    (value) => ref
                        .read(notificationSettingsProvider.notifier)
                        .togglePracticeReminder(value),
              ),
              _SwitchTile(
                title: AppStrings.teacherFeedbackHeader,
                subtitle: AppStrings.notificationTeacherFeedbackSubtitle,
                value: settings.teacherFeedback,
                enabled: settings.allNotifications,
                onChanged:
                    (value) => ref
                        .read(notificationSettingsProvider.notifier)
                        .toggleTeacherFeedback(value),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.space6),

          // Info banner
          Container(
            padding: const EdgeInsets.all(AppSpacing.space4),
            decoration: BoxDecoration(
              color: AppColors.ink.withValues(alpha: 0.08),
              border: Border.all(color: AppColors.ink.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 20, color: AppColors.ink),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: Text(
                    AppStrings.notificationPushPreparingNotice,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.ink,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.inkSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.space2),
        Container(
          decoration: BoxDecoration(
            color: AppColors.paper,
            border: Border.all(color: AppColors.inkQuaternary),
          ),
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    indent: AppSpacing.space4,
                    endIndent: AppSpacing.space4,
                    color: AppColors.inkQuaternary,
                  ),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Teacher-only section: master + D-14/D-7/D-1/D-0 individual toggles.
  Widget _buildSubscriptionExpirySection(
    WidgetRef ref, {
    required bool enabled,
  }) {
    final expiry = ref.watch(subscriptionExpiryReminderSettingsProvider);
    final notifier = ref.read(
      subscriptionExpiryReminderSettingsProvider.notifier,
    );
    final masterOn = enabled && expiry.enabled;

    return _buildSection(
      title: AppStrings.notificationSettingsExpiryAutoSectionTeacher,
      children: [
        _SwitchTile(
          title: AppStrings.notificationExpiryAutoMasterTitle,
          subtitle: AppStrings.notificationExpiryAutoMasterSubtitle,
          value: expiry.enabled,
          enabled: enabled,
          onChanged: notifier.toggleEnabled,
        ),
        _SwitchTile(
          title: AppStrings.notificationExpiryD14Title,
          subtitle: AppStrings.notificationExpiryD14Subtitle,
          value: expiry.remindAtD14,
          enabled: masterOn,
          onChanged: notifier.toggleD14,
        ),
        _SwitchTile(
          title: AppStrings.notificationExpiryD7Title,
          subtitle: AppStrings.notificationExpiryD7Subtitle,
          value: expiry.remindAtD7,
          enabled: masterOn,
          onChanged: notifier.toggleD7,
        ),
        _SwitchTile(
          title: AppStrings.notificationExpiryD1Title,
          subtitle: AppStrings.notificationExpiryD1Subtitle,
          value: expiry.remindAtD1,
          enabled: masterOn,
          onChanged: notifier.toggleD1,
        ),
        _SwitchTile(
          title: AppStrings.notificationExpiryD0Title,
          subtitle: AppStrings.notificationExpiryD0Subtitle,
          value: expiry.remindAtD0,
          enabled: masterOn,
          onChanged: notifier.toggleD0,
        ),
      ],
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    this.enabled = true,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space3,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                    color: enabled ? AppColors.ink : AppColors.inkTertiary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.caption.copyWith(
                    color:
                        enabled
                            ? AppColors.inkSecondary
                            : AppColors.inkTertiary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value && enabled,
            onChanged: enabled ? onChanged : null,
            activeThumbColor: AppColors.paperAccent,
          ),
        ],
      ),
    );
  }
}
