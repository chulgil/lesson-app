import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/auth/auth_state.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/notebook/notebook_masthead.dart';
import '../../../auth/auth_facade.dart';
import '../../../billing/billing_facade.dart';
import '../../../lessons/lessons_facade.dart';
import '../../../students/students_facade.dart';
import '../../../subscription/subscription_facade.dart';
import '../../domain/entities/teacher_profile.dart';
import '../providers/teacher_extended_profile_provider.dart';
import '../widgets/category_menu_grid.dart';
import '../widgets/profile_category_sheets.dart';
import '../widgets/teacher_migration_overlay_gate.dart';

/// Profile tab with user info and 5묶음 카테고리 메뉴 그리드.
///
/// W2 Task 2.4 — spec §3 (IA) + §7.2 (메인 홈) + §11.1 (카드 라벨 규칙).
///
/// 5묶음 카테고리:
/// - 🕐 운영시간 → TeacherAvailability split page (직접 라우트)
/// - 🎓 수업방식 → LessonStyleSettingsScreen (직접 라우트, W3 Task 3.2)
/// - 💰 수강권·정산 → BottomSheet (수강권 템플릿/입금대기/입금 계좌)
/// - 👤 내 프로필 → BasicInfoEdit (직접 라우트)
/// - ⚙️ 정책·알림·지원 → BottomSheet (정책/템플릿/알림/녹음/공개/지원/계정)
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

    // W6 §10.1 — 기존 가입자 첫 진입 마이그레이션 overlay 게이트.
    // shown==false 일 때만 OnboardingCategoryPreviewScreen 노출,
    // 진행/스킵 후 5묶음 NEW 윈도우 시작 + shown flag 영속.
    return TeacherMigrationOverlayGate(
      child: SingleChildScrollView(
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
                      onPressed: () =>
                          context.push(AppRoutes.notificationSettings),
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

            // 5묶음 카테고리 메뉴 그리드 (W2 Task 2.4 — spec §3 + §7.2 + §11.1)
            _buildCategoryGrid(context, ref, teacherId),

            SizedBox(
              height:
                  AppSpacing.space8 +
                  MediaQuery.of(context).padding.bottom +
                  32,
            ),
          ],
        ),
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
              children: instruments
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
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
    // #415 Phase B2: 세션 dismiss state 체크. 닫혀 있으면 banner 미노출
    // (다음 부팅 시 lifetime 윈도우 활성이면 다시 노출 — promo blindness 완화).
    final dismissed = ref.watch(lifetimePromoDismissedProvider);
    if (snapshot == null || !snapshot.lifetimeOfferActive || dismissed) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space4),
      child: LifetimePromoBanner(
        endsAt: snapshot.lifetimeOfferEndsAt!,
        onBuy: () => handleBuyLifetime(context: context, ref: ref),
        onDismiss:
            () =>
                ref.read(lifetimePromoDismissedProvider.notifier).state = true,
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
      onManage: () => _openStoreSubscriptionManagement(
        context,
        AppStrings.billingManageStoreOpening,
      ),
      onReceipts: () => _openStoreSubscriptionManagement(
        context,
        AppStrings.billingReceiptStoreOpening,
      ),
    );
  }

  /// #415 Phase A2 — "플랜 관리" / "영수증" CTA 를 native store 구독 페이지로 라우팅.
  ///
  /// Apple/Google 구독 모두 native store 가 구독 관리 + 영수증 이력을 한 페이지에서
  /// 제공한다 (자체 billing_management_screen 보다 권한·취소·환불 진실성 우위).
  /// deep-link 실패 시 `billingManageStoreFailed` 폴백 안내.
  Future<void> _openStoreSubscriptionManagement(
    BuildContext context,
    String openingHint,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(SnackBar(content: Text(openingHint)));

    final url = Platform.isIOS
        ? Uri.parse('https://apps.apple.com/account/subscriptions')
        : Uri.parse('https://play.google.com/store/account/subscriptions');

    try {
      final ok = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!ok) {
        messenger.showSnackBar(
          const SnackBar(content: Text(AppStrings.billingManageStoreFailed)),
        );
      }
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text(AppStrings.billingManageStoreFailed)),
      );
    }
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

  /// 5묶음 카테고리 카드 그리드 — spec §7.2.
  ///
  /// 단일 묶음 (운영시간/수업방식/내 프로필) → 직접 라우트 push.
  /// 복합 묶음 (수강권·정산/정책·알림) → 행 탭 → BottomSheet 세부 메뉴.
  Widget _buildCategoryGrid(
    BuildContext context,
    WidgetRef ref,
    String teacherId,
  ) {
    return CategoryMenuGrid(
      onOperatingHoursTap: () => context.push(AppRoutes.teacherAvailability),
      onLessonStyleTap: () => context.push(AppRoutes.lessonStyleSettings),
      onSubscriptionBillingTap: () =>
          showSubscriptionBillingSheet(context, teacherId),
      onMyProfileTap: () => showMyProfileSheet(context),
      onPolicyNotificationsTap: () =>
          showPolicyNotificationsSheet(context, ref),
    );
  }
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
