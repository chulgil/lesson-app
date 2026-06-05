import 'package:lessonaza/features/academy/domain/entities/academy_invoice.dart';
import 'package:lessonaza/features/academy/domain/entities/billing_enums.dart';
import 'package:lessonaza/features/academy/domain/repositories/academy_invoice_repository.dart';

/// Mock implementation of AcademyInvoiceRepository.
class MockAcademyInvoiceRepository implements AcademyInvoiceRepository {
  MockAcademyInvoiceRepository({List<AcademyInvoice>? seed})
    : _invoices = List.of(seed ?? const []);

  final List<AcademyInvoice> _invoices;
  int _idSeq = 0;

  String _nextId() {
    _idSeq++;
    return 'invoice_$_idSeq';
  }

  void clear() {
    _invoices.clear();
  }

  // ------------------------------------------------------------------
  // CRUD
  // ------------------------------------------------------------------

  @override
  Future<List<AcademyInvoice>> listForAcademy(
    String academyId, {
    InvoiceStatus? status,
    int? periodYear,
    int? periodMonth,
    int limit = 200,
  }) async {
    await _delay();
    final filtered =
        _invoices.where((i) {
            if (i.academyId != academyId) return false;
            if (status != null && i.status != status) return false;
            if (periodYear != null && i.periodYear != periodYear) return false;
            if (periodMonth != null && i.periodMonth != periodMonth) {
              return false;
            }
            return true;
          }).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return filtered.take(limit).toList();
  }

  @override
  Future<List<AcademyInvoice>> listForStudent(
    String academyStudentId, {
    int limit = 50,
  }) async {
    await _delay();
    final filtered =
        _invoices.where((i) => i.academyStudentId == academyStudentId).toList()
          ..sort((a, b) {
            // year desc, month desc.
            final yc = b.periodYear.compareTo(a.periodYear);
            if (yc != 0) return yc;
            return b.periodMonth.compareTo(a.periodMonth);
          });
    return filtered.take(limit).toList();
  }

  @override
  Future<AcademyInvoice?> get(String invoiceId) async {
    await _delay();
    return _invoices.cast<AcademyInvoice?>().firstWhere(
      (i) => i!.id == invoiceId,
      orElse: () => null,
    );
  }

  @override
  Future<AcademyInvoice> create({
    required String academyId,
    required String academyStudentId,
    required int periodYear,
    required int periodMonth,
    int baseAmount = 0,
    int extraAmount = 0,
    int discountAmount = 0,
    List<Map<String, dynamic>>? lineItems,
    DateTime? dueDate,
  }) async {
    await _delay();
    // unique (academy + student + year + month) — BE 의 unique index 모방.
    final duplicate = _invoices.any(
      (i) =>
          i.academyId == academyId &&
          i.academyStudentId == academyStudentId &&
          i.periodYear == periodYear &&
          i.periodMonth == periodMonth,
    );
    if (duplicate) {
      throw StateError(
        'Invoice already exists for academy=$academyId student=$academyStudentId '
        'period=$periodYear-$periodMonth',
      );
    }
    final total = baseAmount + extraAmount - discountAmount;
    final invoice = AcademyInvoice(
      id: _nextId(),
      academyId: academyId,
      academyStudentId: academyStudentId,
      periodYear: periodYear,
      periodMonth: periodMonth,
      baseAmount: baseAmount,
      extraAmount: extraAmount,
      discountAmount: discountAmount,
      totalAmount: total < 0 ? 0 : total,
      lineItems: lineItems,
      dueDate: dueDate,
      createdAt: DateTime.now(),
    );
    _invoices.add(invoice);
    return invoice;
  }

  @override
  Future<AcademyInvoice> update(AcademyInvoice invoice) async {
    await _delay();
    final index = _invoices.indexWhere((i) => i.id == invoice.id);
    if (index < 0) {
      throw StateError('Invoice not found: ${invoice.id}');
    }
    _invoices[index] = invoice;
    return invoice;
  }

  // ------------------------------------------------------------------
  // Bulk
  // ------------------------------------------------------------------

  @override
  Future<List<AcademyInvoice>> bulkSend(List<String> invoiceIds) async {
    await _delay();
    final now = DateTime.now();
    final updated = <AcademyInvoice>[];
    for (final id in invoiceIds) {
      final index = _invoices.indexWhere((i) => i.id == id);
      if (index < 0) continue;
      final current = _invoices[index];
      if (current.status != InvoiceStatus.draft) continue;
      final sent = current.copyWith(
        status: InvoiceStatus.sent,
        issuedAt: current.issuedAt ?? now,
        sentAt: now,
      );
      _invoices[index] = sent;
      updated.add(sent);
    }
    return updated;
  }

  @override
  Future<AcademyInvoice> cancel(String invoiceId) async {
    await _delay();
    final index = _invoices.indexWhere((i) => i.id == invoiceId);
    if (index < 0) {
      throw StateError('Invoice not found: $invoiceId');
    }
    final current = _invoices[index];
    if (current.status == InvoiceStatus.paid) {
      throw StateError('Cannot cancel paid invoice: $invoiceId');
    }
    final cancelled = current.copyWith(status: InvoiceStatus.cancelled);
    _invoices[index] = cancelled;
    return cancelled;
  }

  Future<void> _delay() async {
    await Future<void>.delayed(const Duration(milliseconds: 30));
  }
}
