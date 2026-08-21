// #1267 — QR/코드 대상 역할 사전결정: InviteScreen 생성 흐름.
// 화면 진입 시 자동 생성 대신 3장 선택지를 먼저 보여주고, 카드를 고르면 그
// 대상 역할로만 초대를 생성한다 (기존 동작: 진입 즉시 자동 생성).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/invite/presentation/screens/invite_screen.dart';
import 'package:lessonaza/features/profile/domain/entities/invite.dart';
import 'package:lessonaza/features/profile/domain/repositories/invite_repository.dart';
import 'package:lessonaza/features/profile/presentation/providers/invite_provider.dart';

/// Records createInvite calls; every other method is a no-op / empty —
/// mirrors invite_history_screen_test.dart's spy pattern.
class _SpyInviteRepository implements InviteRepository {
  final List<InviteTargetRole?> createdTargetRoles = [];
  final List<Duration> createdValidities = [];
  int createCallCount = 0;

  @override
  Future<Invite> createInvite({
    required String creatorId,
    required InviteUserRole creatorRole,
    bool isSingleUse = false,
    int? maxUses,
    Duration validity = const Duration(days: 7),
    String? note,
    InviteTargetRole? targetRole,
  }) async {
    createCallCount++;
    createdTargetRoles.add(targetRole);
    createdValidities.add(validity);
    return Invite(
      id: 'invite-created-$createCallCount',
      creatorId: creatorId,
      creatorRole: creatorRole,
      inviteCode: '999999',
      inviteUrl: 'lessonapp://invite/999999',
      qrCodeData: 'lessonapp://invite/999999',
      createdAt: DateTime(2026),
      expiresAt: DateTime(2027),
      targetRole: targetRole,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

GoRouter _router() {
  return GoRouter(
    initialLocation: '/invite',
    routes: [
      GoRoute(path: '/invite', builder: (_, __) => const InviteScreen()),
      GoRoute(
        path: '/invite/history',
        builder: (_, __) => const Scaffold(body: Text('history page')),
      ),
    ],
  );
}

Future<_SpyInviteRepository> _pump(WidgetTester tester) async {
  final spy = _SpyInviteRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [inviteRepositoryProvider.overrideWithValue(spy)],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: _router()),
    ),
  );
  await tester.pumpAndSettle();
  return spy;
}

void main() {
  group('InviteScreen — target role selector (#1267)', () {
    testWidgets('진입 시 자동 생성하지 않고 대상 선택지를 먼저 보여준다', (tester) async {
      final spy = await _pump(tester);

      expect(
        find.text(AppStrings.inviteTargetRoleSelectorTitle),
        findsOneWidget,
      );
      expect(
        find.text(AppStrings.inviteTargetRoleStudentLabel),
        findsOneWidget,
      );
      expect(spy.createCallCount, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('학생용 카드를 고르면 targetRole=student 로 생성한다', (tester) async {
      final spy = await _pump(tester);

      await tester.tap(find.text(AppStrings.inviteTargetRoleStudentLabel));
      await tester.pumpAndSettle();

      expect(spy.createCallCount, 1);
      expect(spy.createdTargetRoles.single, InviteTargetRole.student);
      // Generated invite view shows the target-role badge.
      expect(
        find.text(AppStrings.inviteTargetRoleStudentLabel),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('생성된 초대 화면에 대상 변경 버튼이 있고, 누르면 선택지로 돌아간다', (tester) async {
      await _pump(tester);

      await tester.tap(find.text(AppStrings.inviteTargetRoleTeacherLabel));
      await tester.pumpAndSettle();

      final changeButton = find.text(AppStrings.inviteTargetRoleChangeButton);
      expect(changeButton, findsOneWidget);

      await tester.tap(changeButton);
      await tester.pumpAndSettle();

      expect(
        find.text(AppStrings.inviteTargetRoleSelectorTitle),
        findsOneWidget,
      );
    });
  });

  group('InviteScreen — 학부모 초대 유효기간·가이드 (#1294)', () {
    testWidgets('학부모용 카드는 24시간 유효 초대를 생성한다', (tester) async {
      final spy = await _pump(tester);

      await tester.tap(find.text(AppStrings.inviteTargetRoleParentLabel));
      await tester.pumpAndSettle();

      expect(spy.createdValidities.single, const Duration(hours: 24));
    });

    testWidgets('학생용 카드는 7일 유효 초대를 생성한다', (tester) async {
      final spy = await _pump(tester);

      await tester.tap(find.text(AppStrings.inviteTargetRoleStudentLabel));
      await tester.pumpAndSettle();

      expect(spy.createdValidities.single, const Duration(days: 7));
    });

    testWidgets('학부모용 초대 화면 가이드가 학부모 대상 문구를 보여준다', (tester) async {
      await _pump(tester);

      await tester.tap(find.text(AppStrings.inviteTargetRoleParentLabel));
      await tester.pumpAndSettle();

      expect(
        find.text(AppStrings.inviteShareGuideFormat(AppStrings.parent)),
        findsOneWidget,
      );
      expect(
        find.text(AppStrings.inviteShareGuideFormat(AppStrings.student)),
        findsNothing,
      );
    });

    testWidgets('앱바 타이틀은 대상 중립 "초대하기" 를 사용한다', (tester) async {
      await _pump(tester);

      expect(find.text(AppStrings.inviteScreenTitle), findsOneWidget);
    });
  });
}
