import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/network/api_client.dart';
import 'package:lessonaza/features/practice/data/repositories/remote_recording_feedback_repository.dart';

void main() {
  Map<String, dynamic> feedbackJson({
    String id = 'feedback-1',
    String content = '좋아졌어요.',
  }) {
    return {
      'id': id,
      'recordingId': 'recording-1',
      'teacherId': 'teacher-1',
      'content': content,
      'createdAt': '2026-05-31T10:00:00.000',
    };
  }

  RemoteRecordingFeedbackRepository repositoryFor(
    void Function(RequestOptions options, RequestInterceptorHandler handler)
    onRequest,
  ) {
    final dio = Dio();
    dio.interceptors.add(InterceptorsWrapper(onRequest: onRequest));
    return RemoteRecordingFeedbackRepository(ApiClient(dio));
  }

  test('list fetches recording feedback endpoint', () async {
    late RequestOptions request;
    final repository = repositoryFor((options, handler) {
      request = options;
      handler.resolve(
        Response(
          requestOptions: options,
          data: [feedbackJson()],
          statusCode: 200,
        ),
      );
    });

    final feedbacks = await repository.list('recording-1');

    expect(request.method, 'GET');
    expect(request.path, '/recordings/recording-1/feedback');
    expect(feedbacks.single.recordingId, 'recording-1');
    expect(feedbacks.single.teacherId, 'teacher-1');
  });

  test('create posts content and maps response', () async {
    late RequestOptions request;
    final repository = repositoryFor((options, handler) {
      request = options;
      handler.resolve(
        Response(
          requestOptions: options,
          data: feedbackJson(),
          statusCode: 201,
        ),
      );
    });

    final feedback = await repository.create(
      recordingId: 'recording-1',
      content: ' 좋아졌어요. ',
    );

    expect(request.method, 'POST');
    expect(request.path, '/recordings/recording-1/feedback');
    expect(request.data, {'content': '좋아졌어요.'});
    expect(feedback.id, 'feedback-1');
  });

  test('update puts content to feedback endpoint', () async {
    late RequestOptions request;
    final repository = repositoryFor((options, handler) {
      request = options;
      handler.resolve(
        Response(
          requestOptions: options,
          data: feedbackJson(content: '수정됐어요.'),
          statusCode: 200,
        ),
      );
    });

    final feedback = await repository.update(
      recordingId: 'recording-1',
      feedbackId: 'feedback-1',
      content: '수정됐어요.',
    );

    expect(request.method, 'PUT');
    expect(request.path, '/recordings/recording-1/feedback/feedback-1');
    expect(request.data, {'content': '수정됐어요.'});
    expect(feedback.content, '수정됐어요.');
  });

  test('delete calls feedback endpoint', () async {
    late RequestOptions request;
    final repository = repositoryFor((options, handler) {
      request = options;
      handler.resolve(Response(requestOptions: options, statusCode: 204));
    });

    await repository.delete(
      recordingId: 'recording-1',
      feedbackId: 'feedback-1',
    );

    expect(request.method, 'DELETE');
    expect(request.path, '/recordings/recording-1/feedback/feedback-1');
  });
}
