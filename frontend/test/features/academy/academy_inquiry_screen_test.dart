import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/inbox/presentation/screens/academy_inquiry_screen.dart';

void main() {
  group('AcademyInquiryScreen', () {
    testWidgets('renders without crashing', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: AcademyInquiryScreen(academyId: 'acad_001')),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.inquiryTitle), findsOneWidget);
    });

    testWidgets('displays inquiry list', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: AcademyInquiryScreen(academyId: 'acad_001')),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('김철수'), findsOneWidget);
    });
  });
}
