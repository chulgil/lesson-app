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

  test('getAvailability — BE 실응답 (id+created_at 채움, 요소 created_at 없음) 파싱 성공 '
      '(2026-06-12 "데이터를 불러올 수 없다" 회귀)', () async {
    // BE get_availability_by_teacher_id 는 항상 id="availability-{uuid}" 와
    // created_at 을 채운다. 기존 파서의 strict 분기 (id+created_at → raw
    // fromJson) 가 weekly_schedules 요소의 created_at 부재로 throw →
    // read provider error → split page 에러 화면.
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response(
              requestOptions: options,
              data: {
                'id': 'availability-uuid-teacher-42',
                'teacher_id': 'uuid-teacher-42',
                'created_at': '2026-06-12T00:00:00Z',
                'slot_duration_minutes': 50,
                'break_time_between_lessons': 10,
                'weekly_schedules': [
                  {
                    // BE 합성 id + created_at 없음 + is_active 포함.
                    'id': '2-14:00-18:00',
                    'day_of_week': 2,
                    'start_time': '14:00',
                    'end_time': '18:00',
                    'is_active': true,
                  },
                  {
                    'id': '4-10:00-12:00',
                    'day_of_week': 4,
                    'start_time': '10:00',
                    'end_time': '12:00',
                    'is_active': false,
                  },
                ],
                'exceptions': [
                  {
                    'id': 'exc-1',
                    'type': 'holiday',
                    'start_date': '2026-06-19T00:00:00Z',
                    'end_date': '2026-06-19T00:00:00Z',
                    'reason': '개인 사정',
                    'created_at': '2026-06-12T00:00:00Z',
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

    final availability = await repository.getAvailability('uuid-teacher-42');

    expect(availability, isNotNull);
    expect(availability!.teacherId, 'uuid-teacher-42');
    expect(availability.weeklySchedules, hasLength(2));
    expect(availability.weeklySchedules.first.dayOfWeek, 2);
    // is_active 가 관대 파서에서도 보존되어야 한다.
    expect(availability.weeklySchedules.last.isActive, isFalse);
    // exceptions 는 best-effort 파싱 (필드 호환 시 보존).
    expect(availability.exceptions, hasLength(1));
  });

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
