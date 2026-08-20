// UXB-2 #1289 — DeepLinkHandler 가 넘긴 경로에서 초대 코드를 뽑아내는 순수 함수.
//
// DeepLinkHandler 는 `lessonapp://invite/{code}` 를 `/invite/code?code=NNNNNN`
// 으로 변환해 navigate 한다. main.dart 는 그 경로에서 코드를 추출해 보관한 뒤
// go() 하므로, 잘못 추출하면 role-skip 이 엉뚱한 딥링크에서도 발동한다.

import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/deep_link/deep_link_parser.dart';
import 'package:lessonaza/core/deep_link/pending_invite_code_provider.dart';

void main() {
  group('pendingInviteCodeFromPath', () {
    test('초대 딥링크 경로에서 6자리 코드를 뽑는다', () {
      expect(pendingInviteCodeFromPath('/invite/code?code=424242'), '424242');
    });

    test('DeepLinkParser 출력과 실제로 맞물린다 (계약 회귀)', () {
      // 파서가 만드는 경로 형태가 바뀌면 여기서 깨져야 한다 — 두 모듈을
      // 각각 테스트하면 사이의 문자열 규약이 조용히 어긋난다.
      final route =
          DeepLinkParser.toRoute(Uri.parse('lessonapp://invite/424242'))!;
      final path =
          Uri(
            path: route.path,
            queryParameters: {'code': route.code!},
          ).toString();

      expect(pendingInviteCodeFromPath(path), '424242');
    });

    test('코드 쿼리가 없으면 null', () {
      expect(pendingInviteCodeFromPath('/invite/code'), isNull);
    });

    test('다른 딥링크(레슨 상세)는 건드리지 않는다', () {
      expect(pendingInviteCodeFromPath('/lessons/abc123'), isNull);
      expect(pendingInviteCodeFromPath('/student/summary/tok'), isNull);
    });

    test('6자리 숫자가 아니면 null', () {
      expect(pendingInviteCodeFromPath('/invite/code?code=12345'), isNull);
      expect(pendingInviteCodeFromPath('/invite/code?code=1234567'), isNull);
      expect(pendingInviteCodeFromPath('/invite/code?code=abcdef'), isNull);
      expect(pendingInviteCodeFromPath('/invite/code?code='), isNull);
    });

    test('유사 경로에 오탐하지 않는다', () {
      expect(pendingInviteCodeFromPath('/invite/confirm?code=424242'), isNull);
      expect(
        pendingInviteCodeFromPath('/invite/code/extra?code=424242'),
        isNull,
      );
    });
  });
}
