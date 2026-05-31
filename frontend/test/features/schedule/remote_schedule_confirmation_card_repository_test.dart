import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/network/api_client.dart';
import 'package:lessonaza/features/schedule/data/repositories/remote_schedule_confirmation_card_repository.dart';
import 'package:lessonaza/features/schedule/domain/entities/schedule_confirmation_card.dart';

void main() {
  Map<String, dynamic> cardJson({
    String id = 'card-1',
    String status = 'pending',
  }) {
    return {
      'id': id,
      'student_id': 'student-1',
      'teacher_id': 'teacher-1',
      'teacher_name': '김선생',
      'instrument': 'violin',
      'subscription_id': 'sub-1',
      'lesson_request_id': 'request-1',
      'card_type': 'afterTrial',
      'status': status,
      'created_at': '2026-05-31T10:00:00.000',
      'responded_at': status == 'pending' ? null : '2026-05-31T11:00:00.000',
      'total_lessons': 4,
      'suggested_day': 2,
      'suggested_time': '16:00',
      'lesson_duration': 60,
      'suggested_day2': 4,
      'suggested_time2': '17:00',
    };
  }

  RemoteScheduleConfirmationCardRepository repositoryFor(
    void Function(RequestOptions options, RequestInterceptorHandler handler)
    onRequest,
  ) {
    final dio = Dio();
    dio.interceptors.add(InterceptorsWrapper(onRequest: onRequest));
    return RemoteScheduleConfirmationCardRepository(ApiClient(dio));
  }

  test(
    'getPendingCardsForStudent calls list endpoint with pending filter',
    () async {
      final requests = <RequestOptions>[];
      final repository = repositoryFor((options, handler) {
        requests.add(options);
        handler.resolve(
          Response(
            requestOptions: options,
            data: [cardJson()],
            statusCode: 200,
          ),
        );
      });

      final cards = await repository.getPendingCardsForStudent('student-1');

      expect(requests.single.method, 'GET');
      expect(requests.single.path, '/schedule/confirmation-cards');
      expect(requests.single.queryParameters['student_id'], 'student-1');
      expect(requests.single.queryParameters['status'], 'pending');
      expect(cards.single.teacherName, '김선생');
      expect(cards.single.suggestedDay2, 4);
    },
  );

  test('createCard posts backend create payload', () async {
    late RequestOptions request;
    final repository = repositoryFor((options, handler) {
      request = options;
      handler.resolve(
        Response(requestOptions: options, data: cardJson(), statusCode: 201),
      );
    });

    final card = await repository.createCard(
      ScheduleConfirmationCard(
        id: '',
        studentId: 'student-1',
        teacherId: 'teacher-1',
        teacherName: '김선생',
        instrument: 'violin',
        subscriptionId: 'sub-1',
        suggestedDay: 2,
        suggestedTime: '16:00',
        lessonDuration: 60,
        cardType: ScheduleCardType.afterTrial,
        createdAt: DateTime(2026, 5, 31),
        totalLessons: 4,
        lessonRequestId: 'request-1',
        suggestedDay2: 4,
        suggestedTime2: '17:00',
      ),
    );

    expect(request.method, 'POST');
    expect(request.path, '/schedule/confirmation-cards');
    expect(request.data['student_id'], 'student-1');
    expect(request.data['subscription_id'], 'sub-1');
    expect(request.data['proposed_slots'], [
      {'day': 2, 'time': '16:00'},
      {'day': 4, 'time': '17:00'},
    ]);
    expect(card.id, 'card-1');
  });

  test('updateCardStatus patches status endpoint', () async {
    late RequestOptions request;
    final repository = repositoryFor((options, handler) {
      request = options;
      handler.resolve(
        Response(
          requestOptions: options,
          data: cardJson(status: 'confirmed'),
          statusCode: 200,
        ),
      );
    });

    final card = await repository.updateCardStatus(
      'card-1',
      ScheduleCardStatus.confirmed,
      respondedAt: DateTime(2026, 5, 31, 11),
    );

    expect(request.method, 'PATCH');
    expect(request.path, '/schedule/confirmation-cards/card-1/status');
    expect(request.data['status'], 'confirmed');
    expect(card.status, ScheduleCardStatus.confirmed);
  });

  test('dismissAllPendingCards posts dismiss-all payload', () async {
    late RequestOptions request;
    final repository = repositoryFor((options, handler) {
      request = options;
      handler.resolve(
        Response(
          requestOptions: options,
          data: {'success': true},
          statusCode: 200,
        ),
      );
    });

    await repository.dismissAllPendingCards('student-1');

    expect(request.method, 'POST');
    expect(request.path, '/schedule/confirmation-cards/dismiss-all');
    expect(request.data['student_id'], 'student-1');
  });

  test('getCardBySubscriptionId calls by-subscription endpoint', () async {
    late RequestOptions request;
    final repository = repositoryFor((options, handler) {
      request = options;
      handler.resolve(
        Response(requestOptions: options, data: cardJson(), statusCode: 200),
      );
    });

    final card = await repository.getCardBySubscriptionId('sub-1');

    expect(request.method, 'GET');
    expect(request.path, '/schedule/confirmation-cards/by-subscription/sub-1');
    expect(card?.subscriptionId, 'sub-1');
  });
}
