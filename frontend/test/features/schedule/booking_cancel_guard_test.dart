import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lessonaza/core/domain/value_objects/clock_time.dart';
import 'package:lessonaza/features/schedule/data/repositories/mock_teacher_availability_repository.dart';
import 'package:lessonaza/features/schedule/domain/entities/availability_slot.dart';
import 'package:lessonaza/features/schedule/presentation/providers/teacher_availability_providers.dart';

/// Regression (#fix1): BookingCancelScreen._performCancel must NOT report
/// success or deduct a reschedule allowance when the cancel actually failed.
/// SlotBookingNotifier.cancelBooking swallows errors into AsyncValue.error, so
/// the screen guards on `hasError` (symmetry with the reschedule flow, #483).
///
/// This exercises the real SlotBookingNotifier with a recording stub repo and
/// replicates the screen's cancel-then-guard contract.
class _RecordingRepo extends MockTeacherAvailabilityRepository {
  final List<String> calls = [];
  bool failCancel = false;

  @override
  Future<AvailabilitySlot> cancelBooking(String slotId) async {
    calls.add('cancel:$slotId');
    if (failCancel) throw Exception('cancel failed');
    return AvailabilitySlot(
      id: slotId,
      teacherId: 't1',
      date: DateTime(2026, 6, 7),
      startTime: const ClockTime(hour: 14, minute: 0),
      endTime: const ClockTime(hour: 15, minute: 0),
      durationMinutes: 60,
      status: AvailabilitySlotStatus.available,
    );
  }
}

/// Replicates BookingCancelScreen._performCancel's cancel + hasError guard.
/// Returns true when the cancel succeeded (i.e. the screen would deduct the
/// allowance and show success); throws when it failed.
Future<bool> performGuardedCancel(
  SlotBookingNotifier notifier,
  ProviderContainer container, {
  required String bookingId,
}) async {
  await notifier.cancelBooking(bookingId);
  if (container.read(slotBookingNotifierProvider).hasError) {
    throw Exception('booking cancel failed');
  }
  return true; // success path: allowance deduction + success message
}

void main() {
  const bookingId = 't1_2026-06-07_14:00';

  ProviderContainer makeContainer(_RecordingRepo repo) {
    return ProviderContainer(
      overrides: [
        teacherAvailabilityRepositoryProvider.overrideWithValue(repo),
      ],
    );
  }

  test('successful cancel reaches the success/deduction path', () async {
    final repo = _RecordingRepo();
    final container = makeContainer(repo);
    addTearDown(container.dispose);
    final notifier = container.read(slotBookingNotifierProvider.notifier);

    final ok = await performGuardedCancel(
      notifier,
      container,
      bookingId: bookingId,
    );

    expect(ok, isTrue);
    expect(repo.calls, contains('cancel:$bookingId'));
  });

  test('failed cancel throws — no success, no allowance deduction', () async {
    final repo = _RecordingRepo()..failCancel = true;
    final container = makeContainer(repo);
    addTearDown(container.dispose);
    final notifier = container.read(slotBookingNotifierProvider.notifier);

    // The guard must throw so the screen skips useReschedule + success snackbar.
    await expectLater(
      performGuardedCancel(notifier, container, bookingId: bookingId),
      throwsA(isA<Exception>()),
    );

    // Notifier reflects the failure (basis for the hasError guard).
    expect(container.read(slotBookingNotifierProvider).hasError, isTrue);
  });
}
