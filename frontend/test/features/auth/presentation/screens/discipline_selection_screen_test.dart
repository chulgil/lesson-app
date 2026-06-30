// #977 — DisciplineSelectionScreen widget smoke + multi-discipline gate guard.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/domain/value_objects/discipline_registry.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/auth/domain/entities/user_role.dart';
import 'package:lessonaza/features/auth/presentation/screens/discipline_selection_screen.dart';

void main() {
  testWidgets('렌더 + 등록 분야(음악) 카드 노출 — 예외 없음', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const DisciplineSelectionScreen(role: UserRole.student),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.disciplineSelectTitle), findsOneWidget);
    expect(find.text(AppStrings.disciplineMusic), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('role 가 null 이어도 안전하게 렌더된다 (deep-link 방어)', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: DisciplineSelectionScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.disciplineSelectTitle), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('#977 게이트 전제: 등록 분야 1개(music) → RoleSelect auto-skip (음악 회귀 0)', () {
    // length == 1 이면 RoleSelectScreen._goToOnboarding 가드가 현행 라우트로
    // 직행한다(분야 선택 화면 미도달 = byte-동일). 2번째 분야 등록(Phase 4) 시
    // 이 단언이 깨지며 분야 선택 흐름을 의식적으로 검토하게 만든다.
    expect(DisciplineRegistry.all.length, 1);
  });
}
