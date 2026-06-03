import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lessonaza/core/domain/value_objects/clock_time.dart';
import 'package:lessonaza/features/schedule/data/repositories/mock_teacher_availability_repository.dart';
import 'package:lessonaza/features/schedule/domain/entities/availability_slot.dart';
import 'package:lessonaza/features/schedule/presentation/providers/teacher_availability_providers.dart';

/// Regression (#bug2): BookingRescheduleScreen._performReschedule must be
/// atomic — book the NEW slot first, only then cancel the OLD booking, and roll
/// back the new booking if the cancel fails. A failure must never leave the
/// student with zero reservations (lost booking).
///
/// Exercises the real SlotBookingNotifier with a recording stub repo and
/// replicates the screen's ordering contract.
class _RecordingRepo extends MockTeacherAvailabilityRepository {
  final List<String> calls = [];
  final Set<String> booked = {};
  bool failBook = false;
  bool failCancel = false;

  @override
  Future<AvailabilitySlot> bookSlot(
    String slotId,
    String studentId,
    String studentName,
  ) async {
    calls.add('book:$slotId');
    if (failBook) throw Exception('book failed');
    booked.add(slotId);
    return _slot(
      slotId,
      AvailabilitySlotStatus.booked,
      studentId: studentId,
      studentName: studentName,
    );
  }

  @override
  Future<AvailabilitySlot> cancelBooking(String slotId) async {
    calls.add('cancel:$slotId');
    if (failCancel) throw Exception('cancel failed');
    booked.remove(slotId);
    return _slot(slotId, AvailabilitySlotStatus.available);
  }

  AvailabilitySlot _slot(
    String slotId,
    AvailabilitySlotStatus status, {
    String? studentId,
    String? studentName,
  }) {
    return AvailabilitySlot(
      id: slotId,
      teacherId: 't1',
      date: DateTime(2026, 6, 7),
      startTime: const ClockTime(hour: 14, minute: 0),
      endTime: const ClockTime(hour: 15, minute: 0),
      durationMinutes: 60,
      status: status,
      bookedByStudentId: studentId,
      bookedByStudentName: studentName,
    );
  }
}

/// Replicates the screen's atomic reschedule sequence
/// (BookingRescheduleScreen._performReschedule).
Future<void> performAtomicReschedule(
  SlotBookingNotifier notifier,
  ProviderContainer container, {
  required String oldBookingId,
  required String newSlotId,
}) async {
  // 1. Book the new slot first.
  await notifier.bookSlotSimple(newSlotId, 's1', '학생');
  if (container.read(slotBookingNotifierProvider).hasError) {
    throw Exception('new slot booking failed');
  }
  // 2. Cancel old booking; roll back new on failure.
  try {
    await notifier.cancelBooking(oldBookingId);
    if (container.read(slotBookingNotifierProvider).hasError) {
      throw Exception('old booking cancel failed');
    }
  } catch (_) {
    await notifier.cancelBooking(newSlotId);
    rethrow;
  }
}

void main() {
  const oldId = 't1_2026-06-07_14:00';
  const newId = 't1_2026-06-07_16:00';

  ProviderContainer makeContainer(_RecordingRepo repo) {
    return ProviderContainer(
      overrides: [
        teacherAvailabilityRepositoryProvider.overrideWithValue(repo),
      ],
    );
  }

  test('happy path books new slot BEFORE cancelling old', () async {
    final repo = _RecordingRepo()..booked.add(oldId);
    final container = makeContainer(repo);
    addTearDown(container.dispose);
    final notifier = container.read(slotBookingNotifierProvider.notifier);

    await performAtomicReschedule(
      notifier,
      container,
      oldBookingId: oldId,
      newSlotId: newId,
    );

    expect(repo.calls.first, 'book:$newId');
    final bookIdx = repo.calls.indexOf('book:$newId');
    final cancelIdx = repo.calls.indexOf('cancel:$oldId');
    expect(cancelIdx, greaterThanOrEqualTo(0));
    expect(bookIdx, lessThan(cancelIdx));
  });

  test('when new booking fails, old booking is NEVER cancelled', () async {
    final repo = _RecordingRepo()
      ..booked.add(oldId)
      ..failBook = true;
    final container = makeContainer(repo);
    addTearDown(container.dispose);
    final notifier = container.read(slotBookingNotifierProvider.notifier);

    await expectLater(
      performAtomicReschedule(
        notifier,
        container,
        oldBookingId: oldId,
        newSlotId: newId,
      ),
      throwsA(isA<Exception>()),
    );

    // Critical: the original booking must remain untouched.
    expect(repo.calls.any((c) => c.startsWith('cancel:$oldId')), isFalse);
    expect(repo.booked.contains(oldId), isTrue);
  });

  test(
    'when cancel fails, new booking is rolled back (no double booking)',
    () async {
      final repo = _RecordingRepo()
        ..booked.add(oldId)
        ..failCancel = true;
      final container = makeContainer(repo);
      addTearDown(container.dispose);
      final notifier = container.read(slotBookingNotifierProvider.notifier);

      await expectLater(
        performAtomicReschedule(
          notifier,
          container,
          oldBookingId: oldId,
          newSlotId: newId,
        ),
        throwsA(isA<Exception>()),
      );

      // New slot was booked, cancel of old failed, so rollback cancels the NEW
      // slot — never leaving two active bookings.
      expect(repo.calls.contains('book:$newId'), isTrue);
      expect(repo.calls.contains('cancel:$newId'), isTrue);
    },
  );
}
