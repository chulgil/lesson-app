import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/domain/value_objects/clock_time.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/schedule/data/repositories/mock_teacher_availability_repository.dart';
import 'package:lessonaza/features/schedule/domain/entities/availability_slot.dart';
import 'package:lessonaza/features/schedule/presentation/providers/teacher_availability_providers.dart';
import 'package:lessonaza/features/schedule/presentation/widgets/booking_reschedule_bottom_sheet.dart';

/// 변경(reschedule)도 취소와 동일한 마감정책(reschedule_credit_spec §3,
/// CancellationCreditPolicy = SSOT)을 따르는지.
/// - 마감 전: 변경권 0이어도 무료(변경 허용) → 기존 버그(remaining<=0 게이트)가 막던 것
/// - 마감 후 + 잔여 0: 차단(변경 불가)
/// - 마감 후 + 잔여>0: 가능(1회 차감)
///
/// 항상 렌더되는 변경권 배지로 검증한다(액션 버튼은 슬롯 선택 후에만 표시).
/// 타이밍 결정성: 레슨은 항상 now+2일. deadlineHours 로 마감 전/후를 뒤집는다
/// (12h → deadline 미래=마감 전 / 100h → deadline 과거=마감 후). 벽시계 무관.
///
/// #1268 — 풀스크린 `BookingRescheduleScreen`을 바텀시트 `BookingRescheduleSheet`로
/// 통합(schedule_change_unification_spec.md §2.3, 즉시확정 정책은 불변). 시트
/// 콘텐츠 위젯은 public이라 모달 트리거 없이 직접 pump 가능.

/// 슬롯을 지연 없이 1개 반환해 빈 상태(nextAvailableDates) 진입과 Timer 누출을 막는다.
class _ImmediateRepo extends MockTeacherAvailabilityRepository {
  @override
  Future<List<AvailabilitySlot>> getAvailableSlotsForDate(
    String teacherId,
    DateTime date, {
    String? currentStudentId,
  }) async => [
    AvailabilitySlot(
      id: 'slot1',
      teacherId: teacherId,
      date: date,
      startTime: const ClockTime(hour: 15, minute: 0),
      endTime: const ClockTime(hour: 16, minute: 0),
      durationMinutes: 60,
      status: AvailabilitySlotStatus.available,
    ),
  ];
}

void main() {
  Future<void> pumpReschedule(
    WidgetTester tester, {
    required int remaining,
    required int total,
    required int deadlineHours,
  }) async {
    final now = DateTime.now();
    final lessonDay = now.add(const Duration(days: 2));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          teacherAvailabilityRepositoryProvider.overrideWithValue(
            _ImmediateRepo(),
          ),
        ],
        child: MaterialApp(
          home: BookingRescheduleSheet(
            teacherId: 't1',
            teacherName: '선생님',
            studentId: 's1',
            studentName: '학생',
            currentBookingId: 'b1',
            currentDate: lessonDay,
            currentStartTime: TimeOfDay(hour: now.hour, minute: now.minute),
            remainingReschedules: remaining,
            totalReschedules: total,
            subscriptionId: 'sub1',
            cancelDeadlineHours: deadlineHours,
          ),
        ),
      ),
    );
    // Badge renders on the first build; drain the mock repo's 100ms timers so
    // they don't leak past dispose.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('마감 전 + 변경권 0 → 무료 배지 (변경 허용)', (tester) async {
    await pumpReschedule(tester, remaining: 0, total: 2, deadlineHours: 12);
    expect(find.text(AppStrings.rescheduleNoCreditUsed), findsOneWidget);
  });

  testWidgets('마감 후 + 변경권 0 → 차단 배지 (변경 불가)', (tester) async {
    await pumpReschedule(tester, remaining: 0, total: 2, deadlineHours: 100);
    expect(
      find.text(AppStrings.bookingRescheduleQuotaUsed(2, 2)),
      findsOneWidget,
    );
    expect(find.text(AppStrings.rescheduleNoCreditUsed), findsNothing);
  });

  testWidgets('마감 후 + 변경권 2 → 일반(가능) 배지, 무료·차단 아님', (tester) async {
    await pumpReschedule(tester, remaining: 2, total: 2, deadlineHours: 100);
    expect(find.text(AppStrings.rescheduleNoCreditUsed), findsNothing);
    expect(
      find.text(AppStrings.bookingRescheduleQuotaUsed(0, 2)),
      findsNothing,
    );
  });
}
