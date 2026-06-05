import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/academy/data/repositories/mock_academy_settlement_repository.dart';
import 'package:lessonaza/features/academy/domain/entities/academy_settlement.dart';
import 'package:lessonaza/features/academy/domain/entities/billing_enums.dart';

void main() {
  group('AcademySettlement entity', () {
    AcademySettlement build({
      SettlementStatus? status,
      int? calculated,
      int? adjusted,
      int? finalA,
      DateTime? ackAt,
      String? disputeNote,
      List<Map<String, dynamic>>? log,
    }) {
      return AcademySettlement(
        id: 'st_1',
        academyId: 'a1',
        teacherMemberId: 'm1',
        periodYear: 2026,
        periodMonth: 6,
        calculatedAmount: calculated ?? 800000,
        adjustedAmount: adjusted,
        finalAmount: finalA ?? 800000,
        status: status ?? SettlementStatus.draft,
        teacherAcknowledgedAt: ackAt,
        teacherDisputeNote: disputeNote,
        adjustmentLog: log,
        createdAt: DateTime(2026, 6, 30),
      );
    }

    test('periodMonth 1..12 assert', () {
      expect(
        () => AcademySettlement(
          id: 'x',
          academyId: 'a',
          teacherMemberId: 'm',
          periodYear: 2026,
          periodMonth: 13,
          createdAt: DateTime.now(),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('negative calculatedAmount / finalAmount rejected', () {
      expect(
        () => AcademySettlement(
          id: 'x',
          academyId: 'a',
          teacherMemberId: 'm',
          periodYear: 2026,
          periodMonth: 6,
          calculatedAmount: -1,
          createdAt: DateTime.now(),
        ),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => AcademySettlement(
          id: 'x',
          academyId: 'a',
          teacherMemberId: 'm',
          periodYear: 2026,
          periodMonth: 6,
          finalAmount: -1,
          createdAt: DateTime.now(),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('breakdown / adjustmentLog 는 unmodifiable', () {
      final s = build(
        log: const [
          {'at': '2026-06-30T10:00', 'by': 'u1', 'from': 800000, 'to': 850000},
        ],
      );
      expect(() => s.adjustmentLog.add({}), throwsUnsupportedError);
      expect(() => s.breakdown.add({}), throwsUnsupportedError);
    });

    test('lifecycle flags', () {
      expect(build(status: SettlementStatus.draft).isDraft, isTrue);
      expect(
        build(status: SettlementStatus.confirmed).isAwaitingTransfer,
        isTrue,
      );
      expect(build(status: SettlementStatus.transferred).isTransferred, isTrue);
    });

    test('isAcknowledged / isDisputed / isAdjusted', () {
      expect(build().isAcknowledged, isFalse);
      expect(build().isDisputed, isFalse);
      expect(build().isAdjusted, isFalse);

      final ack = build(ackAt: DateTime.now());
      expect(ack.isAcknowledged, isTrue);
      expect(ack.isDisputed, isFalse);

      final disputed = build(ackAt: DateTime.now(), disputeNote: '시간당 단가 누락');
      expect(disputed.isAcknowledged, isTrue);
      expect(disputed.isDisputed, isTrue);

      final adjusted = build(adjusted: 850000, finalA: 850000);
      expect(adjusted.isAdjusted, isTrue);
    });

    test('equality + copyWith', () {
      final a = build();
      final b = build();
      final c = a.copyWith(status: SettlementStatus.confirmed);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });

  group('MockAcademySettlementRepository — lifecycle', () {
    test('calculate creates new draft + sets finalAmount', () async {
      final repo = MockAcademySettlementRepository();
      final s = await repo.calculate(
        academyId: 'a1',
        teacherMemberId: 'm1',
        periodYear: 2026,
        periodMonth: 6,
        calculatedAmount: 800000,
        breakdown: const [
          {'studentId': 's1', 'amount': 400000, 'lessons': 4},
          {'studentId': 's2', 'amount': 400000, 'lessons': 4},
        ],
      );
      expect(s.status, equals(SettlementStatus.draft));
      expect(s.calculatedAmount, equals(800000));
      expect(s.finalAmount, equals(800000));
      expect(s.breakdown.length, equals(2));
    });

    test(
      'calculate idempotent on existing draft (replace amount/breakdown)',
      () async {
        final repo = MockAcademySettlementRepository();
        final first = await repo.calculate(
          academyId: 'a1',
          teacherMemberId: 'm1',
          periodYear: 2026,
          periodMonth: 6,
          calculatedAmount: 800000,
        );
        final second = await repo.calculate(
          academyId: 'a1',
          teacherMemberId: 'm1',
          periodYear: 2026,
          periodMonth: 6,
          calculatedAmount: 900000,
        );
        // 같은 id (upsert).
        expect(second.id, equals(first.id));
        expect(second.calculatedAmount, equals(900000));
        expect(second.finalAmount, equals(900000));
      },
    );

    test(
      'calculate rejects when settlement is confirmed/transferred',
      () async {
        final repo = MockAcademySettlementRepository();
        final s = await repo.calculate(
          academyId: 'a1',
          teacherMemberId: 'm1',
          periodYear: 2026,
          periodMonth: 6,
          calculatedAmount: 800000,
        );
        await repo.confirm(s.id);
        expect(
          () => repo.calculate(
            academyId: 'a1',
            teacherMemberId: 'm1',
            periodYear: 2026,
            periodMonth: 6,
            calculatedAmount: 900000,
          ),
          throwsStateError,
        );
      },
    );

    test('adjust appends to log + updates finalAmount', () async {
      final repo = MockAcademySettlementRepository();
      final s = await repo.calculate(
        academyId: 'a1',
        teacherMemberId: 'm1',
        periodYear: 2026,
        periodMonth: 6,
        calculatedAmount: 800000,
      );
      final adjusted = await repo.adjust(
        settlementId: s.id,
        byUserId: 'owner1',
        adjustedAmount: 850000,
        reason: '대체 강사 페이 1회 추가',
      );
      expect(adjusted.adjustedAmount, equals(850000));
      expect(adjusted.finalAmount, equals(850000));
      expect(adjusted.adjustmentLog.length, equals(1));
      expect(adjusted.adjustmentLog.single['from'], equals(800000));
      expect(adjusted.adjustmentLog.single['to'], equals(850000));
      expect(adjusted.adjustmentLog.single['reason'], contains('대체 강사'));
    });

    test('adjust rejected on confirmed/transferred', () async {
      final repo = MockAcademySettlementRepository();
      final s = await repo.calculate(
        academyId: 'a1',
        teacherMemberId: 'm1',
        periodYear: 2026,
        periodMonth: 6,
        calculatedAmount: 800000,
      );
      await repo.confirm(s.id);
      expect(
        () => repo.adjust(
          settlementId: s.id,
          byUserId: 'u',
          adjustedAmount: 900000,
          reason: '',
        ),
        throwsStateError,
      );
    });

    test(
      'confirm sets status + confirmedAt + finalAmount = adjusted ?? calc',
      () async {
        final repo = MockAcademySettlementRepository();
        final s = await repo.calculate(
          academyId: 'a1',
          teacherMemberId: 'm1',
          periodYear: 2026,
          periodMonth: 6,
          calculatedAmount: 800000,
        );
        await repo.adjust(
          settlementId: s.id,
          byUserId: 'u',
          adjustedAmount: 750000,
          reason: '결근 페널티',
        );
        final confirmed = await repo.confirm(s.id);
        expect(confirmed.status, equals(SettlementStatus.confirmed));
        expect(confirmed.confirmedAt, isNotNull);
        expect(confirmed.finalAmount, equals(750000));
      },
    );

    test('markTransferred rejected when settlement is draft', () async {
      final repo = MockAcademySettlementRepository();
      final s = await repo.calculate(
        academyId: 'a1',
        teacherMemberId: 'm1',
        periodYear: 2026,
        periodMonth: 6,
        calculatedAmount: 800000,
      );
      expect(() => repo.markTransferred(s.id), throwsStateError);
    });

    test('markTransferred transitions confirmed → transferred', () async {
      final repo = MockAcademySettlementRepository();
      final s = await repo.calculate(
        academyId: 'a1',
        teacherMemberId: 'm1',
        periodYear: 2026,
        periodMonth: 6,
        calculatedAmount: 800000,
      );
      await repo.confirm(s.id);
      final transferred = await repo.markTransferred(s.id);
      expect(transferred.isTransferred, isTrue);
      expect(transferred.transferredAt, isNotNull);
    });
  });

  group('MockAcademySettlementRepository — queries + audit', () {
    test('listForAcademyPeriod returns desc by teacherMemberId asc', () async {
      final repo = MockAcademySettlementRepository();
      await repo.calculate(
        academyId: 'a1',
        teacherMemberId: 'm_B',
        periodYear: 2026,
        periodMonth: 6,
        calculatedAmount: 800000,
      );
      await repo.calculate(
        academyId: 'a1',
        teacherMemberId: 'm_A',
        periodYear: 2026,
        periodMonth: 6,
        calculatedAmount: 600000,
      );
      // 다른 학원
      await repo.calculate(
        academyId: 'a2',
        teacherMemberId: 'm_X',
        periodYear: 2026,
        periodMonth: 6,
        calculatedAmount: 500000,
      );

      final result = await repo.listForAcademyPeriod(
        academyId: 'a1',
        periodYear: 2026,
        periodMonth: 6,
      );
      expect(result.length, equals(2));
      expect(
        result.map((s) => s.teacherMemberId).toList(),
        equals(['m_A', 'm_B']),
      );
    });

    test('listForTeacher returns year+month desc + limit', () async {
      final repo = MockAcademySettlementRepository();
      for (var month = 1; month <= 6; month++) {
        await repo.calculate(
          academyId: 'a1',
          teacherMemberId: 'm1',
          periodYear: 2026,
          periodMonth: month,
          calculatedAmount: 100000 * month,
        );
      }
      final top3 = await repo.listForTeacher(teacherMemberId: 'm1', limit: 3);
      expect(top3.length, equals(3));
      expect(top3.first.periodMonth, equals(6));
      expect(top3.last.periodMonth, equals(4));
    });

    test('acknowledge sets timestamp + optional disputeNote (멱등)', () async {
      final repo = MockAcademySettlementRepository();
      final s = await repo.calculate(
        academyId: 'a1',
        teacherMemberId: 'm1',
        periodYear: 2026,
        periodMonth: 6,
        calculatedAmount: 800000,
      );
      final ack = await repo.acknowledge(settlementId: s.id);
      expect(ack.isAcknowledged, isTrue);
      expect(ack.isDisputed, isFalse);

      final disputed = await repo.acknowledge(
        settlementId: s.id,
        disputeNote: '시간당 단가 누락',
      );
      expect(disputed.isAcknowledged, isTrue);
      expect(disputed.isDisputed, isTrue);
      expect(disputed.teacherDisputeNote, equals('시간당 단가 누락'));
    });

    test('acknowledge throws on unknown settlement', () async {
      final repo = MockAcademySettlementRepository();
      expect(() => repo.acknowledge(settlementId: 'missing'), throwsStateError);
    });
  });
}
