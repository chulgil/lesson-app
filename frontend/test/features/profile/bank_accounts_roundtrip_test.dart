// 2026-06-12 — 베타 "입금계좌 추가 무반응" 회귀 테스트.
//
// 근본 원인 2축:
//   1. remote_teacher_profile_repository 의 _profileToJson/_profileFromJson 에
//      복수 bank_accounts 왕복 직렬화가 모두 누락 — 저장도 조회도 안 됨
//      (mock 은 in-memory 라 정상 → 베타에서만 재현)
//   2. 프로필 행 미생성 계정 (GET 404 → null) 에서
//      updateBankAccounts 의 current==null 조용히 return (silent fail)
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/network/api_client.dart';
import 'package:lessonaza/features/onboarding/data/repositories/remote_teacher_profile_repository.dart';
import 'package:lessonaza/features/profile/domain/entities/teacher_profile.dart';

void main() {
  Map<String, dynamic> beProfileJson({List<Map<String, dynamic>>? accounts}) {
    return {
      'id': 'teacher-row-1',
      'user_id': 'uuid-user-1',
      'user': {'name': '김선아'},
      'instruments': ['바이올린'],
      'introduction': '소개',
      'created_at': '2026-06-12T00:00:00Z',
      if (accounts != null) 'bank_accounts': accounts,
    };
  }

  test('PUT body 에 복수 bank_accounts 가 직렬화된다 (저장 무반응 회귀)', () async {
    final requests = <RequestOptions>[];
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          handler.resolve(
            Response(
              requestOptions: options,
              data: beProfileJson(
                accounts: [
                  {
                    'id': 'acc-1',
                    'bank_name': '국민은행',
                    'account_number': '123-456',
                    'account_holder': '김선아',
                    'is_default': true,
                    'created_at': '2026-06-12T00:00:00Z',
                  },
                ],
              ),
              statusCode: 200,
            ),
          );
        },
      ),
    );

    final repo = RemoteTeacherProfileRepository(ApiClient(dio));
    final profile = TeacherProfile(
      id: 'teacher-row-1',
      userId: 'uuid-user-1',
      name: '김선아',
      instruments: const ['바이올린'],
      introduction: '소개',
      createdAt: DateTime(2026, 6, 12),
      bankAccounts: [
        BankAccount(
          id: 'acc-1',
          bankName: '국민은행',
          accountNumber: '123-456',
          accountHolder: '김선아',
          isDefault: true,
          createdAt: DateTime(2026, 6, 12),
        ),
      ],
    );

    final updated = await repo.updateProfile(profile);

    // 요청 body 에 bank_accounts 포함.
    final body = requests.single.data as Map<String, dynamic>;
    expect(body['bank_accounts'], isA<List<dynamic>>());
    expect((body['bank_accounts'] as List).single['bank_name'], '국민은행');

    // 응답 역파싱으로 복수 계좌가 복원됨.
    expect(updated.bankAccounts, hasLength(1));
    expect(updated.bankAccounts.single.accountNumber, '123-456');
  });

  test('GET 응답의 bank_accounts 가 역파싱된다 (조회 무반응 회귀)', () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response(
              requestOptions: options,
              data: beProfileJson(
                accounts: [
                  {
                    'id': 'acc-1',
                    'bank_name': '국민은행',
                    'account_number': '123-456',
                    'account_holder': '김선아',
                    'is_default': true,
                    'created_at': '2026-06-12T00:00:00Z',
                  },
                  {
                    'id': 'acc-2',
                    'bank_name': '신한은행',
                    'account_number': '789-000',
                    'account_holder': '김선아',
                    'is_default': false,
                    'created_at': '2026-06-12T00:00:00Z',
                  },
                ],
              ),
              statusCode: 200,
            ),
          );
        },
      ),
    );

    final repo = RemoteTeacherProfileRepository(ApiClient(dio));
    final profile = await repo.getProfileByUserId('uuid-user-1');

    expect(profile, isNotNull);
    expect(profile!.bankAccounts, hasLength(2));
    expect(profile.bankAccounts.first.isDefault, isTrue);
  });

  test('bank_accounts 없는 구버전 응답 — legacy 단수 계좌가 목록으로 승격', () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final json = beProfileJson();
          json['bank_name'] = '우리은행';
          json['account_number'] = '111-222';
          json['account_holder'] = '김선아';
          handler.resolve(
            Response(requestOptions: options, data: json, statusCode: 200),
          );
        },
      ),
    );

    final repo = RemoteTeacherProfileRepository(ApiClient(dio));
    final profile = await repo.getProfileByUserId('uuid-user-1');

    expect(profile!.bankAccounts, hasLength(1));
    expect(profile.bankAccounts.single.bankName, '우리은행');
  });
}
