// W4 Task 4.2 — OnboardingCategoryPreviewScreen (Step 2.5).
// spec §9.1~§9.2 — FirstAvailability 완료 후 5묶음 카테고리 1회 미리보기.
//
// 흐름:
//   Step 1 ProfileSetup → Step 2 FirstAvailability → Step 2.5 (이 화면) → Step 3 Dashboard
//
// 영속: `onboardingCategoryShownProvider` Hive flag — [시작하기]/[건너뛰기]
// 어느 쪽이든 markShown() 호출 + 메인 진입.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/onboarding_category_shown_provider.dart';

class OnboardingCategoryPreviewScreen extends ConsumerWidget {
  /// 진행/스킵 콜백 — null 이면 신규 가입 onboarding 흐름 (markShown + home 라우트).
  ///
  /// W6 마이그레이션 overlay 모드에서는 콜백을 주입하여 ProfileTab 안에서
  /// markCategoryIntroduced(5개) + markShown 을 처리하고 자체 rebuild 한다.
  final Future<void> Function()? onProceed;

  const OnboardingCategoryPreviewScreen({super.key, this.onProceed});

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
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.space4),
              Text(
                AppStrings.onboardingCategoryPreviewTitle,
                style: AppTypography.headingMedium.copyWith(
                  color: AppColors.ink,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.space5),
              _CategoryGrid(items: _categories),
              const SizedBox(height: AppSpacing.space4),
              Text(
                AppStrings.onboardingCategoryPreviewSubtitle,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.inkSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.space5),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _proceed(context, ref),
                      child: const Text(
                        AppStrings.onboardingCategoryPreviewSkip,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space3),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => _proceed(context, ref),
                      child: const Text(
                        AppStrings.onboardingCategoryPreviewStart,
                      ),
                    ),
                  ),
                ],
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
