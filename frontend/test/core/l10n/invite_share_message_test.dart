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

  // UX backlog UXB-3 (#1289) — 공유 메시지 하나만 읽고 가입을 끝낼 수 있어야 한다.
  group('inviteShareMessageFormat — 시작 안내 3단계 (UXB-3)', () {
    String build() => AppStrings.inviteShareMessageFormat(
      'ABC123',
      'https://lesson.app/i/ABC123',
      AppStrings.teacher,
      senderName: '김선생',
      instruments: const ['바이올린'],
    );

    test('앱 한 줄 소개가 포함된다', () {
      expect(build(), contains(AppStrings.inviteStartGuideValueLine));
    });

    test('시작 3단계가 번호 순서대로 포함된다', () {
      final text = build();

      expect(text, contains(AppStrings.inviteStartGuideStepsTitle));
      expectNumberedStepsInOrder(text);
    });

    test('설치 / 코드 입력 / 연결 3단계 의미가 각각 드러난다', () {
      final text = build();

      expect(text, contains('설치'));
      expect(text, contains('초대 코드'));
      expect(text, contains('연결'));
    });

    test('가입에 필요한 코드와 링크가 모두 포함된다', () {
      final text = build();

      expect(text, contains('ABC123'));
      expect(text, contains('https://lesson.app/i/ABC123'));
    });

    test('역할 접미사가 중복되지 않는다 (선생님님 방지)', () {
      expect(build().contains('선생님님과'), isFalse);
    });

    test('이모지를 쓰지 않는다', () {
      expect(emojiPattern.hasMatch(build()), isFalse);
    });
  });

  group('inviteParentShareMessageFormat — 학부모 시작 안내 (UXB-3)', () {
    test('학생 이름이 있으면 누구의 학부모인지 밝힌다', () {
      final text = AppStrings.inviteParentShareMessageFormat(
        'XYZ789',
        studentName: '이학생',
      );

      expect(text, contains('이학생'));
      expect(text, contains('XYZ789'));
    });

    test('학생 이름이 없으면 이름 없이 안내한다', () {
      final text = AppStrings.inviteParentShareMessageFormat('XYZ789');

      expect(text, contains('학부모님을 초대합니다'));
      expect(text, contains('XYZ789'));
    });

    test('앱 소개 + 학부모 가치 문구 + 시작 3단계가 포함된다', () {
      final text = AppStrings.inviteParentShareMessageFormat('XYZ789');

      expect(text, contains(AppStrings.inviteStartGuideValueLine));
      expect(text, contains(AppStrings.inviteParentStartGuideValueLine));
      expect(text, contains(AppStrings.inviteStartGuideStepsTitle));
      expectNumberedStepsInOrder(text);
    });

    test('학부모 코드 유효기간(24시간)이 병기된다', () {
      final text = AppStrings.inviteParentShareMessageFormat('XYZ789');

      expect(text, contains(AppStrings.inviteParentShareValidity));
      expect(text, contains('24시간'));
    });

    test('학부모 초대는 딥링크가 없으므로 링크 단계를 요구하지 않는다', () {
      final text = AppStrings.inviteParentShareMessageFormat('XYZ789');

      expect(text.contains('http'), isFalse);
    });

    test('이모지를 쓰지 않는다', () {
      final text = AppStrings.inviteParentShareMessageFormat(
        'XYZ789',
        studentName: '이학생',
      );

      expect(emojiPattern.hasMatch(text), isFalse);
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

/// UI 이모지 금지 규칙 검증용 — emoji-presentation 코드포인트만 대상.
final emojiPattern = RegExp(
  r'[\u{1F000}-\u{1FAFF}\u{FE0F}\u{2705}\u{274C}\u{2B50}\u{26A0}]',
  unicode: true,
);

/// 공유 메시지 본문에 1. 2. 3. 단계가 이 순서대로 등장하는지 확인한다.
void expectNumberedStepsInOrder(String text) {
  final first = text.indexOf('1.');
  final second = text.indexOf('2.');
  final third = text.indexOf('3.');

  expect(first, greaterThanOrEqualTo(0));
  expect(second, greaterThan(first));
  expect(third, greaterThan(second));
}
