// TDD widget test for ParentPaymentsTab._showChildSelector — Bug #726 fix.
//
// Problem: the BottomSheet builder calls ref.read(childProfilesProvider(parentId)).
// ref.read is evaluated once at sheet-open time. If the provider is still loading,
// the AsyncValue is AsyncLoading and the sheet renders empty (SizedBox.shrink()),
// and never rebuilds when data arrives.
//
// Fix: wrap the sheet body in a Consumer + ref.watch so it rebuilds on state change.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/auth/auth_facade.dart';
import 'package:lessonaza/features/parent_home/domain/entities/child_profile.dart';
import 'package:lessonaza/features/parent_home/presentation/providers/child_profile_provider.dart';
import 'package:lessonaza/features/parent_home/presentation/screens/parent_payments_tab.dart';
import 'package:lessonaza/features/students/students_facade.dart';
import 'package:lessonaza/features/subscription/subscription_facade.dart';

ChildProfile _child() => ChildProfile(
  id: 'child-1',
  parentId: 'parent-1',
  name: '지우',
  birthYear: 2015,
  instrument: 'violin',
  level: 'beginner',
  teacherId: 'teacher-1',
  teacherName: '김선생님',
  linkedStudentId: 'student-1',
  profileColorKey: 'blue',
  createdAt: DateTime(2026),
);

class _FakeSelectedChild extends SelectedChildProfile {
  @override
  ChildProfile? build() => null;
}

void main() {
  group('ParentPaymentsTab child selector sheet — Bug #726 ref.watch', () {
    testWidgets('sheet 가 열린 후 provider 데이터 도착 시 자녀 이름이 표시된다', (tester) async {
      // Completer controls when the async provider resolves.
      final completer = Completer<List<ChildProfile>>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue('parent-1'),
            // Slow async — won't complete until we call completer.complete.
            childProfilesProvider(
              'parent-1',
            ).overrideWith((_) => completer.future),
            selectedChildProfileProvider.overrideWith(
              () => _FakeSelectedChild(),
            ),
            // Stub out unrelated providers to avoid repository calls.
            studentSubscriptionsProvider(
              'student-1',
            ).overrideWith((_) async => const []),
            activeStudentMembershipsProvider(
              'student-1',
            ).overrideWith((_) async => const []),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const Scaffold(body: ParentPaymentsTab()),
          ),
        ),
      );

      // Initial render — tab body is loading.
      await tester.pump();

      // Open child-selector sheet.
      await tester.tap(find.byIcon(Icons.swap_horiz));
      await tester.pump();

      // Before data: child name not yet visible.
      expect(find.text('지우'), findsNothing);

      // Data arrives.
      completer.complete([_child()]);
      await tester.pump(); // provider notifies listeners

      // GREEN: ref.watch makes the Consumer rebuild → child name visible.
      // RED:   ref.read never rebuilds → '지우' still not found.
      expect(
        find.text('지우'),
        findsOneWidget,
        reason: 'Consumer + ref.watch 로 sheet 가 rebuild 되어 자녀 이름이 보여야 함',
      );
    });
  });
}
