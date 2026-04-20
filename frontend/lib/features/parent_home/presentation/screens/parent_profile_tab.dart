import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/providers/user_role_provider.dart';
import '../../../student_home/presentation/widgets/language_select_sheet.dart';
import '../providers/child_profile_provider.dart';
import '../../../../features/parent_home/presentation/providers/parent_crud_provider.dart';
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

    return Scaffold(
      appBar: AppBar(title: const Text('프로필'), centerTitle: true),
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
              title: '설정',
              items: [
                ProfileMenuItem(
                  icon: Icons.language,
                  label: '언어',
                  trailing: Text(
                    '한국어',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  onTap: () => LanguageSelectSheet.show(context),
                ),
                ProfileMenuItem(
                  icon: Icons.backup_outlined,
                  label: '녹음 백업',
                  onTap: () => context.push(AppRoutes.backupSettings),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.space4),

            // Support section
            ProfileMenuSection(
              title: '지원',
              items: [
                ProfileMenuItem(
                  icon: Icons.help_outline,
                  label: '도움말',
                  onTap: () => context.push(AppRoutes.help),
                ),
                ProfileMenuItem(
                  icon: Icons.info_outline,
                  label: '앱 정보',
                  trailing: Text(
                    'v1.0.0',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  onTap: () => context.push(AppRoutes.appInfo),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.space4),

            // Account section
            ProfileMenuSection(
              title: '계정',
              items: [
                ProfileMenuItem(
                  icon: Icons.description_outlined,
                  label: '이용약관',
                  onTap: () => context.push(AppRoutes.termsOfService),
                ),
                ProfileMenuItem(
                  icon: Icons.privacy_tip_outlined,
                  label: '개인정보처리방침',
                  onTap: () => context.push(AppRoutes.privacyPolicy),
                ),
                ProfileMenuItem(
                  icon: Icons.logout,
                  label: '로그아웃',
                  labelColor: AppColors.error,
                  onTap: () => _showLogoutDialog(context),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.space8),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('로그아웃'),
            content: const Text('정말 로그아웃 하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(AppStrings.cancel),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.go(AppRoutes.login);
                },
                style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                child: const Text('로그아웃'),
              ),
            ],
          ),
    );
  }
}
