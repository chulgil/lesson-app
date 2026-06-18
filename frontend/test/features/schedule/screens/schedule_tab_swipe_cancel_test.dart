import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/lessons/domain/entities/lesson.dart';
import 'package:lessonaza/features/lessons/presentation/providers/lesson_crud_provider.dart';
import 'package:lessonaza/features/schedule/presentation/providers/schedule_tab_state_provider.dart';
import 'package:lessonaza/features/schedule/presentation/screens/schedule_tab.dart';

/// #766 — 스와이프 취소가 수강권 차감·정책 우회 회귀 가드.
///
/// 교사 스케줄 탭(list 모드)의 레슨 카드는 우→좌(endToStart) 스와이프로 취소된다.
/// 이 경로는 plain `cancelLesson` 만 호출해 수강권 차감 되돌림/변경권/휴강 이벤트를
/// 우회한다 → 수강권 레슨은 취소 스와이프를 노출하지 않아야 한다(상세 휴강 플로우로만).
/// 수동(비수강권) 레슨은 기존대로 양방향(완료+취소) 스와이프 유지.

/// 결정적 selectedDate 고정 — list 필터(date == selectedDate)와 정합.
class _FixedSelectedDate extends TeacherSelectedDate {
  _FixedSelectedDate(this._date);
  final DateTime _date;
  @override
  DateTime build() => _date;
}

Lesson _scheduledLesson({
  required String id,
  required DateTime date,
  String? subscriptionId,
}) => Lesson(
  id: id,
  studentId: 'stu_$id',
  studentName: '학생 $id',
  teacherId: 'teacher_1',
  instrument: '바이올린',
  date: date,
  startTime: '10:00',
  status: LessonStatus.scheduled,
  subscriptionId: subscriptionId,
  createdAt: DateTime(2026, 1, 1),
);

void main() {
  setUpAll(() {
    // ScheduleViewModeNotifier 가 생성자에서 Hive.openBox('settings') 를
    // fire-and-forget 으로 호출하므로 init 없이는 HiveError 가 발생한다.
    Hive.init(Directory.systemTemp.createTempSync().path);
  });

  // 미래 일자 고정 — displayStatus 가 scheduled 로 남아 스와이프 카드(Dismissible)
  // 가 렌더되도록(과거 scheduled 는 displayStatus 가 completed 로 자동 전환됨).
  final base = DateTime.now().add(const Duration(days: 2));
  final day = DateTime(base.year, base.month, base.day);

  Future<void> pumpScheduleTab(
    WidgetTester tester,
    List<Lesson> lessons,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          lessonsProvider.overrideWith((ref) async => lessons),
          teacherSelectedDateProvider.overrideWith(
            () => _FixedSelectedDate(day),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: ScheduleTab()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
  }

  testWidgets(
    '수강권 레슨 — 취소 스와이프(우→좌) 비활성: Dismissible.direction == startToEnd',
    (tester) async {
      await pumpScheduleTab(tester, [
        _scheduledLesson(id: 'sub_lesson', date: day, subscriptionId: 'sub_1'),
      ]);

      expect(tester.takeException(), isNull);

      final dismissible = tester.widget<Dismissible>(
        find.byKey(const ValueKey('lesson-swipe-sub_lesson')),
      );
      expect(
        dismissible.direction,
        DismissDirection.startToEnd,
        reason:
            '수강권 레슨은 취소 스와이프(endToStart)를 노출하면 안 됨 — '
            'plain cancelLesson 이 차감/변경권/휴강 이벤트를 우회 (#766)',
      );
    },
  );

  testWidgets(
    '수동(비수강권) 레슨 — 양방향 스와이프 유지: Dismissible.direction == horizontal',
    (tester) async {
      await pumpScheduleTab(tester, [
        _scheduledLesson(id: 'manual_lesson', date: day, subscriptionId: null),
      ]);

      expect(tester.takeException(), isNull);

      final dismissible = tester.widget<Dismissible>(
        find.byKey(const ValueKey('lesson-swipe-manual_lesson')),
      );
      expect(
        dismissible.direction,
        DismissDirection.horizontal,
        reason: '수동 레슨은 기존대로 완료(좌→우)+취소(우→좌) 양방향 스와이프 유지',
      );
    },
  );
}
