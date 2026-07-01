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
  testWidgets('렌더 + 등록 분야(음악·헬스) 카드 노출 — 예외 없음 (#979-B)', (tester) async {
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
    expect(find.text(AppStrings.disciplineFitness), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('role 가 null 이어도 안전하게 렌더된다 (deep-link 방어)', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: DisciplineSelectionScreen())),
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

  testWidgets('헬스 분야 선택 → select("fitness") 영속 + 역할 온보딩 이동 (#979-B)', (
    tester,
  ) async {
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

    await tester.tap(find.text(AppStrings.disciplineFitness));
    await tester.pumpAndSettle();

    // Screen persisted the chosen fitness discipline and continued to onboarding.
    expect(spy.selected, [DisciplineRegistry.fitness.id]);
    expect(find.text('student-blocked'), findsOneWidget);
  });

  test('#979-B 게이트 live: 등록 분야 2개(music+fitness) → RoleSelect 가 분야 선택으로 라우팅', () {
    // length > 1 이면 RoleSelectScreen._goToOnboarding 가 DisciplineSelectionScreen
    // 으로 라우팅한다(#977 게이트). Phase 4 에서 fitness 등록으로 게이트가 live 됨.
    expect(DisciplineRegistry.all.length, greaterThan(1));
    expect(
      DisciplineRegistry.all.map((d) => d.id),
      containsAll(<String>['music', 'fitness']),
    );
  });
}
