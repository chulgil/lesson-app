import '../entities/payment.dart';

/// Repository interface for payment management
abstract class PaymentRepository {
  // Payment CRUD
  Future<List<Payment>> getAllPayments();
  Future<List<Payment>> getPaymentsByStudent(String studentId);
  Future<List<Payment>> getPaymentsByStatus(PaymentStatus status);
  Future<List<Payment>> getPaymentsByMonth(int year, int month);
  Future<Payment?> getPaymentById(String id);
  Future<Payment> addPayment(Payment payment);
  Future<Payment> updatePayment(Payment payment);
  Future<void> deletePayment(String id);

  // Tuition settings
  Future<TuitionSettings?> getTuitionSettings(String studentId);
  Future<TuitionSettings> updateTuitionSettings(TuitionSettings settings);

  // Summary
  Future<PaymentSummary> getPaymentSummary({int? year, int? month});
  Future<List<Payment>> getOverduePayments();
}
