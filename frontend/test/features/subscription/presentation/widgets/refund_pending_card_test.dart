import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/auth/auth_facade.dart'
    show currentUserIdProvider;
import 'package:lessonaza/features/subscription/presentation/providers/refund_request_providers.dart';
import 'package:lessonaza/features/subscription/presentation/widgets/refund_pending_card.dart';

const _teacherId = 'teacher_1';

void main() {
  group('RefundPendingCard smoke — #1271', () {
    testWidgets('renders nothing when count is 0', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWith((ref) => _teacherId),
            teacherPendingRefundRequestCountProvider(
              _teacherId,
            ).overrideWith((ref) async => 0),
          ],
          child: const MaterialApp(home: Scaffold(body: RefundPendingCard())),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('환불 대기'), findsNothing);
    });

    testWidgets('renders title and count when count > 0', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWith((ref) => _teacherId),
            teacherPendingRefundRequestCountProvider(
              _teacherId,
            ).overrideWith((ref) async => 2),
          ],
          child: const MaterialApp(home: Scaffold(body: RefundPendingCard())),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('환불 대기'), findsOneWidget);
      expect(find.text('2건'), findsOneWidget);
    });

    testWidgets('renders nothing on error', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWith((ref) => _teacherId),
            teacherPendingRefundRequestCountProvider(_teacherId).overrideWith((
              ref,
            ) async {
              throw Exception('boom');
            }),
          ],
          child: const MaterialApp(home: Scaffold(body: RefundPendingCard())),
        ),
      );
      await tester.pumpAndSettle();
      tester.takeException();
      expect(find.text('환불 대기'), findsNothing);
    });
  });
}
