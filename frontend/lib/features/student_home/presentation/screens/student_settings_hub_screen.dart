// Student settings sub-hub — rarely-changed settings split out of the
// profile tab's flat scroll (Hick's Law: daily-use menu vs. settings).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:lessonaza/core/widgets/notebook/thin_rule.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../providers/practice_reminder_provider.dart';
import '../widgets/language_select_sheet.dart';
import '../widgets/practice_reminder_sheet.dart';

/// Student settings hub — 알림 설정/연습 리마인더/언어/녹음 백업/도움말/앱 정보.
///
/// Split out of [StudentProfileTab] so the daily-use "메뉴" container and the
/// rarely-changed settings don't share the same visual hierarchy.
class StudentSettingsHubScreen extends ConsumerWidget {
  const StudentSettingsHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminderSettings = ref.watch(practiceReminderProvider);

    return NotebookScreenScaffold(
      appBar: const NotebookDetailAppBar(
        title: AppStrings.studentHomeSettingsTitle,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.paper,
              border: Border.all(color: AppColors.inkQuaternary),
            ),
            child: Column(
              children: [
                _buildMenuItem(
                  icon: Icons.notifications_outlined,
                  title: AppStrings.studentHomeMenuNotificationSettings,
                  subtitle: AppStrings.studentHomeMenuNotificationSubtitle,
                  onTap: () => context.push(AppRoutes.notificationSettings),
                ),
                _buildMenuDivider(),
                _buildMenuItem(
                  icon: Icons.alarm_outlined,
                  title: AppStrings.studentHomePracticeReminder,
                  subtitle: reminderSettings.isEnabled
                      ? reminderSettings.formattedTime
                      : AppStrings.studentHomePracticeReminderOff,
                  onTap: () => PracticeReminderSheet.show(context),
                ),
                _buildMenuDivider(),
                _buildMenuItem(
                  icon: Icons.language_outlined,
                  title: AppStrings.studentHomeMenuLanguage,
                  subtitle: AppStrings.studentHomeMenuLanguageValue,
                  onTap: () => LanguageSelectSheet.show(context),
                ),
                _buildMenuDivider(),
                _buildMenuItem(
                  icon: Icons.backup_outlined,
                  title: AppStrings.studentHomeMenuRecordingBackup,
                  onTap: () => context.push(AppRoutes.backupSettings),
                ),
                _buildMenuDivider(),
                _buildMenuItem(
                  icon: Icons.help_outline,
                  title: AppStrings.studentHomeHelpTitle,
                  onTap: () => context.push(AppRoutes.help),
                ),
                _buildMenuDivider(),
                _buildMenuItem(
                  icon: Icons.info_outline,
                  title: AppStrings.studentHomeAppInfoTitle,
                  onTap: () => context.push(AppRoutes.appInfo),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.space2),
              decoration: const BoxDecoration(color: AppColors.paperDark),
              child: Icon(icon, size: 20, color: AppColors.inkSecondary),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.inkSecondary,
                      ),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.inkTertiary),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuDivider() {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.space4 + 36 + AppSpacing.space3,
      ),
      child: const ThinRule(),
    );
  }
}
