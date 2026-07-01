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
  testWidgets('렌더 + 등록 분야(음악) 카드 노출 — 예외 없음', (tester) async {
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

  test('#977 게이트 전제: 등록 분야 1개(music) → RoleSelect auto-skip (음악 회귀 0)', () {
    // length == 1 이면 RoleSelectScreen._goToOnboarding 가드가 현행 라우트로
    // 직행한다(분야 선택 화면 미도달 = byte-동일). 2번째 분야 등록(Phase 4) 시
    // 이 단언이 깨지며 분야 선택 흐름을 의식적으로 검토하게 만든다.
    expect(DisciplineRegistry.all.length, 1);
  });
}
