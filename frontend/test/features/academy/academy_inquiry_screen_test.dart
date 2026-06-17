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

    // UX #791: status label "대기중" → "미답변", SLA text, 320px narrow layout.
    testWidgets('renders at 320px width without overflow', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(320, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: AcademyInquiryScreen(academyId: 'acad_001')),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows unanswered status label not 대기중', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: AcademyInquiryScreen(academyId: 'acad_001')),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // "대기중" must not appear; "미답변" replaces it.
      expect(find.text('대기중'), findsNothing);
      expect(find.text(AppStrings.inquiryStatusUnanswered), findsWidgets);
    });

    testWidgets('shows SLA hint text on unanswered inquiries', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: AcademyInquiryScreen(academyId: 'acad_001')),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.inquiryReplySla), findsWidgets);
    });

    testWidgets('forum icon is present in appbar', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: AcademyInquiryScreen(academyId: 'acad_001')),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.forum_outlined), findsOneWidget);
    });
  });
}
