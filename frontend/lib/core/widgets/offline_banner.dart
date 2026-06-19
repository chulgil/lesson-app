import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_strings.dart';
import '../sync/presentation/providers/connectivity_banner_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Global offline indicator banner.
///
/// Wraps [child] in a [Column]. When the device is offline, a compact banner
/// is injected at the very top (above the app's safe-area content). The banner
/// disappears automatically once connectivity is restored.
///
/// Place this widget high in the widget tree — ideally as the direct child of
/// [MaterialApp.builder] — so it appears on every screen without each screen
/// needing to include it.
class OfflineBannerWrapper extends ConsumerWidget {
  const OfflineBannerWrapper({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOffline = ref.watch(offlineBannerProvider).valueOrNull ?? false;

    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, animation) => SizeTransition(
            sizeFactor: animation,
            axisAlignment: -1,
            child: child,
          ),
          child: isOffline
              ? const _OfflineBanner(key: ValueKey('offline'))
              : const SizedBox.shrink(key: ValueKey('online')),
        ),
        Expanded(child: child),
      ],
    );
  }
}

/// The visible offline strip.
class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.offlineBannerBackground,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space4,
            vertical: AppSpacing.space2,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                size: AppSpacing.iconSM,
                color: AppColors.offlineBannerForeground,
              ),
              const SizedBox(width: AppSpacing.space2),
              Text(
                AppStrings.offlineBannerMessage,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.offlineBannerForeground,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
