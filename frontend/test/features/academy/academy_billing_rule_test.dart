import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/academy/data/repositories/mock_academy_billing_rule_repository.dart';
import 'package:lessonaza/features/academy/domain/entities/academy_billing_rule.dart';
import 'package:lessonaza/features/academy/domain/entities/academy_teacher_payout_override.dart';
import 'package:lessonaza/features/academy/domain/entities/billing_enums.dart';

void main() {
  group('Billing enums', () {
    test('TeacherDistributionType wireValue ↔ fromWire round-trip', () {
      for (final t in TeacherDistributionType.values) {
        expect(TeacherDistributionType.fromWire(t.wireValue), equals(t));
      }
      expect(
        TeacherDistributionType.revenueShare.wireValue,
        equals('revenue_share'),
      );
      expect(
        TeacherDistributionType.perStudent.wireValue,
        equals('per_student'),
      );
    });

    test('SettlementBase wire snake_case', () {
      expect(
        SettlementBase.completedInvoice.wireValue,
        equals('completed_invoice'),
      );
      for (final s in SettlementBase.values) {
        expect(SettlementBase.fromWire(s.wireValue), equals(s));
      }
    });

    test('InvoiceStatus.isOutstanding flags sent/overdue', () {
      expect(InvoiceStatus.draft.isOutstanding, isFalse);
      expect(InvoiceStatus.sent.isOutstanding, isTrue);
      expect(InvoiceStatus.overdue.isOutstanding, isTrue);
      expect(InvoiceStatus.paid.isOutstanding, isFalse);
      expect(InvoiceStatus.cancelled.isOutstanding, isFalse);
    });

    test('PaymentMethod / PaymentSource / SettlementStatus round-trip', () {
      for (final p in PaymentMethod.values) {
        expect(PaymentMethod.fromWire(p.wireValue), equals(p));
      }
      for (final s in PaymentSource.values) {
        expect(PaymentSource.fromWire(s.wireValue), equals(s));
      }
      expect(PaymentSource.csvImport.wireValue, equals('csv_import'));
      expect(PaymentSource.fuzzyMatch.wireValue, equals('fuzzy_match'));
      for (final s in SettlementStatus.values) {
        expect(SettlementStatus.fromWire(s.wireValue), equals(s));
      }
    });

    test('all enums throw on unknown wire value', () {
      expect(() => TeacherDistributionType.fromWire('x'), throwsArgumentError);
      expect(() => SettlementBase.fromWire('x'), throwsArgumentError);
      expect(() => InvoiceStatus.fromWire('x'), throwsArgumentError);
      expect(() => PaymentMethod.fromWire('x'), throwsArgumentError);
      expect(() => PaymentSource.fromWire('x'), throwsArgumentError);
      expect(() => SettlementStatus.fromWire('x'), throwsArgumentError);
    });
  });

  group('AcademyBillingRule entity', () {
    test('BE 와 동일한 기본값 (issueDay=25, dueDays=7, revenueShare, attendance)', () {
      final rule = AcademyBillingRule(
        id: 'r1',
        academyId: 'a1',
        createdAt: DateTime(2026, 6, 5),
      );
      expect(rule.invoiceIssueDay, equals(25));
      expect(rule.paymentDueDays, equals(7));
      expect(
        rule.teacherDistributionType,
        equals(TeacherDistributionType.revenueShare),
      );
      expect(rule.settlementBase, equals(SettlementBase.attendance));
      expect(rule.taxInvoiceEnabled, isFalse);
      expect(rule.cashReceiptEnabled, isTrue);
      expect(rule.absentTeacherPayPct, equals(0.4));
      expect(rule.substitutePayPct, equals(0.6));
      expect(rule.noShowPenaltyStrikes, equals(3));
      expect(rule.paymentMethods, isEmpty);
    });

    test('assert violations (BE CheckConstraint 와 동일)', () {
      expect(
        () => AcademyBillingRule(
          id: 'r1',
          academyId: 'a1',
          invoiceIssueDay: 31,
          createdAt: DateTime.now(),
        ),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => AcademyBillingRule(
          id: 'r1',
          academyId: 'a1',
          paymentDueDays: 90,
          createdAt: DateTime.now(),
        ),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => AcademyBillingRule(
          id: 'r1',
          academyId: 'a1',
          absentTeacherPayPct: 1.5,
          createdAt: DateTime.now(),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('copyWith + equality (paymentMethods list 내용 기반)', () {
      final base = AcademyBillingRule(
        id: 'r1',
        academyId: 'a1',
        paymentMethods: const [PaymentMethod.transfer, PaymentMethod.cash],
        createdAt: DateTime(2026, 6, 5),
      );
      final same = AcademyBillingRule(
        id: 'r1',
        academyId: 'a1',
        paymentMethods: const [PaymentMethod.transfer, PaymentMethod.cash],
        createdAt: DateTime(2026, 6, 5),
      );
      final diffList = base.copyWith(
        paymentMethods: const [PaymentMethod.card],
      );

      expect(base, equals(same));
      expect(base.hashCode, equals(same.hashCode));
      expect(base, isNot(equals(diffList)));
    });

    test('paymentMethods + distributionConfig 는 unmodifiable', () {
      final rule = AcademyBillingRule(
        id: 'r1',
        academyId: 'a1',
        paymentMethods: const [PaymentMethod.transfer],
        teacherDistributionConfig: const {'rate': 0.5},
        createdAt: DateTime(2026, 6, 5),
      );
      expect(
        () => rule.paymentMethods.add(PaymentMethod.cash),
        throwsUnsupportedError,
      );
      expect(
        () => rule.teacherDistributionConfig['x'] = 1,
        throwsUnsupportedError,
      );
    });
  });

  group('AcademyTeacherPayoutOverride entity', () {
    test('isActiveAt: effectiveUntil 없으면 effectiveFrom 이후 항상 active', () {
      final ov = AcademyTeacherPayoutOverride(
        id: 'o1',
        academyId: 'a1',
        teacherMemberId: 'm1',
        distributionType: TeacherDistributionType.hourly,
        effectiveFrom: DateTime(2026, 6, 1),
        createdAt: DateTime(2026, 6, 1),
      );
      expect(ov.isActiveAt(DateTime(2026, 5, 31)), isFalse);
      expect(ov.isActiveAt(DateTime(2026, 6, 1)), isTrue);
      expect(ov.isActiveAt(DateTime(2030, 1, 1)), isTrue);
      expect(ov.isOpen, isTrue);
    });

    test('isActiveAt: effectiveUntil exclusive', () {
      final ov = AcademyTeacherPayoutOverride(
        id: 'o1',
        academyId: 'a1',
        teacherMemberId: 'm1',
        distributionType: TeacherDistributionType.hourly,
        effectiveFrom: DateTime(2026, 6, 1),
        effectiveUntil: DateTime(2026, 7, 1),
        createdAt: DateTime(2026, 6, 1),
      );
      expect(ov.isActiveAt(DateTime(2026, 6, 30)), isTrue);
      expect(ov.isActiveAt(DateTime(2026, 7, 1)), isFalse);
      expect(ov.isOpen, isFalse);
    });

    test('effectiveUntil must be after effectiveFrom', () {
      expect(
        () => AcademyTeacherPayoutOverride(
          id: 'o1',
          academyId: 'a1',
          teacherMemberId: 'm1',
          distributionType: TeacherDistributionType.hourly,
          effectiveFrom: DateTime(2026, 6, 5),
          effectiveUntil: DateTime(2026, 6, 5),
          createdAt: DateTime(2026, 6, 5),
        ),
        throwsArgumentError,
      );
    });
  });

  group('MockAcademyBillingRuleRepository', () {
    test('getForAcademy auto-creates default when missing', () async {
      final repo = MockAcademyBillingRuleRepository();
      final rule = await repo.getForAcademy('a1');
      expect(rule.academyId, equals('a1'));
      expect(rule.invoiceIssueDay, equals(25));
      // 두 번째 호출도 같은 행 반환 (id 동일)
      final again = await repo.getForAcademy('a1');
      expect(again.id, equals(rule.id));
    });

    test('update replaces the rule for academy', () async {
      final repo = MockAcademyBillingRuleRepository();
      final initial = await repo.getForAcademy('a1');
      final updated = initial.copyWith(invoiceIssueDay: 10);
      await repo.update(updated);

      final reread = await repo.getForAcademy('a1');
      expect(reread.invoiceIssueDay, equals(10));
    });

    test(
      'upsertOverride closes previous open override automatically',
      () async {
        final repo = MockAcademyBillingRuleRepository();
        final first = await repo.upsertOverride(
          academyId: 'a1',
          teacherMemberId: 'm1',
          distributionType: TeacherDistributionType.hourly,
          distributionConfig: const {'rate': 50000},
          effectiveFrom: DateTime(2026, 6, 1),
        );
        final second = await repo.upsertOverride(
          academyId: 'a1',
          teacherMemberId: 'm1',
          distributionType: TeacherDistributionType.hourly,
          distributionConfig: const {'rate': 60000},
          effectiveFrom: DateTime(2026, 7, 1),
        );

        final history = await repo.listOverrides('a1');
        expect(history.length, equals(2));
        // 최근 effectiveFrom desc
        expect(history.first.id, equals(second.id));
        // 이전 행은 effectiveUntil 이 새 effectiveFrom 으로 close
        final closedFirst = history.firstWhere((o) => o.id == first.id);
        expect(closedFirst.effectiveUntil, equals(DateTime(2026, 7, 1)));
        expect(closedFirst.isOpen, isFalse);
      },
    );

    test(
      'getActiveForTeacher returns null when no override at given time',
      () async {
        final repo = MockAcademyBillingRuleRepository();
        await repo.upsertOverride(
          academyId: 'a1',
          teacherMemberId: 'm1',
          distributionType: TeacherDistributionType.hourly,
          distributionConfig: const {'rate': 50000},
          effectiveFrom: DateTime(2026, 6, 1),
        );

        // 미래 시점 — 활성
        final future = await repo.getActiveForTeacher(
          teacherMemberId: 'm1',
          asOf: DateTime(2026, 7, 1),
        );
        expect(future, isNotNull);

        // 과거 시점 — null
        final past = await repo.getActiveForTeacher(
          teacherMemberId: 'm1',
          asOf: DateTime(2026, 5, 1),
        );
        expect(past, isNull);

        // 다른 강사 — null
        final other = await repo.getActiveForTeacher(
          teacherMemberId: 'm_other',
        );
        expect(other, isNull);
      },
    );

    test('listOverrides filters by academyId', () async {
      final repo = MockAcademyBillingRuleRepository();
      await repo.upsertOverride(
        academyId: 'a1',
        teacherMemberId: 'm1',
        distributionType: TeacherDistributionType.hourly,
        distributionConfig: const {},
        effectiveFrom: DateTime(2026, 6, 1),
      );
      await repo.upsertOverride(
        academyId: 'a2',
        teacherMemberId: 'm2',
        distributionType: TeacherDistributionType.perStudent,
        distributionConfig: const {},
        effectiveFrom: DateTime(2026, 6, 1),
      );

      final a1 = await repo.listOverrides('a1');
      final a2 = await repo.listOverrides('a2');
      expect(a1.length, equals(1));
      expect(a2.length, equals(1));
      expect(a1.single.teacherMemberId, equals('m1'));
      expect(a2.single.teacherMemberId, equals('m2'));
    });
  });
}
