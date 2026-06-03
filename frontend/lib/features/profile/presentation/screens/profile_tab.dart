import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_alert_dialog.dart';

import '../../../../core/auth/auth_state.dart';
import '../../../../core/config/environment.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/notebook/notebook_masthead.dart';
import '../../../../core/widgets/notebook/thin_rule.dart';
import '../../../auth/auth_facade.dart';
import '../../../billing/billing_facade.dart';
import '../../../lessons/lessons_facade.dart';
import '../../../students/students_facade.dart';
import '../../../subscription/subscription_facade.dart';
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
                  trailing: IconButton(
                    onPressed:
                        () => context.push(AppRoutes.notificationSettings),
                    icon: const Icon(
                      Icons.settings_outlined,
                      color: AppColors.ink,
                      size: 22,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.space4),

          // Profile header with key info
          _buildProfileHeader(name, email, introduction, instruments),

          const SizedBox(height: AppSpacing.space3),

          // ⭐ 프로필 미리보기 CTA (profile_master.md §2.1 #2)
          _buildPreviewCta(context),

          const SizedBox(height: AppSpacing.space5),

          // Stats section (팔로워 → 입금대기(후불))
          _buildStatsSection(ref, teacherId),

          const SizedBox(height: AppSpacing.space5),

          // ⏳ Lifetime 얼리어답터 프로모 배너 (paywall_spec.md §1, §6.2)
          //    snapshot.lifetimeOfferActive 일 때만 노출. 백엔드가 종료시각을
          //    채우기 전까지는 SizedBox.shrink (자동 graceful degradation).
          _buildLifetimePromoBanner(context, ref),

          // 💳 구독 상태 카드 (paywall_spec.md §6.2 — #415 R4 Phase C2)
          _buildSubscriptionStatusCard(context, ref),

          const SizedBox(height: AppSpacing.space5),

          // ⭐ 프로필 완성도 게이지 (profile_master.md §2.2)
          _buildCompletionGauge(context, ref, profile, teacherId),

          // ⭐ 자주 쓰는 설정 (profile_master.md §2.3)
          _buildQuickShortcuts(context, teacherId),

          const SizedBox(height: AppSpacing.space5),

          // 💳 수강권·입금 (상단 이동 — 자주 쓰는 것 먼저)
          _buildMenuSection(
            title: AppStrings.profileSectionSubscriptionPayment,
            items: [
              _MenuItem(
                icon: Icons.card_membership,
                label: AppStrings.profileSubscriptionTemplateLabel,
                subtitle: AppStrings.profileSubscriptionTemplateSubtitle,
                onTap: () => context.push(AppRoutes.subscriptionTemplates),
              ),
              _MenuItem(
                icon: Icons.warning_amber_outlined,
                label: AppStrings.profileOutstandingPaymentsLabel,
                subtitle: AppStrings.profileOutstandingPaymentsSubtitle,
                onTap: () => context.push(AppRoutes.outstandingPayments),
              ),
              _MenuItem(
                icon: Icons.account_balance_outlined,
                label: AppStrings.profileBankAccountLabel,
                subtitle: AppStrings.profileBankAccountSubtitle,
                onTap: () => context.push(AppRoutes.bankAccountEdit),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.space4),

          // 내 소개
          _buildMenuSection(
            title: AppStrings.profileSectionAboutMe,
            items: [
              _MenuItem(
                icon: Icons.person_outline,
                label: AppStrings.profileBasicInfoEditLabel,
                subtitle: AppStrings.profileBasicInfoEditSubtitle,
                onTap: () => context.push(AppRoutes.basicInfoEdit),
              ),
              _MenuItem(
                icon: Icons.music_note,
                label: AppStrings.profileInstrumentManagementLabel,
                subtitle: AppStrings.profileInstrumentManagementSubtitle,
                onTap: () => context.push(AppRoutes.instrumentManagement),
              ),
              _MenuItem(
                icon: Icons.school_outlined,
                label: AppStrings.profileCredentialsLabel,
                subtitle: AppStrings.profileCredentialsSubtitle,
                onTap: () => context.push(AppRoutes.extendedProfile),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.space4),

          // 레슨 운영
          _buildMenuSection(
            title: AppStrings.profileSectionLessonOperation,
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
                label: AppStrings.profileLessonTimeSettingsLabel,
                subtitle: AppStrings.profileLessonTimeSettingsSubtitle,
                onTap: () => context.push(AppRoutes.lessonTimeSettings),
              ),
              _MenuItem(
                icon: Icons.calendar_month,
                label: AppStrings.profileAvailabilityLabel,
                subtitle: AppStrings.profileAvailabilitySubtitle,
                onTap: () => context.push(AppRoutes.teacherAvailability),
              ),
              _MenuItem(
                icon: Icons.shield_outlined,
                label: AppStrings.profileCancelPolicyLabel,
                subtitle: AppStrings.profileCancelPolicySubtitle,
                onTap:
                    () => context.push(
                      '${AppRoutes.lessonPolicy}?teacherId=$teacherId',
                    ),
              ),
              _MenuItem(
                icon: Icons.event_busy_outlined,
                label: AppStrings.profileCancellationDefaultsLabel,
                subtitle: AppStrings.profileCancellationDefaultsSubtitle,
                onTap: () => context.push(AppRoutes.cancellationDefaults),
              ),
              _MenuItem(
                icon: Icons.library_music,
                label: AppStrings.profileRepertoireLabel,
                subtitle: AppStrings.profileRepertoireSubtitle,
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
                label: AppStrings.profileTipTemplateLabel,
                subtitle: AppStrings.profileTipTemplateSubtitle,
                onTap: () => context.push(AppRoutes.tipTemplateManagement),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.space4),

          // 소셜
          _buildMenuSection(
            title: AppStrings.profileSectionSocial,
            items: [
              _MenuItem(
                icon: Icons.people_outline,
                label: AppStrings.profileFollowingLabel,
                subtitle: AppStrings.profileFollowingSubtitle,
                onTap: () => context.push(AppRoutes.followList),
              ),
              _MenuItem(
                icon: Icons.article_outlined,
                label: AppStrings.profileNewsLabel,
                subtitle: AppStrings.profileNewsSubtitle,
                onTap: () => context.push(AppRoutes.followFeed),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.space4),

          // 설정
          _buildMenuSection(
            title: AppStrings.profileSectionSettings,
            items: [
              _MenuItem(
                icon: Icons.notifications_outlined,
                label: AppStrings.profileNotificationLabel,
                onTap: () => context.push(AppRoutes.notificationSettings),
              ),
              _MenuItem(
                icon: Icons.mic_outlined,
                label: AppStrings.profileRecordingLabel,
                onTap: () => context.push(AppRoutes.allRecordings),
              ),
              _MenuItem(
                icon: Icons.lock_outlined,
                label: AppStrings.profileVisibilityLabel,
                subtitle: AppStrings.profileVisibilitySubtitleLabel,
                onTap: () => context.push(AppRoutes.profileVisibility),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.space4),

          // 지원
          _buildMenuSection(
            title: AppStrings.profileSectionSupport,
            items: [
              _MenuItem(
                icon: Icons.campaign_outlined,
                label: AppStrings.newsRoadmapTitle,
                onTap: () => context.push(AppRoutes.newsRoadmap),
              ),
              _MenuItem(
                icon: Icons.help_outline,
                label: AppStrings.profileHelpLabel,
                onTap: () => context.push(AppRoutes.help),
              ),
              _MenuItem(
                icon: Icons.info_outline,
                label: AppStrings.profileAppInfoLabel,
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
            title: AppStrings.profileSectionAccount,
            items: [
              _MenuItem(
                icon: Icons.description_outlined,
                label: AppStrings.profileTermsLabel,
                onTap: () => context.push(AppRoutes.termsOfService),
              ),
              _MenuItem(
                icon: Icons.privacy_tip_outlined,
                label: AppStrings.profilePrivacyPolicyLabel,
                onTap: () => context.push(AppRoutes.privacyPolicy),
              ),
              _MenuItem(
                icon: Icons.logout,
                label: AppStrings.profileLogoutLabel,
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
          label: const Text(AppStrings.profilePreviewCta),
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

  /// 자주 쓰는 설정 3개 카드 (가용시간 · 입금대기(후불) · 수강권 템플릿).
  Widget _buildQuickShortcuts(BuildContext context, String teacherId) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Row(
        children: [
          Expanded(
            child: _ShortcutCard(
              icon: Icons.calendar_month,
              label: AppStrings.profileShortcutAvailability,
              onTap: () => context.push(AppRoutes.teacherAvailability),
            ),
          ),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: _ShortcutCard(
              icon: Icons.warning_amber_outlined,
              label: AppStrings.profileShortcutOutstandingPayment,
              onTap: () => context.push(AppRoutes.outstandingPayments),
            ),
          ),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: _ShortcutCard(
              icon: Icons.card_membership,
              label: AppStrings.profileShortcutSubscription,
              onTap: () => context.push(AppRoutes.subscriptionTemplates),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLifetimePromoBanner(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(appBillingSnapshotProvider).valueOrNull;
    if (snapshot == null || !snapshot.lifetimeOfferActive) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space4),
      child: LifetimePromoBanner(
        endsAt: snapshot.lifetimeOfferEndsAt!,
        onBuy: () => handleBuyLifetime(context: context, ref: ref),
      ),
    );
  }

  Widget _buildSubscriptionStatusCard(BuildContext context, WidgetRef ref) {
    final snapshotAsync = ref.watch(appBillingSnapshotProvider);
    final teacherId = ref.watch(currentUserIdProvider);
    final groupsAsync = ref.watch(groupedStudentsProvider(teacherId));

    final snapshot = snapshotAsync.valueOrNull;
    final groups = groupsAsync.valueOrNull;
    if (snapshot == null || groups == null) {
      return const SizedBox.shrink();
    }

    final studentCount = groups.fold(0, (sum, g) => sum + g.students.length);

    return SubscriptionStatusCard(
      snapshot: snapshot,
      studentCount: studentCount,
      onUpgrade: () => handleBuyPro(context: context, ref: ref),
      onManage: () => _showBillingComingSoon(context),
      onReceipts: () => _showBillingComingSoon(context),
    );
  }

  void _showBillingComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.paywallComingSoonHint)),
    );
  }

  Widget _buildStatsSection(WidgetRef ref, String teacherId) {
    final lessonStatsAsync = ref.watch(lessonStatsProvider);
    final groupsAsync = ref.watch(groupedStudentsProvider(teacherId));
    // 팔로워 → 입금대기(후불)로 교체 (profile_master.md §2.4)
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
            _buildStatItem('입금대기(후불)', unpaidValue),
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
            decoration: const BoxDecoration(color: AppColors.paper),
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
                          Padding(
                            padding: EdgeInsets.only(
                              left: AppSpacing.space4 + 24 + AppSpacing.space3,
                            ),
                            child: const ThinRule(),
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
