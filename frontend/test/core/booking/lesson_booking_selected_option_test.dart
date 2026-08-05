import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/booking/entities/lesson_booking.dart';
import 'package:lessonaza/core/domain/value_objects/clock_time.dart';

/// #1243 — `selectedOption` 은 빈 옵션 리스트에서 StateError 를 던졌다.
/// null 만 가드하고 `orElse: () => scheduleOptions!.first` 로 빠졌기 때문
/// (형제 `primaryOption` 은 isEmpty 까지 가드). 배선 전 방어.
LessonBooking _booking({
  List<ScheduleOption>? options,
  String? selectedOptionId,
}) => LessonBooking(
  id: 'b1',
  teacherId: 't1',
  teacherName: '김선생',
  studentId: 's1',
  studentName: '이학생',
  lessonType: LessonType.regular,
  status: BookingStatus.pending,
  lessonDate: DateTime(2026, 8, 10),
  startTime: const ClockTime(hour: 10, minute: 0),
  endTime: const ClockTime(hour: 11, minute: 0),
  fee: 50000,
  createdAt: DateTime(2026, 8, 1),
  scheduleOptions: options,
  selectedOptionId: selectedOptionId,
);

ScheduleOption _option(String id, int priority) =>
    ScheduleOption(id: id, priority: priority);

void main() {
  test('빈 옵션 리스트 + 선택 id → null (StateError 아님)', () {
    final booking = _booking(options: const [], selectedOptionId: 'opt-1');

    expect(booking.selectedOption, isNull);
  });

  test('옵션 null + 선택 id → null (회귀)', () {
    expect(_booking(selectedOptionId: 'opt-1').selectedOption, isNull);
  });

  test('일치하는 옵션이 있으면 그 옵션을 돌려준다', () {
    final booking = _booking(
      options: [_option('opt-1', 1), _option('opt-2', 2)],
      selectedOptionId: 'opt-2',
    );

    expect(booking.selectedOption?.id, 'opt-2');
  });

  test('일치하는 옵션이 없으면 첫 옵션으로 폴백', () {
    final booking = _booking(
      options: [_option('opt-1', 1)],
      selectedOptionId: 'missing',
    );

    expect(booking.selectedOption?.id, 'opt-1');
  });
}
