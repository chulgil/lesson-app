import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/subscription/data/repositories/mock_makeup_credit_repository.dart';
import 'package:lessonaza/features/subscription/domain/entities/makeup_credit.dart';
import 'package:lessonaza/features/subscription/presentation/providers/makeup_credit_providers.dart';
import 'package:lessonaza/features/subscription/presentation/screens/makeup_credit_screen.dart';
import 'package:lessonaza/features/subscription/presentation/widgets/makeup_credit_card.dart';
import 'package:lessonaza/features/subscription/presentation/widgets/makeup_credit_use_selector.dart';
import 'package:lessonaza/features/subscription/presentation/widgets/teacher_makeup_credit_section.dart';

Widget _scoped(Widget child) {
  return ProviderScope(
    overrides: [
      makeupCreditRepositoryProvider.overrideWithValue(
        MockMakeupCreditRepository(),
      ),
    ],
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  group('MakeupCreditCard (student)', () {
    testWidgets('renders balance + history without exception', (tester) async {
      await tester.pumpWidget(_scoped(const MakeupCreditCard()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.makeupCreditTitle), findsOneWidget);
    });
  });

  group('TeacherMakeupCreditSection', () {
    testWidgets('renders grant button + list without exception', (
      tester,
    ) async {
      await tester.pumpWidget(
        _scoped(const TeacherMakeupCreditSection(studentId: 'mock-student-1')),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.makeupCreditManageTitle), findsOneWidget);
      expect(find.text(AppStrings.makeupCreditGrantButton), findsOneWidget);
    });
  });

  group('MakeupCreditScreen', () {
    testWidgets('student view (no studentId) renders card', (tester) async {
      await tester.pumpWidget(_scoped(const MakeupCreditScreen()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('teacher view (studentId) renders management', (tester) async {
      await tester.pumpWidget(
        _scoped(const MakeupCreditScreen(studentId: 'mock-student-1')),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // Title appears in both the app bar and the section header.
      expect(find.text(AppStrings.makeupCreditManageTitle), findsWidgets);
    });
  });

  group('MakeupCreditUseSelector', () {
    testWidgets('hides credit option when balance empty', (tester) async {
      var selected = BookingPaymentSource.regularSubscription;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MakeupCreditUseSelector(
              balance: const MakeupCreditBalance(),
              regularRemaining: 5,
              regularTotal: 8,
              selected: selected,
              onChanged: (v) => selected = v,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.makeupCreditUseRegularLabel), findsOneWidget);
      expect(find.text(AppStrings.makeupCreditUseCreditLabel), findsNothing);
    });

    testWidgets('shows credit option + switches selection when balance > 0', (
      tester,
    ) async {
      final balance = MakeupCreditBalance(
        available: [
          MakeupCredit(
            id: 'c1',
            studentId: 's1',
            teacherId: 't1',
            reason: MakeupCreditReason.teacherVacation,
            createdAt: DateTime(2026, 8, 1),
            expiresAt: DateTime(2026, 9, 2),
          ),
        ],
      );
      BookingPaymentSource selected = BookingPaymentSource.regularSubscription;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => MaterialApp(
            home: Scaffold(
              body: MakeupCreditUseSelector(
                balance: balance,
                regularRemaining: 5,
                regularTotal: 8,
                selected: selected,
                onChanged: (v) => setState(() => selected = v),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.makeupCreditUseCreditLabel), findsOneWidget);
      await tester.tap(find.text(AppStrings.makeupCreditUseCreditLabel));
      await tester.pumpAndSettle();
      expect(selected, BookingPaymentSource.makeupCredit);
    });
  });
}
