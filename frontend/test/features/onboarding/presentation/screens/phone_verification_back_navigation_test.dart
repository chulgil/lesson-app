// #1287 UXC-8 — 전화인증 뒤로가기 데드엔드 회귀 가드.
//
// 프로덕션 진입점은 둘 다 홈이다: 퀘스트 행은 push, E3 게이트 모달은 go.
// 그런데 뒤로가기는 이미 끝낸 온보딩 프로필 폼(/onboarding/profile-setup)을
// 다시 열어 사용자를 가입 흐름 안에 가뒀다.
//
// 목적지 라우트는 타이머·비동기 프로바이더가 없는 스텁이다 (전화인증 화면의
// build 는 provider 를 watch 하지 않으므로 pending timer 크래시가 없다).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lessonaza/core/router/app_routes.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/onboarding/presentation/screens/phone_verification_screen.dart';

const _homeMarker = 'HOME_STUB';
const _profileSetupMarker = 'PROFILE_SETUP_STUB';

void main() {
  GoRouter buildRouter({required bool enterFromHome}) {
    return GoRouter(
      initialLocation:
          enterFromHome ? AppRoutes.home : AppRoutes.teacherPhoneVerification,
      routes: [
        GoRoute(
          path: AppRoutes.home,
          builder:
              (context, state) => Scaffold(
                body: Center(
                  child: TextButton(
                    // 퀘스트 행과 같은 push 진입.
                    onPressed:
                        () => context.push(AppRoutes.teacherPhoneVerification),
                    child: const Text(_homeMarker),
                  ),
                ),
              ),
        ),
        GoRoute(
          path: AppRoutes.teacherPhoneVerification,
          builder: (context, state) => const PhoneVerificationScreen(),
        ),
        GoRoute(
          path: AppRoutes.teacherProfileSetup,
          builder:
              (context, state) => const Scaffold(
                body: Center(child: Text(_profileSetupMarker)),
              ),
        ),
      ],
    );
  }

  Future<void> pump(WidgetTester tester, GoRouter router) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('퀘스트에서 push 로 진입하면 뒤로가기가 홈으로 돌아간다', (tester) async {
    await pump(tester, buildRouter(enterFromHome: true));

    await tester.tap(find.text(_homeMarker));
    await tester.pumpAndSettle();
    expect(find.byType(PhoneVerificationScreen), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text(_homeMarker), findsOneWidget);
    expect(
      find.text(_profileSetupMarker),
      findsNothing,
      reason: '이미 끝낸 온보딩 폼으로 되돌리면 안 된다',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('게이트에서 go 로 진입해 스택이 없어도 온보딩 폼이 아닌 홈으로 나간다', (tester) async {
    await pump(tester, buildRouter(enterFromHome: false));
    expect(find.byType(PhoneVerificationScreen), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text(_homeMarker), findsOneWidget);
    expect(find.text(_profileSetupMarker), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
