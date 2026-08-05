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
  late String? capturedMethod;
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
    capturedMethod = null;
    final dio = Dio(BaseOptions(baseUrl: 'https://contract.test/api/v1'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          capturedPath = options.path;
          capturedMethod = options.method;
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

  test('updateLesson sends ONLY the LessonUpdate whitelist (#1238)', () async {
    await repo.updateLesson(
      testLesson(subscriptionId: 'sub-1').copyWith(
        feedback: '노트',
        keyPoints: const ['보잉'],
        practiceTips: '스케일',
      ),
    );

    expect(capturedPath, '/lessons/lesson-1');
    expect(capturedBody!.keys.toSet(), {
      'instrument',
      'date',
      'start_time',
      'duration',
      'pieces',
    });
    // Sending these here used to 200-OK and silently drop them.
    for (final dropped in ['status', 'feedback', 'key_points', 'practice_tips']) {
      expect(capturedBody!.containsKey(dropped), isFalse, reason: dropped);
    }
  });

  test('updateLessonStatus hits the dedicated PATCH endpoint (#1237)', () async {
    await repo.updateLessonStatus(testLesson(), LessonStatus.completed);

    expect(capturedMethod, 'PATCH');
    expect(capturedPath, '/lessons/lesson-1/status');
    expect(capturedBody, {'status': 'completed'});
  });

  test('updateLessonFeedback hits the feedback endpoint, omits untouched fields (#1236)',
      () async {
    await repo.updateLessonFeedback(
      testLesson(),
      feedback: '활 사용이 좋았어요',
      keyPoints: const ['보잉', '음정'],
    );

    expect(capturedMethod, 'PUT');
    expect(capturedPath, '/lessons/lesson-1/feedback');
    expect(capturedBody!['feedback'], '활 사용이 좋았어요');
    expect(capturedBody!['key_points'], ['보잉', '음정']);
    expect(
      capturedBody!.containsKey('practice_tips'),
      isFalse,
      reason: 'omitted argument must leave the field untouched server-side',
    );
  });
}
