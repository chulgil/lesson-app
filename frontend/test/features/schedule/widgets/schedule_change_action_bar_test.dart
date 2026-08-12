import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/schedule/presentation/widgets/schedule_change_action_bar.dart';
import 'package:lessonaza/features/schedule/presentation/widgets/schedule_slot_choice_list.dart';

/// M-3 (schedule_change_unification_spec §4) — the negotiation surface
/// shared by CurrentRequestBox (계열 A) and SubscriptionBottomInputBar
/// (계열 B). Covers both action-bar states in isolation, independent of
/// either host screen.
void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  group('ScheduleChangeWaitingBar', () {
    testWidgets('shows the opponent waiting message and fires withdraw', (
      tester,
    ) async {
      var withdrawTapped = false;

      await tester.pumpWidget(
        wrap(
          ScheduleChangeWaitingBar(
            opponentName: '이서현',
            onWithdraw: () => withdrawTapped = true,
          ),
        ),
      );

      expect(find.text('이서현님의 응답을 기다리고 있습니다'), findsOneWidget);
      expect(find.text(AppStrings.withdrawApproval), findsOneWidget);

      await tester.tap(find.text(AppStrings.withdrawApproval));
      await tester.pump();

      expect(withdrawTapped, isTrue);
    });

    testWidgets('withdraw button is disabled when onWithdraw is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const ScheduleChangeWaitingBar(opponentName: '이서현', onWithdraw: null),
        ),
      );

      final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
      expect(button.onPressed, isNull);
    });
  });

  group('ScheduleChangeResponseBar — no reject (계열 A 2-button layout)', () {
    testWidgets(
      'renders slot choices, disables accept until a slot is chosen, and '
      'fires onAccept with the trimmed message',
      (tester) async {
        int? acceptedIndex;
        String? acceptedMessage;

        await tester.pumpWidget(
          wrap(
            ScheduleChangeResponseBar(
              choices: const [
                ScheduleSlotChoice(priority: 1, label: '월 16:00~17:00'),
                ScheduleSlotChoice(priority: 2, label: '화 10:00~11:00'),
              ],
              messageHint: AppStrings.messageHint,
              onAccept: (index, message) {
                acceptedIndex = index;
                acceptedMessage = message;
              },
              onCounterPropose: () {},
            ),
          ),
        );

        expect(find.text(AppStrings.scheduleChangeCounter), findsOneWidget);
        expect(find.text(AppStrings.scheduleChangeAccept), findsOneWidget);
        expect(find.text(AppStrings.scheduleChangeReject), findsNothing);

        final acceptButtonBefore = tester.widget<ElevatedButton>(
          find.byType(ElevatedButton),
        );
        expect(acceptButtonBefore.onPressed, isNull);

        await tester.tap(find.text('화 10:00~11:00'));
        await tester.pump();
        await tester.enterText(find.byType(TextField), '  이 시간이 좋아요  ');
        await tester.tap(find.text(AppStrings.scheduleChangeAccept));
        await tester.pump();

        expect(acceptedIndex, 1);
        expect(acceptedMessage, '이 시간이 좋아요');
      },
    );

    testWidgets('counter-propose button fires onCounterPropose', (
      tester,
    ) async {
      var counterTapped = false;

      await tester.pumpWidget(
        wrap(
          ScheduleChangeResponseBar(
            choices: const [
              ScheduleSlotChoice(priority: 1, label: '월 16:00~17:00'),
            ],
            messageHint: AppStrings.messageHint,
            onAccept: (_, __) {},
            onCounterPropose: () => counterTapped = true,
          ),
        ),
      );

      await tester.tap(find.text(AppStrings.scheduleChangeCounter));
      await tester.pump();

      expect(counterTapped, isTrue);
    });
  });

  group(
    'ScheduleChangeResponseBar — with reject (계열 B 3-button layout, N8)',
    () {
      testWidgets('renders reject + counter + accept and fires each', (
        tester,
      ) async {
        var rejectMessage = '';
        var counterTapped = false;
        int? acceptedIndex;

        await tester.pumpWidget(
          wrap(
            ScheduleChangeResponseBar(
              choices: const [
                ScheduleSlotChoice(priority: 1, label: '월 16:00~17:00'),
              ],
              messageHint: AppStrings.subscriptionMessageHint,
              messageMinLines: 1,
              messageMaxLines: 3,
              onAccept: (index, _) => acceptedIndex = index,
              onReject: (message) => rejectMessage = message,
              onCounterPropose: () => counterTapped = true,
            ),
          ),
        );

        expect(find.text(AppStrings.scheduleChangeReject), findsOneWidget);
        expect(find.text(AppStrings.scheduleChangeCounter), findsOneWidget);
        expect(find.text(AppStrings.scheduleChangeAccept), findsOneWidget);

        await tester.enterText(find.byType(TextField), '이번 주는 어렵습니다');
        await tester.tap(find.text(AppStrings.scheduleChangeReject));
        await tester.pump();
        expect(rejectMessage, '이번 주는 어렵습니다');

        await tester.tap(find.text(AppStrings.scheduleChangeCounter));
        await tester.pump();
        expect(counterTapped, isTrue);

        await tester.tap(find.text('1순위'));
        await tester.pump();
        await tester.tap(find.text(AppStrings.scheduleChangeAccept));
        await tester.pump();
        expect(acceptedIndex, 0);
      });
    },
  );
}
