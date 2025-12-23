import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Profile tab with user info and settings
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.space4),

          // Profile header
          _buildProfileHeader(context),

          const SizedBox(height: AppSpacing.space6),

          // Stats section
          _buildStatsSection(),

          const SizedBox(height: AppSpacing.space6),

          // Menu sections
          _buildMenuSection(
            title: '레슨 관리',
            items: [
              _MenuItem(
                icon: Icons.music_note,
                label: '악기 관리',
                onTap: () => context.push(AppRoutes.instrumentManagement),
              ),
              _MenuItem(
                icon: Icons.library_music,
                label: '레퍼토리 관리',
                onTap: () => context.push(AppRoutes.repertoireManagement),
              ),
              _MenuItem(
                icon: Icons.schedule,
                label: '레슨 시간 설정',
                onTap: () => context.push(AppRoutes.lessonTimeSettings),
              ),
              _MenuItem(
                icon: Icons.event_note,
                label: '예약 관리',
                onTap: () => context.push(AppRoutes.bookingList),
              ),
              _MenuItem(
                icon: Icons.pending_actions,
                label: '승인 대기 목록',
                onTap: () => context.push(AppRoutes.pendingBookings),
              ),
              _MenuItem(
                icon: Icons.payments_outlined,
                label: '수강료 관리',
                onTap: () => context.push(AppRoutes.paymentManagement),
              ),
              _MenuItem(
                icon: Icons.library_books_outlined,
                label: '템플릿 관리',
                onTap: () => context.push(AppRoutes.tipTemplateManagement),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.space4),

          _buildMenuSection(
            title: '설정',
            items: [
              _MenuItem(
                icon: Icons.notifications_outlined,
                label: '알림 설정',
                trailing: _buildSwitch(true),
                onTap: () {},
              ),
              _MenuItem(
                icon: Icons.dark_mode_outlined,
                label: '다크 모드',
                trailing: _buildSwitch(false),
                onTap: () {},
              ),
              _MenuItem(
                icon: Icons.language,
                label: '언어',
                trailing: Text(
                  '한국어',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                onTap: () {},
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.space4),

          _buildMenuSection(
            title: '지원',
            items: [
              _MenuItem(
                icon: Icons.help_outline,
                label: '도움말',
                onTap: () {},
              ),
              _MenuItem(
                icon: Icons.feedback_outlined,
                label: '피드백 보내기',
                onTap: () {},
              ),
              _MenuItem(
                icon: Icons.info_outline,
                label: '앱 정보',
                trailing: Text(
                  'v1.0.0',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                onTap: () {},
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.space4),

          _buildMenuSection(
            title: '계정',
            items: [
              _MenuItem(
                icon: Icons.description_outlined,
                label: '이용약관',
                onTap: () {},
              ),
              _MenuItem(
                icon: Icons.privacy_tip_outlined,
                label: '개인정보처리방침',
                onTap: () {},
              ),
              _MenuItem(
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
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Row(
        children: [
          // Profile avatar
          Stack(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  '김',
                  style: AppTypography.headingLarge.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: AppSpacing.space4),

          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '김선생님',
                      style: AppTypography.headingLarge,
                    ),
                    const SizedBox(width: AppSpacing.space2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '선생님',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space1),
                Text(
                  'teacher@example.com',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),

          // Edit button
          IconButton(
            onPressed: () {
              // TODO: Navigate to edit profile
            },
            icon: const Icon(Icons.edit_outlined),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.primaryDark,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        ),
        child: Row(
          children: [
            _buildStatItem('학생', '6명'),
            _buildStatDivider(),
            _buildStatItem('이번 달 레슨', '24회'),
            _buildStatDivider(),
            _buildStatItem('평균 연습률', '72%'),
          ],
        ),
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
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.white.withValues(alpha: 0.3),
    );
  }

  Widget _buildMenuSection({
    required String title,
    required List<_MenuItem> items,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiaryLight,
              fontWeight: FontWeight.w600,
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
              children: items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isLast = index == items.length - 1;

                return Column(
                  children: [
                    _buildMenuItem(item),
                    if (!isLast)
                      Divider(
                        height: 1,
                        indent: AppSpacing.space4 + 24 + AppSpacing.space3,
                        color: AppColors.borderLight,
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(_MenuItem item) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space4),
        child: Row(
          children: [
            Icon(
              item.icon,
              size: 24,
              color: item.labelColor ?? AppColors.textSecondaryLight,
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Text(
                item.label,
                style: AppTypography.bodyLarge.copyWith(
                  color: item.labelColor ?? AppColors.textPrimaryLight,
                ),
              ),
            ),
            if (item.trailing != null) item.trailing!,
            if (item.trailing == null)
              Icon(
                Icons.chevron_right,
                color: AppColors.textTertiaryLight,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitch(bool value) {
    return Switch(
      value: value,
      onChanged: (_) {},
      activeColor: AppColors.primary,
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
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.go(AppRoutes.login);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final Color? labelColor;
  final Widget? trailing;
  final VoidCallback onTap;

  _MenuItem({
    required this.icon,
    required this.label,
    this.labelColor,
    this.trailing,
    required this.onTap,
  });
}
