import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/network/api_client.dart';
import 'package:lessonaza/features/schedule/data/repositories/remote_teacher_availability_repository.dart';
import 'package:lessonaza/features/schedule/domain/entities/teacher_availability.dart';

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

  test(
    'addWeeklySchedule — 첫 설정 (GET 404) 이면 기본값으로 생성 후 PUT (2026-06-12 회귀)',
    () async {
      // 회귀 배경: 첫 설정 사용자 (BE 레코드 없음) 가 "시간대 추가" 시
      // getAvailability == null → throw 로 silent fail. BE PUT 은
      // replace/upsert 이므로 기본값 availability 를 구성해 저장해야 한다.
      final requests = <RequestOptions>[];
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requests.add(options);
            if (options.method == 'GET') {
              handler.reject(
                DioException(
                  requestOptions: options,
                  response: Response(requestOptions: options, statusCode: 404),
                  type: DioExceptionType.badResponse,
                ),
              );
              return;
            }
            // PUT — echo back the saved availability.
            handler.resolve(
              Response(
                requestOptions: options,
                data: {
                  'teacher_id': 'teacher-123',
                  'weekly_schedules': [
                    {
                      'day_of_week': 2,
                      'start_time': '14:00',
                      'end_time': '18:00',
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

      final result = await repository.addWeeklySchedule(
        'teacher-123',
        WeeklySchedule(
          id: 'slot-1',
          dayOfWeek: 2,
          startTime: '14:00',
          endTime: '18:00',
          createdAt: DateTime(2026, 6, 12),
        ),
      );

      // GET (404) → PUT 순서로 호출됨.
      expect(requests, hasLength(2));
      expect(requests.first.method, 'GET');
      expect(requests.last.method, 'PUT');
      expect(requests.last.path, '/schedule/availability');
      // 신규 availability 가 추가 슬롯을 포함해 저장됨.
      expect(result.weeklySchedules, hasLength(1));
      expect(result.weeklySchedules.single.dayOfWeek, 2);
    },
  );
}
