import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:lessonaza/core/widgets/notebook/thin_rule.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/notebook/notebook_masthead.dart';
import '../../../auth/auth_facade.dart';
import '../providers/student_home_profile_provider.dart';

/// Student profile tab with settings and account info
class StudentProfileTab extends ConsumerWidget {
  const StudentProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(studentHomeProfileProvider);

    return SingleChildScrollView(
      child: Column(
        children: [
          // Notebook masthead
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
            ),
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.space2),
                NotebookMasthead(
                  eyebrow: 'PROFILE',
                  meta:
                      'VOL. ${romanOf(DateTime.now().month - 1)} · NO. ${DateTime.now().day}',
                ),
              ],
            ),
          ),

          // Profile header
          _buildProfileHeader(
            context,
            name: profile.name,
            initial: profile.initial,
            email: profile.email,
            instrument: profile.instrument,
          ),

          const SizedBox(height: AppSpacing.space6),

          // Stats summary
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
            ),
            child: _buildStatsSummary(
              lessonCount: profile.lessonCountLabel,
              practiceTime: profile.practiceTimeLabel,
              period: profile.lessonPeriodLabel,
            ),
          ),

          const SizedBox(height: AppSpacing.space6),

          // Menu items
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
            ),
            child: _buildMenuSection(context, ref, profile),
          ),

          const SizedBox(height: AppSpacing.space6),

          // Settings
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
            ),
            child: _buildSettingsSection(context),
          ),

          const SizedBox(height: AppSpacing.space6),

          // Logout button
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
            ),
            child: _buildLogoutButton(context, ref),
          ),

          const SizedBox(height: AppSpacing.space8),

          // App version
          Text(
            '버전 1.0.0',
            style: AppTypography.caption.copyWith(color: AppColors.inkTertiary),
          ),

          const SizedBox(height: AppSpacing.space6),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context, {
    required String name,
    required String initial,
    required String email,
    required String instrument,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space6),
      decoration: const BoxDecoration(color: AppColors.paper),
      child: Column(
        children: [
          // Profile image
          Stack(
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: AppColors.paperAccentSoft,
                child: Text(
                  initial,
                  style: AppTypography.displayMedium.copyWith(
                    color: AppColors.paperAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: () => context.push(AppRoutes.profileEdit),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: AppColors.paperDark),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 16,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.space3),

          // Name
          Text(
            name,
            style: AppTypography.headingLarge.copyWith(color: AppColors.ink),
          ),

          const SizedBox(height: AppSpacing.space1),

          // Email
          Text(
            email,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),

          const SizedBox(height: AppSpacing.space2),

          // Instrument tag
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space3,
              vertical: AppSpacing.space2,
            ),
            decoration: BoxDecoration(color: AppColors.paperDark),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.music_note, size: 16, color: AppColors.ink),
                const SizedBox(width: AppSpacing.space1),
                Text(
                  instrument,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSummary({
    String? lessonCount,
    String? practiceTime,
    String? period,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Row(
        children: [
          _buildStatItem('레슨 받은 횟수', lessonCount ?? '-'),
          _buildDivider(),
          _buildStatItem('총 연습 시간', practiceTime ?? '-'),
          _buildDivider(),
          _buildStatItem('레슨 기간', period ?? '-'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: AppTypography.headingMedium.copyWith(color: AppColors.ink),
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.inkSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 40, color: AppColors.inkQuaternary);
  }

  Widget _buildMenuSection(
    BuildContext context,
    WidgetRef ref,
    StudentHomeProfileState profile,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.school_outlined,
            title: AppStrings.studentHomeMenuMyTeachers,
            subtitle: profile.teacherSubtitle,
            onTap: () => context.push(AppRoutes.myTeachers),
          ),
          // #P1 — "내 레슨 요청" moved to the top of the 레슨 탭 (was a
          // duplicate entry point; 진행 중인 신청 there also links to the
          // same AllLessonRequestsScreen via AppRoutes.myLessonRequests).
          _buildMenuDivider(),
          _buildMenuItem(
            icon: Icons.library_music_outlined,
            title: AppStrings.studentHomeMenuRepertoire,
            subtitle:
                profile.repertoireCount != null
                    ? '${profile.repertoireCount}곡 진행 중'
                    : null,
            onTap:
                () => context.push(
                  '${AppRoutes.practiceRepertoire}?studentId=${profile.studentId}',
                ),
          ),
          _buildMenuDivider(),
          _buildMenuItem(
            icon: Icons.history,
            title: AppStrings.studentHomeMenuPracticeHistory,
            onTap:
                () => context.push(
                  '${AppRoutes.repertoireHistory}?studentId=${profile.studentId}',
                ),
          ),
          _buildMenuDivider(),
          _buildMenuItem(
            icon: Icons.headphones_outlined,
            title: AppStrings.studentHomeMenuRecordings,
            subtitle: AppStrings.studentHomeMenuRecordingsSubtitle,
            onTap: () => context.push(AppRoutes.allRecordings),
          ),
          _buildMenuDivider(),
          _buildMenuItem(
            icon: Icons.family_restroom,
            iconColor: AppColors.paperAccent,
            title: AppStrings.studentHomeMenuParentInvite,
            subtitle: AppStrings.studentHomeMenuParentInviteSubtitle,
            onTap: () => _showInviteCodeDialog(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: _buildMenuItem(
        icon: Icons.settings_outlined,
        title: AppStrings.studentHomeSettingsTitle,
        onTap: () => context.push(AppRoutes.studentSettingsHub),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    Color? iconColor,
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
              decoration: BoxDecoration(
                color: iconColor?.withValues(alpha: 0.1) ?? AppColors.paperDark,
              ),
              child: Icon(
                icon,
                size: 20,
                color: iconColor ?? AppColors.inkSecondary,
              ),
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
            if (trailing != null)
              trailing
            else
              Icon(Icons.chevron_right, color: AppColors.inkTertiary),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuDivider() {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.space4 + 36 + AppSpacing.space3,
      ),
      child: const ThinRule(),
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _showLogoutDialog(context, ref),
        icon: Icon(Icons.logout, color: AppColors.paperAccent),
        label: Text(
          AppStrings.studentHomeLogout,
          style: TextStyle(color: AppColors.paperAccent),
        ),
        // §7.132: paperAccent.alpha border → solid paperAccent.
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.space4),
          side: const BorderSide(color: AppColors.paperAccent),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showNotebookDialog(
      context: context,
      titleWidget: const Text(AppStrings.studentHomeLogout),
      content: const Text(AppStrings.studentHomeLogoutConfirm),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(AppStrings.cancel),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(context);
            await ref.read(authNotifierProvider.notifier).logout();
            // Explicit nav after logout (redirect is a secondary safety net).
            if (context.mounted) context.go(AppRoutes.login);
          },
          child: Text(
            AppStrings.studentHomeLogout,
            style: const TextStyle(color: AppColors.paperAccent),
          ),
        ),
      ],
    );
  }

  Future<void> _showInviteCodeDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final inviteCode =
        await ref
            .read(studentHomeProfileActionsProvider)
            .createParentInvitationCode();
    if (!context.mounted) return;

    showNotebookDialog(
      context: context,
      titleWidget: const Text(AppStrings.studentHomeParentInviteCodeTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppStrings.studentHomeParentInviteMessage,
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.space4),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space5,
              vertical: AppSpacing.space4,
            ),
            decoration: BoxDecoration(
              color: AppColors.paperAccentSoft,
              border: Border.all(color: AppColors.paperAccent),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children:
                  inviteCode.split('').map((digit) {
                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.space1,
                      ),
                      child: Text(
                        digit,
                        style: AppTypography.headingLarge.copyWith(
                          color: AppColors.paperAccent,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          Text(
            '이 코드를 학부모님께 전달해주세요.\n학부모님이 앱에서 코드를 입력하면\n연결됩니다.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.inkSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            AppStrings.inviteParentValidityNote,
            style: AppTypography.caption.copyWith(color: AppColors.inkTertiary),
          ),
        ],
      ),
      actions: [
        TextButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: inviteCode));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(AppStrings.studentHomeInviteCodeCopied),
                duration: Duration(seconds: 2),
              ),
            );
          },
          icon: const Icon(Icons.copy, size: 18),
          label: const Text(AppStrings.studentHomeCopyAction),
        ),
        FilledButton.icon(
          onPressed: () {
            SharePlus.instance.share(
              ShareParams(
                text: AppStrings.inviteParentShareMessageFormat(inviteCode),
              ),
            );
          },
          icon: const Icon(Icons.share, size: 18),
          label: const Text(AppStrings.studentHomeShareAction),
        ),
      ],
    );
  }
}
