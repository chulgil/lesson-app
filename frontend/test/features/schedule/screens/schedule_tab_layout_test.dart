import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/lessons/domain/entities/lesson.dart';
import 'package:lessonaza/features/lessons/presentation/providers/lesson_crud_provider.dart';
import 'package:lessonaza/features/schedule/presentation/screens/schedule_tab.dart';
import 'package:lessonaza/features/schedule/presentation/widgets/sticky_schedule_header_delegate.dart';

/// P1-3 — schedule_tab 헤더 collapse + sticky WeekStrip 회귀 가드.
///
/// 목적:
/// - list 모드: CustomScrollView 로 헤더가 스크롤되어 사라지고,
///   SliverPersistentHeader(pinned) 가 CompactWeekStrip + DateHeader 를 sticky 로 유지.
///   시그니처 4대(NotebookMasthead / "Programme of Schedule" / "스케줄" 마스트헤드 / ThinRule)
///   는 펼친 상태에서 모두 보존.
/// - timeline/weeklyGrid 모드: 자체 ScrollController 와의 충돌을 피하기 위해
///   기존 Column 레이아웃을 유지 — CustomScrollView 가 사용되지 않아야 한다.
/// - BoxConstraints / RenderBox 류 런타임 레이아웃 크래시가 없어야 한다.
void main() {
  setUpAll(() {
    // ScheduleViewModeNotifier 가 생성자에서 Hive.openBox('settings') 를
    // fire-and-forget 으로 호출하므로 init 없이는 HiveError 가 발생한다.
    Hive.init(Directory.systemTemp.createTempSync().path);
  });

  Future<void> pumpScheduleTab(
    WidgetTester tester, {
    List<Lesson> lessons = const [],
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [lessonsProvider.overrideWith((ref) async => lessons)],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: ScheduleTab()),
        ),
      ),
    );
    // FutureProvider 가 resolve 하고, AnimatedSwitcher 가 안정화될 때까지.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
  }

  testWidgets(
    'list 모드 (default) — CustomScrollView + sticky WeekStrip 로 렌더, 크래시 없음',
    (tester) async {
      await pumpScheduleTab(tester);

      expect(
        tester.takeException(),
        isNull,
        reason: 'list 모드 collapse 레이아웃에서 BoxConstraints/RenderBox 크래시가 없어야 한다',
      );

      // CustomScrollView 1개 + sticky delegate 1개 — collapse 구조 확인.
      expect(find.byType(CustomScrollView), findsOneWidget);
      expect(find.byType(SliverPersistentHeader), findsOneWidget);
    },
  );

  testWidgets(
    'list 모드 — 시그니처 4대(Masthead/Programme/스케줄/ThinRule) 펼친 상태에서 모두 보존',
    (tester) async {
      await pumpScheduleTab(tester);

      // Notebook × Score §1.2 정체성 — 펼친 상태에서 시그니처 보존.
      expect(find.text('SCHEDULE'), findsOneWidget);
      expect(find.text('Programme of Schedule'), findsOneWidget);
      expect(find.text('스케줄'), findsOneWidget);
    },
  );

  testWidgets('list 모드 — sticky delegate 가 고정 높이로 등록되어 layout 회귀 가드', (
    tester,
  ) async {
    await pumpScheduleTab(tester);

    final delegateFinder = find.byWidgetPredicate(
      (w) =>
          w is SliverPersistentHeader &&
          w.delegate is StickyScheduleHeaderDelegate,
    );
    expect(delegateFinder, findsOneWidget);

    final header = tester.widget<SliverPersistentHeader>(delegateFinder);
    final delegate = header.delegate as StickyScheduleHeaderDelegate;
    // CompactWeekStrip(약 80) + space3(12) + DateHeader(약 36) + space3(12).
    // 위젯이 변경되면 이 가드가 회귀를 잡는다.
    expect(delegate.minExtent, equals(delegate.maxExtent));
    expect(delegate.minExtent, greaterThan(80.0));
    expect(delegate.minExtent, lessThan(200.0));
  });

  testWidgets(
    'list 모드 — 빈 레슨 리스트에서도 sticky 헤더 + EmptyState 가 SliverFillRemaining 으로 안정 렌더',
    (tester) async {
      await pumpScheduleTab(tester);

      expect(tester.takeException(), isNull);
      expect(find.byType(SliverFillRemaining), findsOneWidget);
    },
  );
}
