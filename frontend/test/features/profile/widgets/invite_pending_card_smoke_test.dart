import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/profile/presentation/providers/invite_pending_provider.dart';
import 'package:lessonaza/features/profile/presentation/widgets/invite_pending_card.dart';

void main() {
  group('InvitePendingCard smoke — #5 D-G3 Phase 2', () {
    testWidgets('renders nothing when count is 0', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [pendingInviteCountProvider.overrideWith((_) async => 0)],
          child: const MaterialApp(home: Scaffold(body: InvitePendingCard())),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('초대 대기'), findsNothing);
    });

    testWidgets('renders title and count when count > 0', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [pendingInviteCountProvider.overrideWith((_) async => 4)],
          child: const MaterialApp(home: Scaffold(body: InvitePendingCard())),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('초대 대기'), findsOneWidget);
      expect(find.text('4건'), findsOneWidget);
    });

    testWidgets('renders nothing on error', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pendingInviteCountProvider.overrideWith(
              (_) async => throw Exception('boom'),
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: InvitePendingCard())),
        ),
      );
      await tester.pumpAndSettle();
      tester.takeException();
      expect(find.text('초대 대기'), findsNothing);
    });
  });
}
