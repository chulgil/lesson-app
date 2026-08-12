// Regression — StudentInviteCodeScreen ↔ CodeInputScreen unification.
//
// The onboarding invite-code screen now reuses the shared 6-box
// InviteCodeDigitInput widget and the shared InviteConfirmScreen (instead of
// a free-text field that posted a connection request directly). Covers:
//   (a) valid code -> confirm step shown -> connection created -> profile setup
//   (b) invalid/expired code -> inline error, no navigation
//   (c) skip path — unchanged, see invite_code_skip_guard_test.dart and
//       student_invite_code_age_gate_test.dart
//   (d) CodeInputScreen (post-onboarding) still renders with the shared widget

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/providers/repository_provider.dart';
import 'package:lessonaza/core/router/app_routes.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/auth/presentation/screens/student_invite_code_screen.dart';
import 'package:lessonaza/features/invite/presentation/screens/code_input_screen.dart';
import 'package:lessonaza/features/profile/domain/entities/invite.dart';
import 'package:lessonaza/features/profile/presentation/providers/invite_provider.dart';

// ---------------------------------------------------------------------------
// Stubs
// ---------------------------------------------------------------------------

Invite _fakeInvite({
  InviteStatus status = InviteStatus.active,
  DateTime? expiresAt,
}) {
  return Invite(
    id: 'invite-onboarding-1',
    creatorId: 'teacher-1',
    creatorName: '김선생',
    creatorRole: InviteUserRole.teacher,
    inviteCode: '111111',
    inviteUrl: 'lessonapp://invite/111111',
    qrCodeData: 'lessonapp://invite/111111',
    status: status,
    expiresAt: expiresAt ?? DateTime.now().add(const Duration(days: 6)),
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
  );
}

/// Stub that succeeds and returns a ConnectionRequest — mirrors the pattern
/// in invite_confirm_error_chain_test.dart.
class _SuccessRequester extends ConnectionRequester {
  @override
  AsyncValue<ConnectionRequest?> build() => const AsyncValue.data(null);

  @override
  Future<ConnectionRequest?> requestConnection({
    required String targetId,
    required InviteUserRole targetRole,
    required InviteMethod method,
    String? inviteId,
    String? message,
  }) async {
    final req = ConnectionRequest(
      id: 'req-onboarding-1',
      requesterId: 'student-onboarding-1',
      requesterRole: InviteUserRole.student,
      targetId: targetId,
      targetRole: targetRole,
      method: method,
      inviteId: inviteId,
      message: message,
      createdAt: DateTime(2026),
      expiresAt: DateTime(2027),
    );
    state = AsyncValue.data(req);
    return req;
  }
}

/// Fake role notifier so CodeInputScreen builds without the auth provider
/// chain (mirrors code_input_prefill_test.dart).
class _FakeInviteUserRole extends CurrentInviteUserRole {
  @override
  InviteUserRole build() => InviteUserRole.teacher;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

GoRouter _router(Widget initial) {
  return GoRouter(
    initialLocation: '/invite',
    routes: [
      GoRoute(path: '/invite', builder: (_, __) => initial),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const Scaffold(body: Text('login page')),
      ),
      GoRoute(
        path: AppRoutes.studentProfileSetup,
        builder: (_, __) => const Scaffold(body: Text('profile setup page')),
      ),
    ],
  );
}

Future<void> _pumpScreen(
  WidgetTester tester,
  Widget screen,
  List<Override> overrides,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: _router(screen),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Enters [code] into the 6 digit boxes — the last digit triggers auto-submit
/// (InviteCodeDigitInput._submitCode via onChanged), same as real typing.
Future<void> _enterCode(WidgetTester tester, String code) async {
  final digitFields = find.byType(TextField);
  expect(digitFields, findsNWidgets(6));
  for (var i = 0; i < 6; i++) {
    await tester.enterText(digitFields.at(i), code[i]);
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('StudentInviteCodeScreen — unified invite-code flow', () {
    testWidgets(
      '(a) valid code -> confirm step -> connection created -> profile setup',
      (tester) async {
        final invite = _fakeInvite();

        await _pumpScreen(tester, const StudentInviteCodeScreen(), [
          mockDataModeProvider.overrideWithValue(true),
          inviteByCodeProvider('111111').overrideWith((ref) async => invite),
          connectionRequesterProvider.overrideWith(() => _SuccessRequester()),
        ]);

        await _enterCode(tester, '111111');
        await tester.pumpAndSettle();

        // Confirm step shown via the shared InviteConfirmScreen — not a
        // custom onboarding-only dialog.
        expect(find.text(AppStrings.inviteConnectionRequest), findsOneWidget);
        final connectBtn = find.text(AppStrings.inviteSendConnectionRequest);
        expect(connectBtn, findsOneWidget);

        await tester.ensureVisible(connectBtn);
        await tester.tap(connectBtn);
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();

        // Success dialog — onboarding single-button variant (no
        // home/book-a-lesson choice), scoped to the dialog to avoid matching
        // the buried digit-input's own "확인" button underneath.
        expect(find.text(AppStrings.inviteRequestSent), findsOneWidget);
        final dialogConfirm = find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text(AppStrings.confirm),
        );
        expect(dialogConfirm, findsOneWidget);

        await tester.tap(dialogConfirm);
        await tester.pumpAndSettle();

        // Lands on profile setup — not home (mid-onboarding, homeRoute would
        // be redirected away by the auth guard).
        expect(find.text('profile setup page'), findsOneWidget);
      },
    );

    testWidgets(
      '(b) unknown code shows inline "not found" error, no navigation',
      (tester) async {
        await _pumpScreen(tester, const StudentInviteCodeScreen(), [
          mockDataModeProvider.overrideWithValue(true),
          inviteByCodeProvider('000000').overrideWith((ref) async => null),
        ]);

        await _enterCode(tester, '000000');
        await tester.pumpAndSettle();

        expect(find.text(AppStrings.inviteCodeNotFound), findsOneWidget);
        expect(find.text(AppStrings.inviteConnectionRequest), findsNothing);
      },
    );

    testWidgets(
      '(b) expired code shows inline "expired" error, no navigation',
      (tester) async {
        final expired = _fakeInvite(
          status: InviteStatus.expired,
          expiresAt: DateTime.now().subtract(const Duration(days: 1)),
        );

        await _pumpScreen(tester, const StudentInviteCodeScreen(), [
          mockDataModeProvider.overrideWithValue(true),
          inviteByCodeProvider('222222').overrideWith((ref) async => expired),
        ]);

        await _enterCode(tester, '222222');
        await tester.pumpAndSettle();

        expect(find.text(AppStrings.inviteCodeExpired), findsOneWidget);
        expect(find.text(AppStrings.inviteConnectionRequest), findsNothing);
      },
    );
  });

  testWidgets(
    '(d) CodeInputScreen (post-onboarding) still renders the shared digit input',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentInviteUserRoleProvider.overrideWith(_FakeInviteUserRole.new),
          ],
          child: const MaterialApp(home: CodeInputScreen()),
        ),
      );
      await tester.pump();

      expect(find.byType(TextField), findsNWidgets(6));
      expect(find.text(AppStrings.inviteCodeQrScan), findsOneWidget);
      expect(find.text(AppStrings.confirm), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
