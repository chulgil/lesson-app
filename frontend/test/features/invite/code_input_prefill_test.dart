// Regression (#480 R2) — deep-link invite code prefill.
//
// lessonapp://invite/{code} forwards the 6-digit code via the route's
// `?code=` query param. CodeInputScreen must prefill those digits (and
// auto-submit). Previously the code was silently dropped and the field
// opened empty.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/invite/presentation/screens/code_input_screen.dart';
import 'package:lessonaza/features/profile/domain/entities/invite.dart';
import 'package:lessonaza/features/profile/presentation/providers/invite_provider.dart';

/// Fake role notifier so the screen builds without the auth provider chain.
class _FakeInviteUserRole extends CurrentInviteUserRole {
  @override
  InviteUserRole build() => InviteUserRole.teacher;
}

void main() {
  testWidgets('prefills digit fields from initialCode', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentInviteUserRoleProvider.overrideWith(_FakeInviteUserRole.new),
          // Auto-submit looks up the code; return null so the flow stops at the
          // "not found" error without needing a router for navigation.
          inviteByCodeProvider('123456').overrideWith((ref) async => null),
        ],
        child: const MaterialApp(
          home: CodeInputScreen(initialCode: '123456'),
        ),
      ),
    );
    await tester.pump();

    // Each of the 6 digit fields shows the corresponding character.
    for (final digit in ['1', '2', '3', '4', '5', '6']) {
      expect(find.text(digit), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('ignores invalid initialCode (no prefill)', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentInviteUserRoleProvider.overrideWith(_FakeInviteUserRole.new),
        ],
        child: const MaterialApp(
          home: CodeInputScreen(initialCode: 'abc'),
        ),
      ),
    );
    await tester.pump();

    // Bad code must not prefill any field.
    for (final ch in ['a', 'b', 'c']) {
      expect(find.text(ch), findsNothing);
    }
    expect(tester.takeException(), isNull);
  });
}
