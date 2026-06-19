import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/booking/entities/time_slot.dart';
import 'package:lessonaza/features/lessons/domain/entities/lesson.dart';
import 'package:lessonaza/features/schedule/presentation/widgets/alternative_time_grid.dart';

/// 회색 화면(#64 후속) 회귀 가드 — 일정 위젯도 비정상 remote startTime 에서
/// 파싱 크래시로 회색화되면 안 된다. schedule 위젯의 시간 파싱은 ClockTime.parse
/// (total)로 위임됐다. AlternativeTimeGrid 는 lessons 를 파라미터로 받으므로
/// provider 셋업 없이 적대적 입력을 직접 주입할 수 있다.
void main() {
  for (final bad in const ['', '09', '09:00:00']) {
    testWidgets('AlternativeTimeGrid: startTime="$bad" 파싱 크래시 없이 렌더', (
      tester,
    ) async {
      final weekStart = DateTime(2026, 5, 4);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 420,
              height: 360,
              child: AlternativeTimeGrid(
                weekStart: weekStart,
                lessons: [
                  Lesson(
                    id: 'l1',
                    studentId: 's1',
                    studentName: '학생',
                    instrument: '피아노',
                    date: weekStart,
                    startTime: bad,
                    duration: 60,
                    createdAt: DateTime(2026, 5, 1),
                  ),
                ],
                suggestedSlots: const <TimeSlot>[],
                onEmptyCellTap: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(AlternativeTimeGrid), findsOneWidget);
      final ex = tester.takeException();
      expect(ex, isNot(isA<FormatException>()));
      expect(ex, isNot(isA<RangeError>()));
    });
  }
}
