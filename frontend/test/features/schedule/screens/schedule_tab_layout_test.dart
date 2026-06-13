import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_colors.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_masthead.dart';
import 'package:lessonaza/features/lessons/domain/entities/lesson.dart';
import 'package:lessonaza/features/lessons/presentation/providers/lesson_crud_provider.dart';
import 'package:lessonaza/features/schedule/presentation/providers/schedule_tab_state_provider.dart';
import 'package:lessonaza/features/schedule/presentation/providers/schedule_view_mode_provider.dart';
import 'package:lessonaza/features/schedule/presentation/providers/teacher_availability_providers.dart';
import 'package:lessonaza/features/schedule/presentation/providers/vacation_providers.dart';
import 'package:lessonaza/features/schedule/presentation/providers/week_lessons_provider.dart';
import 'package:lessonaza/features/schedule/presentation/screens/schedule_tab.dart';
import 'package:lessonaza/features/schedule/presentation/widgets/sticky_schedule_header_delegate.dart';

/// Hive 우회: build() 에서 weeklyGrid 고정 (codegen Notifier 서브클래스).
class _WeeklyGridViewMode extends ScheduleViewModeNotifier {
  @override
  ScheduleViewMode build() => ScheduleViewMode.weeklyGrid;
}

/// 주(weekStart) 를 결정적으로 고정 — family provider override 와 정합.
class _FixedSelectedDate extends TeacherSelectedDate {
  @override
  DateTime build() => DateTime(2026, 6, 8); // 월요일
}

/// P1-3 — schedule_tab compact header + sticky WeekStrip 회귀 가드.
///
/// 목적:
/// - list 모드: compact toolbar 는 짧게 시작하고,
///   SliverPersistentHeader(pinned) 가 CompactWeekStrip + DateHeader 를 sticky 로 유지.
/// - 업무형 스케줄 화면에서는 장식성 Masthead/Programme 헤더를 제거해
///   하위 스크롤 영역을 확보한다.
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

  testWidgets('list 모드 — 홈/수강관리와 같은 paper 표면과 masthead를 노출', (tester) async {
    await pumpScheduleTab(tester);

    expect(
      find.byWidgetPredicate(
        (widget) => widget is ColoredBox && widget.color == AppColors.paper,
      ),
      findsAtLeastNWidgets(1),
    );
    expect(find.text('SCHEDULE'), findsOneWidget);
    expect(find.byType(NotebookMasthead), findsOneWidget);
    expect(find.byTooltip(AppStrings.addLessonTooltip), findsOneWidget);
    expect(find.text('Programme of Schedule'), findsNothing);
    expect(find.text('Schedule'), findsNothing);
  });

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
    // CompactWeekStrip(약 80) + DateHeader(약 36) + compact spacing.
    // 위젯이 변경되면 이 가드가 회귀를 잡는다.
    expect(delegate.minExtent, equals(delegate.maxExtent));
    expect(delegate.minExtent, greaterThan(80.0));
    expect(delegate.minExtent, lessThan(160.0));
  });

  testWidgets(
    'list 모드 — 빈 레슨 리스트에서도 sticky 헤더 + EmptyState 가 SliverFillRemaining 으로 안정 렌더',
    (tester) async {
      await pumpScheduleTab(tester);

      expect(tester.takeException(), isNull);
      expect(find.byType(SliverFillRemaining), findsOneWidget);
    },
  );

  testWidgets(
    'weeklyGrid 모드 (Phase A) — list 와 동일한 CustomScrollView + sticky WeekStrip collapse 구조, 그리드를 sliver 에 intrinsic 임베드해도 크래시 없음',
    (tester) async {
      final monday = DateTime(2026, 6, 8);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            // weeklyGrid 모드 고정 + 결정적 주(weekStart) 고정.
            scheduleViewModeNotifierProvider.overrideWith(
              () => _WeeklyGridViewMode(),
            ),
            teacherSelectedDateProvider.overrideWith(
              () => _FixedSelectedDate(),
            ),
            // sticky 헤더용 일별 레슨 + 그리드용 주간 레슨/가용시간/휴가 —
            // 즉시 완료하는 빈 값으로 실제 repository 체인 차단.
            lessonsProvider.overrideWith((ref) async => const <Lesson>[]),
            weekLessonsProvider(
              monday,
            ).overrideWith((ref) async => const <Lesson>[]),
            teacherAvailabilityProvider(
              'teacher_1',
            ).overrideWith((ref) async => null),
            vacationListProvider.overrideWith((ref) async => const []),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const Scaffold(body: ScheduleTab()),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(
        tester.takeException(),
        isNull,
        reason:
            'weeklyGrid collapse 레이아웃에서 intrinsic 그리드를 SliverToBoxAdapter 에 '
            '임베드해도 BoxConstraints/RenderBox 크래시가 없어야 한다',
      );

      // list 모드와 동일한 collapse 구조 — CustomScrollView + sticky delegate.
      expect(find.byType(CustomScrollView), findsOneWidget);
      expect(find.byType(SliverPersistentHeader), findsOneWidget);
      // 시그니처 — 펼친 상태에서 masthead 보존.
      expect(find.text('SCHEDULE'), findsOneWidget);
      expect(find.byType(NotebookMasthead), findsOneWidget);
    },
  );
}
