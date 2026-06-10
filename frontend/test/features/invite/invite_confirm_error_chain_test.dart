// Regression — invite_confirm_screen error chain fix.
//
// Before the fix:
//   requestConnection() swallowed all exceptions → _sendRequest()'s catch was
//   dead code → "이미 연결" dialog unreachable, raw Text(errorMessage) never
//   shown but catch logic was misleading.
//
// After the fix:
//   requestConnection() rethrows ApiException so _sendRequest() can:
//     - 409  → show AlreadyConnected dialog (success UX)
//     - other → show generic inviteConnectionFailed snackbar (no raw leak)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/network/api_exceptions.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/invite/presentation/screens/invite_confirm_screen.dart';
import 'package:lessonaza/features/profile/domain/entities/invite.dart';
import 'package:lessonaza/features/profile/presentation/providers/invite_provider.dart';

// ---------------------------------------------------------------------------
// Stubs
// ---------------------------------------------------------------------------

class _FakeUserRole extends CurrentInviteUserRole {
  @override
  InviteUserRole build() => InviteUserRole.student;
}

class _FakeUserId extends CurrentInviteUserId {
  @override
  String build() => 'student-1';
}

/// Stub that succeeds and returns a ConnectionRequest.
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
      id: 'req-1',
      requesterId: 'student-1',
      requesterRole: InviteUserRole.student,
      targetId: 'teacher-1',
      targetRole: InviteUserRole.teacher,
      method: method,
      createdAt: DateTime(2026),
      expiresAt: DateTime(2027),
    );
    state = AsyncValue.data(req);
    return req;
  }
}

/// Stub that throws ApiException(409) — already connected.
class _ConflictRequester extends ConnectionRequester {
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
    state = AsyncValue.error(
      const ApiException(message: '이미 연결됨', statusCode: 409),
      StackTrace.empty,
    );
    throw const ApiException(message: '이미 연결됨', statusCode: 409);
  }
}

/// Stub that throws a generic ApiException (e.g. network error).
class _NetworkErrorRequester extends ConnectionRequester {
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
    state = AsyncValue.error(
      const NetworkException(message: '네트워크 오류'),
      StackTrace.empty,
    );
    throw const NetworkException(message: '네트워크 오류');
  }
}

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------

Invite _fakeInvite() => Invite(
  id: 'inv-1',
  creatorId: 'teacher-1',
  creatorName: '김선생',
  creatorRole: InviteUserRole.teacher,
  inviteCode: 'ABC123',
  inviteUrl: 'lessonapp://invite/ABC123',
  qrCodeData: 'lessonapp://invite/ABC123',
  status: InviteStatus.active,
  expiresAt: DateTime(2027),
  createdAt: DateTime(2026),
);

Future<void> _pumpScreen(WidgetTester tester, List<Override> overrides) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              height: 900,
              child: InviteConfirmScreen(invite: _fakeInvite()),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tapConnectButton(WidgetTester tester) async {
  final btn = find.text(AppStrings.inviteSendConnectionRequest);
  await tester.ensureVisible(btn);
  await tester.pumpAndSettle();
  await tester.tap(btn);
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('InviteConfirmScreen error-chain', () {
    testWidgets('성공 시 연결 요청 완료 dialog 표시', (tester) async {
      await _pumpScreen(tester, [
        connectionRequesterProvider.overrideWith(() => _SuccessRequester()),
        currentInviteUserRoleProvider.overrideWith(() => _FakeUserRole()),
        currentInviteUserIdProvider.overrideWith(() => _FakeUserId()),
      ]);

      await _tapConnectButton(tester);
      await tester.pumpAndSettle();

      // Success dialog should appear (not a snackbar).
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('409 충돌 시 이미연결 dialog 표시 (raw 에러 노출 없음)', (tester) async {
      await _pumpScreen(tester, [
        connectionRequesterProvider.overrideWith(() => _ConflictRequester()),
        currentInviteUserRoleProvider.overrideWith(() => _FakeUserRole()),
        currentInviteUserIdProvider.overrideWith(() => _FakeUserId()),
      ]);

      await _tapConnectButton(tester);
      await tester.pumpAndSettle();

      // AlreadyConnected dialog expected, not snackbar.
      expect(find.byType(AlertDialog), findsOneWidget);
      // Raw exception string must NOT appear on screen.
      expect(find.textContaining('ApiException'), findsNothing);
      expect(find.textContaining('409'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('네트워크 오류 시 generic snackbar (raw 에러 노출 없음)', (tester) async {
      await _pumpScreen(tester, [
        connectionRequesterProvider.overrideWith(
          () => _NetworkErrorRequester(),
        ),
        currentInviteUserRoleProvider.overrideWith(() => _FakeUserRole()),
        currentInviteUserIdProvider.overrideWith(() => _FakeUserId()),
      ]);

      await _tapConnectButton(tester);
      await tester.pumpAndSettle();

      // Generic snackbar with the safe message.
      expect(
        find.text(AppStrings.inviteConnectionFailed),
        findsOneWidget,
        reason: 'generic snackbar should be shown, not a raw error string',
      );
      // Raw exception must NOT appear.
      expect(find.textContaining('NetworkException'), findsNothing);
      expect(find.textContaining('네트워크 오류'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
