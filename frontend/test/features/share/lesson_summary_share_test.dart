// #808 — 레슨 요약 공유 토큰 repository/model 테스트.
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/network/api_client.dart';
import 'package:lessonaza/features/share/data/repositories/mock_lesson_summary_share_repository.dart';
import 'package:lessonaza/features/share/data/repositories/remote_lesson_summary_share_repository.dart';
import 'package:lessonaza/features/share/domain/entities/lesson_summary_share.dart';

void main() {
  group('LessonSummaryShare.fromJson', () {
    test('백엔드 응답 필드 파싱', () {
      final s = LessonSummaryShare.fromJson({
        'token': 'tok-1',
        'url': 'https://lessonaza.app/student/summary/tok-1',
        'app_deep_link': 'lessonaza://student/summary/tok-1',
        'share_text': '요약을 확인하세요 https://lessonaza.app/student/summary/tok-1',
        'expires_at': '2026-06-19T00:00:00Z',
      });
      expect(s.token, 'tok-1');
      expect(s.url, contains('tok-1'));
      expect(s.appDeepLink, startsWith('lessonaza://'));
      expect(s.shareText, isNotEmpty);
      expect(s.expiresAt.isAfter(DateTime.utc(2026, 6, 18)), isTrue);
    });

    test('누락 필드 안전 기본값', () {
      final s = LessonSummaryShare.fromJson(const {});
      expect(s.token, '');
      expect(s.url, '');
      expect(s.shareText, '');
    });
  });

  group('RemoteLessonSummaryShareRepository', () {
    test(
      'POST /lesson-summaries/{id}/share 에 expires_in_hours 전송 + 응답 파싱',
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
                    'token': 'tok-9',
                    'url': 'https://lessonaza.app/student/summary/tok-9',
                    'app_deep_link': 'lessonaza://student/summary/tok-9',
                    'share_text':
                        '레슨 요약: https://lessonaza.app/student/summary/tok-9',
                    'expires_at': '2026-06-19T00:00:00Z',
                  },
                  statusCode: 201,
                ),
              );
            },
          ),
        );
        final repo = RemoteLessonSummaryShareRepository(ApiClient(dio));

        final result = await repo.createLessonSummaryShare(
          'lesson-1',
          expiresInHours: 12,
        );

        expect(requests.single.method, 'POST');
        expect(requests.single.path, '/lesson-summaries/lesson-1/share');
        expect(requests.single.data, {'expires_in_hours': 12});
        expect(result.token, 'tok-9');
        expect(result.url, contains('tok-9'));
      },
    );
  });

  group('MockLessonSummaryShareRepository', () {
    test('가짜 토큰/URL 반환', () async {
      final result = await MockLessonSummaryShareRepository()
          .createLessonSummaryShare('lesson-1');
      expect(result.url, contains(result.token));
      expect(result.shareText, contains('http'));
    });
  });
}
