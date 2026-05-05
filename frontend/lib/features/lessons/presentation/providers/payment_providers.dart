import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../students/students_facade.dart' show studentsNotifierProvider;
import '../../../students/domain/entities/student.dart';
import '../../domain/entities/payment.dart';
import '../../domain/repositories/payment_repository.dart';
import 'payment_repository_provider.dart';

// Legacy independent payment providers.
//
// Current payment policy uses Subscription payment status and deposit
// confirmation screens. These providers must not be routed as a current
// payment-management feature until a future billing spec is approved.

/// All payments provider
final allPaymentsProvider = FutureProvider<List<Payment>>((ref) async {
  final repository = ref.watch(paymentRepositoryProvider);
  return repository.getAllPayments();
});

/// Single payment provider
final paymentProvider = FutureProvider.family<Payment?, String>((
  ref,
  paymentId,
) async {
  final repository = ref.watch(paymentRepositoryProvider);
  return repository.getPaymentById(paymentId);
});

/// Payments by student provider
final studentPaymentsProvider = FutureProvider.family<List<Payment>, String>((
  ref,
  studentId,
) async {
  final repository = ref.watch(paymentRepositoryProvider);
  return repository.getPaymentsByStudent(studentId);
});

/// Payments by status provider
final paymentsByStatusProvider =
    FutureProvider.family<List<Payment>, PaymentStatus>((ref, status) async {
      final repository = ref.watch(paymentRepositoryProvider);
      return repository.getPaymentsByStatus(status);
    });

/// Pending payments provider
final pendingPaymentsProvider = FutureProvider<List<Payment>>((ref) async {
  final repository = ref.watch(paymentRepositoryProvider);
  return repository.getPaymentsByStatus(PaymentStatus.pending);
});

/// Overdue payments provider
final overduePaymentsProvider = FutureProvider<List<Payment>>((ref) async {
  final repository = ref.watch(paymentRepositoryProvider);
  return repository.getOverduePayments();
});

/// Payment summary provider
final paymentSummaryProvider = FutureProvider<PaymentSummary>((ref) async {
  final repository = ref.watch(paymentRepositoryProvider);
  return repository.getPaymentSummary();
});

/// Monthly payment summary provider
final monthlyPaymentSummaryProvider = FutureProvider.family<
  PaymentSummary,
  ({int year, int month})
>((ref, params) async {
  final repository = ref.watch(paymentRepositoryProvider);
  return repository.getPaymentSummary(year: params.year, month: params.month);
});

/// Tuition settings provider
final tuitionSettingsProvider = FutureProvider.family<TuitionSettings?, String>(
  (ref, studentId) async {
    final repository = ref.watch(paymentRepositoryProvider);
    return repository.getTuitionSettings(studentId);
  },
);

/// Payments notifier for CRUD operations
class PaymentsNotifier extends AsyncNotifier<List<Payment>> {
  PaymentRepository get _repository => ref.read(paymentRepositoryProvider);

  @override
  Future<List<Payment>> build() async {
    return _repository.getAllPayments();
  }

  /// Add a new payment
  Future<Payment> addPayment(Payment payment) async {
    state = const AsyncValue.loading();
    try {
      final newPayment = await _repository.addPayment(payment);
      final payments = await _repository.getAllPayments();
      state = AsyncValue.data(payments);
      return newPayment;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Update a payment
  Future<void> updatePayment(Payment payment) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updatePayment(payment);
      final payments = await _repository.getAllPayments();
      state = AsyncValue.data(payments);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Mark payment as completed (teacher confirmation - step 2)
  /// Also updates student status: regular payment → active status
  Future<void> markAsCompleted(String paymentId) async {
    final current = state.value;
    if (current == null) return;

    final payment = current.firstWhere((p) => p.id == paymentId);
    await updatePayment(
      payment.copyWith(
        status: PaymentStatus.confirmed,
        paymentDate: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    // Auto-update student status when regular payment is confirmed
    // Trial → remains trial (need explicit upgrade)
    // Regular payment confirmed → student becomes active
    if (payment.type == PaymentType.regular) {
      try {
        await ref
            .read(studentsNotifierProvider.notifier)
            .updateStudentStatus(payment.studentId, StudentStatus.active);
      } catch (_) {
        // If student update fails, don't fail the payment update
      }
    }
  }

  /// Mark payment as student confirmed (step 1)
  Future<void> markStudentConfirmed(String paymentId) async {
    final current = state.value;
    if (current == null) return;

    final payment = current.firstWhere((p) => p.id == paymentId);
    await updatePayment(
      payment.copyWith(
        studentConfirmed: true,
        studentConfirmedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  /// Cancel payment
  Future<void> cancelPayment(String paymentId) async {
    final current = state.value;
    if (current == null) return;

    final payment = current.firstWhere((p) => p.id == paymentId);
    await updatePayment(payment.copyWith(status: PaymentStatus.cancelled));
  }

  /// Delete a payment
  Future<void> deletePayment(String paymentId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deletePayment(paymentId);
      final payments = await _repository.getAllPayments();
      state = AsyncValue.data(payments);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Refresh payments
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getAllPayments());
  }
}

final paymentsNotifierProvider =
    AsyncNotifierProvider<PaymentsNotifier, List<Payment>>(
      PaymentsNotifier.new,
    );

/// Tuition settings notifier
class TuitionSettingsNotifier
    extends FamilyAsyncNotifier<TuitionSettings?, String> {
  PaymentRepository get _repository => ref.read(paymentRepositoryProvider);

  @override
  Future<TuitionSettings?> build(String studentId) async {
    return _repository.getTuitionSettings(studentId);
  }

  /// Update tuition settings
  Future<void> updateSettings(TuitionSettings settings) async {
    state = const AsyncValue.loading();
    try {
      final updated = await _repository.updateTuitionSettings(settings);
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final tuitionSettingsNotifierProvider = AsyncNotifierProvider.family<
  TuitionSettingsNotifier,
  TuitionSettings?,
  String
>(TuitionSettingsNotifier.new);
