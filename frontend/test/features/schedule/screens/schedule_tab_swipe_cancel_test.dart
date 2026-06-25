import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/core/widgets/swipe_action_tile.dart';
import 'package:lessonaza/features/lessons/domain/entities/lesson.dart';
import 'package:lessonaza/features/lessons/presentation/providers/lesson_crud_provider.dart';
import 'package:lessonaza/features/schedule/presentation/providers/schedule_tab_state_provider.dart';
import 'package:lessonaza/features/schedule/presentation/screens/schedule_tab.dart';

/// #766 — 스와이프 취소가 수강권 차감·정책 우회 회귀 가드.
/// Phase 2b (#931): Dismissible → SwipeActionTile 로 교체.
///
/// 수강권 레슨은 actions=[] (취소 스와이프 비노출).
/// 수동(비수강권) 레슨은 actions=[destructive] + startActions=[convenience].

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
  studentId: 'stu_\$id',
  studentName: '학생 \$id',
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
    Hive.init(Directory.systemTemp.createTempSync().path);
  });

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
    '수강권 레슨 — 취소 SwipeAction 비노출: actions 가 비어 있어야 함',
    (tester) async {
      await pumpScheduleTab(tester, [
        _scheduledLesson(id: 'sub_lesson', date: day, subscriptionId: 'sub_1'),
      ]);

      expect(tester.takeException(), isNull);

      final tile = tester.widget<SwipeActionTile>(
        find.byKey(const ValueKey('lesson-swipe-sub_lesson')),
      );
      expect(
        tile.actions,
        isEmpty,
        reason:
            '수강권 레슨은 취소 SwipeAction(actions) 이 없어야 함 — '
            'plain cancelLesson 이 차감/변경권/휴강 이벤트를 우회 (#766)',
      );
    },
  );

  testWidgets(
    '수동(비수강권) 레슨 — 취소 SwipeAction(destructive) 포함, 완료 startAction(convenience) 포함',
    (tester) async {
      await pumpScheduleTab(tester, [
        _scheduledLesson(id: 'manual_lesson', date: day, subscriptionId: null),
      ]);

      expect(tester.takeException(), isNull);

      final tile = tester.widget<SwipeActionTile>(
        find.byKey(const ValueKey('lesson-swipe-manual_lesson')),
      );
      expect(
        tile.actions.length,
        1,
        reason: '수동 레슨은 취소 SwipeAction(destructive) 1개가 있어야 함',
      );
      expect(tile.actions.first.tone, SwipeActionTone.destructive);
      expect(
        tile.startActions.length,
        1,
        reason: '완료 startAction(convenience) 1개가 있어야 함',
      );
      expect(tile.startActions.first.tone, SwipeActionTone.convenience);
    },
  );
}
