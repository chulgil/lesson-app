// R3 (audit 2026-07-10) — the booking re-entrancy guard must engage BEFORE the
// first await, so a double tap on a slow network cannot stack two confirm
// dialogs and create duplicate bookings (D2-class TOCTOU).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lessonaza/core/domain/value_objects/clock_time.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/schedule/data/repositories/mock_teacher_availability_repository.dart';
import 'package:lessonaza/features/schedule/domain/entities/availability_slot.dart';
import 'package:lessonaza/features/schedule/domain/entities/teacher_availability.dart';
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

  /// Slow lead-time lookup: models the slow network that opens the double-tap
  /// window inside `_confirmAndBook` (the guard must engage before this await).
  @override
  Future<TeacherAvailability?> getAvailability(String teacherId) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return null;
  }
}

AvailabilitySlot _slot(String id, int hour) => AvailabilitySlot(
  id: id,
  teacherId: 't1',
  date: DateTime.now().add(const Duration(days: 7)),
  startTime: ClockTime(hour: hour, minute: 0),
  endTime: ClockTime(hour: hour + 1, minute: 0),
  durationMinutes: 50,
  status: AvailabilitySlotStatus.available,
);

void main() {
  testWidgets('예약 버튼 첫 탭 직후 가드가 걸려 재진입(중복 확인 다이얼로그)이 불가능하다', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          teacherAvailabilityRepositoryProvider.overrideWithValue(
            _StubRepo([_slot('slot1', 14)]),
          ),
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
      ),
    );
    await tester.pumpAndSettle();

    // Select the slot → the "예약하기" bar appears.
    await tester.tap(find.text('14:00'));
    await tester.pumpAndSettle();
    expect(find.text('예약하기'), findsOneWidget);

    // Two taps while the lead-time lookup (400ms) is still pending — exactly
    // the slow-network window a late guard leaves open.
    await tester.tap(find.text('예약하기'), warnIfMissed: false);
    await tester.pump();
    await tester.tap(find.text('예약하기'), warnIfMissed: false);
    await tester.pump();

    // Let both lookups resolve. The confirm dialog stays open (no settle).
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();

    // A single confirm dialog — a late guard stacks two (duplicate booking).
    expect(
      find.text(AppStrings.lessonBookingConfirmTitle).evaluate().length,
      1,
      reason: '가드가 await 뒤에 걸리면 확인 다이얼로그가 2중첩되어 중복 예약 가능 (R3)',
    );
  });
}
