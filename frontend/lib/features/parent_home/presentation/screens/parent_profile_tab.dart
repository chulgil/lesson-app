import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/auth_facade.dart';
import '../../../student_home/student_home_ui_facade.dart';
import '../providers/child_profile_provider.dart';
import '../../../../features/parent_home/parent_home_facade.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_menu_section.dart';
import '../widgets/profile_notification_section.dart';
import '../widgets/profile_children_section.dart';

/// Parent profile tab with settings and child management
class ParentProfileTab extends ConsumerWidget {
  const ParentProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parentId = ref.watch(currentUserIdProvider);
    final childProfilesAsync = ref.watch(childProfilesProvider(parentId));
    final notificationSettingsAsync = ref.watch(
      notificationSettingsNotifierProvider(parentId),
    );

    return NotebookScreenScaffold(
      appBar: AppBar(
        title: const Text(AppStrings.parentHomeProfile),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.space4),

            // Profile header
            const ProfileHeader(),

            const SizedBox(height: AppSpacing.space6),

            // Connected children section
            ProfileChildrenSection(
              childProfilesAsync: childProfilesAsync,
              parentId: parentId,
            ),

            const SizedBox(height: AppSpacing.space4),

            // Notification settings
            ProfileNotificationSection(
              settingsAsync: notificationSettingsAsync,
              parentId: parentId,
            ),

            const SizedBox(height: AppSpacing.space4),

            // General settings
            ProfileMenuSection(
              title: AppStrings.parentProfileSectionSettings,
              items: [
                ProfileMenuItem(
                  icon: Icons.language,
                  label: AppStrings.parentProfileLanguageLabel,
                  trailing: Text(
                    AppStrings.studentHomeMenuLanguageValue,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.inkSecondary,
                    ),
                  ),
                  onTap: () => LanguageSelectSheet.show(context),
                ),
                ProfileMenuItem(
                  icon: Icons.backup_outlined,
                  label: AppStrings.parentProfileRecordingBackupLabel,
                  onTap: () => context.push(AppRoutes.backupSettings),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.space4),

            // Support section
            ProfileMenuSection(
              title: AppStrings.parentProfileSectionSupport,
              items: [
                ProfileMenuItem(
                  icon: Icons.help_outline,
                  label: AppStrings.profileHelpLabel,
                  onTap: () => context.push(AppRoutes.help),
                ),
                ProfileMenuItem(
                  icon: Icons.info_outline,
                  label: AppStrings.profileAppInfoLabel,
                  trailing: Text(
                    'v1.0.0',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.inkSecondary,
                    ),
                  ),
                  onTap: () => context.push(AppRoutes.appInfo),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.space4),

            // Account section
            ProfileMenuSection(
              title: AppStrings.parentProfileSectionAccount,
              items: [
                ProfileMenuItem(
                  icon: Icons.description_outlined,
                  label: AppStrings.profileTermsLabel,
                  onTap: () => context.push(AppRoutes.termsOfService),
                ),
                ProfileMenuItem(
                  icon: Icons.privacy_tip_outlined,
                  label: AppStrings.profilePrivacyPolicyLabel,
                  onTap: () => context.push(AppRoutes.privacyPolicy),
                ),
                ProfileMenuItem(
                  icon: Icons.logout,
                  label: AppStrings.profileLogoutLabel,
                  labelColor: AppColors.paperAccent,
                  onTap: () => _showLogoutDialog(context, ref),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.space8),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showNotebookDialog<void>(
      context: context,
      title: AppStrings.parentHomeLogout,
      content: const Text(AppStrings.parentHomeLogoutConfirm),
      confirmLabel: AppStrings.parentHomeLogout,
      cancelLabel: AppStrings.cancel,
      isDestructive: true,
      onConfirm: () async {
        Navigator.pop(context);
        // Call auth logout so tokens are cleared and keepAlive providers
        // do not leak previous user's data to the next session.
        await ref.read(authNotifierProvider.notifier).logout();
        if (context.mounted) context.go(AppRoutes.login);
      },
    );
  }
}
