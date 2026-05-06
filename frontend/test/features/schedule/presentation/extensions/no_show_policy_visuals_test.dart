import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/schedule/domain/entities/no_show_policy.dart';
import 'package:lessonaza/features/schedule/presentation/extensions/no_show_policy_visuals.dart';

void main() {
  group('NoShowPolicyVisualX', () {
    test('maps labels and descriptions in presentation', () {
      expect(NoShowPolicy.deductCredit.label, '회차 차감');
      expect(NoShowPolicy.halfCredit.label, '0.5회 차감');
      expect(NoShowPolicy.noDeduction.label, '차감 없음');
      expect(NoShowPolicy.reschedule.label, '보강으로 전환');

      expect(NoShowPolicy.deductCredit.description, '무단 결석 시 1회 차감됩니다');
      expect(NoShowPolicy.halfCredit.description, '무단 결석 시 0.5회 차감됩니다');
      expect(NoShowPolicy.noDeduction.description, '무단 결석 시에도 차감되지 않습니다');
      expect(NoShowPolicy.reschedule.description, '무단 결석 시 보강 1회로 전환됩니다');
    });
  });
}
