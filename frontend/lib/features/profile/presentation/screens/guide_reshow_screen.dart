import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/notebook/notebook_screen_scaffold.dart';
import '../../../home/home_ui_facade.dart' show QuestBoardCard;
import '../providers/quest_celebration_provider.dart';

/// "가이드 다시 보기" 화면 — 졸업 후 fallback (W5 Task 5.6).
///
/// SSOT: `.harness/spec/2026-06-11-teacher-settings-redesign.md` §8.4
///
/// 진입점: ⚙️ 정책·알림·지원 → "가이드 다시 보기" 메뉴.
///
/// 동작:
/// - 진입 즉시 `questCelebrationProvider.resetDismissal()` 호출하여 명시
///   dismiss 만 리셋 (BE `celebratedAt` 은 유지).
/// - `QuestBoardCard` 를 재사용 — 11개 mandatory quest 가 모두 완료된
///   상태에선 졸업 카드를 다시 노출 (visible == true).
/// - "Step 2.5 카테고리 미리보기" 재실행 진입점 제공.
class GuideReshowScreen extends ConsumerStatefulWidget {
  const GuideReshowScreen({super.key});

  @override
  ConsumerState<GuideReshowScreen> createState() => _GuideReshowScreenState();
}

class _GuideReshowScreenState extends ConsumerState<GuideReshowScreen> {
  @override
  void initState() {
    super.initState();
    // 진입 시 명시 dismiss 리셋 — graduated == false 로 전환.
    // celebratedAt 후 7일 경과한 경우는 여전히 hide (스펙 §8.4 보전).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // ignore: discarded_futures — fire-and-forget.
      ref.read(questCelebrationProvider.notifier).resetDismissal();
    });
  }

  @override
  Widget build(BuildContext context) {
    return NotebookScreenScaffold(
      appBar: AppBar(
        backgroundColor: AppColors.paper,
        elevation: 0,
        title: const Text(AppStrings.categoryGuideReplayLabel),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.categoryGuideReplaySubtitle,
              style: NotebookTypography.handMedium.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.space4),
            // 졸업한 quest board 재노출.
            const QuestBoardCard(),
            const SizedBox(height: AppSpacing.space4),
            // Step 2.5 카테고리 미리보기 재실행.
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, AppSpacing.buttonHeight),
                side: const BorderSide(color: AppColors.ink, width: 1.5),
                shape: const RoundedRectangleBorder(),
              ),
              icon: const Icon(Icons.dashboard_outlined, color: AppColors.ink),
              label: Text(
                AppStrings.guideReshowCategoryPreviewButton,
                style: NotebookTypography.roman.copyWith(
                  fontSize: 14,
                  color: AppColors.ink,
                ),
              ),
              onPressed:
                  () => context.push(AppRoutes.onboardingCategoryPreview),
            ),
          ],
        ),
      ),
    );
  }
}
