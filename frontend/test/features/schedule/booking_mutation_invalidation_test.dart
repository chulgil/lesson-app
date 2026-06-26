import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/booking/entities/lesson_booking.dart';
import 'package:lessonaza/core/booking/repositories/booking_repository.dart';
import 'package:lessonaza/core/domain/value_objects/clock_time.dart';
import 'package:lessonaza/features/lessons/lessons_facade.dart';
import 'package:lessonaza/features/schedule/domain/entities/availability_slot.dart';
import 'package:lessonaza/features/schedule/domain/entities/teacher_availability.dart';
import 'package:lessonaza/features/schedule/domain/repositories/teacher_availability_repository.dart';
import 'package:lessonaza/features/schedule/presentation/providers/teacher_availability_providers.dart';

/// #528 회귀: 변경(reschedule)·취소(cancel) 흐름이 SlotBookingNotifier 의
/// `bookSlotSimple` / `cancelBooking` 을 호출하면서 `ref.invalidateSelf()` 만
/// 했다. 그러면 예약 목록(availableSlotsForDateRangeProvider)과 학생 홈 다음
/// 레슨 카드(studentBookingsProvider → studentHomeNextLessonProvider)가
/// 갱신되지 않아 성공 토스트만 뜨고 화면이 stale 했다.
///
/// 이 테스트는 두 read provider 가 mutation 후 재요청(re-fetch)되는지를
/// 호출 카운트로 검증한다. (RED: invalidate 추가 전엔 카운트가 1 에 머문다.)
class _CountingAvailabilityRepo implements TeacherAvailabilityRepository {
  int slotRangeFetchCount = 0;

  @override
  Future<List<AvailabilitySlot>> getAvailableSlotsForDateRange(
    String teacherId,
    DateTime startDate,
    DateTime endDate, {
    String? currentStudentId,
  }) async {
    slotRangeFetchCount++;
    return const <AvailabilitySlot>[];
  }

  // 리드타임 필터용 — null 이면 minBookingHours 0 으로 처리.
  @override
  Future<TeacherAvailability?> getAvailability(String teacherId) async => null;

  @override
  Future<AvailabilitySlot> cancelBooking(String slotId) async =>
      AvailabilitySlot(
        id: slotId,
        teacherId: 't1',
        date: DateTime(2026, 1, 1),
        startTime: const ClockTime(hour: 10, minute: 0),
        endTime: const ClockTime(hour: 11, minute: 0),
        durationMinutes: 60,
      );

  @override
  Future<AvailabilitySlot> bookSlot(
    String slotId,
    String studentId,
    String studentName,
  ) async => AvailabilitySlot(
    id: slotId,
    teacherId: 't1',
    date: DateTime(2026, 1, 1),
    startTime: const ClockTime(hour: 10, minute: 0),
    endTime: const ClockTime(hour: 11, minute: 0),
    durationMinutes: 60,
    status: AvailabilitySlotStatus.myBooking,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _CountingBookingRepo implements BookingRepository {
  int studentBookingsFetchCount = 0;

  @override
  Future<List<LessonBooking>> getBookingsByStudent(String studentId) async {
    studentBookingsFetchCount++;
    return const <LessonBooking>[];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _CountingAvailabilityRepo availabilityRepo;
  late _CountingBookingRepo bookingRepo;
  late ProviderContainer container;

  setUp(() {
    availabilityRepo = _CountingAvailabilityRepo();
    bookingRepo = _CountingBookingRepo();
    container = ProviderContainer(
      overrides: [
        teacherAvailabilityRepositoryProvider.overrideWithValue(
          availabilityRepo,
        ),
        bookingRepositoryProvider.overrideWithValue(bookingRepo),
      ],
    );
    addTearDown(container.dispose);
  });

  /// 두 read provider 를 alive 로 유지 + 초기 fetch 를 강제한다.
  Future<void> primeReadProviders() async {
    container.listen(
      availableSlotsForDateRangeProvider(
        teacherId: 't1',
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 3, 1),
        currentStudentId: 's1',
      ),
      (_, _) {},
      fireImmediately: true,
    );
    container.listen(
      studentBookingsProvider('s1'),
      (_, _) {},
      fireImmediately: true,
    );
    await container.pump();
  }

  test('cancelBooking 후 예약목록 + 학생예약 provider 가 재요청된다', () async {
    await primeReadProviders();
    final slotsBefore = availabilityRepo.slotRangeFetchCount;
    final bookingsBefore = bookingRepo.studentBookingsFetchCount;
    expect(slotsBefore, 1);
    expect(bookingsBefore, 1);

    await container
        .read(slotBookingNotifierProvider.notifier)
        .cancelBooking('slot1', studentId: 's1');
    await container.pump();

    expect(
      availabilityRepo.slotRangeFetchCount,
      greaterThan(slotsBefore),
      reason: 'availableSlotsForDateRangeProvider 가 invalidate 되어 재요청돼야 한다',
    );
    expect(
      bookingRepo.studentBookingsFetchCount,
      greaterThan(bookingsBefore),
      reason: 'studentBookingsProvider 가 invalidate 되어 재요청돼야 한다',
    );
  });

  test('bookSlotSimple 후 예약목록 + 학생예약 provider 가 재요청된다', () async {
    await primeReadProviders();
    final slotsBefore = availabilityRepo.slotRangeFetchCount;
    final bookingsBefore = bookingRepo.studentBookingsFetchCount;

    await container
        .read(slotBookingNotifierProvider.notifier)
        .bookSlotSimple('slot1', 's1', '학생');
    await container.pump();

    expect(availabilityRepo.slotRangeFetchCount, greaterThan(slotsBefore));
    expect(bookingRepo.studentBookingsFetchCount, greaterThan(bookingsBefore));
  });
}
