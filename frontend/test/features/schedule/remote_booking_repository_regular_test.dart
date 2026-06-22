import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/booking/entities/lesson_booking.dart';
import 'package:lessonaza/core/booking/entities/time_slot.dart';
import 'package:lessonaza/core/domain/value_objects/clock_time.dart';
import 'package:lessonaza/core/network/api_client.dart';
import 'package:lessonaza/features/schedule/data/repositories/remote_booking_repository.dart';

/// #301: standalone 주N회 등록 payload 계약.
/// register_regular_lesson_screen 이 모은 N개 슬롯이 .first 로 붕괴되지 않고
/// 모두 BE 로 전달되어야 한다 (요일은 FE 1=Mon..7=Sun → BE 0=Mon..6=Sun 변환).
void main() {
  RemoteBookingRepository repositoryFor(
    void Function(RequestOptions options, RequestInterceptorHandler handler)
    onRequest,
  ) {
    final dio = Dio();
    dio.interceptors.add(InterceptorsWrapper(onRequest: onRequest));
    return RemoteBookingRepository(ApiClient(dio));
  }

  test(
    'registerRegularLesson sends every weekly slot with 0-based weekday',
    () async {
      late RequestOptions request;
      final repository = repositoryFor((options, handler) {
        request = options;
        handler.resolve(
          Response(
            requestOptions: options,
            data: {
              'id': 'booking-1',
              'teacher_id': 'teacher-1',
              'lesson_date': '2026-07-06',
            },
            statusCode: 201,
          ),
        );
      });

      final registration = RegularLessonRegistration(
        studentId: 'student-1',
        scheduleType: ScheduleType.fixed,
        fixedTimeSlots: [
          TimeSlot(
            id: 'slot_1',
            dayOfWeek: 1, // Monday (FE 1=Mon)
            startTime: const ClockTime(hour: 10, minute: 0),
            endTime: const ClockTime(hour: 11, minute: 0),
          ),
          TimeSlot(
            id: 'slot_3',
            dayOfWeek: 3, // Wednesday (FE 3=Wed)
            startTime: const ClockTime(hour: 14, minute: 0),
            endTime: const ClockTime(hour: 14, minute: 45),
          ),
        ],
        lessonsPerWeek: 2,
        monthlyFee: 200000,
        startDate: DateTime(2026, 7, 1),
      );

      await repository.registerRegularLesson(
        teacherId: 'teacher-1',
        teacherName: '김선생님',
        studentId: 'student-1',
        studentName: '주2회 학생',
        registration: registration,
      );

      final body = request.data as Map<String, dynamic>;
      expect(body['lessons_per_week'], 2);
      expect(body['start_date'], '2026-07-01'); // date-only (lesson 422 교훈)

      final slots = body['fixed_time_slots'] as List;
      expect(slots, hasLength(2));
      expect(slots[0], {
        'day_of_week': 0, // Mon: FE 1 → BE 0
        'start_time': '10:00',
        'duration_minutes': 60,
      });
      expect(slots[1], {
        'day_of_week': 2, // Wed: FE 3 → BE 2
        'start_time': '14:00',
        'duration_minutes': 45,
      });
    },
  );
}
