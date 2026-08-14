// #1105 — teacher invite HISTORY: accepted(used)/expired/revoked sections with
// status badges, expired rows expose a 재발송 CTA reusing the existing resend
// flow, empty history shows EmptyStateWidget. The pending dashboard (#5 D-G3)
// stays a separate surface — this only extends the invite history screen.
//
// Spy-mock pattern: myInvitesProvider is overridden with a fixed seed list so
// the screen renders deterministically; inviteRepositoryProvider is a spy that
// records resendInvite calls (synchronous future — no real timers).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/widgets/empty_state_widget.dart';
import 'package:lessonaza/features/invite/presentation/screens/invite_history_screen.dart';
import 'package:lessonaza/features/profile/domain/entities/invite.dart';
import 'package:lessonaza/features/profile/domain/repositories/invite_repository.dart';
import 'package:lessonaza/features/profile/presentation/providers/invite_provider.dart';

/// Records resendInvite calls; every other method is a no-op / empty.
class _SpyInviteRepository implements InviteRepository {
  final List<String> resentIds = [];

  @override
  Future<void> resendInvite(String inviteId) async {
    resentIds.add(inviteId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Invite _invite({
  required String id,
  required String code,
  required InviteStatus status,
  int useCount = 0,
}) {
  final now = DateTime.now();
  return Invite(
    id: id,
    creatorId: 'teacher_1',
    creatorName: '김선생님',
    creatorRole: InviteUserRole.teacher,
    inviteCode: code,
    inviteUrl: 'lessonapp://invite/$code',
    qrCodeData: 'lessonapp://invite/$code',
    status: status,
    createdAt: now.subtract(const Duration(days: 3)),
    // expired invite's expiresAt is in the past; others in the future.
    expiresAt:
        status == InviteStatus.expired
            ? now.subtract(const Duration(days: 1))
            : now.add(const Duration(days: 4)),
    useCount: useCount,
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required List<Invite> invites,
  _SpyInviteRepository? spy,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        myInvitesProvider.overrideWith((ref) async => invites),
        if (spy != null) inviteRepositoryProvider.overrideWithValue(spy),
      ],
      child: const MaterialApp(home: InviteHistoryScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('InviteHistoryScreen — #1105 invite history', () {
    testWidgets('renders used/expired/revoked history sections', (
      tester,
    ) async {
      await _pump(
        tester,
        invites: [
          _invite(id: 'i-used', code: 'USED01', status: InviteStatus.used),
          _invite(id: 'i-exp', code: 'EXP001', status: InviteStatus.expired),
          _invite(id: 'i-rev', code: 'REV001', status: InviteStatus.revoked),
        ],
      );

      expect(tester.takeException(), isNull);
      // Section headers (수락/만료/회수) — issue's three history categories.
      expect(find.text('수락'), findsOneWidget);
      expect(find.text('만료'), findsOneWidget);
      expect(find.text('회수'), findsOneWidget);
      // Each history invite code is rendered.
      expect(find.text('USED01'), findsOneWidget);
      expect(find.text('EXP001'), findsOneWidget);
      expect(find.text('REV001'), findsOneWidget);
    });

    testWidgets('expired row resend triggers repository resendInvite', (
      tester,
    ) async {
      final spy = _SpyInviteRepository();
      await _pump(
        tester,
        spy: spy,
        invites: [
          _invite(id: 'i-exp', code: 'EXP001', status: InviteStatus.expired),
        ],
      );

      // Resend CTA only appears on expired rows.
      final resendButton = find.widgetWithText(FilledButton, '재발송');
      expect(resendButton, findsOneWidget);

      await tester.tap(resendButton);
      await tester.pumpAndSettle();

      expect(spy.resentIds, ['i-exp']);
    });

    testWidgets('used/revoked rows do not show a resend CTA', (tester) async {
      await _pump(
        tester,
        invites: [
          _invite(id: 'i-used', code: 'USED01', status: InviteStatus.used),
          _invite(id: 'i-rev', code: 'REV001', status: InviteStatus.revoked),
        ],
      );

      expect(find.widgetWithText(FilledButton, '재발송'), findsNothing);
    });

    testWidgets('empty history shows EmptyStateWidget', (tester) async {
      await _pump(tester, invites: const []);

      expect(find.byType(EmptyStateWidget), findsOneWidget);
    });

    // #1267 — QR/코드 대상 역할 사전결정: 대상이 지정된 초대는 이력에도 배지가
    // 붙고, 레거시 초대(targetRole=null)는 배지가 없다 (AC4 호환 회귀).
    testWidgets('대상 역할이 있는 초대는 이력에 배지가 표시된다', (tester) async {
      final withTarget = _invite(
        id: 'i-used',
        code: 'USED01',
        status: InviteStatus.used,
      ).copyWith(targetRole: InviteTargetRole.student);

      await _pump(tester, invites: [withTarget]);

      expect(find.text('학생용'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('레거시 초대(targetRole=null)는 배지가 없다', (tester) async {
      await _pump(
        tester,
        invites: [
          _invite(id: 'i-used', code: 'USED01', status: InviteStatus.used),
        ],
      );

      expect(find.text('학생용'), findsNothing);
      expect(find.text('선생님용'), findsNothing);
      expect(find.text('학부모용'), findsNothing);
    });
  });
}
