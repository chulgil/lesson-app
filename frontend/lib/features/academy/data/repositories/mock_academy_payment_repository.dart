import 'package:lessonaza/features/academy/domain/entities/academy_payment.dart';
import 'package:lessonaza/features/academy/domain/entities/billing_enums.dart';
import 'package:lessonaza/features/academy/domain/repositories/academy_payment_repository.dart';

/// Mock implementation of AcademyPaymentRepository.
class MockAcademyPaymentRepository implements AcademyPaymentRepository {
  MockAcademyPaymentRepository({List<AcademyPayment>? seed})
    : _payments = List.of(seed ?? const []);

  final List<AcademyPayment> _payments;
  int _idSeq = 0;

  String _nextId() {
    _idSeq++;
    return 'payment_$_idSeq';
  }

  void clear() {
    _payments.clear();
  }

  @override
  Future<List<AcademyPayment>> listForAcademy(
    String academyId, {
    DateTime? from,
    DateTime? to,
    int limit = 200,
  }) async {
    await _delay();
    final filtered =
        _payments.where((p) {
            if (p.academyId != academyId) return false;
            if (from != null && p.paidAt.isBefore(from)) return false;
            if (to != null && p.paidAt.isAfter(to)) return false;
            return true;
          }).toList()
          ..sort((a, b) => b.paidAt.compareTo(a.paidAt));
    return filtered.take(limit).toList();
  }

  @override
  Future<List<AcademyPayment>> listForInvoice(String invoiceId) async {
    await _delay();
    final filtered =
        _payments.where((p) => p.invoiceId == invoiceId).toList()
          ..sort((a, b) => a.paidAt.compareTo(b.paidAt));
    return filtered;
  }

  @override
  Future<AcademyPayment> record({
    required String academyId,
    required String invoiceId,
    required int paidAmount,
    required DateTime paidAt,
    required String confirmedByUserId,
    PaymentMethod method = PaymentMethod.transfer,
    PaymentSource source = PaymentSource.manual,
    String? bankTxRef,
    String? depositorRaw,
    String? note,
  }) async {
    await _delay();
    if (paidAmount <= 0) {
      throw ArgumentError('paidAmount must be > 0');
    }
    final payment = AcademyPayment(
      id: _nextId(),
      academyId: academyId,
      invoiceId: invoiceId,
      paidAmount: paidAmount,
      paidAt: paidAt,
      method: method,
      confirmedByUserId: confirmedByUserId,
      source: source,
      bankTxRef: bankTxRef,
      depositorRaw: depositorRaw,
      note: note,
      createdAt: DateTime.now(),
    );
    _payments.add(payment);
    return payment;
  }

  @override
  Future<int> sumForInvoice(String invoiceId) async {
    await _delay();
    return _payments
        .where((p) => p.invoiceId == invoiceId)
        .fold<int>(0, (sum, p) => sum + p.paidAmount);
  }

  Future<void> _delay() async {
    await Future<void>.delayed(const Duration(milliseconds: 30));
  }
}
