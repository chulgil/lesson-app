import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/practice/presentation/widgets/manual_practice_entry_sheet.dart';

void main() {
  group('ManualPracticeEntrySheet', () {
    testWidgets('renders form fields without layout errors', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: ManualPracticeEntrySheet(studentId: 's1')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.manualPracticeTitle), findsOneWidget);
      expect(find.text(AppStrings.save), findsOneWidget);
    });

    testWidgets('shows validation error and stays open when minutes empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: ManualPracticeEntrySheet(studentId: 's1')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.save));
      await tester.pump();

      // Validation blocks save before the logger provider is read,
      // so no provider override is needed here.
      expect(
        find.text(AppStrings.manualPracticeInvalidMinutes),
        findsOneWidget,
      );
      expect(find.text(AppStrings.manualPracticeTitle), findsOneWidget);
    });
  });
}
