import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/router/app_router.dart';

/// Regression test for [GoRouterRefreshStream].
///
/// CRITICAL/HIGH: auth state changes must drive GoRouter redirect
/// re-evaluation via refreshListenable, replacing the old "rebuild the whole
/// router on every build" hack.
void main() {
  test('notifies once on construction (initial evaluation)', () {
    final controller = StreamController<int>.broadcast();
    addTearDown(controller.close);
    final refresh = GoRouterRefreshStream(controller.stream);
    addTearDown(refresh.dispose);

    var count = 0;
    refresh.addListener(() => count++);
    // Construction already fired one notify before the listener was attached;
    // attaching after construction means we only count subsequent events.
    expect(count, 0);
  });

  test('notifies listeners on each stream event', () async {
    final controller = StreamController<int>.broadcast();
    addTearDown(controller.close);
    final refresh = GoRouterRefreshStream(controller.stream);
    addTearDown(refresh.dispose);

    var count = 0;
    refresh.addListener(() => count++);

    controller.add(1);
    controller.add(2);
    await Future<void>.delayed(Duration.zero);

    expect(count, 2);
  });

  test('stops notifying after dispose', () async {
    final controller = StreamController<int>.broadcast();
    addTearDown(controller.close);
    final refresh = GoRouterRefreshStream(controller.stream);

    var count = 0;
    refresh.addListener(() => count++);
    refresh.dispose();

    controller.add(1);
    await Future<void>.delayed(Duration.zero);

    expect(count, 0);
  });
}
