import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_state.dart';
import '../../../../core/config/environment.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/providers/user_role_provider.dart';
import '../../../follow/presentation/providers/follow_providers.dart';
import '../../../lessons/presentation/providers/lesson_stats_provider.dart';
import '../../../students/presentation/providers/grouped_students_provider.dart';
import '../providers/teacher_extended_profile_provider.dart';

/// Profile tab with user info and settings — redesigned for 1-tap access.
///
/// Menu groups:
/// 1. 내 소개 — profile editing, instruments, credentials, preview
/// 2. 레슨 운영 — time, availability, policy, repertoire, templates
/// 3. 수강권·결제 — subscription templates, outstanding, history
/// 4. 설정 — notifications, recordings, visibility
/// 5. 지원 — help, app info
/// 6. 계정 — terms, privacy, logout
class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final authName = authState is AuthAuthenticated ? authState.name : '';
    final email = authState is AuthAuthenticated ? authState.email : '';
    final teacherId = ref.watch(currentUserIdProvider);

    // Profile name takes priority over auth name (editable in BasicInfoEdit)
    final profileState = ref.watch(teacherExtendedProfileProvider);
    final profile = profileState.valueOrNull;
    final name = profile?.name ?? authName;
    final introduction = profile?.introduction;
    final instruments = profile?.instruments ?? [];

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.space4),

          // Profile header with key info
          _buildProfileHeader(name, email, introduction, instruments),

          const SizedBox(height: AppSpacing.space6),

          // Stats section
          _buildStatsSection(ref, teacherId),

          const SizedBox(height: AppSpacing.space6),

          // 내 소개
          _buildMenuSection(
            title: '내 소개',
            items: [
              _MenuItem(
                icon: Icons.person_outline,
                label: '기본 정보 수정',
                subtitle: '이름, 사진, 소개, 교수 스타일, 활동 지역',
                onTap: () => context.push(AppRoutes.basicInfoEdit),
              ),
              _MenuItem(
                icon: Icons.music_note,
                label: '악기 관리',
                subtitle: '가르치는 악기 추가/관리',
                onTap: () => context.push(AppRoutes.instrumentManagement),
              ),
              _MenuItem(
                icon: Icons.school_outlined,
                label: '학력·경력·자격증',
                subtitle: '교육 배경 및 경력 사항',
                onTap: () => context.push(AppRoutes.extendedProfile),
              ),
              _MenuItem(
                icon: Icons.visibility_outlined,
                label: '프로필 미리보기',
                subtitle: '학생에게 보이는 내 프로필',
                onTap: () => context.push(AppRoutes.profilePreview),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.space4),

          // 레슨 운영
          _buildMenuSection(
            title: '레슨 운영',
            items: [
              _MenuItem(
                icon: Icons.assignment,
                label: AppStrings.lessonRequestManagement,
                subtitle: AppStrings.lessonRequestManagementDesc,
                onTap: () => context.push(
                  '${AppRoutes.lessonRequests}?teacherId=$teacherId',
                ),
              ),
              _MenuItem(
                icon: Icons.access_time,
                label: '레슨 시간 설정',
                subtitle: '시간 길이, 쉬는시간, 시작 간격',
                onTap: () => context.push(AppRoutes.lessonTimeSettings),
              ),
              _MenuItem(
                icon: Icons.calendar_month,
                label: '가용 시간 관리',
                subtitle: '주간 스케줄, 휴무, 예외 시간',
                onTap: () => context.push(AppRoutes.teacherAvailability),
              ),
              _MenuItem(
                icon: Icons.shield_outlined,
                label: '취소/노쇼 정책',
                subtitle: '변경 횟수, 취소 기한, 노쇼 처리',
                onTap: () => context.push(
                  '${AppRoutes.lessonPolicy}?teacherId=$teacherId',
                ),
              ),
              _MenuItem(
                icon: Icons.library_music,
                label: '레퍼토리 관리',
                subtitle: '교재 및 곡 목록',
                onTap: () => context.push(AppRoutes.repertoireManagement),
              ),
              _MenuItem(
                icon: Icons.chat_outlined,
                label: '피드백 템플릿',
                subtitle: '자주 쓰는 레슨 피드백 문구',
                onTap: () => context.push(AppRoutes.tipTemplateManagement),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.space4),

          // 수강권·결제
          _buildMenuSection(
            title: '수강권·결제',
            items: [
              _MenuItem(
                icon: Icons.card_membership,
                label: '수강권 템플릿',
                subtitle: '수강권 종류 및 가격 설정',
                onTap: () => context.push(AppRoutes.subscriptionTemplates),
              ),
              _MenuItem(
                icon: Icons.warning_amber_outlined,
                label: '미수금 관리',
                subtitle: '결제 대기 중인 수강권',
                onTap: () => context.push(AppRoutes.outstandingPayments),
              ),
              _MenuItem(
                icon: Icons.receipt_long_outlined,
                label: '결제 내역',
                subtitle: '전체 결제 이력 확인',
                onTap: () => context.push(AppRoutes.paymentManagement),
              ),
              _MenuItem(
                icon: Icons.account_balance_outlined,
                label: '입금 계좌',
                subtitle: '수강료 입금받을 계좌 설정',
                onTap: () => context.push(AppRoutes.bankAccountEdit),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.space4),

          // 소셜
          _buildMenuSection(
            title: '소셜',
            items: [
              _MenuItem(
                icon: Icons.people_outline,
                label: '팔로잉',
                subtitle: '팔로우한 선생님·학원 관리',
                onTap: () => context.push(AppRoutes.followList),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.space4),

          // 설정
          _buildMenuSection(
            title: '설정',
            items: [
              _MenuItem(
                icon: Icons.notifications_outlined,
                label: '알림 설정',
                onTap: () => context.push(AppRoutes.notificationSettings),
              ),
              _MenuItem(
                icon: Icons.mic_outlined,
                label: '녹음 관리',
                onTap: () => context.push(AppRoutes.allRecordings),
              ),
              _MenuItem(
                icon: Icons.lock_outlined,
                label: '공개 설정',
                subtitle: '프로필 항목별 공개/비공개',
                onTap: () => context.push(AppRoutes.profileVisibility),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.space4),

          // 지원
          _buildMenuSection(
            title: '지원',
            items: [
              _MenuItem(
                icon: Icons.help_outline,
                label: '도움말',
                onTap: () => context.push(AppRoutes.help),
              ),
              _MenuItem(
                icon: Icons.info_outline,
                label: '앱 정보',
                trailing: Text(
                  'v${EnvironmentConfig.appVersion}',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                onTap: () => context.push(AppRoutes.appInfo),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.space4),

          // 계정
          _buildMenuSection(
            title: '계정',
            items: [
              _MenuItem(
                icon: Icons.description_outlined,
                label: '이용약관',
                onTap: () => context.push(AppRoutes.termsOfService),
              ),
              _MenuItem(
                icon: Icons.privacy_tip_outlined,
                label: '개인정보처리방침',
                onTap: () => context.push(AppRoutes.privacyPolicy),
              ),
              _MenuItem(
                icon: Icons.logout,
                label: '로그아웃',
                labelColor: AppColors.error,
                onTap: () => _showLogoutDialog(context, ref),
              ),
            ],
          ),

          SizedBox(height: AppSpacing.space8 + MediaQuery.of(context).padding.bottom + 32),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(
    String name,
    String email,
    String? introduction,
    List<String> instruments,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  name.isNotEmpty ? name[0] : '?',
                  style: AppTypography.headingLarge.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.space4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppTypography.headingMedium),
                    if (email.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          // Instruments chips
          if (instruments.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.space3),
            Wrap(
              spacing: AppSpacing.space2,
              runSpacing: AppSpacing.space1,
              children: instruments.map((inst) => Chip(
                label: Text(
                  inst,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                side: BorderSide.none,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              )).toList(),
            ),
          ],
          // Introduction
          if (introduction != null && introduction.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.space2),
            Text(
              introduction,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsSection(WidgetRef ref, String teacherId) {
    final lessonStatsAsync = ref.watch(lessonStatsProvider);
    final groupsAsync = ref.watch(groupedStudentsProvider(teacherId));
    final followerCountAsync = ref.watch(followerCountProvider(teacherId));

    final studentCountValue = groupsAsync.whenOrNull(
          data: (groups) {
            final total = groups.fold(0, (sum, g) => sum + g.students.length);
            return '$total명';
          },
        ) ??
        '-';
    final lessonCountValue =
        lessonStatsAsync.whenOrNull(
          data: (stats) => '${stats['completed'] ?? 0}회',
        ) ??
        '-';
    final followerCountValue = followerCountAsync.whenOrNull(
          data: (count) => '$count명',
        ) ??
        '-';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        ),
        child: Row(
          children: [
            _buildStatItem('학생', studentCountValue),
            _buildStatDivider(),
            _buildStatItem('이번 달 레슨', lessonCountValue),
            _buildStatDivider(),
            _buildStatItem('팔로워', followerCountValue),
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
            style: AppTypography.headingMedium.copyWith(color: Colors.white),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: AppTypography.bodyLarge.copyWith(
                      color: item.labelColor ?? AppColors.textPrimaryLight,
                    ),
                  ),
                  if (item.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle!,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textTertiaryLight,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (item.trailing != null) item.trailing!,
            if (item.trailing == null)
              Icon(Icons.chevron_right, color: AppColors.textTertiaryLight),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await ref.read(authNotifierProvider.notifier).logout();
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
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
  final String? subtitle;
  final Color? labelColor;
  final Widget? trailing;
  final VoidCallback onTap;

  _MenuItem({
    required this.icon,
    required this.label,
    this.subtitle,
    this.labelColor,
    this.trailing,
    required this.onTap,
  });
}
