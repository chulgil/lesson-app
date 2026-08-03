// Wiring tests for E1 — force-update gate.
//
// The app already ships a fully-built ForceUpdateScreen and an
// AppVersionSnapshot.requiresForceUpdate getter, but nothing consumed the
// getter (0 call sites) so a below-min-version client was never blocked.
//
// ForceUpdateGate wraps the app shell and swaps in ForceUpdateScreen when the
// server-reported min_version is newer than the running version. Critically it
// MUST fail open: while the version snapshot is loading or errors (e.g. network
// down), the app stays usable — a transient outage must never lock users out.
//
// Cases:
//   1. requiresForceUpdate == true  → ForceUpdateScreen shown, child hidden
//   2. requiresForceUpdate == false → child shown, no ForceUpdateScreen
//   3. snapshot loading (never resolves) → child shown (fail-open)
//   4. snapshot errors → child shown (fail-open)

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/settings/domain/entities/app_release.dart';
import 'package:lessonaza/features/settings/presentation/screens/force_update_screen.dart';
import 'package:lessonaza/features/settings/presentation/widgets/force_update_gate.dart';
import 'package:lessonaza/features/settings/settings_facade.dart'
    show appVersionSnapshotProvider;

const _childKey = Key('gate-child');

Widget _harness(List<Override> overrides) {
  return ProviderScope(
    overrides: overrides,
    child: const MaterialApp(
      home: ForceUpdateGate(child: Text('APP', key: _childKey)),
    ),
  );
}

AppVersionSnapshot _snapshot({String current = '1.0.0', String? min}) {
  return AppVersionSnapshot(
    currentVersion: current,
    minVersion: min,
    checkedAt: DateTime.utc(2026, 7, 9),
  );
}

void main() {
  testWidgets('blocks with ForceUpdateScreen when below min version', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness([
        appVersionSnapshotProvider.overrideWith(
          (ref) async => _snapshot(current: '1.0.0', min: '2.0.0'),
        ),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ForceUpdateScreen), findsOneWidget);
    expect(find.byKey(_childKey), findsNothing);
  });

  testWidgets('shows the app when current version meets min version', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness([
        appVersionSnapshotProvider.overrideWith(
          (ref) async => _snapshot(current: '2.0.0', min: '2.0.0'),
        ),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ForceUpdateScreen), findsNothing);
    expect(find.byKey(_childKey), findsOneWidget);
  });

  testWidgets('fails open (shows app) while the snapshot is loading', (
    tester,
  ) async {
    final never = Completer<AppVersionSnapshot>();
    addTearDown(() => never.complete(_snapshot()));

    await tester.pumpWidget(
      _harness([
        appVersionSnapshotProvider.overrideWith((ref) => never.future),
      ]),
    );
    await tester.pump();

    expect(find.byType(ForceUpdateScreen), findsNothing);
    expect(find.byKey(_childKey), findsOneWidget);
  });

  testWidgets('fails open (shows app) when the snapshot errors', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness([
        appVersionSnapshotProvider.overrideWith(
          (ref) async => throw Exception('version check failed'),
        ),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ForceUpdateScreen), findsNothing);
    expect(find.byKey(_childKey), findsOneWidget);
  });
}
