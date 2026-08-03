import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/network/api_client.dart';
import 'package:lessonaza/features/profile/domain/entities/teacher.dart';
import 'package:lessonaza/features/search/data/repositories/remote_teacher_repository.dart';

/// #1145 — 선생님이 설정한 호칭(nickname)을 학생이 보는 검증.
void main() {
  group('Teacher.displayName', () {
    Teacher teacher({String? nickname}) => Teacher(
      id: 't1',
      name: '김선생님',
      nickname: nickname,
      instruments: const ['바이올린'],
      createdAt: DateTime(2026, 1, 1),
    );

    test('nickname 이 있으면 nickname 을 반환한다', () {
      expect(teacher(nickname: '지수쌤').displayName, '지수쌤');
    });

    test('nickname 이 null 이면 본명(name)으로 폴백한다', () {
      expect(teacher(nickname: null).displayName, '김선생님');
    });

    test('nickname 이 빈 문자열이면 본명(name)으로 폴백한다', () {
      expect(teacher(nickname: '').displayName, '김선생님');
    });
  });

  group('RemoteTeacherRepository nickname 매핑', () {
    Dio dioReturning(Map<String, dynamic> data) {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest:
              (options, handler) => handler.resolve(
                Response(requestOptions: options, data: data, statusCode: 200),
              ),
        ),
      );
      return dio;
    }

    test('TeacherResponse.nickname 을 Teacher.displayName 으로 노출한다', () async {
      final repo = RemoteTeacherRepository(
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

      final result = await repo.getTeacherById('t1');

      expect(result, isNotNull);
      expect(result!.name, '김선생님');
      expect(result.nickname, '지수쌤');
      expect(result.displayName, '지수쌤');
    });

    test('nickname 이 없으면 displayName 은 본명(name)으로 폴백한다', () async {
      final repo = RemoteTeacherRepository(
        ApiClient(
          dioReturning({
            'id': 't2',
            'user': {'name': '박선생님'},
            'instruments': ['피아노'],
            'created_at': '2026-01-01T00:00:00.000Z',
          }),
        ),
      );

      final result = await repo.getTeacherById('t2');

      expect(result!.nickname, isNull);
      expect(result.displayName, '박선생님');
    });
  });
}
