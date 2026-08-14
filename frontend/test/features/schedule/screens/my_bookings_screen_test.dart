import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/domain/value_objects/clock_time.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/schedule/domain/entities/availability_slot.dart';
import 'package:lessonaza/features/schedule/domain/entities/teacher_availability.dart';
import 'package:lessonaza/features/schedule/domain/repositories/teacher_availability_repository.dart';
import 'package:lessonaza/features/schedule/presentation/providers/teacher_availability_providers.dart';
import 'package:lessonaza/features/schedule/presentation/screens/my_bookings_screen.dart';
import 'package:lessonaza/features/schedule/presentation/widgets/booking_reschedule_bottom_sheet.dart';

/// #1274 회귀: MyBookingsScreen.build() 가 매 build 마다 `DateTime.now()` 를
/// availableSlotsForDateRangeProvider 의 family 키(startDate/endDate)로 직접
/// 넘겨, microsecond 단위로 매번 달라지는 키 때문에 캐시가 절대 히트하지
/// 않고 로딩이 끝없이 반복됐다(pumpAndSettle 타임아웃). build() 안에서 day
/// 단위로 자른 안정 키를 쓰는지 검증한다.
///
/// 즉시 응답하는 mock repo 를 써서 데이터가 안정된 뒤에도 화면에 무한
/// 애니메이션(로딩 스피너 등)이 남지 않게 한다 — 그래야 이 테스트의
/// `pumpAndSettle()` 정지 자체가 유효한 증거가 된다.
class _ImmediateAvailabilityRepo implements TeacherAvailabilityRepository {
  _ImmediateAvailabilityRepo(this._slots);

  final List<AvailabilitySlot> _slots;

  @override
  Future<List<AvailabilitySlot>> getAvailableSlotsForDateRange(
    String teacherId,
    DateTime startDate,
    DateTime endDate, {
    String? currentStudentId,
  }) async => _slots;

  @override
  Future<List<AvailabilitySlot>> getAvailableSlotsForDate(
    String teacherId,
    DateTime date, {
    String? currentStudentId,
  }) async => const <AvailabilitySlot>[];

  @override
  Future<TeacherAvailability?> getAvailability(String teacherId) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final now = DateTime.now();
  final upcomingBooking = AvailabilitySlot(
    id: 'slot1',
    teacherId: 't1',
    date: now.add(const Duration(days: 2)),
    startTime: const ClockTime(hour: 15, minute: 0),
    endTime: const ClockTime(hour: 16, minute: 0),
    durationMinutes: 60,
    status: AvailabilitySlotStatus.myBooking,
    bookedByStudentId: 's1',
  );

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          teacherAvailabilityRepositoryProvider.overrideWithValue(
            _ImmediateAvailabilityRepo([upcomingBooking]),
          ),
        ],
        child: const MaterialApp(
          home: MyBookingsScreen(
            studentId: 's1',
            studentName: '학생',
            teacherId: 't1',
            teacherName: '선생님',
            remainingReschedules: 2,
            totalReschedules: 3,
            subscriptionId: 'sub1',
          ),
        ),
      ),
    );
  }

  testWidgets('예약 데이터가 안정된 뒤 pumpAndSettle 이 정지하고, 변경 탭 시 바텀시트가 뜬다', (
    tester,
  ) async {
    await pumpScreen(tester);

    // family 키가 build 마다 안정적이지 않으면 여기서 타임아웃한다(#1274).
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.rescheduleShort), findsOneWidget);

    await tester.tap(find.text(AppStrings.rescheduleShort));
    await tester.pumpAndSettle();

    expect(find.byType(BookingRescheduleSheet), findsOneWidget);
  });
}
