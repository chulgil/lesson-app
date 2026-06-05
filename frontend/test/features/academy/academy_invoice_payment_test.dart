import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/academy/data/repositories/mock_academy_invoice_repository.dart';
import 'package:lessonaza/features/academy/data/repositories/mock_academy_payment_repository.dart';
import 'package:lessonaza/features/academy/domain/entities/academy_invoice.dart';
import 'package:lessonaza/features/academy/domain/entities/billing_enums.dart';

void main() {
  group('AcademyInvoice entity', () {
    AcademyInvoice buildInvoice({
      InvoiceStatus? status,
      int? total,
      DateTime? dueDate,
      List<Map<String, dynamic>>? lineItems,
    }) {
      return AcademyInvoice(
        id: 'inv_1',
        academyId: 'a1',
        academyStudentId: 's1',
        periodYear: 2026,
        periodMonth: 6,
        baseAmount: 200000,
        extraAmount: 30000,
        discountAmount: 10000,
        totalAmount: total ?? 220000,
        status: status ?? InvoiceStatus.draft,
        dueDate: dueDate,
        lineItems: lineItems,
        createdAt: DateTime(2026, 6, 1),
      );
    }

    test('periodMonth out of 1..12 throws assertion', () {
      expect(
        () => AcademyInvoice(
          id: 'x',
          academyId: 'a',
          academyStudentId: 's',
          periodYear: 2026,
          periodMonth: 13,
          createdAt: DateTime.now(),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('negative totalAmount rejected', () {
      expect(
        () => AcademyInvoice(
          id: 'x',
          academyId: 'a',
          academyStudentId: 's',
          periodYear: 2026,
          periodMonth: 6,
          totalAmount: -1,
          createdAt: DateTime.now(),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('lineItems is unmodifiable', () {
      final inv = buildInvoice(
        lineItems: const [
          {'desc': '6월 수강료', 'amount': 200000},
        ],
      );
      expect(() => inv.lineItems.add({}), throwsUnsupportedError);
    });

    test('isOutstanding tracks status.isOutstanding', () {
      expect(buildInvoice(status: InvoiceStatus.draft).isOutstanding, isFalse);
      expect(buildInvoice(status: InvoiceStatus.sent).isOutstanding, isTrue);
      expect(buildInvoice(status: InvoiceStatus.overdue).isOutstanding, isTrue);
      expect(buildInvoice(status: InvoiceStatus.paid).isOutstanding, isFalse);
    });

    test('isDraft / isPastDueAt / hasConsistentTotal', () {
      final inv = buildInvoice(
        status: InvoiceStatus.sent,
        dueDate: DateTime(2026, 7, 7),
      );
      expect(inv.isDraft, isFalse);
      expect(inv.isPastDueAt(DateTime(2026, 7, 6)), isFalse);
      expect(inv.isPastDueAt(DateTime(2026, 7, 8)), isTrue);
      // base(200000) + extra(30000) - discount(10000) == total(220000)
      expect(inv.hasConsistentTotal, isTrue);

      final inconsistent = inv.copyWith(totalAmount: 999000);
      expect(inconsistent.hasConsistentTotal, isFalse);
    });

    test('copyWith + equality', () {
      final a = buildInvoice();
      final b = buildInvoice();
      final c = a.copyWith(status: InvoiceStatus.sent);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });

  group('AcademyPayment entity (via Mock)', () {
    test('paidAmount > 0 assert (BE CheckConstraint)', () async {
      final repo = MockAcademyPaymentRepository();
      expect(
        () => repo.record(
          academyId: 'a1',
          invoiceId: 'inv1',
          paidAmount: 0,
          paidAt: DateTime.now(),
          confirmedByUserId: 'u1',
        ),
        throwsArgumentError,
      );
    });
  });

  group('MockAcademyInvoiceRepository', () {
    test('create + listForAcademy + listForStudent + get', () async {
      final repo = MockAcademyInvoiceRepository();
      final inv = await repo.create(
        academyId: 'a1',
        academyStudentId: 's1',
        periodYear: 2026,
        periodMonth: 6,
        baseAmount: 200000,
      );
      expect(inv.status, equals(InvoiceStatus.draft));
      expect(inv.totalAmount, equals(200000));

      final list = await repo.listForAcademy('a1');
      expect(list.length, equals(1));

      final studentList = await repo.listForStudent('s1');
      expect(studentList.single.id, equals(inv.id));

      final fetched = await repo.get(inv.id);
      expect(fetched, equals(inv));
    });

    test('create rejects duplicate (academy, student, year, month)', () async {
      final repo = MockAcademyInvoiceRepository();
      await repo.create(
        academyId: 'a1',
        academyStudentId: 's1',
        periodYear: 2026,
        periodMonth: 6,
      );
      expect(
        () => repo.create(
          academyId: 'a1',
          academyStudentId: 's1',
          periodYear: 2026,
          periodMonth: 6,
        ),
        throwsStateError,
      );
    });

    test('listForAcademy filters by status / period', () async {
      final repo = MockAcademyInvoiceRepository();
      await repo.create(
        academyId: 'a1',
        academyStudentId: 's1',
        periodYear: 2026,
        periodMonth: 6,
      );
      await repo.create(
        academyId: 'a1',
        academyStudentId: 's2',
        periodYear: 2026,
        periodMonth: 7,
      );
      final juneOnly = await repo.listForAcademy(
        'a1',
        periodYear: 2026,
        periodMonth: 6,
      );
      expect(juneOnly.length, equals(1));

      // 모두 draft 이므로 sent 필터링은 빈 결과.
      final sent = await repo.listForAcademy('a1', status: InvoiceStatus.sent);
      expect(sent, isEmpty);
    });

    test('bulkSend transitions draft → sent, skips non-draft', () async {
      final repo = MockAcademyInvoiceRepository();
      final i1 = await repo.create(
        academyId: 'a1',
        academyStudentId: 's1',
        periodYear: 2026,
        periodMonth: 6,
      );
      final i2 = await repo.create(
        academyId: 'a1',
        academyStudentId: 's2',
        periodYear: 2026,
        periodMonth: 6,
      );
      // i2 를 미리 cancelled 로 만든다.
      await repo.cancel(i2.id);

      final sent = await repo.bulkSend([i1.id, i2.id, 'unknown']);
      // i1 만 sent 됨. i2 (cancelled), 'unknown' 은 skip.
      expect(sent.length, equals(1));
      expect(sent.single.id, equals(i1.id));
      expect(sent.single.status, equals(InvoiceStatus.sent));
      expect(sent.single.issuedAt, isNotNull);
      expect(sent.single.sentAt, isNotNull);

      final freshI2 = await repo.get(i2.id);
      expect(freshI2!.status, equals(InvoiceStatus.cancelled));
    });

    test('cancel rejects paid invoice', () async {
      final repo = MockAcademyInvoiceRepository();
      final inv = await repo.create(
        academyId: 'a1',
        academyStudentId: 's1',
        periodYear: 2026,
        periodMonth: 6,
      );
      // sent → paid 로 수동 update.
      await repo.update(inv.copyWith(status: InvoiceStatus.paid));
      expect(() => repo.cancel(inv.id), throwsStateError);
    });
  });

  group('MockAcademyPaymentRepository', () {
    test('record + sumForInvoice (부분 수금 N건)', () async {
      final repo = MockAcademyPaymentRepository();
      await repo.record(
        academyId: 'a1',
        invoiceId: 'inv1',
        paidAmount: 100000,
        paidAt: DateTime(2026, 6, 10),
        confirmedByUserId: 'owner1',
      );
      await repo.record(
        academyId: 'a1',
        invoiceId: 'inv1',
        paidAmount: 50000,
        paidAt: DateTime(2026, 6, 15),
        confirmedByUserId: 'owner1',
        source: PaymentSource.csvImport,
        bankTxRef: 'TX_001',
      );

      final sum = await repo.sumForInvoice('inv1');
      expect(sum, equals(150000));

      final byInvoice = await repo.listForInvoice('inv1');
      // paidAt asc.
      expect(byInvoice.first.paidAmount, equals(100000));
      expect(byInvoice.last.paidAmount, equals(50000));
      expect(byInvoice.last.hasMatchingAudit, isTrue);
    });

    test('listForAcademy time-range filter', () async {
      final repo = MockAcademyPaymentRepository();
      await repo.record(
        academyId: 'a1',
        invoiceId: 'i1',
        paidAmount: 100000,
        paidAt: DateTime(2026, 6, 5),
        confirmedByUserId: 'u',
      );
      await repo.record(
        academyId: 'a1',
        invoiceId: 'i2',
        paidAmount: 100000,
        paidAt: DateTime(2026, 7, 5),
        confirmedByUserId: 'u',
      );

      final juneOnly = await repo.listForAcademy(
        'a1',
        from: DateTime(2026, 6, 1),
        to: DateTime(2026, 6, 30),
      );
      expect(juneOnly.length, equals(1));
      expect(juneOnly.single.invoiceId, equals('i1'));
    });

    test('listForAcademy returns desc by paidAt + limit', () async {
      final repo = MockAcademyPaymentRepository();
      for (var i = 0; i < 5; i++) {
        await repo.record(
          academyId: 'a1',
          invoiceId: 'inv$i',
          paidAmount: 10000,
          paidAt: DateTime(2026, 6, 1 + i),
          confirmedByUserId: 'u',
        );
      }
      final top2 = await repo.listForAcademy('a1', limit: 2);
      expect(top2.length, equals(2));
      // 가장 최근 paidAt 부터.
      expect(top2.first.invoiceId, equals('inv4'));
      expect(top2.last.invoiceId, equals('inv3'));
    });

    test('sumForInvoice returns 0 when no payments', () async {
      final repo = MockAcademyPaymentRepository();
      expect(await repo.sumForInvoice('nonexistent'), equals(0));
    });
  });
}
