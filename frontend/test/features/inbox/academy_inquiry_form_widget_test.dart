import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/inbox/presentation/widgets/academy_inquiry_form_widget.dart';

void main() {
  group('AcademyInquiryFormWidget', () {
    testWidgets('renders without crashing', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AcademyInquiryFormWidget(academyId: 'acad_001')),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.inquiryTabAsk), findsOneWidget);
    });

    testWidgets('displays all form fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AcademyInquiryFormWidget(academyId: 'acad_001')),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text(AppStrings.inquiryFormNameLabel), findsOneWidget);
      expect(find.text(AppStrings.inquiryFormPhoneLabel), findsOneWidget);
      expect(find.text(AppStrings.inquiryFormMessageLabel), findsOneWidget);
    });

    testWidgets('validates form fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AcademyInquiryFormWidget(academyId: 'acad_001')),
        ),
      );

      await tester.pumpAndSettle();

      // Tap submit without filling form
      final submitButton = find.byType(FilledButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Should show validation errors
      expect(find.text('이름을 입력해주세요'), findsOneWidget);
    });
  });
}
