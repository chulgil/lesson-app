import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/environment.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/notebook/notebook_alert_dialog.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../../core/widgets/notebook/notebook_screen_scaffold.dart';
import '../../../auth/auth_facade.dart';

/// ⚙️ 알림·소식·지원 카테고리 화면 (#765 — BottomSheet → 정식 라우트 승격).
///
/// 기존 `showPolicyNotificationsSheet` 의 3 섹션(템플릿 / 알림·소식 / 지원·계정)을
/// 그대로 옮긴 화면. 시트와 달리 하위 상세에서 뒤로가기 시 이 메뉴로 복귀한다.
class PolicyNotificationsCategoryScreen extends ConsumerWidget {
  const PolicyNotificationsCategoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NotebookScreenScaffold(
      appBar: const NotebookDetailAppBar(
        title: AppStrings.categorySheetPolicyNotificationsTitle,
      ),
      body: ListView(
        children: [
          const _CategorySectionLabel(
            title: AppStrings.categorySheetSectionTemplates,
          ),
          ListTile(
            leading: const Icon(Icons.chat_outlined),
            title: const Text(AppStrings.feedbackTemplateMenuTitle),
            subtitle: const Text(AppStrings.feedbackTemplateMenuSubtitle),
            onTap: () => context.push(AppRoutes.feedbackTemplateManagement),
          ),
          ListTile(
            leading: const Icon(Icons.tips_and_updates_outlined),
            title: const Text(AppStrings.profileTipTemplateLabel),
            subtitle: const Text(AppStrings.profileTipTemplateSubtitle),
            onTap: () => context.push(AppRoutes.tipTemplateManagement),
          ),
          const _CategorySectionLabel(
            title: AppStrings.categorySheetSectionNotificationsNews,
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text(AppStrings.profileNotificationLabel),
            onTap: () => context.push(AppRoutes.notificationSettings),
          ),
          ListTile(
            leading: const Icon(Icons.mic_outlined),
            title: const Text(AppStrings.profileRecordingLabel),
            onTap: () => context.push(AppRoutes.allRecordings),
          ),
          ListTile(
            leading: const Icon(Icons.people_outline),
            title: const Text(AppStrings.profileFollowingLabel),
            subtitle: const Text(AppStrings.profileFollowingSubtitle),
            onTap: () => context.push(AppRoutes.followList),
          ),
          ListTile(
            leading: const Icon(Icons.article_outlined),
            title: const Text(AppStrings.profileNewsLabel),
            subtitle: const Text(AppStrings.profileNewsSubtitle),
            onTap: () => context.push(AppRoutes.followFeed),
          ),
          ListTile(
            leading: const Icon(Icons.campaign_outlined),
            title: const Text(AppStrings.newsRoadmapTitle),
            onTap: () => context.push(AppRoutes.newsRoadmap),
          ),
          const _CategorySectionLabel(
            title: AppStrings.categorySheetSectionSupportAccount,
          ),
          ListTile(
            leading: const Icon(Icons.menu_book_outlined),
            title: const Text(AppStrings.categoryGuideReplayLabel),
            subtitle: const Text(AppStrings.categoryGuideReplaySubtitle),
            onTap: () => context.push(AppRoutes.guideReshow),
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text(AppStrings.profileHelpLabel),
            onTap: () => context.push(AppRoutes.help),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text(AppStrings.profileAppInfoLabel),
            trailing: Text(
              'v${EnvironmentConfig.appVersion}',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
            onTap: () => context.push(AppRoutes.appInfo),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text(AppStrings.profileTermsLabel),
            onTap: () => context.push(AppRoutes.termsOfService),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text(AppStrings.profilePrivacyPolicyLabel),
            onTap: () => context.push(AppRoutes.privacyPolicy),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.paperAccent),
            title: Text(
              AppStrings.profileLogoutLabel,
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.paperAccent,
              ),
            ),
            onTap: () => _showLogoutDialog(context, ref),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showNotebookDialog(
      context: context,
      title: AppStrings.profileLogoutLabel,
      content: const Text(AppStrings.profileLogoutConfirm),
      confirmLabel: AppStrings.profileLogoutLabel,
      cancelLabel: AppStrings.cancel,
      isDestructive: true,
      onConfirm: () async {
        Navigator.pop(context);
        await ref.read(authNotifierProvider.notifier).logout();
        // Explicit nav after logout (redirect is a secondary safety net).
        if (context.mounted) context.go(AppRoutes.login);
      },
    );
  }
}

/// 성격별 섹션 헤더 (작은 캡션). 기존 시트 `_SheetSectionLabel` 이전.
class _CategorySectionLabel extends StatelessWidget {
  final String title;

  const _CategorySectionLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space4,
        AppSpacing.space3,
        AppSpacing.space4,
        AppSpacing.space1,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.inkTertiary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
