import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/domain/value_objects/clock_time.dart';
import 'package:lessonaza/core/booking/entities/time_slot.dart';
import 'package:lessonaza/core/network/api_client.dart';
import 'package:lessonaza/features/settings/data/repositories/remote_settings_repository.dart';

void main() {
  test('getTeacherSettingsById fetches teacher-specific settings', () async {
    final requests = <RequestOptions>[];
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          if (options.path == '/settings/teacher/teacher-123') {
            handler.resolve(
              Response(
                requestOptions: options,
                data: {
                  'id': 'teacher-123',
                  'instruments': ['피아노'],
                  'default_lesson_duration': 60,
                  'created_at': '2026-05-02T00:00:00Z',
                  'booking_guidance_message': '대상 선생님 안내',
                  'lesson_price_table': {
                    '피아노': {'beginner': 88000},
                  },
                },
                statusCode: 200,
              ),
            );
            return;
          }
          handler.resolve(
            Response(
              requestOptions: options,
              data: {'teacher_id': 'teacher-123', 'availabilities': []},
              statusCode: 200,
            ),
          );
        },
      ),
    );

    final repository = RemoteSettingsRepository(ApiClient(dio));

    final settings = await repository.getTeacherSettingsById('teacher-123');

    expect(requests.map((request) => request.method), ['GET', 'GET']);
    expect(requests.first.path, '/settings/teacher/teacher-123');
    expect(requests.last.path, '/schedule/availability/teacher-123');
    expect(settings.id, 'teacher-123');
    expect(settings.bookingGuidanceMessage, '대상 선생님 안내');
    expect(settings.getPrice('피아노', 'beginner'), 88000);
  });

  test(
    'updateTimeSlot persists operating hours through schedule API',
    () async {
      final requests = <RequestOptions>[];
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requests.add(options);
            if (options.path == '/settings/teacher') {
              handler.resolve(
                Response(
                  requestOptions: options,
                  data: {
                    'id': 'teacher-123',
                    'instruments': ['피아노'],
                    'default_lesson_duration': 60,
                    'break_time_between_lessons': 10,
                    'min_booking_hours': 24,
                    'created_at': '2026-05-02T00:00:00Z',
                  },
                  statusCode: 200,
                ),
              );
              return;
            }
            if (options.method == 'GET' &&
                options.path == '/schedule/availability') {
              handler.resolve(
                Response(
                  requestOptions: options,
                  data: {'teacher_id': 'teacher-123', 'availabilities': []},
                  statusCode: 200,
                ),
              );
              return;
            }
            handler.resolve(
              Response(
                requestOptions: options,
                data: {'teacher_id': 'teacher-123', 'availabilities': []},
                statusCode: 200,
              ),
            );
          },
        ),
      );

      final repository = RemoteSettingsRepository(ApiClient(dio));

      final settings = await repository.updateTimeSlot(
        const TimeSlot(
          id: 'new-slot',
          dayOfWeek: 1,
          startTime: ClockTime(hour: 9, minute: 0),
          endTime: ClockTime(hour: 18, minute: 0),
        ),
      );

      final put = requests.singleWhere(
        (request) =>
            request.method == 'PUT' && request.path == '/schedule/availability',
      );
      expect(put.data, {
        'availabilities': [
          {
            'day_of_week': 0,
            'time_slots': [
              {'start_time': '09:00', 'end_time': '18:00'},
            ],
          },
        ],
        'slot_duration_minutes': 60,
        'break_time_between_lessons': 10,
        'min_booking_hours': 24,
      });
      expect(settings.availableSlots, hasLength(1));
      expect(settings.availableSlots.single.dayOfWeek, 1);
    },
  );

  test(
    'updateBreakTime mirrors the value to the availability SSOT (#19)',
    () async {
      final requests = <RequestOptions>[];
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requests.add(options);
            if (options.method == 'PUT' && options.path == '/settings/teacher') {
              handler.resolve(
                Response(
                  requestOptions: options,
                  data: {
                    'id': 'teacher-123',
                    'instruments': ['피아노'],
                    'default_lesson_duration': 60,
                    'break_time_between_lessons': 15,
                    'min_booking_hours': 24,
                    'created_at': '2026-05-02T00:00:00Z',
                  },
                  statusCode: 200,
                ),
              );
              return;
            }
            handler.resolve(
              Response(
                requestOptions: options,
                data: {'teacher_id': 'teacher-123', 'availabilities': []},
                statusCode: 200,
              ),
            );
          },
        ),
      );

      final repository = RemoteSettingsRepository(ApiClient(dio));

      final settings = await repository.updateBreakTime(15);

      // The booking engine reads break/min from /schedule/availability, so a
      // settings change must also PUT there.
      final availabilityPut = requests.singleWhere(
        (request) =>
            request.method == 'PUT' &&
            request.path == '/schedule/availability',
      );
      final data = availabilityPut.data as Map<String, dynamic>;
      expect(data['break_time_between_lessons'], 15);
      expect(data['min_booking_hours'], 24);
      expect(settings.breakTimeBetweenLessons, 15);
    },
  );
}
