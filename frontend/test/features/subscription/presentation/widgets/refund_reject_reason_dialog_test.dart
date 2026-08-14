import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/subscription/presentation/widgets/refund_reject_reason_dialog.dart';

void main() {
  testWidgets('confirm disabled until a reason is entered, then returns it', (
    tester,
  ) async {
    String? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder:
                (context) => ElevatedButton(
                  onPressed: () async {
                    result = await showDialog<String>(
                      context: context,
                      builder: (_) => const RefundRejectReasonDialog(),
                    );
                  },
                  child: const Text('open'),
                ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final confirmButton = tester.widget<TextButton>(
      find
          .ancestor(
            of: find.text(AppStrings.refundActionBoxReject),
            matching: find.byType(TextButton),
          )
          .first,
    );
    expect(confirmButton.onPressed, isNull, reason: '사유 없이는 반려 확정 불가');

    await tester.enterText(find.byType(TextField), '반려 사유입니다');
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.refundActionBoxReject));
    await tester.pumpAndSettle();

    expect(result, '반려 사유입니다');
  });
}
