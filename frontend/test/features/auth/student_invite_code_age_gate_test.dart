import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/providers/repository_provider.dart';
import 'package:lessonaza/core/router/app_routes.dart';
import 'package:lessonaza/features/auth/presentation/screens/student_invite_code_screen.dart';

/// CRITICAL #6 — 만 14세 미만 차단 안전망.
///
/// "코드 없이 시작하기" 진입 시 프로필 설정으로 곧장 이동하던 갭을 막고,
/// 자가신고 연령 게이트를 거치도록 한다 (PASS 통합 전 최소 안전망).
void main() {
  Widget harness() {
    final router = GoRouter(
      initialLocation: AppRoutes.studentInviteCode,
      routes: [
        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) =>
              const Scaffold(body: Text('login page')),
        ),
        GoRoute(
          path: AppRoutes.studentInviteCode,
          builder: (context, state) => const StudentInviteCodeScreen(),
        ),
        GoRoute(
          path: AppRoutes.studentProfileSetup,
          builder: (context, state) =>
              const Scaffold(body: Text('profile setup page')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        // mock mode so remote API is never touched in this flow
        mockDataModeProvider.overrideWithValue(true),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  testWidgets('"코드 없이 시작하기" shows age gate before profile setup', (
    tester,
  ) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    await tester.tap(find.text('코드 없이 시작하기'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.authAgeGateTitle), findsOneWidget);
    expect(find.text(AppStrings.authAgeGateConfirm), findsOneWidget);
    expect(find.text(AppStrings.authAgeGateCancel), findsOneWidget);
    // Must NOT have navigated to profile setup yet.
    expect(find.text('profile setup page'), findsNothing);
  });

  testWidgets('declining the age gate blocks navigation and shows message', (
    tester,
  ) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    await tester.tap(find.text('코드 없이 시작하기'));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.authAgeGateCancel));
    await tester.pumpAndSettle();

    // Gate closed, no profile setup reached.
    expect(find.text(AppStrings.authAgeGateTitle), findsNothing);
    expect(find.text('profile setup page'), findsNothing);
    expect(find.text(AppStrings.authAgeGateBlocked), findsOneWidget);
  });

  testWidgets('confirming 만 14세 이상 proceeds to profile setup', (
    tester,
  ) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    await tester.tap(find.text('코드 없이 시작하기'));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.authAgeGateConfirm));
    await tester.pumpAndSettle();

    expect(find.text('profile setup page'), findsOneWidget);
  });
}
