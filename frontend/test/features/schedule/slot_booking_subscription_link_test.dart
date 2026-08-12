// #580 Gap B — SlotBookingNotifier.bookSlot 이 LessonBookingParams.subscriptionId
// 를 BookingRepository.requestTrialLesson 까지 끝까지 전달하는지 검증.
// SSOT: docs/specs/schedule/student_direct_booking_spec.md §6.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/booking/entities/lesson_booking.dart';
import 'package:lessonaza/core/booking/repositories/booking_repository.dart';
import 'package:lessonaza/core/domain/value_objects/clock_time.dart';
import 'package:lessonaza/features/lessons/presentation/providers/booking_repository_provider.dart';
import 'package:lessonaza/features/schedule/domain/entities/availability_slot.dart';
import 'package:lessonaza/features/schedule/domain/entities/teacher_availability.dart';
import 'package:lessonaza/features/schedule/domain/repositories/teacher_availability_repository.dart';
import 'package:lessonaza/features/schedule/presentation/providers/teacher_availability_providers.dart';

class _StubAvailabilityRepo implements TeacherAvailabilityRepository {
  @override
  Future<AvailabilitySlot> bookSlot(
    String slotId,
    String studentId,
    String studentName,
  ) async => AvailabilitySlot(
    id: slotId,
    teacherId: 't1',
    date: DateTime(2026, 6, 10),
    startTime: const ClockTime(hour: 10, minute: 0),
    endTime: const ClockTime(hour: 11, minute: 0),
    durationMinutes: 60,
    status: AvailabilitySlotStatus.myBooking,
  );

  @override
  Future<TeacherAvailability?> getAvailability(String teacherId) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Captures the subscriptionId passed to requestTrialLesson without exercising
/// the real HTTP/mock persistence layer.
class _CapturingBookingRepo implements BookingRepository {
  String? capturedSubscriptionId;
  int callCount = 0;

  @override
  Future<LessonBooking> requestTrialLesson({
    required String teacherId,
    required String teacherName,
    required TrialLessonRequest request,
    required int fee,
    String? subscriptionId,
  }) async {
    callCount++;
    capturedSubscriptionId = subscriptionId;
    return LessonBooking(
      id: 'booking_test',
      teacherId: teacherId,
      teacherName: teacherName,
      studentId: request.studentId,
      studentName: request.studentName,
      lessonType: LessonType.trial,
      status: BookingStatus.pending,
      lessonDate: request.effectiveDate,
      startTime: request.effectiveStartTime,
      endTime: request.effectiveEndTime,
      fee: fee,
      subscriptionId: subscriptionId,
      createdAt: DateTime(2026, 6, 10),
    );
  }

  @override
  Future<List<LessonBooking>> getAllBookings() async => const <LessonBooking>[];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _StubAvailabilityRepo availabilityRepo;
  late _CapturingBookingRepo bookingRepo;
  late ProviderContainer container;

  setUp(() {
    availabilityRepo = _StubAvailabilityRepo();
    bookingRepo = _CapturingBookingRepo();
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

  test('subscriptionId 가 requestTrialLesson 까지 전달된다', () async {
    await container
        .read(slotBookingNotifierProvider.notifier)
        .bookSlot(
          'slot1',
          's1',
          '학생',
          teacherId: 't1',
          teacherName: '김선생',
          slotDate: DateTime(2026, 6, 10),
          slotStartTime: const TimeOfDay(hour: 10, minute: 0),
          slotEndTime: const TimeOfDay(hour: 11, minute: 0),
          subscriptionId: 'sub-active-1',
        );

    expect(bookingRepo.callCount, 1);
    expect(bookingRepo.capturedSubscriptionId, 'sub-active-1');
  });

  test('subscriptionId 미전달 시 null 로 전달된다 (기존 신청 플로우 무회귀)', () async {
    await container
        .read(slotBookingNotifierProvider.notifier)
        .bookSlot(
          'slot1',
          's1',
          '학생',
          teacherId: 't1',
          teacherName: '김선생',
          slotDate: DateTime(2026, 6, 10),
          slotStartTime: const TimeOfDay(hour: 10, minute: 0),
          slotEndTime: const TimeOfDay(hour: 11, minute: 0),
        );

    expect(bookingRepo.callCount, 1);
    expect(bookingRepo.capturedSubscriptionId, isNull);
  });
}
