// UXB-2 #1289 — 초대 딥링크로 역할 선택을 건너뛰고 도착한 학생 초대코드 화면.
//
// 검증 대상:
//   1. 배너 + 보조 링크 노출 (건너뛴 사실을 밝히고 탈출구를 준다)
//   2. redirect 로 왔으므로 route extra 가 없다 — provider 의 코드로 prefill
//   3. 무효/만료 코드는 기존 인라인 에러로 자연 낙하 (화면 유지)
//   4. 보조 링크 → 코드 비우고 roleSelect (spy 라우터)
//   5. 코드 없는 일반 진입은 배너 없음 (기존 흐름 불변)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lessonaza/core/auth/auth_state.dart';
import 'package:lessonaza/core/deep_link/pending_invite_code_provider.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/providers/repository_provider.dart';
import 'package:lessonaza/core/router/app_routes.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/auth/auth_facade.dart';
import 'package:lessonaza/features/auth/presentation/providers/auth_provider.dart';
import 'package:lessonaza/features/auth/presentation/screens/student_invite_code_screen.dart';
import 'package:lessonaza/features/profile/domain/entities/invite.dart';
import 'package:lessonaza/features/profile/presentation/providers/invite_provider.dart';

const _code = '424242';

/// 역할 미확정 세션 — 딥링크 role-skip 이 성립하는 유일한 상태.
class _SpyAuthNotifier extends AuthNotifier {
  int setRoleCalls = 0;
  UserRole? lastRole;

  @override
  AuthState build() =>
      const AuthNeedsRole(userId: 'u-1', name: '새 사용자', email: 'u@test.com');

  @override
  Future<void> setRole(UserRole role) async {
    setRoleCalls++;
    lastRole = role;
    state = AuthNeedsOnboarding(
      userId: 'u-1',
      name: '새 사용자',
      email: 'u@test.com',
      role: role,
    );
  }
}

Invite _validInvite() => Invite(
  id: 'invite-uxb2',
  creatorId: 'teacher-1',
  creatorName: '김선생',
  creatorRole: InviteUserRole.teacher,
  inviteCode: _code,
  inviteUrl: 'lessonapp://invite/$_code',
  qrCodeData: 'lessonapp://invite/$_code',
  status: InviteStatus.active,
  expiresAt: DateTime.now().add(const Duration(days: 6)),
  createdAt: DateTime.now().subtract(const Duration(days: 1)),
  targetRole: InviteTargetRole.student,
);

/// roleSelect 로의 이동만 관측하는 spy 라우터 — 실제 RoleSelectScreen 을
/// 띄우지 않아 그 화면의 프로바이더 의존에 물리지 않는다.
GoRouter _spyRouter() => GoRouter(
  initialLocation: AppRoutes.studentInviteCode,
  routes: [
    GoRoute(
      path: AppRoutes.studentInviteCode,
      builder: (_, _) => const StudentInviteCodeScreen(),
    ),
    GoRoute(
      path: AppRoutes.roleSelect,
      builder: (_, _) => const Scaffold(body: Text('role-select-spy')),
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (_, _) => const Scaffold(body: Text('login-spy')),
    ),
    GoRoute(
      path: AppRoutes.studentProfileSetup,
      builder: (_, _) => const Scaffold(body: Text('student-profile-setup')),
    ),
  ],
);

ProviderContainer _container({
  required String? pendingCode,
  required Invite? Function() lookup,
  _SpyAuthNotifier? auth,
}) {
  return ProviderContainer(
    overrides: [
      mockDataModeProvider.overrideWithValue(true),
      pendingInviteCodeProvider.overrideWith((ref) => pendingCode),
      inviteByCodeProvider(_code).overrideWith((ref) async => lookup()),
      if (auth != null) authNotifierProvider.overrideWith(() => auth),
    ],
  );
}

Future<void> _pump(WidgetTester tester, ProviderContainer container) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: _spyRouter(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('딥링크 코드 보유 시 배너와 보조 링크가 보인다', (tester) async {
    // 무효 코드로 두어 확인 화면으로 넘어가지 않고 화면에 머물게 한다.
    final container = _container(pendingCode: _code, lookup: () => null);
    addTearDown(container.dispose);
    await _pump(tester, container);

    expect(find.text(AppStrings.inviteDeepLinkStudentBanner), findsOneWidget);
    expect(find.text(AppStrings.inviteDeepLinkRoleSwitch), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('무효·만료 코드는 기존 인라인 에러로 자연 낙하한다', (tester) async {
    final container = _container(pendingCode: _code, lookup: () => null);
    addTearDown(container.dispose);
    await _pump(tester, container);

    // 기존 InviteCodeDigitInput 의 에러 경로 — 새 에러 처리를 만들지 않았다.
    expect(find.text(AppStrings.inviteCodeNotFound), findsOneWidget);
    // 화면을 벗어나지 않으므로 재입력 가능.
    expect(find.byType(TextField), findsNWidgets(6));
  });

  testWidgets('유효 코드는 route extra 없이도 prefill·자동제출되어 확인 화면으로 간다', (
    tester,
  ) async {
    final auth = _SpyAuthNotifier();
    final container = _container(
      pendingCode: _code,
      lookup: _validInvite,
      auth: auth,
    );
    addTearDown(container.dispose);
    await _pump(tester, container);

    expect(find.text(AppStrings.inviteConnectionRequest), findsOneWidget);
    expect(auth.setRoleCalls, 1, reason: '역할 미확정 사용자는 코드가 유효할 때 학생으로 확정되어야 한다');
    expect(auth.lastRole, UserRole.student);
    expect(
      container.read(pendingInviteCodeProvider),
      isNull,
      reason: '코드는 라우팅 목적을 다했으므로 소진되어야 한다',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('보조 링크 → 코드를 비우고 roleSelect 로 빠져나간다', (tester) async {
    final container = _container(pendingCode: _code, lookup: () => null);
    addTearDown(container.dispose);
    await _pump(tester, container);

    await tester.tap(find.text(AppStrings.inviteDeepLinkRoleSwitch));
    await tester.pumpAndSettle();

    expect(find.text('role-select-spy'), findsOneWidget);
    expect(
      container.read(pendingInviteCodeProvider),
      isNull,
      reason: '코드가 남아 있으면 auth 가드가 다시 초대코드 화면으로 튕긴다',
    );
  });

  testWidgets('코드 없는 일반 진입은 배너 없이 기존 화면 그대로', (tester) async {
    final container = _container(pendingCode: null, lookup: () => null);
    addTearDown(container.dispose);
    await _pump(tester, container);

    expect(find.text(AppStrings.inviteDeepLinkStudentBanner), findsNothing);
    expect(find.text(AppStrings.inviteDeepLinkRoleSwitch), findsNothing);
    expect(find.byType(TextField), findsNWidgets(6));
    expect(tester.takeException(), isNull);
  });
}
