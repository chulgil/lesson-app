import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/domain/value_objects/clock_time.dart';

/// 회색 화면(#64·65) 회귀 가드 — 시간 파싱은 절대 throw 하면 안 된다.
///
/// 원격 데이터의 빈/비정상 startTime 하나가 build 중 FormatException/RangeError 를
/// 던지면 릴리스 모드에서 화면 전체가 회색 ErrorWidget 으로 덮인다. mock 은 항상
/// "HH:mm" 라 단위/E2E 모두 false-green 이었다. 이 테스트가 RED→GREEN 으로 그 갭을
/// 메운다.
void main() {
  group('ClockTime.parse — 비정상 입력에도 throw 하지 않는다', () {
    test('정상 "HH:mm"', () {
      final t = ClockTime.parse('17:30');
      expect(t.hour, 17);
      expect(t.minute, 30);
    });

    test('빈 문자열 "" → 00:00 (throw 금지)', () {
      final t = ClockTime.parse('');
      expect(t.hour, 0);
      expect(t.minute, 0);
    });

    test('콜론 없음 "17" → 17:00 (RangeError 금지)', () {
      final t = ClockTime.parse('17');
      expect(t.hour, 17);
      expect(t.minute, 0);
    });

    test('초 포함 "17:30:00" → 17:30 (여분 토큰 무시)', () {
      final t = ClockTime.parse('17:30:00');
      expect(t.hour, 17);
      expect(t.minute, 30);
    });

    test('비숫자 "ab:cd" → 00:00 (FormatException 금지)', () {
      final t = ClockTime.parse('ab:cd');
      expect(t.hour, 0);
      expect(t.minute, 0);
    });

    test('범위 초과 "25:99" → clamp 23:59 (assert 위반 금지)', () {
      final t = ClockTime.parse('25:99');
      expect(t.hour, 23);
      expect(t.minute, 59);
    });

    test('공백 " 9 : 5 " → 09:05 (trim)', () {
      final t = ClockTime.parse(' 9 : 5 ');
      expect(t.hour, 9);
      expect(t.minute, 5);
    });
  });

  group('ClockTime.fromJson — String/null 도 throw 하지 않는다', () {
    test('정상 int', () {
      final t = ClockTime.fromJson({'hour': 8, 'minute': 15});
      expect(t.hour, 8);
      expect(t.minute, 15);
    });

    test('String 숫자 (원격 직렬화 변형) → CastError 금지', () {
      final t = ClockTime.fromJson({'hour': '8', 'minute': '15'});
      expect(t.hour, 8);
      expect(t.minute, 15);
    });

    test('null → 00:00 (CastError 금지)', () {
      final t = ClockTime.fromJson({'hour': null, 'minute': null});
      expect(t.hour, 0);
      expect(t.minute, 0);
    });
  });
}
