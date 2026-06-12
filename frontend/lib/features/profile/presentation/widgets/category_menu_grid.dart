// W2 Task 2.4 — 5묶음 카테고리 메뉴 그리드.
// spec §3 (IA) + §7.2 (메인 홈 5묶음 메뉴 영역) + §11.1 (카드 라벨 규칙).
//
// 단일 묶음 (운영시간/수업방식/내 프로필) → 직접 라우트 push.
// 복합 묶음 (수강권·정산/정책·알림) → 행 탭 → BottomSheet 세부 메뉴.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/category_new_badge_provider.dart';
import '../providers/category_status_provider.dart';
import 'category_card.dart';

/// 프로필 탭 5묶음 카테고리 메뉴 그리드.
///
/// 5개의 [CategoryCard] 를 세로로 나열한다. 각 카드의 상태는
/// `category_status_provider` 의 5개 status provider 에서 watch.
///
/// 콜백은 각각 단일 묶음(직접 라우트) 또는 복합 묶음(BottomSheet) 으로 위임.
class CategoryMenuGrid extends ConsumerWidget {
  /// 🕐 운영시간 카드 탭 콜백.
  final VoidCallback onOperatingHoursTap;

  /// 🎓 수업방식 카드 탭 콜백.
  final VoidCallback onLessonStyleTap;

  /// 💰 수강권·정산 카드 탭 콜백 (BottomSheet 호출).
  final VoidCallback onSubscriptionBillingTap;

  /// 👤 내 프로필 카드 탭 콜백.
  final VoidCallback onMyProfileTap;

  /// ⚙️ 정책·알림·지원 카드 탭 콜백 (BottomSheet 호출).
  final VoidCallback onPolicyNotificationsTap;

  const CategoryMenuGrid({
    required this.onOperatingHoursTap,
    required this.onLessonStyleTap,
    required this.onSubscriptionBillingTap,
    required this.onMyProfileTap,
    required this.onPolicyNotificationsTap,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final operatingHours = ref.watch(operatingHoursStatusProvider);
    final lessonStyle = ref.watch(lessonStyleStatusProvider);
    final subscriptionBilling = ref.watch(subscriptionBillingStatusProvider);
    final myProfile = ref.watch(myProfileStatusProvider);
    final policyNotifications = ref.watch(policyNotificationsStatusProvider);

    // W6 §10.2 — NEW 배지 상태. AsyncValue.value 가 null 이면 표시 안 함
    // (배지 loading 보다 미표시 가 안전).
    final newBadgeState = ref.watch(categoryNewBadgeProvider).valueOrNull;
    final now = DateTime.now();
    bool showNew(ProfileCategoryId id) {
      return newBadgeState?.shouldShowNew(id, now) ?? false;
    }

    VoidCallback wrapTap(ProfileCategoryId id, VoidCallback delegate) {
      return () {
        if (showNew(id)) {
          ref.read(categoryNewBadgeProvider.notifier).markEntered(id);
        }
        delegate();
      };
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.categorySectionTitle,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.inkTertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          CategoryCard(
            title: AppStrings.categoryOperatingHours,
            icon: Icons.access_time,
            status: operatingHours,
            onTap: wrapTap(
              ProfileCategoryId.operatingHours,
              onOperatingHoursTap,
            ),
            showNewBadge: showNew(ProfileCategoryId.operatingHours),
          ),
          const SizedBox(height: AppSpacing.space2),
          CategoryCard(
            title: AppStrings.categoryLessonStyle,
            icon: Icons.school_outlined,
            status: lessonStyle,
            onTap: wrapTap(ProfileCategoryId.lessonStyle, onLessonStyleTap),
            showNewBadge: showNew(ProfileCategoryId.lessonStyle),
          ),
          const SizedBox(height: AppSpacing.space2),
          CategoryCard(
            title: AppStrings.categorySubscriptionBilling,
            icon: Icons.payments_outlined,
            status: subscriptionBilling,
            onTap: wrapTap(
              ProfileCategoryId.subscriptionBilling,
              onSubscriptionBillingTap,
            ),
            showNewBadge: showNew(ProfileCategoryId.subscriptionBilling),
          ),
          const SizedBox(height: AppSpacing.space2),
          CategoryCard(
            title: AppStrings.categoryMyProfile,
            icon: Icons.person_outline,
            status: myProfile,
            onTap: wrapTap(ProfileCategoryId.myProfile, onMyProfileTap),
            showNewBadge: showNew(ProfileCategoryId.myProfile),
          ),
          const SizedBox(height: AppSpacing.space2),
          CategoryCard(
            title: AppStrings.categoryPolicyNotifications,
            icon: Icons.settings_outlined,
            status: policyNotifications,
            onTap: wrapTap(
              ProfileCategoryId.policyNotifications,
              onPolicyNotificationsTap,
            ),
            showNewBadge: showNew(ProfileCategoryId.policyNotifications),
          ),
        ],
      ),
    );
  }
}
