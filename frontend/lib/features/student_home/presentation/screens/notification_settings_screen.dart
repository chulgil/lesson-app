// Notification settings screen with per-category toggle switches.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('알림 설정')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          // Master toggle
          _buildSection(
            title: '전체 알림',
            children: [
              _SwitchTile(
                title: '알림 받기',
                subtitle: '모든 알림을 켜거나 끕니다',
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
            title: '레슨 알림',
            children: [
              _SwitchTile(
                title: '레슨 시작 알림',
                subtitle: '레슨 30분 전 알림',
                value: settings.lessonReminder,
                enabled: settings.allNotifications,
                onChanged:
                    (value) => ref
                        .read(notificationSettingsProvider.notifier)
                        .toggleLessonReminder(value),
              ),
              _SwitchTile(
                title: '레슨 변경 알림',
                subtitle: '레슨 시간/일정 변경 시',
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
            title: '수강권 알림',
            children: [
              _SwitchTile(
                title: '수강권 제안 알림',
                subtitle: '선생님이 수강권을 제안할 때',
                value: settings.subscriptionProposal,
                enabled: settings.allNotifications,
                onChanged:
                    (value) => ref
                        .read(notificationSettingsProvider.notifier)
                        .toggleSubscriptionProposal(value),
              ),
              _SwitchTile(
                title: '수강권 만료 알림',
                subtitle: '수강권 만료 7일 전 알림',
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
            title: '연습 알림',
            children: [
              _SwitchTile(
                title: '연습 리마인더',
                subtitle: '매일 설정한 시간에 알림',
                value: settings.practiceReminder,
                enabled: settings.allNotifications,
                onChanged:
                    (value) => ref
                        .read(notificationSettingsProvider.notifier)
                        .togglePracticeReminder(value),
              ),
              _SwitchTile(
                title: '선생님 피드백',
                subtitle: '선생님이 피드백을 남길 때',
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
                    '푸시 알림은 준비 중입니다.\n'
                    '알림 설정은 저장되며, 기능이 활성화되면 자동 적용됩니다.',
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
      title: '수강권 만료 자동 알림 (선생님)',
      children: [
        _SwitchTile(
          title: '만료 자동 알림',
          subtitle: '활성 수강권의 만료 시점에 자동으로 알림',
          value: expiry.enabled,
          enabled: enabled,
          onChanged: notifier.toggleEnabled,
        ),
        _SwitchTile(
          title: 'D-14 (14일 전)',
          subtitle: '여유 있게 재등록 제안 시점',
          value: expiry.remindAtD14,
          enabled: masterOn,
          onChanged: notifier.toggleD14,
        ),
        _SwitchTile(
          title: 'D-7 (7일 전)',
          subtitle: '재등록 유도 주차 알림',
          value: expiry.remindAtD7,
          enabled: masterOn,
          onChanged: notifier.toggleD7,
        ),
        _SwitchTile(
          title: 'D-1 (하루 전)',
          subtitle: '만료 임박 최종 알림',
          value: expiry.remindAtD1,
          enabled: masterOn,
          onChanged: notifier.toggleD1,
        ),
        _SwitchTile(
          title: 'D-0 (당일)',
          subtitle: '만료 당일 보관 이동 알림',
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
