import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/subscription/presentation/widgets/payment_pending_progress_bar.dart';

void main() {
  group('PaymentPendingProgressBar', () {
    testWidgets('smoke — renders without exception', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: PaymentPendingProgressBar())),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows all three step labels', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: PaymentPendingProgressBar())),
      );
      await tester.pumpAndSettle();
      expect(find.text('입금 알림'), findsOneWidget);
      expect(find.text('확인 대기'), findsOneWidget);
      expect(find.text('수강권 발급'), findsOneWidget);
    });

    testWidgets('renders correctly at narrow viewport (320px)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: PaymentPendingProgressBar())),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
