import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/payment_receipt.dart';

part 'payment_receipt_providers.g.dart';

// ============================================================
// Mock data helpers
// ============================================================

List<PaymentReceipt> _buildMockReceipts() {
  final now = DateTime.now();
  return [
    PaymentReceipt(
      id: 'receipt_001',
      receiptNumber: '2026-T3fa8b2c1-0003',
      teacherId: 'teacher_1',
      studentId: 'student_1',
      studentName: '김민지',
      subscriptionType: '8회권',
      amount: 400000,
      paymentDate: DateTime(now.year, now.month, 1),
      period:
          '${now.year}.${now.month.toString().padLeft(2, '0')}.01 ~ '
          '${now.year}.${now.month.toString().padLeft(2, '0')}.30',
      createdAt: DateTime(now.year, now.month, 1, 10, 0),
      pdfUrl: null,
    ),
    PaymentReceipt(
      id: 'receipt_002',
      receiptNumber: '2026-T3fa8b2c1-0002',
      teacherId: 'teacher_1',
      studentId: 'student_2',
      studentName: '박지수',
      subscriptionType: '월정액',
      amount: 200000,
      paymentDate: DateTime(now.year, now.month - 1, 15),
      period:
          '${now.year}.${(now.month - 1).toString().padLeft(2, '0')}.01 ~ '
          '${now.year}.${(now.month - 1).toString().padLeft(2, '0')}.30',
      createdAt: DateTime(now.year, now.month - 1, 15, 9, 30),
      pdfUrl: null,
    ),
    PaymentReceipt(
      id: 'receipt_003',
      receiptNumber: '2026-T3fa8b2c1-0001',
      teacherId: 'teacher_1',
      studentId: 'student_3',
      studentName: '이준서',
      subscriptionType: '체험',
      amount: 50000,
      paymentDate: DateTime(now.year, now.month - 1, 3),
      period:
          '${now.year}.${(now.month - 1).toString().padLeft(2, '0')}.03',
      createdAt: DateTime(now.year, now.month - 1, 3, 14, 0),
      pdfUrl: null,
    ),
    PaymentReceipt(
      id: 'receipt_004',
      receiptNumber: '2026-T3fa8b2c1-0004',
      teacherId: 'teacher_1',
      studentId: 'student_4',
      studentName: '최서연',
      subscriptionType: '16회권',
      amount: 720000,
      paymentDate: DateTime(now.year, now.month, 5),
      period:
          '${now.year}.${now.month.toString().padLeft(2, '0')}.05 ~ '
          '${now.year}.${(now.month + 1).toString().padLeft(2, '0')}.05',
      createdAt: DateTime(now.year, now.month, 5, 11, 0),
      pdfUrl: null,
    ),
    PaymentReceipt(
      id: 'receipt_005',
      receiptNumber: '2026-T3fa8b2c1-0005',
      teacherId: 'teacher_1',
      studentId: 'student_5',
      studentName: '정하늘',
      subscriptionType: '8회권',
      amount: 320000,
      paymentDate: DateTime(now.year, now.month, 7),
      period:
          '${now.year}.${now.month.toString().padLeft(2, '0')}.07 ~ '
          '${now.year}.${(now.month + 1).toString().padLeft(2, '0')}.07',
      createdAt: DateTime(now.year, now.month, 7, 15, 30),
      pdfUrl: null,
    ),
  ];
}

// ============================================================
// Providers
// ============================================================

/// All receipts for the current teacher (mock data).
@riverpod
Future<List<PaymentReceipt>> teacherPaymentReceipts(
  TeacherPaymentReceiptsRef ref, {
  int? year,
  int? month,
}) async {
  // Simulated network delay.
  await Future.delayed(const Duration(milliseconds: 300));

  final receipts = _buildMockReceipts();

  return receipts.where((r) {
    if (year != null && r.paymentDate.year != year) return false;
    if (month != null && r.paymentDate.month != month) return false;
    return true;
  }).toList()
    ..sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
}

/// Single receipt by ID.
@riverpod
Future<PaymentReceipt?> paymentReceipt(
  PaymentReceiptRef ref,
  String id,
) async {
  await Future.delayed(const Duration(milliseconds: 200));
  return _buildMockReceipts().where((r) => r.id == id).firstOrNull;
}
