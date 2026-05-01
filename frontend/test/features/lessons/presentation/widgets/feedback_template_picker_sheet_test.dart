import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/lessons/presentation/widgets/feedback_template_picker_sheet.dart';

/// Widget smoke test (HARD-GATE) for FeedbackTemplatePickerSheet.
///
/// Asserts the sheet renders without RenderBox/BoxConstraints runtime
/// crashes that `flutter analyze` cannot detect.
void main() {
  testWidgets('FeedbackTemplatePickerSheet renders without crash', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder:
                (context) => Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      onPressed:
                          () => FeedbackTemplatePickerSheet.show(context),
                      child: const Text('open'),
                    ),
                  ),
                ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Sheet header must render
    expect(find.text('피드백 템플릿 선택'), findsOneWidget);
    // Category chip line
    expect(find.text('전체'), findsOneWidget);
    // Seed template should appear
    expect(find.text('음정 주의'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
