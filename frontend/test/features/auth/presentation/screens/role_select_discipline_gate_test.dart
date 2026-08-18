// #1278 — RoleSelect 가 분야 선택을 건너뛰고 역할 온보딩으로 직행함을 고정.
//
// #977 이 심은 게이트(role_select_screen.dart `_goToOnboarding`:
// selectableDisciplines().length>1 → 분야 선택 화면)는 #979-B/#1102 가 fitness·
// language 를 등록하는 동안 live 였다. 음악 단일 포커스(#1278)로 등록 분야가
// music 하나가 되면서 게이트가 다시 닫혔다 — 고를 것이 하나뿐인 화면을 사용자에게
// 보여주지 않는다. 이 테스트가 그 라우팅을 실 위젯 흐름으로 가드한다.
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

  testWidgets('#1278 게이트 dormant: 약관 동의 → 역할 탭 → 분야 선택 건너뛰고 역할 온보딩', (
    tester,
  ) async {
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
        // If the gate were wrong (length>1 path), it would land on the
        // discipline picker instead — make that observably different.
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

    // Tap the teacher role → _goToOnboarding → length==1 → role onboarding.
    await tester.tap(find.text(AppStrings.roleSelectTeacher));
    await tester.pumpAndSettle();

    expect(find.text('teacher-onboarding-reached'), findsOneWidget);
    expect(find.text('discipline-select-reached'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
