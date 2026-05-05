import '../../domain/entities/payment.dart';
import '../../domain/repositories/payment_repository.dart';

/// Mock implementation of PaymentRepository
class MockPaymentRepository implements PaymentRepository {
  List<Payment> _payments = [];

  MockPaymentRepository({bool empty = false}) {
    if (empty) return;
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);

    _payments = [
      // Regular monthly payment - completed
      Payment(
        id: 'payment_1',
        studentId: 'student_1',
        studentName: '김서연',
        type: PaymentType.regular,
        amount: 200000,
        status: PaymentStatus.confirmed,
        method: PaymentMethod.bankTransfer,
        paymentDate: now.subtract(const Duration(days: 5)),
        lessonCount: 4,
        periodStart: currentMonth,
        periodEnd: monthEnd,
        weekStart: 1,
        weekEnd: 4,
        createdAt: now.subtract(const Duration(days: 10)),
      ),
      // Regular - advanced level student
      Payment(
        id: 'payment_2',
        studentId: 'student_2',
        studentName: '이준호',
        type: PaymentType.regular,
        amount: 240000,
        status: PaymentStatus.confirmed,
        method: PaymentMethod.card,
        paymentDate: now.subtract(const Duration(days: 3)),
        lessonCount: 4,
        periodStart: currentMonth,
        periodEnd: monthEnd,
        weekStart: 1,
        weekEnd: 4,
        createdAt: now.subtract(const Duration(days: 8)),
      ),
      // Regular - pending (overdue)
      Payment(
        id: 'payment_3',
        studentId: 'student_3',
        studentName: '박민지',
        type: PaymentType.regular,
        amount: 180000,
        status: PaymentStatus.pending,
        method: PaymentMethod.bankTransfer,
        paymentDate: now,
        dueDate: now.subtract(const Duration(days: 2)),
        lessonCount: 4,
        periodStart: currentMonth,
        periodEnd: monthEnd,
        weekStart: 1,
        weekEnd: 4,
        createdAt: now.subtract(const Duration(days: 15)),
      ),
      // Partial month payment (2 weeks only)
      Payment(
        id: 'payment_4',
        studentId: 'student_4',
        studentName: '최예은',
        type: PaymentType.regular,
        amount: 100000,
        status: PaymentStatus.pending,
        method: PaymentMethod.bankTransfer,
        paymentDate: now,
        dueDate: now.add(const Duration(days: 5)),
        lessonCount: 2,
        periodStart: DateTime(now.year, now.month, 15),
        periodEnd: monthEnd,
        weekStart: 3,
        weekEnd: 4,
        createdAt: now.subtract(const Duration(days: 5)),
      ),
      // Beginner level
      Payment(
        id: 'payment_5',
        studentId: 'student_5',
        studentName: '정하늘',
        type: PaymentType.regular,
        amount: 160000,
        status: PaymentStatus.confirmed,
        method: PaymentMethod.cash,
        paymentDate: now.subtract(const Duration(days: 7)),
        lessonCount: 4,
        periodStart: currentMonth,
        periodEnd: monthEnd,
        weekStart: 1,
        weekEnd: 4,
        createdAt: now.subtract(const Duration(days: 12)),
      ),
      // Trial lesson - completed
      Payment(
        id: 'payment_6',
        studentId: 'student_6',
        studentName: '신유진',
        type: PaymentType.trial,
        amount: 30000,
        status: PaymentStatus.confirmed,
        method: PaymentMethod.bankTransfer,
        paymentDate: now.subtract(const Duration(days: 1)),
        lessonCount: 1,
        periodStart: DateTime(now.year, now.month, 14),
        periodEnd: DateTime(now.year, now.month, 14),
        weekStart: 2,
        weekEnd: 2,
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      // Trial lesson - pending
      Payment(
        id: 'payment_7',
        studentId: 'student_7',
        studentName: '한지민',
        type: PaymentType.trial,
        amount: 30000,
        status: PaymentStatus.pending,
        method: PaymentMethod.bankTransfer,
        paymentDate: now,
        dueDate: now.add(const Duration(days: 1)),
        lessonCount: 1,
        periodStart: DateTime(now.year, now.month, 21),
        periodEnd: DateTime(now.year, now.month, 21),
        weekStart: 3,
        weekEnd: 3,
        createdAt: now,
      ),
    ];
  }

