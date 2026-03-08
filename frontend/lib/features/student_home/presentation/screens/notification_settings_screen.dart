// Notification settings screen with per-category toggle switches.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/notification_settings_provider.dart';

/// Notification settings screen with category-based ON/OFF switches.
class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(notificationSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('알림 설정'),
      ),
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
                onChanged: (value) => ref
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
                onChanged: (value) => ref
                    .read(notificationSettingsProvider.notifier)
                    .toggleLessonReminder(value),
              ),
              _SwitchTile(
                title: '레슨 변경 알림',
                subtitle: '레슨 시간/일정 변경 시',
                value: settings.lessonChange,
                enabled: settings.allNotifications,
                onChanged: (value) => ref
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
                onChanged: (value) => ref
                    .read(notificationSettingsProvider.notifier)
                    .toggleSubscriptionProposal(value),
              ),
              _SwitchTile(
                title: '수강권 만료 알림',
                subtitle: '수강권 만료 7일 전 알림',
                value: settings.subscriptionExpiry,
                enabled: settings.allNotifications,
                onChanged: (value) => ref
                    .read(notificationSettingsProvider.notifier)
                    .toggleSubscriptionExpiry(value),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.space4),

          // Practice notifications
          _buildSection(
            title: '연습 알림',
            children: [
              _SwitchTile(
                title: '연습 리마인더',
                subtitle: '매일 설정한 시간에 알림',
                value: settings.practiceReminder,
                enabled: settings.allNotifications,
                onChanged: (value) => ref
                    .read(notificationSettingsProvider.notifier)
                    .togglePracticeReminder(value),
              ),
              _SwitchTile(
                title: '선생님 피드백',
                subtitle: '선생님이 피드백을 남길 때',
                value: settings.teacherFeedback,
                enabled: settings.allNotifications,
                onChanged: (value) => ref
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
              color: AppColors.info.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              border: Border.all(
                color: AppColors.info.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: AppColors.info,
                ),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: Text(
                    '푸시 알림은 준비 중입니다.\n'
                    '알림 설정은 저장되며, 기능이 활성화되면 자동 적용됩니다.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.info,
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
            color: AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: AppSpacing.space2),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    indent: AppSpacing.space4,
                    endIndent: AppSpacing.space4,
                    color: AppColors.borderLight,
                  ),
                children[i],
              ],
            ],
          ),
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
                    color: enabled
                        ? AppColors.textPrimaryLight
                        : AppColors.textTertiaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.caption.copyWith(
                    color: enabled
                        ? AppColors.textSecondaryLight
                        : AppColors.textTertiaryLight,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value && enabled,
            onChanged: enabled ? onChanged : null,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
