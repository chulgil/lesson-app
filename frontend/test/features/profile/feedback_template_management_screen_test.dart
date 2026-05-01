import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/profile/presentation/screens/feedback_template_management_screen.dart';

/// Widget smoke test (HARD-GATE) for FeedbackTemplateManagementScreen.
///
/// Asserts the screen renders without RenderBox/RenderMetaData/BoxConstraints
/// runtime crashes that `flutter analyze` cannot detect.
void main() {
  testWidgets('FeedbackTemplateManagementScreen renders without crash', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: const FeedbackTemplateManagementScreen(),
        ),
      ),
    );

    // Initial frame: AppBar + TabBar + loading indicator
    expect(find.text('피드백 템플릿'), findsOneWidget);
    expect(find.text('전체'), findsOneWidget);

    // Allow seed templates to load (Mock has 200ms delay).
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
  });

  testWidgets('FeedbackTemplateManagementScreen seed templates render', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: const FeedbackTemplateManagementScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle(const Duration(seconds: 1));

    // At least one seed template title should appear (e.g., '음정 주의').
    expect(find.text('음정 주의'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
