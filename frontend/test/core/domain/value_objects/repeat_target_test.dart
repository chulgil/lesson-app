import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/domain/value_objects/repeat_target.dart';

void main() {
  // #970 멀티 Discipline Phase 2 — RepeatTarget 값객체 (primary/secondary 2축)
  // + music single factory. 순수 도메인 값객체: 동등성·factory·축 판별. 음악 동작 0.
  group('RepeatTarget', () {
    test('single 은 단일축 — primary 설정, secondary null', () {
      final t = RepeatTarget.single(3);
      expect(t.primary, 3);
      expect(t.secondary, isNull);
      expect(t.isSingleAxis, isTrue);
    });

    test('setsReps 는 2축 — primary=sets, secondary=reps (fitness 골격)', () {
      final t = RepeatTarget.setsReps(4, 12);
      expect(t.primary, 4);
      expect(t.secondary, 12);
      expect(t.isSingleAxis, isFalse);
    });

    test('동등성 — primary/secondary 모두 같을 때만', () {
      expect(RepeatTarget.single(3), RepeatTarget.single(3));
      expect(RepeatTarget.single(3).hashCode, RepeatTarget.single(3).hashCode);
      expect(RepeatTarget.single(3), isNot(RepeatTarget.single(4)));
      // 같은 primary 라도 축이 다르면 불일치 (single(4) != setsReps(4, 12))
      expect(RepeatTarget.single(4), isNot(RepeatTarget.setsReps(4, 12)));
      expect(RepeatTarget.setsReps(4, 12), RepeatTarget.setsReps(4, 12));
      expect(
        RepeatTarget.setsReps(4, 12).hashCode,
        RepeatTarget.setsReps(4, 12).hashCode,
      );
    });

    test('toString — 단일축/2축 표기 분리', () {
      expect(RepeatTarget.single(3).toString(), 'RepeatTarget(3)');
      expect(RepeatTarget.setsReps(4, 12).toString(), 'RepeatTarget(4 x 12)');
    });
  });
}
