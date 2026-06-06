// #580 — LessonBookingScreen widget smoke + 핵심 인터랙션.
// ux-rules HARD-GATE: top-level 위젯 smoke test 필수.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lessonaza/core/domain/value_objects/clock_time.dart';
import 'package:lessonaza/features/schedule/data/repositories/mock_teacher_availability_repository.dart';
import 'package:lessonaza/features/schedule/domain/entities/availability_slot.dart';
import 'package:lessonaza/features/schedule/presentation/providers/teacher_availability_providers.dart';
import 'package:lessonaza/features/schedule/presentation/screens/lesson_booking_screen.dart';

class _StubRepo extends MockTeacherAvailabilityRepository {
  final List<AvailabilitySlot> slots;
  _StubRepo(this.slots);

  @override
  Future<List<AvailabilitySlot>> getAvailableSlotsForDate(
    String teacherId,
    DateTime date, {
    String? currentStudentId,
  }) async => slots;
}

AvailabilitySlot _slot(String id, int hour) => AvailabilitySlot(
  id: id,
  teacherId: 't1',
  date: DateTime(2026, 6, 10),
  startTime: ClockTime(hour: hour, minute: 0),
  endTime: ClockTime(hour: hour + 1, minute: 0),
  durationMinutes: 50,
  status: AvailabilitySlotStatus.available,
);

Widget _harness(_StubRepo repo) {
  return ProviderScope(
    overrides: [
      teacherAvailabilityRepositoryProvider.overrideWithValue(repo),
    ],
    child: const MaterialApp(
      home: LessonBookingScreen(
        params: LessonBookingParams(
          teacherId: 't1',
          teacherName: '김선생',
          studentId: 's1',
          studentName: '학생',
          instrument: '바이올린',
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('가용 슬롯이 있으면 예외 없이 렌더하고 오전/오후 칩을 표시', (tester) async {
    await tester.pumpWidget(
      _harness(_StubRepo([_slot('a', 10), _slot('b', 14)])),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('10:00'), findsOneWidget); // 오전
    expect(find.text('14:00'), findsOneWidget); // 오후
  });

  testWidgets('슬롯 미선택 시 예약 바(예약하기)가 보이지 않음', (tester) async {
    await tester.pumpWidget(_harness(_StubRepo([_slot('a', 10)])));
    await tester.pumpAndSettle();

    // 예약하기 버튼은 슬롯 선택 후에만 노출.
    expect(find.text('예약하기'), findsNothing);
  });

  testWidgets('슬롯 탭 → 예약하기 바 노출', (tester) async {
    await tester.pumpWidget(_harness(_StubRepo([_slot('a', 10)])));
    await tester.pumpAndSettle();

    await tester.tap(find.text('10:00'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('예약하기'), findsOneWidget);
  });

  testWidgets('가용 슬롯 0개여도 예외 없이 렌더 (빈 상태)', (tester) async {
    await tester.pumpWidget(_harness(_StubRepo(const [])));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
