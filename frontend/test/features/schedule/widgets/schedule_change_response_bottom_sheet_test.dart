import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/schedule/domain/entities/request_event.dart';
import 'package:lessonaza/features/schedule/domain/entities/unified_lesson_request.dart';
import 'package:lessonaza/features/schedule/presentation/widgets/schedule_change_response_bottom_sheet.dart';

void main() {
  group('showScheduleChangeResponseBottomSheet reject confirmation', () {
    testWidgets(
      'reject shows a confirm dialog and only resolves after confirming',
      (tester) async {
        ScheduleChangeResponseResult? result;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () async {
                      result = await showScheduleChangeResponseBottomSheet(
                        context,
                        proposedSlots: [
                          TimeSlotOption(
                            id: 'slot_1',
                            dayOfWeek: 0,
                            startTime: '16:00',
                            endTime: '17:00',
                          ),
                        ],
                        changeType: ScheduleChangeType.singleLesson,
                        durationMinutes: 60,
                      );
                    },
                    child: const Text('open'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('거절'));
        await tester.pumpAndSettle();

        // Confirm dialog blocks the sheet from resolving until confirmed.
        expect(find.text('제안 거절'), findsOneWidget);
        expect(result, isNull);

        // Cancel keeps the sheet open with no result.
        await tester.tap(find.text('취소'));
        await tester.pumpAndSettle();
        expect(result, isNull);

        // Re-open and confirm this time — the dialog's confirm action is a
        // TextButton, distinct from the sheet's OutlinedButton reject CTA.
        await tester.tap(find.text('거절'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(TextButton, '거절'));
        await tester.pumpAndSettle();

        expect(result, isNotNull);
        expect(result!.action, ScheduleChangeResponseAction.reject);
      },
    );
  });
}
