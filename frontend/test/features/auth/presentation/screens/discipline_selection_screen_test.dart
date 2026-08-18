// #977 — DisciplineSelectionScreen widget smoke + multi-discipline gate guard.
// #979-A — discipline selection persists the choice before role onboarding.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lessonaza/core/domain/value_objects/discipline_registry.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/router/app_routes.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/auth/domain/entities/user_role.dart';
import 'package:lessonaza/features/auth/presentation/providers/active_discipline_provider.dart';
import 'package:lessonaza/features/auth/presentation/screens/discipline_selection_screen.dart';
import 'package:lessonaza/core/widgets/onboarding_step_header.dart';

/// Records `select` calls without touching Hive, so the screen's tap→persist
/// wiring can be verified with real navigation (spy pattern — real storage I/O
/// is covered in active_discipline_provider_test.dart).
class _SpyStorage extends SelectedDisciplineStorage {
  final selected = <String>[];

  @override
  Future<String?> build() async => null;

  @override
  Future<void> select(String disciplineId) async {
    selected.add(disciplineId);
    state = AsyncData(disciplineId);
  }
}

void main() {
  testWidgets('렌더 + 등록 분야(음악) 카드 노출 — 예외 없음 (#1278)', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: const DisciplineSelectionScreen(role: UserRole.student),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.disciplineSelectTitle), findsOneWidget);
    expect(find.text(AppStrings.disciplineMusic), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('role 가 null 이어도 안전하게 렌더된다 (deep-link 방어)', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: DisciplineSelectionScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.disciplineSelectTitle), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('음악 분야 선택 → select 영속 호출 + 역할 온보딩으로 이동 (#979-A)', (tester) async {
    final spy = _SpyStorage();
    final router = GoRouter(
      initialLocation: '/discipline',
      routes: [
        GoRoute(
          path: '/discipline',
          builder:
              (_, __) =>
                  const DisciplineSelectionScreen(role: UserRole.student),
        ),
        GoRoute(
          path: AppRoutes.studentSignupBlocked,
          builder: (_, __) => const Scaffold(body: Text('student-blocked')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [selectedDisciplineStorageProvider.overrideWith(() => spy)],
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.disciplineMusic));
    await tester.pumpAndSettle();

    // Screen persisted the chosen discipline via the storage notifier...
    expect(spy.selected, [DisciplineRegistry.music.id]);
    // ...and continued to the role's onboarding route.
    expect(find.text('student-blocked'), findsOneWidget);
  });

  testWidgets('뒤로가기 → 역할 선택으로 복귀한다 (M7, 0702 감사)', (tester) async {
    final router = GoRouter(
      initialLocation: '/discipline',
      routes: [
        GoRoute(
          path: '/discipline',
          builder:
              (_, __) =>
                  const DisciplineSelectionScreen(role: UserRole.student),
        ),
        GoRoute(
          path: AppRoutes.roleSelect,
          builder: (_, __) => const Scaffold(body: Text('role-select')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('role-select'), findsOneWidget);
  });

  test('#1278 게이트 dormant: 등록 분야 1개(music) → RoleSelect 가 분야 선택을 건너뛴다', () {
    // RoleSelectScreen._goToOnboarding 는 selectableDisciplines().length > 1 일
    // 때만 이 화면으로 라우팅한다(#977 게이트). 음악 단일 포커스에서는 고를 것이
    // 하나뿐이라 게이트가 닫히고 역할 온보딩으로 직행한다 — 화면 자체는 딥링크
    // 방어용으로 유지되며 위 테스트들이 렌더를 가드한다.
    expect(DisciplineRegistry.all.map((d) => d.id).toList(), ['music']);
  });

  testWidgets('#1104 선생님 역할일 때 스텝 헤더(2/4 분야 선택 활성)를 표시한다', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: const DisciplineSelectionScreen(role: UserRole.teacher),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingStepHeader), findsOneWidget);
    final header = tester.widget<OnboardingStepHeader>(
      find.byType(OnboardingStepHeader),
    );
    expect(header.steps, OnboardingStepHeader.teacherSteps);
    expect(header.currentStep, 2, reason: '분야 선택은 4단계 중 2번째');
    expect(tester.takeException(), isNull);
  });

  testWidgets('#1104 학생·학부모 역할에는 스텝 헤더를 표시하지 않는다 (교사 전용)', (tester) async {
    for (final role in const [UserRole.student, UserRole.parent]) {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light,
            home: DisciplineSelectionScreen(role: role),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byType(OnboardingStepHeader),
        findsNothing,
        reason: '$role 플로우에는 교사 스텝 헤더가 없어야 한다',
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('#1104 role 이 null 이면 스텝 헤더를 표시하지 않는다 (deep-link 방어)', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: DisciplineSelectionScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingStepHeader), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
