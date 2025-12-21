import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Student profile tab with settings and account info
class StudentProfileTab extends StatelessWidget {
  const StudentProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Profile header
          _buildProfileHeader(context),

          const SizedBox(height: AppSpacing.space6),

          // Stats summary
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding),
            child: _buildStatsSummary(),
          ),

          const SizedBox(height: AppSpacing.space6),

          // Menu items
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding),
            child: _buildMenuSection(context),
          ),

          const SizedBox(height: AppSpacing.space6),

          // Settings
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding),
            child: _buildSettingsSection(context),
          ),

          const SizedBox(height: AppSpacing.space6),

          // Logout button
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding),
            child: _buildLogoutButton(context),
          ),

          const SizedBox(height: AppSpacing.space8),

          // App version
          Text(
            '버전 1.0.0',
            style: AppTypography.caption.copyWith(
              color: AppColors.textTertiaryLight,
            ),
          ),

          const SizedBox(height: AppSpacing.space6),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Profile image
            Stack(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: Text(
                    '홍',
                    style: AppTypography.displayMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.space3),

            // Name
            Text(
              '홍길동',
              style: AppTypography.headingLarge.copyWith(
                color: Colors.white,
              ),
            ),

            const SizedBox(height: AppSpacing.space1),

            // Email
            Text(
              'student@example.com',
              style: AppTypography.bodyMedium.copyWith(
                color: Colors.white70,
              ),
            ),

            const SizedBox(height: AppSpacing.space2),

            // Instrument tag
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.music_note,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '바이올린',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSummary() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
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
      child: Row(
        children: [
          _buildStatItem('레슨 받은 횟수', '24회'),
          _buildDivider(),
          _buildStatItem('총 연습 시간', '86시간'),
          _buildDivider(),
          _buildStatItem('레슨 기간', '6개월'),
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
            style: AppTypography.headingMedium.copyWith(
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 40,
      color: AppColors.borderLight,
    );
  }

  Widget _buildMenuSection(BuildContext context) {
    return Container(
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
          _buildMenuItem(
            icon: Icons.person_outline,
            title: '프로필 수정',
            onTap: () {},
          ),
          _buildMenuDivider(),
          _buildMenuItem(
            icon: Icons.school_outlined,
            title: '내 선생님',
            subtitle: '김선생님',
            onTap: () {},
          ),
          _buildMenuDivider(),
          _buildMenuItem(
            icon: Icons.library_music_outlined,
            title: '레퍼토리',
            subtitle: '3곡 진행 중',
            onTap: () {},
          ),
          _buildMenuDivider(),
          _buildMenuItem(
            icon: Icons.history,
            title: '연습 기록 내역',
            onTap: () {},
          ),
          _buildMenuDivider(),
          _buildMenuItem(
            icon: Icons.headphones_outlined,
            title: '레슨 녹음 파일',
            subtitle: '12개 저장됨',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return Container(
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
          _buildMenuItem(
            icon: Icons.notifications_outlined,
            title: '알림 설정',
            trailing: Switch(
              value: true,
              onChanged: (value) {},
              activeColor: AppColors.primary,
            ),
            onTap: () {},
          ),
          _buildMenuDivider(),
          _buildMenuItem(
            icon: Icons.alarm_outlined,
            title: '연습 리마인더',
            subtitle: '매일 오후 5시',
            onTap: () {},
          ),
          _buildMenuDivider(),
          _buildMenuItem(
            icon: Icons.dark_mode_outlined,
            title: '다크 모드',
            trailing: Switch(
              value: false,
              onChanged: (value) {},
              activeColor: AppColors.primary,
            ),
            onTap: () {},
          ),
          _buildMenuDivider(),
          _buildMenuItem(
            icon: Icons.language_outlined,
            title: '언어',
            subtitle: '한국어',
            onTap: () {},
          ),
          _buildMenuDivider(),
          _buildMenuItem(
            icon: Icons.help_outline,
            title: '도움말',
            onTap: () {},
          ),
          _buildMenuDivider(),
          _buildMenuItem(
            icon: Icons.info_outline,
            title: '앱 정보',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: AppColors.textSecondaryLight,
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
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null)
              trailing
            else
              Icon(
                Icons.chevron_right,
                color: AppColors.textTertiaryLight,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuDivider() {
    return Divider(
      height: 1,
      indent: AppSpacing.space4 + 36 + AppSpacing.space3,
      color: AppColors.borderLight,
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _showLogoutDialog(context),
        icon: Icon(Icons.logout, color: AppColors.error),
        label: Text(
          '로그아웃',
          style: TextStyle(color: AppColors.error),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.space4),
          side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go(AppRoutes.login);
            },
            child: Text(
              '로그아웃',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
