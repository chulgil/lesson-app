import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings_facade.dart' show appVersionSnapshotProvider;
import '../screens/force_update_screen.dart';

/// App-shell gate that blocks the whole app with [ForceUpdateScreen] when the
/// running version is below the server-reported `min_version`.
///
/// Wraps the router's child in `main.dart`'s `MaterialApp.router` builder, so
/// the blocker covers every route once the version snapshot resolves.
///
/// Fails open by design: while [appVersionSnapshotProvider] is loading or has
/// errored (e.g. the version endpoint is unreachable), the app stays usable.
/// A force update only triggers on a resolved snapshot that actually reports a
/// newer minimum — a transient outage must never lock users out.
class ForceUpdateGate extends ConsumerWidget {
  const ForceUpdateGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final versionAsync = ref.watch(appVersionSnapshotProvider);

    return versionAsync.maybeWhen(
      data: (version) {
        final minVersion = version.minVersion;
        if (version.requiresForceUpdate && minVersion != null) {
          return ForceUpdateScreen(
            currentVersion: version.currentVersion,
            minVersion: minVersion,
          );
        }
        return child;
      },
      // Loading / error → fail open: show the app, never block on a failed
      // or in-flight version check.
      orElse: () => child,
    );
  }
}
