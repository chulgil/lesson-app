// Widget smoke + form contract test for GroupClassFormScreen (J9a, P1-1).
//
// Contract (ux-rules.md HARD-GATE):
//   pumpWidget(MaterialApp(...)) + pumpAndSettle() + takeException() isNull,
//   plus the two behaviours the spec pins down:
//     - D1: one form, drop-in is a switch inside it (no pre-flow branch)
//     - a regular class cannot be saved without repeat days
//
// The screen is pushed onto a host route so its post-save Navigator.pop() runs
// against a real route stack, the way it will in the app.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/schedule/data/repositories/mock_group_class_repository.dart';
import 'package:lessonaza/features/schedule/domain/entities/group_class.dart';
import 'package:lessonaza/features/schedule/presentation/providers/group_class_providers.dart';
import 'package:lessonaza/features/schedule/presentation/screens/group_class_form_screen.dart';
import 'package:lessonaza/features/schedule/presentation/widgets/group_class_form_fields.dart';

const _kTeacherId = 'teacher_1';
const _kOpenLabel = 'open-form';

Widget _host(MockGroupClassRepository repository, {GroupClass? existing}) {
  return ProviderScope(
    overrides: [groupClassRepositoryProvider.overrideWithValue(repository)],
    child: MaterialApp(
      theme: AppTheme.light,
      home: Builder(
        builder:
            (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed:
                      () => Navigator.of(context).push(
                        MaterialPageRoute<GroupClass>(
                          builder:
                              (_) => GroupClassFormScreen(
                                teacherId: _kTeacherId,
                                groupClass: existing,
                              ),
                        ),
                      ),
                  child: const Text(_kOpenLabel),
                ),
              ),
            ),
      ),
    ),
  );
}

/// Tall viewport so the long form scrolls instead of overflowing under test.
void _useTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(375, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Future<void> _openForm(WidgetTester tester) async {
  await tester.tap(find.text(_kOpenLabel));
  await tester.pumpAndSettle();
}

Finder get _submitButton =>
    find.widgetWithText(FilledButton, AppStrings.groupClassFormCreateTitle);

Future<void> _tapSubmit(WidgetTester tester) async {
  await tester.ensureVisible(_submitButton);
  await tester.pumpAndSettle();
  await tester.tap(_submitButton);
  await tester.pumpAndSettle();
}

final _existingClass = GroupClass(
  id: 'group_class_edit',
  teacherId: _kTeacherId,
  name: '금요일 챔버반',
  type: GroupClassType.regular,
  maxCapacity: 4,
  durationMinutes: 60,
  repeatDaysOfWeek: const [5],
  repeatTimeOfDay: '17:00',
  createdAt: DateTime(2026, 7, 1),
);

void main() {
  group('GroupClassFormScreen', () {
    testWidgets('renders the create form without exceptions', (tester) async {
      _useTallViewport(tester);

      await tester.pumpWidget(_host(MockGroupClassRepository(seed: false)));
      await _openForm(tester);

      expect(find.text(AppStrings.groupClassFormCreateTitle), findsWidgets);
      // D1: cohort fields are visible up front and drop-in is a switch on the
      // same form — the teacher is never asked to pick a type first.
      expect(
        find.text(AppStrings.groupClassFormRepeatDaysLabel),
        findsOneWidget,
      );
      expect(
        find.text(AppStrings.groupClassFormDropInToggleTitle),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('blocks save when the name is empty', (tester) async {
      _useTallViewport(tester);

      final repository = MockGroupClassRepository(seed: false);
      await tester.pumpWidget(_host(repository));
      await _openForm(tester);

      await _tapSubmit(tester);

      expect(find.text(AppStrings.groupClassFormNameRequired), findsOneWidget);
      expect(
        repository.storedClasses,
        isEmpty,
        reason: 'A failed validation must not reach the repository.',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('blocks save when a regular class has no repeat day', (
      tester,
    ) async {
      _useTallViewport(tester);

      final repository = MockGroupClassRepository(seed: false);
      await tester.pumpWidget(_host(repository));
      await _openForm(tester);

      await tester.enterText(find.byType(TextFormField).first, '앙상블반');
      await _tapSubmit(tester);

      expect(
        find.text(AppStrings.groupClassFormRepeatDaysRequired),
        findsOneWidget,
      );
      expect(repository.storedClasses, isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('saves a regular class with the picked repeat days', (
      tester,
    ) async {
      _useTallViewport(tester);

      final repository = MockGroupClassRepository(seed: false);
      await tester.pumpWidget(_host(repository));
      await _openForm(tester);

      await tester.enterText(find.byType(TextFormField).first, '목요일 앙상블반');
      await tester.tap(find.widgetWithText(ChoiceChip, '목'));
      await tester.pumpAndSettle();
      await _tapSubmit(tester);

      final saved = repository.storedClasses;
      expect(saved, hasLength(1));
      expect(saved.single.name, '목요일 앙상블반');
      expect(saved.single.type, GroupClassType.regular);
      // 1=Mon … 7=Sun wire contract — 목 is 4.
      expect(saved.single.repeatDaysOfWeek, [4]);
      expect(saved.single.repeatTimeOfDay, isNotNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('drop-in switch saves a drop-in class with one session', (
      tester,
    ) async {
      _useTallViewport(tester);

      final repository = MockGroupClassRepository(seed: false);
      await tester.pumpWidget(_host(repository));
      await _openForm(tester);

      await tester.enterText(find.byType(TextFormField).first, '원데이 보잉 특강');
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();

      // Repeat days give way to a single date once drop-in is on.
      expect(find.text(AppStrings.groupClassFormRepeatDaysLabel), findsNothing);
      expect(
        find.text(AppStrings.groupClassFormDropInDateLabel),
        findsOneWidget,
      );

      await _tapSubmit(tester);

      final saved = repository.storedClasses;
      expect(saved, hasLength(1));
      expect(saved.single.type, GroupClassType.dropIn);
      expect(saved.single.repeatDaysOfWeek, isNull);
      // Without this session the drop-in class would have nothing to book.
      expect(repository.schedulesFor(saved.single.id), hasLength(1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('edit mode seeds the form from the existing class', (
      tester,
    ) async {
      _useTallViewport(tester);

      final repository = MockGroupClassRepository(seed: false);

      await tester.pumpWidget(_host(repository, existing: _existingClass));
      await _openForm(tester);

      expect(find.text(AppStrings.groupClassFormEditTitle), findsOneWidget);
      expect(find.text('금요일 챔버반'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('no-show policy chips do not offer retired halfCredit', (
      tester,
    ) async {
      // halfCredit retired 2026-08-18 (Obsidian 54) — selectable set is the
      // market-aligned trio: deduct / deduct+makeup / no deduction.
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: GroupClassNoShowPolicyChips(
              selectedPolicy: NoShowPolicy.deductCredit,
              onChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.noShowPolicyDeductCredit), findsOneWidget);
      expect(find.text(AppStrings.noShowPolicyNoDeduction), findsOneWidget);
      expect(find.text(AppStrings.noShowPolicyReschedule), findsOneWidget);
      expect(find.text(AppStrings.noShowPolicyHalfCredit), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
