import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../features/parent_home/domain/entities/parent_notification_settings.dart';
import '../../../../features/parent_home/presentation/providers/parent_crud_provider.dart';
import 'notification_settings_sheet.dart';

/// Notification settings section in the parent profile tab
class ProfileNotificationSection extends ConsumerWidget {
  final AsyncValue<ParentNotificationSettings?> settingsAsync;
  final String parentId;

  const ProfileNotificationSection({
    super.key,
    required this.settingsAsync,
    required this.parentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '알림 설정',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.inkTertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed:
                    () =>
                        _showNotificationSettingsSheet(context, ref, parentId),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('상세 설정'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          Container(
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.zero,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: settingsAsync.when(
              loading:
                  () => const Padding(
                    padding: EdgeInsets.all(AppSpacing.space4),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              error:
                  (_, __) => const Padding(
                    padding: EdgeInsets.all(AppSpacing.space4),
                    child: Text('오류가 발생했습니다.'),
                  ),
              data: (settings) {
                // Use default settings if none exist
                final s =
                    settings ??
                    ParentNotificationSettings.defaultSettings(
                      id: 'default',
                      parentId: parentId,
                    );

                return Column(
                  children: [
                    _buildNotificationItem(
                      icon: Icons.assignment_outlined,
                      label: '과제 알림',
                      subtitle: '새 과제 등록, 미완료 알림',
                      value: s.newAssignment || s.assignmentIncomplete,
                      onChanged:
                          (value) => _toggleNotificationGroup(
                            ref,
                            s,
                            parentId,
                            assignmentEnabled: value,
                          ),
                    ),
                    _buildDivider(),
                    _buildNotificationItem(
                      icon: Icons.schedule,
                      label: '레슨 알림',
                      subtitle: '일정 변경, 취소 알림',
                      value: s.lessonChange || s.lessonCancel,
                      onChanged:
                          (value) => _toggleNotificationGroup(
                            ref,
                            s,
                            parentId,
                            lessonEnabled: value,
                          ),
                    ),
                    _buildDivider(),
                    _buildNotificationItem(
                      icon: Icons.music_note,
                      label: '연습 알림',
                      subtitle: '연습 완료, 스트릭 달성',
                      value: s.practiceComplete || s.streakAchievement,
                      onChanged:
                          (value) => _toggleNotificationGroup(
                            ref,
                            s,
                            parentId,
                            practiceEnabled: value,
                          ),
                    ),
                    _buildDivider(),
                    _buildNotificationItem(
                      icon: Icons.payment,
                      label: '결제 알림',
                      subtitle: '결제 요청, 완료 확인 (필수)',
                      value: true,
                      isRequired: true,
                      onChanged: null,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required String label,
    required String subtitle,
    required bool value,
    bool isRequired = false,
    ValueChanged<bool>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space3,
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: AppColors.inkSecondary),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(label, style: AppTypography.bodyLarge),
                    if (isRequired) ...[
                      const SizedBox(width: AppSpacing.space1),
                      // §7.132: paperAccent.alpha → paperAccentSoft.
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.paperAccentSoft,
                          borderRadius: BorderRadius.zero,
                        ),
                        child: Text(
                          '필수',
                          style: AppTypography.captionSmall.copyWith(
                            color: AppColors.paperAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.inkTertiary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: isRequired ? null : onChanged,
            activeThumbColor: AppColors.paperAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      indent: AppSpacing.space4 + 24 + AppSpacing.space3,
      color: AppColors.inkQuaternary,
    );
  }

  void _toggleNotificationGroup(
    WidgetRef ref,
    ParentNotificationSettings settings,
    String parentId, {
    bool? assignmentEnabled,
    bool? lessonEnabled,
    bool? practiceEnabled,
  }) {
    ParentNotificationSettings updated = settings;

    if (assignmentEnabled != null) {
      updated = updated.copyWith(
        newAssignment: assignmentEnabled,
        assignmentIncomplete: assignmentEnabled,
      );
    }
    if (lessonEnabled != null) {
      updated = updated.copyWith(
        lessonChange: lessonEnabled,
        lessonCancel: lessonEnabled,
      );
    }
    if (practiceEnabled != null) {
      updated = updated.copyWith(
        practiceComplete: practiceEnabled,
        streakAchievement: practiceEnabled,
      );
    }

    ref
        .read(notificationSettingsNotifierProvider(parentId).notifier)
        .saveSettings(updated);
  }

  void _showNotificationSettingsSheet(
    BuildContext context,
    WidgetRef ref,
    String parentId,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) {
              final settingsAsync = ref.watch(
                notificationSettingsNotifierProvider(parentId),
              );

              return settingsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Center(child: Text('오류가 발생했습니다.')),
                data: (settings) {
                  final s =
                      settings ??
                      ParentNotificationSettings.defaultSettings(
                        id: 'default',
                        parentId: parentId,
                      );

                  return NotificationSettingsSheet(
                    settings: s,
                    scrollController: scrollController,
                    onSettingsChanged: (newSettings) {
                      ref
                          .read(
                            notificationSettingsNotifierProvider(
                              parentId,
                            ).notifier,
                          )
                          .saveSettings(newSettings);
                    },
                  );
                },
              );
            },
          ),
    );
  }
}
