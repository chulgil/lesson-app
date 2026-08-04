import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/network/api_client.dart';
import 'package:lessonaza/features/lessons/data/repositories/remote_lesson_repository.dart';
import 'package:lessonaza/features/lessons/domain/entities/entities.dart';

/// HTTP-contract link for the add-lesson intent flow
/// (subscription_required_spec §2.6.2).
///
/// The BE reads snake_case keys (`overflow_mode`, `subscription_id`) from the
/// POST /lessons body. These tests capture the actual request payload at the
/// Dio boundary so a key rename on either side fails here instead of silently
/// falling back to the legacy bonus path.
void main() {
  late Map<String, dynamic>? capturedBody;
  late String? capturedPath;
  late RemoteLessonRepository repo;

  Lesson testLesson({String? subscriptionId}) {
    return Lesson(
      id: 'lesson-1',
      studentId: 'student-1',
      studentName: 'Test Student',
      teacherId: 'teacher-1',
      instrument: 'violin',
      date: DateTime(2026, 8, 10),
      startTime: '10:00',
      status: LessonStatus.scheduled,
      subscriptionId: subscriptionId,
      createdAt: DateTime(2026, 8, 4),
    );
  }

  setUp(() {
    capturedBody = null;
    capturedPath = null;
    final dio = Dio(BaseOptions(baseUrl: 'https://contract.test/api/v1'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          capturedPath = options.path;
          capturedBody = Map<String, dynamic>.from(options.data as Map);
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 201,
              data: testLesson(subscriptionId: 'sub-1').toJson(),
            ),
          );
        },
      ),
    );
    repo = RemoteLessonRepository(ApiClient(dio));
  });

  test(
    'createLesson serializes overflow_mode + subscription_id snake_case',
    () async {
      await repo.createLesson(
        testLesson(subscriptionId: 'sub-1'),
        overflowMode: 'renewal_pending',
      );

      expect(capturedPath, '/lessons');
      expect(capturedBody!['overflow_mode'], 'renewal_pending');
      expect(capturedBody!['subscription_id'], 'sub-1');
      expect(
        capturedBody!.containsKey('overflowMode'),
        isFalse,
        reason: 'camelCase key would be silently ignored by the BE schema',
      );
    },
  );

  test(
    'createLesson omits overflow_mode when not provided (legacy path)',
    () async {
      await repo.createLesson(testLesson());

      expect(capturedBody!.containsKey('overflow_mode'), isFalse);
    },
  );
}
