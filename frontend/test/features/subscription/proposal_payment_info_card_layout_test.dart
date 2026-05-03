import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/profile/domain/entities/teacher_profile.dart';
import 'package:lessonaza/features/subscription/presentation/widgets/proposal_card_widgets.dart';

void main() {
  testWidgets('proposal payment info card lays out with long account text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: ProposalPaymentInfoCard(
              bankAccount: BankAccount(
                id: 'account-1',
                bankName: '카카오뱅크 장기표기 테스트 은행명',
                accountNumber: '3333-1234-567890-123456789',
                accountHolder: '홍길동선생님',
                createdAt: DateTime.utc(2026, 5, 4),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('3333-1234-567890-123456789'), findsOneWidget);
  });
}
