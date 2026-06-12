import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/practice/presentation/widgets/manual_practice_entry_dialog.dart';

Future<void> _pump(
  WidgetTester tester,
  Future<void> Function(int, String?) onConfirm,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder:
              (context) => Center(
                child: FilledButton(
                  onPressed:
                      () => showDialog<void>(
                        context: context,
                        builder:
                            (_) =>
                                ManualPracticeEntryDialog(onConfirm: onConfirm),
                      ),
                  child: const Text('open'),
                ),
              ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders 4 preset chips (5/15/30/직접입력)', (tester) async {
    await _pump(tester, (_, __) async {});
    expect(find.byKey(const ValueKey('preset_5')), findsOneWidget);
    expect(find.byKey(const ValueKey('preset_15')), findsOneWidget);
    expect(find.byKey(const ValueKey('preset_30')), findsOneWidget);
    expect(find.byKey(const ValueKey('preset_custom')), findsOneWidget);
  });

  testWidgets('confirm button disabled until a preset is selected', (
    tester,
  ) async {
    await _pump(tester, (_, __) async {});
    final btn = tester.widget<FilledButton>(
      find.byKey(const ValueKey('confirm_button')),
    );
    expect(btn.onPressed, isNull);
  });

  testWidgets('selecting 15분 enables confirm, fires onConfirm with 15', (
    tester,
  ) async {
    int? captured;
    await _pump(tester, (m, _) async {
      captured = m;
    });
    await tester.tap(find.byKey(const ValueKey('preset_15')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('confirm_button')));
    await tester.pump();
    expect(captured, 15);
  });

  testWidgets('직접입력 mode shows custom input + valid number enables confirm', (
    tester,
  ) async {
    int? captured;
    await _pump(tester, (m, _) async {
      captured = m;
    });
    await tester.tap(find.byKey(const ValueKey('preset_custom')));
    await tester.pump();
    expect(find.byKey(const ValueKey('custom_minutes_input')), findsOneWidget);
    // Empty input → confirm disabled
    final btnBefore = tester.widget<FilledButton>(
      find.byKey(const ValueKey('confirm_button')),
    );
    expect(btnBefore.onPressed, isNull);
    await tester.enterText(
      find.byKey(const ValueKey('custom_minutes_input')),
      '45',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('confirm_button')));
    await tester.pump();
    expect(captured, 45);
  });

  testWidgets('note input passed to onConfirm (optional, empty → null)', (
    tester,
  ) async {
    String? capturedNote;
    await _pump(tester, (m, n) async {
      capturedNote = n;
    });
    await tester.tap(find.byKey(const ValueKey('preset_5')));
    await tester.enterText(find.byKey(const ValueKey('note_input')), '왈츠 1악장');
    await tester.tap(find.byKey(const ValueKey('confirm_button')));
    await tester.pump();
    expect(capturedNote, '왈츠 1악장');
  });
}
