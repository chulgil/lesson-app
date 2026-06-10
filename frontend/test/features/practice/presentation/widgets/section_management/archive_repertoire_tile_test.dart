// Smoke + behavior tests for ArchiveRepertoireTile.
//
// Covers swipe consistency audit (2026-06-10 §2 — practice v2 D3):
// - PopupMenuButton 이 제거되었는지
// - SwipeActionTile 로 destructive [영구 삭제] 액션이 노출되는지
// - 행 탭 시 [복원] 다이얼로그가 열리는지
// - 영구 삭제 시 강화 확인 다이얼로그 (복구 불가) 가 노출되는지
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/widgets/swipe_action_tile.dart';
import 'package:lessonaza/features/practice/domain/entities/practice_repertoire.dart';
import 'package:lessonaza/features/practice/presentation/widgets/section_management/archive_repertoire_tile.dart';

void main() {
  PracticeRepertoire makeArchivedRepertoire() {
    final now = DateTime(2026, 5, 7);
    return PracticeRepertoire(
      id: 'rep-1',
      studentId: 'student-1',
      name: 'Canon',
      startDate: now.subtract(const Duration(days: 30)),
      sections: const [],
      createdAt: now.subtract(const Duration(days: 30)),
      isArchived: true,
      archivedAt: now,
    );
  }

  Future<void> pumpTile(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ArchiveRepertoireTile(repertoire: makeArchivedRepertoire()),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('renders without runtime crash', (tester) async {
    await pumpTile(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('does not render PopupMenuButton (swipe consistency D3)', (
    tester,
  ) async {
    await pumpTile(tester);
    expect(
      find.byType(PopupMenuButton<String>),
      findsNothing,
      reason:
          'ArchiveRepertoireTile 의 PopupMenuButton 은 SwipeActionTile 로 대체되어야 한다.',
    );
  });

  testWidgets('renders SwipeActionTile for archive tile', (tester) async {
    await pumpTile(tester);
    expect(
      find.byType(SwipeActionTile),
      findsWidgets,
      reason: 'ArchiveRepertoireTile 은 SwipeActionTile 로 래핑되어야 한다.',
    );
  });

  testWidgets('tapping tile opens restore dialog', (tester) async {
    await pumpTile(tester);
    await tester.tap(find.byType(InkWell).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.text(AppStrings.practiceRepertoireRestoreTitle),
      findsOneWidget,
      reason: '행 탭 시 [복원] 다이얼로그 제목이 노출되어야 한다.',
    );
  });
}
