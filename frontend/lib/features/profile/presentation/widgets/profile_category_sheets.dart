// W2 Task 2.4 — 복합 카테고리 BottomSheet 헬퍼.
// spec §3 (IA) + §7.2 (메인 홈) + ux-rules.md (BottomSheet 다중 액션 패턴).
//
// 단일 묶음은 CategoryMenuGrid 에서 직접 라우트 push.
// 복합 묶음 (수강권·정산, 정책·알림·지원) 만 본 헬퍼의 BottomSheet 로 분기.

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
import '../../../../core/widgets/notebook/notebook_bottom_sheet.dart';
import '../../../../core/widgets/notebook/thin_rule.dart';
import '../../../auth/auth_facade.dart';

/// 💰 수강권·정산 BottomSheet — 수강권 템플릿/입금대기/입금 계좌/취소 정책.
void showSubscriptionBillingSheet(BuildContext context, String teacherId) {
  showNotebookModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _SheetHeader(
              title: AppStrings.categorySheetSubscriptionBillingTitle,
            ),
            ListTile(
              leading: const Icon(Icons.card_membership),
              title: const Text(AppStrings.profileSubscriptionTemplateLabel),
              subtitle: const Text(
                AppStrings.profileSubscriptionTemplateSubtitle,
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                context.push(AppRoutes.subscriptionTemplates);
              },
            ),
            ListTile(
              leading: const Icon(Icons.warning_amber_outlined),
              title: const Text(AppStrings.profileOutstandingPaymentsLabel),
              subtitle: const Text(
                AppStrings.profileOutstandingPaymentsSubtitle,
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                context.push(AppRoutes.outstandingPayments);
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_outlined),
              title: const Text(AppStrings.profileBankAccountLabel),
              subtitle: const Text(AppStrings.profileBankAccountSubtitle),
              onTap: () {
                Navigator.pop(sheetContext);
                context.push(AppRoutes.bankAccountEdit);
              },
            ),
            ListTile(
              leading: const Icon(Icons.shield_outlined),
              title: const Text(AppStrings.profileCancelPolicyLabel),
              subtitle: const Text(AppStrings.profileCancelPolicySubtitle),
              onTap: () {
                Navigator.pop(sheetContext);
                context.push('${AppRoutes.lessonPolicy}?teacherId=$teacherId');
              },
            ),
            ListTile(
              leading: const Icon(Icons.event_busy_outlined),
              title: const Text(AppStrings.profileCancellationDefaultsLabel),
              subtitle: const Text(
                AppStrings.profileCancellationDefaultsSubtitle,
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                context.push(AppRoutes.cancellationDefaults);
              },
            ),
          ],
        ),
      );
    },
  );
}

/// ⚙️ 정책·알림·지원 BottomSheet — 템플릿/알림/녹음/공개/지원/계정/로그아웃.
void showPolicyNotificationsSheet(BuildContext context, WidgetRef ref) {
  showNotebookModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) {
      return SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _SheetHeader(
                title: AppStrings.categorySheetPolicyNotificationsTitle,
              ),
              ListTile(
                leading: const Icon(Icons.chat_outlined),
                title: const Text(AppStrings.feedbackTemplateMenuTitle),
                subtitle: const Text(AppStrings.feedbackTemplateMenuSubtitle),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.push(AppRoutes.feedbackTemplateManagement);
                },
              ),
              ListTile(
                leading: const Icon(Icons.tips_and_updates_outlined),
                title: const Text(AppStrings.profileTipTemplateLabel),
                subtitle: const Text(AppStrings.profileTipTemplateSubtitle),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.push(AppRoutes.tipTemplateManagement);
                },
              ),
              ListTile(
                leading: const Icon(Icons.notifications_outlined),
                title: const Text(AppStrings.profileNotificationLabel),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.push(AppRoutes.notificationSettings);
                },
              ),
              ListTile(
                leading: const Icon(Icons.mic_outlined),
                title: const Text(AppStrings.profileRecordingLabel),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.push(AppRoutes.allRecordings);
                },
              ),
              ListTile(
                leading: const Icon(Icons.lock_outlined),
                title: const Text(AppStrings.profileVisibilityLabel),
                subtitle: const Text(AppStrings.profileVisibilitySubtitleLabel),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.push(AppRoutes.profileVisibility);
                },
              ),
              ListTile(
                leading: const Icon(Icons.campaign_outlined),
                title: const Text(AppStrings.newsRoadmapTitle),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.push(AppRoutes.newsRoadmap);
                },
              ),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text(AppStrings.profileHelpLabel),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.push(AppRoutes.help);
                },
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
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.push(AppRoutes.appInfo);
                },
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.space4),
                child: ThinRule(),
              ),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text(AppStrings.profileTermsLabel),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.push(AppRoutes.termsOfService);
                },
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text(AppStrings.profilePrivacyPolicyLabel),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.push(AppRoutes.privacyPolicy);
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.paperAccent),
                title: Text(
                  AppStrings.profileLogoutLabel,
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.paperAccent,
                  ),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showLogoutDialog(context, ref);
                },
              ),
            ],
          ),
        ),
      );
    },
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

/// 5묶음 BottomSheet 상단 제목.
class _SheetHeader extends StatelessWidget {
  final String title;

  const _SheetHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space3,
      ),
      child: Row(
        children: [
          Text(
            title,
            style: AppTypography.headingSmall.copyWith(color: AppColors.ink),
          ),
        ],
      ),
    );
  }
}
