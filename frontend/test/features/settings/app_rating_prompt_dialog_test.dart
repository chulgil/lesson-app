import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/settings/presentation/widgets/app_rating_prompt_dialog.dart';

void main() {
  testWidgets('AppRatingPromptDialog renders without exception', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppRatingPromptDialog(
            onSatisfied: () {},
            onDissatisfied: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('AppRatingPromptDialog shows title and buttons', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppRatingPromptDialog(
            onSatisfied: () {},
            onDissatisfied: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('레슨앱이 도움이 되고 있나요?'), findsOneWidget);
    expect(find.text('네, 도움돼요!'), findsOneWidget);
    expect(find.text('아니요, 별로예요'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('AppRatingFeedbackDialog renders without exception',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppRatingFeedbackDialog(
            onFeedback: () {},
            onLater: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('AppRatingFeedbackDialog shows title and buttons', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppRatingFeedbackDialog(
            onFeedback: () {},
            onLater: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('어떤 점을 개선하면 좋을까요?'), findsOneWidget);
    expect(find.text('피드백 보내기'), findsOneWidget);
    expect(find.text('나중에'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
