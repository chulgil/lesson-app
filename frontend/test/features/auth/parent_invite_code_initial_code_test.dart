// #1267 — QR 스캔으로 온 신규 학부모 사용자는 코드를 이미 알고 있으므로 수동
// 입력 없이 자동 제출되어야 한다 (ParentInviteCodeScreen 에는 공유 digit-input
// 위젯이 없어 화면 자체가 initState 에서 prefill+auto-submit 한다).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lessonaza/core/providers/repository_provider.dart';
import 'package:lessonaza/core/router/app_routes.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/auth/presentation/screens/parent_invite_code_screen.dart';
import 'package:lessonaza/features/profile/domain/entities/invite.dart';
import 'package:lessonaza/features/profile/domain/repositories/invite_repository.dart';
import 'package:lessonaza/features/profile/presentation/providers/invite_provider.dart';

/// getInviteByCode 만 구현하는 spy — ParentInviteCodeScreen._handleSubmitCode
/// 는 repository 를 직접 읽어 호출하므로 inviteByCodeProvider 오버라이드로는
/// 닿지 않는다.
class _SpyInviteRepository implements InviteRepository {
  _SpyInviteRepository(this._invite);
  final Invite? _invite;

  @override
  Future<Invite?> getInviteByCode(String code) async => _invite;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Invite _fakeInvite() => Invite(
  id: 'invite-1267-parent',
  creatorId: 'teacher-1',
  creatorName: '김선생',
  creatorRole: InviteUserRole.teacher,
  inviteCode: 'PARENT1',
  inviteUrl: 'lessonapp://invite/PARENT1',
  qrCodeData: 'lessonapp://invite/PARENT1',
  status: InviteStatus.active,
  expiresAt: DateTime.now().add(const Duration(hours: 20)),
  createdAt: DateTime.now().subtract(const Duration(hours: 1)),
  targetRole: InviteTargetRole.parent,
);

GoRouter _router(String? initialCode) {
  return GoRouter(
    initialLocation: '/parent/invite-code',
    routes: [
      GoRoute(
        path: '/parent/invite-code',
        builder: (_, __) => ParentInviteCodeScreen(initialCode: initialCode),
      ),
      GoRoute(
        path: AppRoutes.parentHome,
        builder: (_, __) => const Scaffold(body: Text('parent home page')),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const Scaffold(body: Text('login page')),
      ),
    ],
  );
}

void main() {
  testWidgets('initialCode 가 주어지면 코드 입력 없이 자동 제출되어 parent-home 으로 이동한다', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mockDataModeProvider.overrideWithValue(true),
          inviteRepositoryProvider.overrideWithValue(
            _SpyInviteRepository(_fakeInvite()),
          ),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: _router('PARENT1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('parent home page'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('initialCode 없이 진입하면 기존처럼 코드 입력 필드가 비어 있다', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [mockDataModeProvider.overrideWithValue(true)],
        child: MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: _router(null),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('parent home page'), findsNothing);
    final field = tester.widget<TextFormField>(find.byType(TextFormField));
    expect(field.controller!.text, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
