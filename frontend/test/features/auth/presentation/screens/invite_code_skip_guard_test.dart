import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lessonaza/core/auth/auth_state.dart';
import 'package:lessonaza/core/providers/repository_provider.dart';
import 'package:lessonaza/core/router/app_routes.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/auth/auth_facade.dart';
import 'package:lessonaza/features/auth/presentation/providers/auth_provider.dart';
import 'package:lessonaza/features/auth/presentation/screens/parent_invite_code_screen.dart';
import 'package:lessonaza/features/auth/presentation/screens/student_invite_code_screen.dart';

/// #103/#104: 온보딩 skip 경로의 더블탭 가드.
/// 진행 중(_isLoading) 재탭이 completeOnboarding PATCH·age-gate·navigation 을
/// 중복 실행하지 않아야 한다.

class _SpyAuthNotifier extends AuthNotifier {
  int completeOnboardingCalls = 0;

  @override
  AuthState build() => const AuthNeedsOnboarding(
    userId: 'real-user-1',
    name: '사용자',
    email: 'u@test.com',
    role: UserRole.parent,
  );

  @override
  Future<void> completeOnboarding() async {
    completeOnboardingCalls++;
  }
}

GoRouter _router(Widget initial) {
  return GoRouter(
    initialLocation: '/invite',
    routes: [
      GoRoute(path: '/invite', builder: (_, __) => initial),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const Scaffold(body: Text('login')),
      ),
      GoRoute(
        path: AppRoutes.parentHome,
        builder: (_, __) => const Scaffold(body: Text('parent-home')),
      ),
      GoRoute(
        path: AppRoutes.studentProfileSetup,
        builder: (_, __) => const Scaffold(body: Text('student-profile-setup')),
      ),
    ],
  );
}

Future<void> _pump(
  WidgetTester tester,
  Widget screen,
  _SpyAuthNotifier auth,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        mockDataModeProvider.overrideWithValue(false),
        authNotifierProvider.overrideWith(() => auth),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: _router(screen),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('#103 학부모 skip 더블탭 → completeOnboarding 1회만 호출', (tester) async {
    final auth = _SpyAuthNotifier();
    await _pump(tester, const ParentInviteCodeScreen(), auth);

    final skip = find.text('코드가 없어도 괜찮아요');
    expect(skip, findsOneWidget);

    // 더블탭 (첫 탭의 async 완료 전 재탭).
    await tester.tap(skip);
    await tester.tap(skip);
    await tester.pumpAndSettle();

    expect(
      auth.completeOnboardingCalls,
      1,
      reason: '진행 중 재탭은 무시되어 PATCH 가 정확히 1회여야 한다 (#103)',
    );
  });

  testWidgets('#104 학생 "코드 없이 시작" 탭 시 진행 중 버튼 비활성화 (재탭 가드)', (tester) async {
    final auth = _SpyAuthNotifier();
    await _pump(tester, const StudentInviteCodeScreen(), auth);

    final skip = find.text('코드 없이 시작하기');
    expect(skip, findsOneWidget);

    OutlinedButton skipButton() => tester.widget<OutlinedButton>(
      find.ancestor(of: skip, matching: find.byType(OutlinedButton)),
    );
    // 탭 전: 활성.
    expect(skipButton().onPressed, isNotNull);

    await tester.tap(skip);
    // 한 프레임만 진행 — setState(_isLoading=true) 반영(스피너 무한 애니메이션이라
    // pumpAndSettle 금지).
    await tester.pump();

    // 진행 중에는 skip 버튼이 비활성 → 재탭(중복 age-gate/navigation) 차단.
    expect(
      skipButton().onPressed,
      isNull,
      reason: '진행 중 skip 버튼은 비활성이어야 한다 (#104 더블탭 가드)',
    );
  });
}
