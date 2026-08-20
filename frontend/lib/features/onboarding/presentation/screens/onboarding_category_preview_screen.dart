// W4 Task 4.2 — OnboardingCategoryPreviewScreen (Step 2.5).
// spec §9.1~§9.2 — FirstAvailability 완료 후 5묶음 카테고리 1회 미리보기.
//
// 흐름:
//   Step 1 ProfileSetup → Step 2 FirstAvailability → Step 2.5 (이 화면) → Step 3 Dashboard
//
// 영속: `onboardingCategoryShownProvider` Hive flag — [시작하기] 가 markShown()
// 호출 + 메인 진입.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/notebook/notebook_screen_scaffold.dart';
import '../providers/onboarding_category_shown_provider.dart';

class OnboardingCategoryPreviewScreen extends ConsumerWidget {
  /// 진행/스킵 콜백 — null 이면 신규 가입 onboarding 흐름 (markShown + home 라우트).
  ///
  /// W6 마이그레이션 overlay 모드에서는 콜백을 주입하여 ProfileTab 안에서
  /// markCategoryIntroduced(5개) + markShown 을 처리하고 자체 rebuild 한다.
  final Future<void> Function()? onProceed;

  /// 화면 타이틀 — null 이면 신규 가입 문구 (환영합니다!).
  ///
  /// W6 마이그레이션 overlay 는 기존 사용자용 변경 공지 문구
  /// (`AppStrings.migrationCategoryPreviewTitle`) 를 주입한다.
  final String? title;

  /// 보조 안내 — null 이면 신규 가입 문구.
  final String? subtitle;

  const OnboardingCategoryPreviewScreen({
    super.key,
    this.onProceed,
    this.title,
    this.subtitle,
  });

  static const _categories = <_CategoryPreview>[
    _CategoryPreview(
      icon: Icons.access_time,
      label: AppStrings.categoryOperatingHours,
    ),
    _CategoryPreview(
      icon: Icons.school_outlined,
      label: AppStrings.categoryLessonStyle,
    ),
    _CategoryPreview(
      icon: Icons.payments_outlined,
      label: AppStrings.categorySubscriptionBilling,
    ),
    _CategoryPreview(
      icon: Icons.person_outline,
      label: AppStrings.categoryMyProfile,
    ),
    _CategoryPreview(
      icon: Icons.settings_outlined,
      label: AppStrings.categoryPolicyNotifications,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NotebookScreenScaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.space4),
              Text(
                title ?? AppStrings.onboardingCategoryPreviewTitle,
                style: AppTypography.headingMedium.copyWith(
                  color: AppColors.ink,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.space5),
              _CategoryGrid(items: _categories),
              const SizedBox(height: AppSpacing.space4),
              // '수강권' first appears on the tile above and is the one term a
              // new teacher cannot infer from the word itself.
              Text(
                AppStrings.onboardingCategorySubscriptionGloss,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.inkSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.space3),
              Text(
                subtitle ?? AppStrings.onboardingCategoryPreviewSubtitle,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.inkSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.space5),
              // Single CTA — [건너뛰기] and [시작하기] both ran _proceed, so the
              // choice was cosmetic (ux-rules: same action = one CTA).
              FilledButton(
                onPressed: () => _proceed(context, ref),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, AppSpacing.buttonHeight),
                ),
                child: const Text(AppStrings.onboardingCategoryPreviewStart),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _proceed(BuildContext context, WidgetRef ref) async {
    if (onProceed != null) {
      await onProceed!();
      return;
    }
    await ref.read(onboardingCategoryShownProvider.notifier).markShown();
    if (!context.mounted) return;
    context.go(AppRoutes.home);
  }
}

class _CategoryGrid extends StatelessWidget {
  final List<_CategoryPreview> items;

  const _CategoryGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: AppSpacing.space3,
      crossAxisSpacing: AppSpacing.space3,
      childAspectRatio: 1.4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: items
          .map((item) => _CategoryTile(item: item))
          .toList(growable: false),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final _CategoryPreview item;

  const _CategoryTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.paperDark,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(item.icon, size: 32, color: AppColors.paperAccent),
          const SizedBox(height: AppSpacing.space2),
          Text(
            item.label,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _CategoryPreview {
  final IconData icon;
  final String label;

  const _CategoryPreview({required this.icon, required this.label});
}
