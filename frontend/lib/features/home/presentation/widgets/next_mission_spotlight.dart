// W4 Task 4.4 — NextMissionSpotlight (메인 첫 진입 1회 안내).
// spec §9.1 Step 3 — 가입 후 DashboardTab 첫 진입 시 spotlight 1회.
//
// 영속: `nextMissionSpotlightDismissedProvider` (UXC-2). 과거에는
// `questFirstShownProvider` 의 타임스탬프를 재사용했으나, home 진입 즉시
// (post-frame) 기록되는 그 값이 곧 노출 조건이라 spotlight 가 플래시하거나
// 아예 뜨지 않았다. 소거는 사용자가 [시작]/[나중에] 를 탭할 때만 일어난다.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../profile/profile_facade.dart'
    show nextMissionSpotlightDismissedProvider;

/// 메인 첫 진입 1회 spotlight overlay.
///
/// DashboardTab 의 Stack 안에 `Positioned.fill` 로 배치한다. 미노출 상태에는
/// `SizedBox.shrink()` 만 반환하여 화면 영역을 차지하지 않는다.
class NextMissionSpotlight extends ConsumerWidget {
  /// [시작] 탭 시 호출 — spotlight 종료 + 미션 화면 push.
  final VoidCallback? onStart;

  const NextMissionSpotlight({super.key, this.onStart});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dismissedAsync = ref.watch(nextMissionSpotlightDismissedProvider);

    return dismissedAsync.when(
      data: (dismissed) {
        // 사용자가 [시작]/[나중에] 를 탭한 적이 있으면 다시 띄우지 않는다.
        if (dismissed) return const SizedBox.shrink();
        return _SpotlightOverlay(
          onStart: () async {
            await ref
                .read(nextMissionSpotlightDismissedProvider.notifier)
                .markDismissed();
            onStart?.call();
          },
          onLater: () async {
            await ref
                .read(nextMissionSpotlightDismissedProvider.notifier)
                .markDismissed();
          },
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _SpotlightOverlay extends StatelessWidget {
  final Future<void> Function() onStart;
  final Future<void> Function() onLater;

  const _SpotlightOverlay({required this.onStart, required this.onLater});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Material(
        color: AppColors.inkScrim,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [_SpotlightCard(onStart: onStart, onLater: onLater)],
            ),
          ),
        ),
      ),
    );
  }
}

class _SpotlightCard extends StatelessWidget {
  final Future<void> Function() onStart;
  final Future<void> Function() onLater;

  const _SpotlightCard({required this.onStart, required this.onLater});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space5),
      decoration: const BoxDecoration(color: AppColors.paper),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppStrings.nextMissionSpotlightTitle,
            style: AppTypography.headingMedium.copyWith(color: AppColors.ink),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.space3),
          Text(
            AppStrings.nextMissionSpotlightHint,
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
                  onPressed: onLater,
                  child: const Text(AppStrings.nextMissionSpotlightLater),
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: FilledButton(
                  onPressed: onStart,
                  child: const Text(AppStrings.nextMissionSpotlightStart),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