  final Map<String, TuitionSettings> _tuitionSettings = {
    'student_1': const TuitionSettings(
      studentId: 'student_1',
      monthlyFee: 200000,
      lessonsPerMonth: 4,
      billingDay: 1,
    ),
    'student_2': const TuitionSettings(
      studentId: 'student_2',
      monthlyFee: 240000,
      lessonsPerMonth: 4,
      billingDay: 1,
    ),
    'student_3': const TuitionSettings(
      studentId: 'student_3',
      monthlyFee: 180000,
      lessonsPerMonth: 4,
      billingDay: 1,
    ),
    'student_4': const TuitionSettings(
      studentId: 'student_4',
      monthlyFee: 200000,
      lessonsPerMonth: 4,
      billingDay: 1,
    ),
    'student_5': const TuitionSettings(
      studentId: 'student_5',
      monthlyFee: 160000,
      lessonsPerMonth: 4,
      billingDay: 1,
    ),
  };

  @override
  Future<List<Payment>> getAllPayments() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_payments)
      ..sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
  }

  @override
  Future<List<Payment>> getPaymentsByStudent(String studentId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _payments.where((p) => p.studentId == studentId).toList()
      ..sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
  }

  @override
  Future<List<Payment>> getPaymentsByStatus(PaymentStatus status) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _payments.where((p) => p.status == status).toList();
  }

  @override
  Future<List<Payment>> getPaymentsByMonth(int year, int month) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _payments.where((p) {
      return p.periodStart.year == year && p.periodStart.month == month;
    }).toList();
  }

  @override
  Future<Payment?> getPaymentById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _payments.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Payment> addPayment(Payment payment) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final newPayment = payment.copyWith(
      id: 'payment_${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
    );
    _payments.add(newPayment);
    return newPayment;
  }

  @override
  Future<Payment> updatePayment(Payment payment) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _payments.indexWhere((p) => p.id == payment.id);
    if (index == -1) {
      throw Exception('Payment not found');
    }
    final updated = payment.copyWith(updatedAt: DateTime.now());
    _payments[index] = updated;
    return updated;
  }

  @override
  Future<void> deletePayment(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _payments.removeWhere((p) => p.id == id);
  }

  @override
  Future<TuitionSettings?> getTuitionSettings(String studentId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _tuitionSettings[studentId];
  }

  @override
  Future<TuitionSettings> updateTuitionSettings(
    TuitionSettings settings,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _tuitionSettings[settings.studentId] = settings;
    return settings;
  }

  @override
  Future<PaymentSummary> getPaymentSummary({int? year, int? month}) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final now = DateTime.now();
    final targetYear = year ?? now.year;
    final targetMonth = month ?? now.month;

    final monthPayments =
        _payments.where((p) {
          return p.periodStart.year == targetYear &&
              p.periodStart.month == targetMonth;
        }).toList();

    final completed = monthPayments.where(
      (p) => p.status == PaymentStatus.confirmed,
    );
    final pending = monthPayments.where(
      (p) => p.status == PaymentStatus.pending,
    );
    final overdue = pending.where((p) => p.isOverdue);

    return PaymentSummary(
      totalReceived: completed.fold(0, (sum, p) => sum + p.amount),
      totalPending: pending.fold(0, (sum, p) => sum + p.amount),
      totalOverdue: overdue.fold(0, (sum, p) => sum + p.amount),
      paidStudents: completed.length,
      unpaidStudents: pending.length,
      overdueStudents: overdue.length,
    );
  }

  @override
  Future<List<Payment>> getOverduePayments() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _payments.where((p) => p.isOverdue).toList();
  }
}
