import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/network/api_client.dart';
import 'package:lessonaza/features/schedule/data/repositories/remote_teacher_availability_repository.dart';

void main() {
  test(
    'getAvailability fetches teacher endpoint and maps availabilities',
    () async {
      final requests = <RequestOptions>[];
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requests.add(options);
            handler.resolve(
              Response(
                requestOptions: options,
                data: {
                  'teacher_id': 'teacher-123',
                  'slot_duration_minutes': 45,
                  'break_time_between_lessons': 10,
                  'min_booking_hours': 12,
                  'auto_generate_weeks': 6,
                  'slot_start_interval': 30,
                  'availabilities': [
                    {
                      'day_of_week': 1,
                      'time_slots': [
                        {'start_time': '10:00', 'end_time': '12:00'},
                        {'start_time': '14:00', 'end_time': '16:00'},
                      ],
                    },
                  ],
                },
                statusCode: 200,
              ),
            );
          },
        ),
      );

      final repository = RemoteTeacherAvailabilityRepository(ApiClient(dio));

      final availability = await repository.getAvailability('teacher-123');

      expect(requests.single.method, 'GET');
      expect(requests.single.path, '/schedule/availability/teacher-123');
      expect(availability, isNotNull);
      expect(availability!.teacherId, 'teacher-123');
      expect(availability.slotDurationMinutes, 45);
      expect(availability.breakTimeBetweenLessons, 10);
      expect(availability.minBookingHours, 12);
      expect(availability.autoGenerateWeeks, 6);
      expect(availability.weeklySchedules, hasLength(2));
      expect(availability.weeklySchedules.first.dayOfWeek, 1);
      expect(availability.weeklySchedules.first.startTime, '10:00');
      expect(availability.weeklySchedules.first.endTime, '12:00');
      expect(availability.weeklySchedules.last.startTime, '14:00');
    },
  );

  test(
    'getAvailability maps backend weekly_schedules response without full model fields',
    () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response(
                requestOptions: options,
                data: {
                  'teacher_id': 'teacher-123',
                  'weekly_schedules': [
                    {
                      'day_of_week': 5,
                      'start_time': '09:30',
                      'end_time': '11:00',
                    },
                  ],
                },
                statusCode: 200,
              ),
            );
          },
        ),
      );

      final repository = RemoteTeacherAvailabilityRepository(ApiClient(dio));

      final availability = await repository.getAvailability('teacher-123');

      expect(availability, isNotNull);
      expect(availability!.id, 'availability_teacher-123');
      expect(availability.weeklySchedules, hasLength(1));
      expect(availability.weeklySchedules.single.dayOfWeek, 5);
      expect(availability.weeklySchedules.single.startTime, '09:30');
      expect(availability.weeklySchedules.single.endTime, '11:00');
    },
  );
}
