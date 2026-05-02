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
import '../../../lessons/presentation/providers/lesson_stats_provider.dart';
import '../../../students/presentation/providers/grouped_students_provider.dart';
import '../../../subscription/presentation/providers/subscription_providers.dart';
import '../../domain/entities/teacher_profile.dart';
import '../providers/teacher_extended_profile_provider.dart';

/// Profile tab with user info and settings — redesigned for 1-tap access.
///
/// Menu groups:
/// 1. 내 소개 — profile editing, instruments, credentials, preview
/// 2. 레슨 운영 — time, availability, policy, repertoire, templates
/// 3. 수강권·입금 — subscription templates, deposit status, bank account
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

          const SizedBox(height: AppSpacing.space3),

          // ⭐ 프로필 미리보기 CTA (profile_master.md §2.1 #2)
          _buildPreviewCta(context),

          const SizedBox(height: AppSpacing.space5),

          // Stats section (팔로워 → 입금 확인 대기)
          _buildStatsSection(ref, teacherId),

          const SizedBox(height: AppSpacing.space5),

          // ⭐ 프로필 완성도 게이지 (profile_master.md §2.2)
          _buildCompletionGauge(context, ref, profile, teacherId),

          // ⭐ 자주 쓰는 설정 (profile_master.md §2.3)
          _buildQuickShortcuts(context, teacherId),

          const SizedBox(height: AppSpacing.space5),

          // 💳 수강권·입금 (상단 이동 — 자주 쓰는 것 먼저)
          _buildMenuSection(
            title: '수강권·입금',
            items: [
              _MenuItem(
                icon: Icons.card_membership,
                label: '수강권 템플릿',
                subtitle: '수강권 종류 및 가격 설정',
                onTap: () => context.push(AppRoutes.subscriptionTemplates),
              ),
              _MenuItem(
                icon: Icons.warning_amber_outlined,
                label: '입금 확인 대기',
                subtitle: '입금 확인이 필요한 수강권',
                onTap: () => context.push(AppRoutes.outstandingPayments),
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
                onTap:
                    () => context.push(
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
                onTap:
                    () => context.push(
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
                label: AppStrings.feedbackTemplateMenuTitle,
                subtitle: AppStrings.feedbackTemplateMenuSubtitle,
                onTap: () => context.push(AppRoutes.feedbackTemplateManagement),
              ),
              _MenuItem(
                icon: Icons.tips_and_updates_outlined,
                label: '연습 팁 템플릿',
                subtitle: '학생에게 보내는 짧은 연습 팁',
                onTap: () => context.push(AppRoutes.tipTemplateManagement),
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
              _MenuItem(
                icon: Icons.article_outlined,
                label: '소식',
                subtitle: '팔로우한 선생님의 공지·이벤트',
                onTap: () => context.push(AppRoutes.followFeed),
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
                    color: AppColors.inkSecondary,
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
                labelColor: AppColors.paperAccent,
                onTap: () => _showLogoutDialog(context, ref),
              ),
            ],
          ),

          SizedBox(
            height:
                AppSpacing.space8 + MediaQuery.of(context).padding.bottom + 32,
          ),
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
                backgroundColor: AppColors.paperAccentSoft,
                child: Text(
                  name.isNotEmpty ? name[0] : '?',
                  style: AppTypography.headingLarge.copyWith(
                    color: AppColors.paperAccent,
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
                          color: AppColors.inkSecondary,
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
              children:
                  instruments
                      .map(
                        (inst) => Chip(
                          label: Text(
                            inst,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.paperAccent,
                            ),
                          ),
                          backgroundColor: AppColors.paperAccent.withValues(
                            alpha: 0.08,
                          ),
                          side: BorderSide.none,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                        ),
                      )
                      .toList(),
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
                color: AppColors.inkSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 프로필 미리보기 CTA (최상단 버튼).
  Widget _buildPreviewCta(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => context.push(AppRoutes.profilePreview),
          icon: const Icon(Icons.visibility_outlined, size: 18),
          label: const Text('내 프로필 미리보기'),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: AppColors.paperAccent),
            foregroundColor: AppColors.paperAccent,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.space3),
            shape: const RoundedRectangleBorder(),
          ),
        ),
      ),
    );
  }

  /// 프로필 완성도 게이지 (profile_master.md §2.2).
  ///
  /// 100% 미만일 때만 표시. 7가지 항목의 가중치 합산으로 완성도 계산.
  Widget _buildCompletionGauge(
    BuildContext context,
    WidgetRef ref,
    TeacherProfile? profile,
    String teacherId,
  ) {
    // 동일 provider. profile 인자와 동일하지만, 본 메서드에서 직접 사용.
    final extended = profile;

    final percent = _calculateCompletion(extended);
    if (percent >= 100) return const SizedBox.shrink();

    final nextStep = _nextCompletionStep(extended);

    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.screenPadding,
        right: AppSpacing.screenPadding,
        bottom: AppSpacing.space4,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          color: AppColors.paper,
          border: Border.all(color: AppColors.inkQuaternary),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '프로필 완성도',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$percent%',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.paperAccent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space2),
            ClipRRect(
              borderRadius: BorderRadius.zero,
              child: LinearProgressIndicator(
                value: percent / 100,
                minHeight: 6,
                backgroundColor: AppColors.inkQuaternary,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.paperAccent,
                ),
              ),
            ),
            if (nextStep != null) ...[
              const SizedBox(height: AppSpacing.space2),
              Text(
                '다음: $nextStep',
                style: AppTypography.caption.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 완성도 계산 (100%). profile_master.md §2.2 가중치 참조.
  int _calculateCompletion(TeacherProfile? profile) {
    if (profile == null) return 0;
    var score = 0;
    if (profile.profileImage != null) score += 20;
    if (profile.introduction.length >= 20) score += 20;
    if (profile.instruments.isNotEmpty) score += 15;
    // 가용시간/수강권템플릿/입금계좌는 별도 Provider 필요 — 단순 버전에서 생략
    // 확장 프로필 (경력 또는 학력 또는 자격증 중 하나 이상)
    final hasCareer = profile.career?.isNotEmpty ?? false;
    final hasEducation = profile.education?.isNotEmpty ?? false;
    final hasCert = profile.verification.certificates.isNotEmpty;
    if (hasCareer || hasEducation || hasCert) score += 10;
    // 최대 65% (나머지 3개 항목은 추후)
    // 사용자 체감상 0~65% 구간을 0~100% 스케일로 정규화
    return (score * 100 / 65).round().clamp(0, 100);
  }

  /// 다음 완성 단계 안내 메시지.
  String? _nextCompletionStep(TeacherProfile? profile) {
    if (profile == null) return null;
    if (profile.profileImage == null) return '프로필 사진을 등록해보세요';
    if (profile.introduction.length < 20) return '자기소개를 20자 이상 작성해보세요';
    if (profile.instruments.isEmpty) return '가르치는 악기를 추가해보세요';
    final hasAny =
        (profile.career?.isNotEmpty ?? false) ||
        (profile.education?.isNotEmpty ?? false) ||
        profile.verification.certificates.isNotEmpty;
    if (!hasAny) return '경력·학력·자격증을 등록해보세요';
    return null;
  }

  /// 자주 쓰는 설정 3개 카드 (가용시간 · 입금 확인 대기 · 수강권 템플릿).
  Widget _buildQuickShortcuts(BuildContext context, String teacherId) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Row(
        children: [
          Expanded(
            child: _ShortcutCard(
              icon: Icons.calendar_month,
              label: '가용시간',
              onTap: () => context.push(AppRoutes.teacherAvailability),
            ),
          ),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: _ShortcutCard(
              icon: Icons.warning_amber_outlined,
              label: '입금대기',
              onTap: () => context.push(AppRoutes.outstandingPayments),
            ),
          ),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: _ShortcutCard(
              icon: Icons.card_membership,
              label: '수강권',
              onTap: () => context.push(AppRoutes.subscriptionTemplates),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(WidgetRef ref, String teacherId) {
    final lessonStatsAsync = ref.watch(lessonStatsProvider);
    final groupsAsync = ref.watch(groupedStudentsProvider(teacherId));
    // 팔로워 → 입금 확인 대기로 교체 (profile_master.md §2.4)
    final unpaidSummaryAsync = ref.watch(unpaidSummaryProvider(teacherId));

    final studentCountValue =
        groupsAsync.whenOrNull(
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
    final unpaidValue =
        unpaidSummaryAsync.whenOrNull(
          data: (summary) => '${summary.studentCount}건',
        ) ??
        '-';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.paperAccent, AppColors.paperAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            _buildStatItem('학생', studentCountValue),
            _buildStatDivider(),
            _buildStatItem('이번 달 레슨', lessonCountValue),
            _buildStatDivider(),
            _buildStatItem('입금대기', unpaidValue),
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
            style: AppTypography.headingMedium.copyWith(color: AppColors.paper),
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.paper.withValues(alpha: 0.8),
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
      color: AppColors.paper.withValues(alpha: 0.3),
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
              color: AppColors.inkTertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          Container(
            decoration: BoxDecoration(
              color: AppColors.paper,
              boxShadow: [
                BoxShadow(
                  color: AppColors.ink.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children:
                  items.asMap().entries.map((entry) {
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
                            color: AppColors.inkQuaternary,
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
      borderRadius: BorderRadius.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space4),
        child: Row(
          children: [
            Icon(
              item.icon,
              size: 24,
              color: item.labelColor ?? AppColors.inkSecondary,
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: AppTypography.bodyLarge.copyWith(
                      color: item.labelColor ?? AppColors.ink,
                    ),
                  ),
                  if (item.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle!,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.inkTertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (item.trailing != null) item.trailing!,
            if (item.trailing == null)
              Icon(Icons.chevron_right, color: AppColors.inkTertiary),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('로그아웃'),
            content: const Text('정말 로그아웃 하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text(AppStrings.cancel),
              ),
              FilledButton(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  await ref.read(authNotifierProvider.notifier).logout();
                },
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

/// 프로필 탭 자주 쓰는 설정 바로가기 카드.
class _ShortcutCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ShortcutCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.zero,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.space4,
          horizontal: AppSpacing.space2,
        ),
        decoration: BoxDecoration(
          color: AppColors.paper,
          border: Border.all(color: AppColors.inkQuaternary),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: AppColors.paperAccent),
            const SizedBox(height: AppSpacing.space2),
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
