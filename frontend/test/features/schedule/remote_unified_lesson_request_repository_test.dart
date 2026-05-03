import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/network/api_client.dart';
import 'package:lessonaza/features/schedule/data/repositories/remote_unified_lesson_request_repository.dart';
import 'package:lessonaza/features/schedule/domain/entities/request_event.dart';
import 'package:lessonaza/features/schedule/domain/entities/unified_lesson_request.dart';

void main() {
  test('update sends lifecycle status changes to status endpoint', () async {
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
                'id': 'request-001',
                'student_id': 'student-001',
                'teacher_id': 'teacher-001',
                'type': 'regular',
                'instrument': '피아노',
                'goal': 'hobby',
                'experience': 'beginner',
                'preferred_duration': 60,
                'current_round': 0,
                'is_returning_student': false,
                'status': 'subscriptionIssued',
                'created_at': '2026-05-02T00:00:00Z',
                'proposal_id': 'subscription-001',
              },
              statusCode: 200,
            ),
          );
        },
      ),
    );

    final repository = RemoteUnifiedLessonRequestRepository(ApiClient(dio));

    await repository.update(
      UnifiedLessonRequest(
        id: 'request-001',
        studentId: 'student-001',
        teacherId: 'teacher-001',
        type: LessonRequestType.regular,
        instrument: '피아노',
        goal: UnifiedLessonGoal.hobby,
        experience: UnifiedExperienceLevel.beginner,
        preferredDuration: 60,
        status: UnifiedRequestStatus.subscriptionIssued,
        proposalId: 'subscription-001',
        createdAt: DateTime.utc(2026, 5, 2),
      ),
    );

    expect(requests.single.method, 'PATCH');
    expect(
      requests.single.path,
      '/schedule/lesson-requests/request-001/status',
    );
    expect(
      (requests.single.data as Map<String, dynamic>)['status'],
      'subscriptionIssued',
    );
    expect(
      (requests.single.data as Map<String, dynamic>)['proposal_id'],
      'subscription-001',
    );
  });

  test('getEventsByRequestId fetches persisted request events', () async {
    final requests = <RequestOptions>[];
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          handler.resolve(
            Response(
              requestOptions: options,
              data: [
                {
                  'id': 'event-001',
                  'request_id': 'request-001',
                  'actor_type': 'teacher',
                  'actor_id': 'teacher-001',
                  'event_type': 'subscriptionIssued',
                  'suggested_slots': [],
                  'message': '입금 확인 후 수강권을 발급했습니다.',
                  'created_at': '2026-05-02T00:00:00Z',
                },
              ],
              statusCode: 200,
            ),
          );
        },
      ),
    );

    final repository = RemoteUnifiedLessonRequestRepository(ApiClient(dio));

    final events = await repository.getEventsByRequestId('request-001');

    expect(requests.single.method, 'GET');
    expect(
      requests.single.path,
      '/schedule/lesson-requests/request-001/events',
    );
    expect(events.single.eventType, RequestEventType.subscriptionIssued);
  });

  test('addEvent posts event to request events endpoint', () async {
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
                'id': 'event-001',
                'request_id': 'request-001',
                'actor_type': 'teacher',
                'actor_id': 'teacher-001',
                'event_type': 'subscriptionIssued',
                'suggested_slots': [],
                'message': '입금 확인 후 수강권을 발급했습니다.',
                'created_at': '2026-05-02T00:00:00Z',
              },
              statusCode: 201,
            ),
          );
        },
      ),
    );

    final repository = RemoteUnifiedLessonRequestRepository(ApiClient(dio));

    final event = await repository.addEvent(
      RequestEvent(
        id: 'event-local',
        requestId: 'request-001',
        actorType: ProposerRole.teacher,
        actorId: 'teacher-001',
        eventType: RequestEventType.subscriptionIssued,
        message: '입금 확인 후 수강권을 발급했습니다.',
        createdAt: DateTime.utc(2026, 5, 2),
      ),
    );

    expect(requests.single.method, 'POST');
    expect(
      requests.single.path,
      '/schedule/lesson-requests/request-001/events',
    );
    expect(
      (requests.single.data as Map<String, dynamic>)['event_type'],
      'subscriptionIssued',
    );
    expect(event.id, 'event-001');
  });
}
