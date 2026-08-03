// #980 — RoleSelect → DisciplineSelection 라우팅이 live 임을 behavioral 로 고정.
//
// #977 이 심은 게이트(role_select_screen.dart `_goToOnboarding`: all.length>1 →
// 분야 선택 화면)는 #979-B 가 fitness 를 등록해 length==2 가 되면서 live 됐다.
// #979-B 는 length·화면 단언까지만 커버했고, RoleSelect 를 실제로 mount·탭 해
// 분야 선택 화면으로 이동하는 경로는 미검증이었다(리뷰 defer ②). 이 테스트가
// 그 now-live 경로를 실 위젯 흐름으로 가드한다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lessonaza/core/auth/auth_state.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/router/app_routes.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/auth/domain/entities/user_role.dart';
import 'package:lessonaza/features/auth/presentation/providers/auth_provider.dart';
import 'package:lessonaza/features/auth/presentation/screens/role_select_screen.dart';

/// Auth already in onboarding for [role], so tapping that role card takes
/// RoleSelectScreen._selectRole's early `_goToOnboarding(role)` branch (no repo).
class _OnboardingStubAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthNeedsOnboarding(
    userId: 'u1',
    name: '테스트',
    email: 't@test.com',
    role: UserRole.teacher,
  );

  @override
  void acceptTerms({bool marketingConsent = false}) {
    // no-op: no auth repository wired in this widget test.
  }
}

void main() {
  // RoleSelectScreen (NotebookScreenScaffold) uses Playfair via google_fonts;
  // navigating away unmounts it, so keep tests offline (no dangling font fetch).
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('#980 게이트 live: 약관 동의 → 역할 탭 → 분야 선택 화면으로 라우팅', (tester) async {
    final router = GoRouter(
      initialLocation: AppRoutes.roleSelect,
      routes: [
        GoRoute(
          path: AppRoutes.roleSelect,
          builder: (_, __) => const RoleSelectScreen(),
        ),
        GoRoute(
          path: AppRoutes.disciplineSelection,
          builder:
              (_, __) =>
                  const Scaffold(body: Text('discipline-select-reached')),
        ),
        // Fallback: if the gate were wrong (length==1 path), it would land on a
        // role onboarding route instead — make that observably different.
        GoRoute(
          path: AppRoutes.teacherProfileSetup,
          builder:
              (_, __) =>
                  const Scaffold(body: Text('teacher-onboarding-reached')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(() => _OnboardingStubAuth()),
        ],
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    // Accept required terms (전체 동의) so the role cards become tappable.
    await tester.tap(find.text(AppStrings.authTermsSelectAll));
    await tester.pumpAndSettle();
    // Terms accepted → consent-required hint gone + role cards enabled. Assert
    // this settled state before tapping (guards a cold-start nav flake).
    expect(find.text(AppStrings.roleSelectConsentRequired), findsNothing);

    // Tap the teacher role → _goToOnboarding → all.length>1 → discipline select.
    await tester.tap(find.text(AppStrings.roleSelectTeacher));
    await tester.pumpAndSettle();

    expect(find.text('discipline-select-reached'), findsOneWidget);
    expect(find.text('teacher-onboarding-reached'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
