import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
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
        },
      ),
    );

    final repository = RemoteSettingsRepository(ApiClient(dio));

    final settings = await repository.getTeacherSettingsById('teacher-123');

    expect(requests.single.method, 'GET');
    expect(requests.single.path, '/settings/teacher/teacher-123');
    expect(settings.id, 'teacher-123');
    expect(settings.bookingGuidanceMessage, '대상 선생님 안내');
    expect(settings.getPrice('피아노', 'beginner'), 88000);
  });
}
