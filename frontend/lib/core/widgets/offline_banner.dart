import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_strings.dart';
import '../sync/lost_writes_provider.dart';
import '../sync/presentation/providers/connectivity_banner_provider.dart';
import '../sync/presentation/providers/stale_data_provider.dart';
import '../utils/date_format_utils.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Global offline / slow-network staleness banner.
///
/// Wraps [child] in a [Column]. A compact banner is injected at the very top
/// (above the app's safe-area content) when EITHER:
/// - the device is fully offline (no connectivity), OR
/// - a cached (stale) response is currently on screen because a read timed out
///   on a slow-but-connected network (G-06). The marker is set on every cache
///   serve and cleared once a live read reaches a caller, so the banner tracks
///   on-screen data freshness regardless of the raw connectivity state.
///
/// Place this widget high in the widget tree — ideally as the direct child of
/// [MaterialApp.builder] — so it appears on every screen without each screen
/// needing to include it.
class OfflineBannerWrapper extends ConsumerWidget {
  const OfflineBannerWrapper({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Surface silently-dropped unsent writes (INV-3/INV-4) as a SnackBar, then
    // clear so it shows once. Fed by cleanup expiry (#1115) and logout (#1114).
    ref.listen<LostWritesEvent?>(lostWritesProvider, (previous, next) {
      if (next == null) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger == null) return;
      final message = switch (next.reason) {
        LostWritesReason.expired => AppStrings.lostWritesExpired(next.count),
        LostWritesReason.logout => AppStrings.lostWritesLogout(next.count),
      };
      messenger.showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 6)),
      );
      ref.read(lostWritesProvider.notifier).clear();
    });

    final isOffline = ref.watch(offlineBannerProvider).valueOrNull ?? false;
    final staleSince = ref.watch(lastServedFromCacheAtProvider);
    // Show while offline, or while serving stale cache on a slow network.
    final showBanner = isOffline || staleSince != null;

    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder:
              (child, animation) => SizeTransition(
                sizeFactor: animation,
                axisAlignment: -1,
                child: child,
              ),
          child:
              showBanner
                  ? _OfflineBanner(
                    key: const ValueKey('stale'),
                    isOffline: isOffline,
                    lastSyncedAt: staleSince,
                  )
                  : const SizedBox.shrink(key: ValueKey('online')),
        ),
        Expanded(child: child),
      ],
    );
  }
}

/// The visible staleness strip.
class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({super.key, required this.isOffline, this.lastSyncedAt});

  /// True = device fully offline; false = connected but serving stale cache
  /// (slow network). Drives the icon and copy.
  final bool isOffline;

  /// `cachedAt` of the most recently cache-served response (D2). When set,
  /// the banner tells the user how fresh the on-screen data is.
  final DateTime? lastSyncedAt;

  @override
  Widget build(BuildContext context) {
    final hhmm =
        lastSyncedAt == null ? null : formatTimeHM(lastSyncedAt!.toLocal());

    final IconData icon;
    final String message;
    if (isOffline) {
      icon = Icons.wifi_off_rounded;
      message =
          hhmm == null
              ? AppStrings.offlineBannerMessage
              : AppStrings.offlineBannerLastSync(hhmm);
    } else {
      // Slow network: the marker is always set here, so hhmm is non-null.
      icon = Icons.history_rounded;
      message = AppStrings.slowNetworkBannerLastSync(hhmm ?? '');
    }

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
              Icon(
                icon,
                size: AppSpacing.iconSM,
                color: AppColors.offlineBannerForeground,
              ),
              const SizedBox(width: AppSpacing.space2),
              Text(
                message,
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
