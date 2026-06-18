// #416 — inviteShareMessageFormat 테스트.
//
// 카톡 공유 텍스트가 선생님 이름·악기 정보를 포함하는지 검증.
// 다국어 전환에 대비해 구조 검증(필수 라인 포함) 위주.

import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';

void main() {
  group('inviteShareMessageFormat — 기본 (senderName 없음)', () {
    test('기본 메시지에 초대 코드와 URL이 포함된다', () {
      final text = AppStrings.inviteShareMessageFormat(
        '123456',
        'https://lesson.app/i/123456',
        AppStrings.teacher,
      );

      expect(text, contains('123456'));
      expect(text, contains('https://lesson.app/i/123456'));
      expect(text, contains(AppStrings.teacher));
    });

    test('senderName 없으면 일반 헤더 사용', () {
      final text = AppStrings.inviteShareMessageFormat(
        '123456',
        'https://lesson.app/i/123456',
        AppStrings.student,
      );

      expect(text, contains('레슨앱에서 저와 함께해요'));
    });
  });

  group('inviteShareMessageFormat — 선생님 (senderName + instruments)', () {
    test('이름과 악기가 모두 있으면 헤더에 둘 다 포함', () {
      final text = AppStrings.inviteShareMessageFormat(
        '654321',
        'https://lesson.app/i/654321',
        AppStrings.teacher,
        senderName: '김선생',
        instruments: const ['바이올린', '비올라'],
      );

      expect(text, contains('김선생'));
      expect(text, contains('바이올린'));
      expect(text, contains('비올라'));
      expect(text, contains('654321'));
    });

    test('이름만 있고 악기가 비어있으면 이름만 노출', () {
      final text = AppStrings.inviteShareMessageFormat(
        '111111',
        'https://lesson.app/i/111111',
        AppStrings.teacher,
        senderName: '박선생',
      );

      expect(text, contains('박선생'));
      expect(text.contains('바이올린'), isFalse);
    });

    test('senderName 빈 문자열은 senderName 없음으로 처리', () {
      final text = AppStrings.inviteShareMessageFormat(
        '222222',
        'https://lesson.app/i/222222',
        AppStrings.teacher,
        senderName: '',
        instruments: const ['피아노'],
      );

      // 빈 이름이면 기본 헤더로 fallback (이름 없는 악기 노출 방지)
      expect(text, contains('레슨앱에서 저와 함께해요'));
      expect(text.contains('피아노'), isFalse);
    });

    test('서명 라인에도 senderName 포함', () {
      final text = AppStrings.inviteShareMessageFormat(
        '333333',
        'https://lesson.app/i/333333',
        AppStrings.teacher,
        senderName: '이선생',
        instruments: const ['첼로'],
      );

      // signature: "- 이선생 선생님 드림"
      expect(text, contains('- 이선생'));
      expect(text, contains('드림'));
    });
  });

  group('inviteShareMessageFormat — 유효기간 병기 (#799)', () {
    test('공유 메시지에 유효기간(7일)이 병기된다', () {
      final text = AppStrings.inviteShareMessageFormat(
        '123456',
        'https://lesson.app/i/123456',
        AppStrings.teacher,
      );

      expect(text, contains('유효기간'));
      expect(text, contains('7일'));
    });
  });

  group('초대 유효기간 표기 상수 (#799)', () {
    test('학부모 초대(24시간) 표기 상수', () {
      expect(AppStrings.inviteParentShareValidity, contains('24시간'));
      expect(AppStrings.inviteParentCodeValidityHint, contains('24시간'));
      expect(AppStrings.inviteParentValidityNote, contains('24시간'));
    });

    test('학생/동료 초대(7일) 표기 상수', () {
      expect(AppStrings.inviteStudentShareValidity, contains('7일'));
      expect(AppStrings.inviteStudentCodeValidityHint, contains('7일'));
    });
  });
}
