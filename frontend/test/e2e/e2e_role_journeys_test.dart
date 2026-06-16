// #731 Gate 3 — 역할별 E2E 여정 (로컬 반복형)
//
// 실제 GoRouter 앱 셸을 띄워 3역할 핵심 여정을 구동한다. 목적은 flutter analyze
// 가 통과시키는 런타임 렌더 크래시(BoxConstraints / RenderMetaData / dead route)
// 를 화면 횡단으로 잡는 것 (Gate 1 정적 스캔의 런타임 보완).
//
// 각 여정은 (1) 역할 홈 렌더 (2) 실제 라우트/탭 네비게이션으로 액션 화면 도달
// (3) 매 단계 takeException()==null 을 확정 단언한다. 종단 액션(레슨 완료·노트
// 저장)은 해당 mock 데이터가 있을 때 수행한다(best-effort) — 게이트의 본질은
// 렌더 안전성이며, 기능 정확성은 단위/위젯 테스트가 담당한다.
//
// 실행 (디바이스 불필요 — flutter_tester 헤드리스):
//   flutter test test/e2e/e2e_role_journeys_test.dart
// 전체 스위트(`flutter test`)에도 포함되어 매 실행마다 게이트로 동작한다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/home/presentation/widgets/lesson_card.dart';
import 'package:lessonaza/features/lessons/presentation/screens/lesson_detail_screen.dart';
import 'package:lessonaza/features/practice_journal/presentation/screens/practice_journal_screen.dart';

import 'helpers/e2e_harness.dart';

void main() {
  setUpAll(initE2eEnvironment);
  tearDownAll(disposeE2eEnvironment);

  testWidgets('교사 — 레슨 상세 → (가능 시) 완료 처리', (tester) async {
    await bootAsRole(tester, DevAccount.teacher);

    // 대시보드(탭 I)는 오늘 레슨을 LessonCard 로 보여준다.
    final lessonCards = find.byType(LessonCard);
    expect(lessonCards, findsWidgets, reason: '교사 홈 대시보드에 레슨 카드가 있어야 함');

    // 실제 GoRouter push(/lessons/:id) → 레슨 상세 렌더.
    await tester.ensureVisible(lessonCards.first);
    await settle(tester);
    await tester.tap(lessonCards.first);
    await settle(tester);
    expect(
      find.byType(LessonDetailScreen),
      findsOneWidget,
      reason: '레슨 상세 화면(실제 라우트)에 도달해야 함',
    );
    expect(tester.takeException(), isNull, reason: '레슨 상세 렌더 크래시 없음');

    // 상단 오버플로 메뉴 렌더.
    final menu = find.byType(PopupMenuButton<String>);
    expect(menu, findsOneWidget, reason: '레슨 상세 상단 액션 메뉴');
    await tester.tap(menu);
    await settle(tester);
    expect(tester.takeException(), isNull, reason: '레슨 액션 메뉴 렌더 크래시 없음');

    // scheduled 레슨이면 완료 처리까지 — 확인 다이얼로그 → 스낵바.
    final markComplete = find.text(AppStrings.markComplete);
    if (markComplete.evaluate().isNotEmpty) {
      await tester.tap(markComplete);
      await settle(tester);
      await tester.tap(find.text(AppStrings.completeAction).last);
      await settle(tester);
      expect(
        find.text(AppStrings.lessonCompletedSnack),
        findsOneWidget,
        reason: '레슨 완료 스낵바',
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('학생 — 연습 탭 → (가능 시) 연습노트 저장', (tester) async {
    await bootAsRole(tester, DevAccount.student);

    // 하단 내비 III → 연습 탭 (IndexedStack index 2) 렌더.
    await tester.tap(find.text(AppStrings.navPractice));
    await settle(tester);
    expect(tester.takeException(), isNull, reason: '연습 탭 전환 렌더 크래시 없음');

    // 노트 추가 진입 — 섹션 시트 / 노트 다이얼로그 / 빈상태 스낵바 중 하나 렌더.
    final addNote = find.byTooltip(AppStrings.practiceNoteAddTooltip);
    expect(addNote, findsOneWidget, reason: '연습노트 추가 버튼');
    await tester.tap(addNote);
    await settle(tester);
    expect(tester.takeException(), isNull, reason: '연습노트 추가 진입 렌더 크래시 없음');

    // 섹션 선택 시트가 떴으면 섹션(library_music 타일)을 고른다.
    if (find.text(AppStrings.practiceNotePickSection).evaluate().isNotEmpty) {
      await tester.tap(
        find.widgetWithIcon(ListTile, Icons.library_music).first,
      );
      await settle(tester);
    }

    // 노트 다이얼로그가 떴으면 입력 → 저장 → 스낵바.
    final field = find.byType(TextField);
    if (field.evaluate().isNotEmpty) {
      await tester.enterText(field.first, '오늘 연습 완료');
      await settle(tester);
      await tester.tap(find.widgetWithText(FilledButton, '저장'));
      await settle(tester);
      expect(
        find.text(AppStrings.practiceNoteAddedSnack),
        findsOneWidget,
        reason: '연습노트 추가 스낵바',
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('학부모 — 연습장 카드 → 연습장 상세', (tester) async {
    await bootAsRole(tester, DevAccount.parent);

    // 부모 대시보드의 연습장 카드까지 노출 후 탭 → 연습장 상세 렌더.
    final journalCard = find.text(AppStrings.journalTitleStandard);
    expect(journalCard, findsWidgets, reason: '부모 대시보드에 연습장 카드가 있어야 함');
    await tester.ensureVisible(journalCard.first);
    await settle(tester);
    await tester.tap(journalCard.first);
    await settle(tester);
    expect(tester.takeException(), isNull, reason: '연습장 진입 렌더 크래시 없음');

    expect(
      find.byType(PracticeJournalScreen),
      findsOneWidget,
      reason: '연습장 상세 화면에 도달해야 함',
    );
  });
}
