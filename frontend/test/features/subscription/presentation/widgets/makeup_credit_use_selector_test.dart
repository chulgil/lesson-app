import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lessonaza/features/subscription/domain/entities/makeup_credit.dart';
import 'package:lessonaza/features/subscription/presentation/widgets/makeup_credit_use_selector.dart';

/// Regression (#bug7): when the credit balance is empty the credit option is
/// hidden, and a stale `makeupCredit` selection must auto-fall back to
/// `regularSubscription` so the booking flow never submits an invalid source.
MakeupCredit _credit() => MakeupCredit(
  id: 'c1',
  studentId: 's1',
  teacherId: 't1',
  reason: MakeupCreditReason.teacherVacation,
  createdAt: DateTime(2026, 6, 1),
  expiresAt: DateTime(2026, 7, 1),
);

Future<BookingPaymentSource?> _pump(
  WidgetTester tester, {
  required MakeupCreditBalance balance,
  required BookingPaymentSource selected,
}) async {
  BookingPaymentSource? lastChanged;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: MakeupCreditUseSelector(
          balance: balance,
          selected: selected,
          onChanged: (v) => lastChanged = v,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return lastChanged;
}

void main() {
  group('MakeupCreditUseSelector', () {
    testWidgets('shows both options when credit is available', (tester) async {
      await _pump(
        tester,
        balance: MakeupCreditBalance(available: [_credit()]),
        selected: BookingPaymentSource.regularSubscription,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'empty balance with stale makeupCredit selection auto-falls back',
      (tester) async {
        final changed = await _pump(
          tester,
          balance: const MakeupCreditBalance(),
          selected: BookingPaymentSource.makeupCredit,
        );

        expect(tester.takeException(), isNull);
        // Parent is notified to correct the invalid selection.
        expect(changed, BookingPaymentSource.regularSubscription);
      },
    );

    testWidgets(
      'empty balance with regular selection does not re-notify',
      (tester) async {
        final changed = await _pump(
          tester,
          balance: const MakeupCreditBalance(),
          selected: BookingPaymentSource.regularSubscription,
        );

        expect(tester.takeException(), isNull);
        // Already valid → no spurious onChanged callback.
        expect(changed, isNull);
      },
    );
  });
}
