import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/network/api_client.dart';
import 'package:lessonaza/features/profile/domain/entities/teacher_profile.dart';
import 'package:lessonaza/features/profile/domain/entities/teacher_search.dart';
import 'package:lessonaza/features/search/data/repositories/remote_teacher_search_repository.dart';

/// #1151 — 선생님 호칭(nickname)을 검색·공개 프로필 경로에 노출하는지 검증.
void main() {
  group('TeacherPublicProfile.displayName', () {
    TeacherPublicProfile profile({String? name, String? nickname}) =>
        TeacherPublicProfile(
          id: 't1',
          name: name,
          nickname: nickname,
          instruments: const ['바이올린'],
          introduction: '',
          completionLevel: ProfileCompletionLevel.minimum,
        );

    test('nickname 이 있으면 nickname 을 반환한다', () {
      expect(profile(name: '김선생님', nickname: '지수쌤').displayName, '지수쌤');
    });

    test('nickname 이 null 이면 본명(name)으로 폴백한다', () {
      expect(profile(name: '김선생님', nickname: null).displayName, '김선생님');
    });

    test('nickname 이 빈 문자열이면 본명(name)으로 폴백한다', () {
      expect(profile(name: '김선생님', nickname: '').displayName, '김선생님');
    });
  });

  group('RemoteTeacherSearchRepository nickname 매핑', () {
    Dio dioReturning(Map<String, dynamic> data) {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) => handler.resolve(
            Response(requestOptions: options, data: data, statusCode: 200),
          ),
        ),
      );
      return dio;
    }

    test(
      'TeacherResponse.nickname 을 TeacherPublicProfile.displayName 으로 노출한다',
      () async {
        final repo = RemoteTeacherSearchRepository(
          ApiClient(
            dioReturning({
              'id': 't1',
              'user': {'name': '김선생님', 'profile_image_url': null},
              'nickname': '지수쌤',
              'instruments': ['바이올린'],
              'created_at': '2026-01-01T00:00:00.000Z',
            }),
          ),
        );

        final result = await repo.getTeacherPublicProfile('t1');

        expect(result, isNotNull);
        expect(result!.name, '김선생님');
        expect(result.nickname, '지수쌤');
        expect(result.displayName, '지수쌤');
      },
    );

    test('nickname 이 없으면 displayName 은 본명(name)으로 폴백한다', () async {
      final repo = RemoteTeacherSearchRepository(
        ApiClient(
          dioReturning({
            'id': 't2',
            'user': {'name': '박선생님'},
            'instruments': ['피아노'],
            'created_at': '2026-01-01T00:00:00.000Z',
          }),
        ),
      );

      final result = await repo.getTeacherPublicProfile('t2');

      expect(result!.nickname, isNull);
      expect(result.displayName, '박선생님');
    });
  });
}
