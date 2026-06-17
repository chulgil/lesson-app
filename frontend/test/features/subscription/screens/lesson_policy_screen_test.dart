// Widget smoke test for LessonPolicyScreen — #789 noshow student preview
// Covers: render without crash (320px narrow), preview text toggling.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/subscription/domain/entities/lesson_policy.dart';
import 'package:lessonaza/features/subscription/domain/repositories/lesson_policy_repository.dart';
import 'package:lessonaza/features/subscription/presentation/providers/lesson_policy_providers.dart';
import 'package:lessonaza/features/subscription/presentation/screens/lesson_policy_screen.dart';

/// Fake repository that returns a pre-built policy.
class _FakeLessonPolicyRepository implements LessonPolicyRepository {
  final LessonPolicy? policy;
  _FakeLessonPolicyRepository({this.policy});

  @override
  Future<LessonPolicy?> getTeacherPolicy(String teacherId) async => policy;

  @override
  Future<LessonPolicy?> getClassPolicy(String lessonClassId) async => policy;

  @override
  Future<LessonPolicy?> getEffectivePolicy({
    required String teacherId,
    String? lessonClassId,
  }) async => policy;

  @override
  Future<LessonPolicy> savePolicy(LessonPolicy policy) async => policy;

  @override
  Future<void> deletePolicy(String policyId) async {}
}

Widget _pumpScreen({double width = 375, LessonPolicy? policy}) {
  return ProviderScope(
    overrides: [
      lessonPolicyRepositoryProvider.overrideWithValue(
        _FakeLessonPolicyRepository(policy: policy),
      ),
    ],
    child: MaterialApp(
      home: SizedBox(
        width: width,
        child: LessonPolicyScreen(teacherId: 'teacher-1'),
      ),
    ),
  );
}

LessonPolicy _makePolicy({bool deductOnNoShow = true}) => LessonPolicy(
  id: 'policy-1',
  teacherId: 'teacher-1',
  minCancelHours: 4,
  maxChangesPerMonth: 2,
  allowSameDayCancel: false,
  deductLessonOnNoShow: deductOnNoShow,
  gracePeriodMinutes: 15,
  allowCarryover: true,
  maxCarryoverLessons: 1,
  carryoverPeriodMonths: 1,
  createdAt: DateTime(2026, 1, 1),
);

void main() {
  group('LessonPolicyScreen — noshow student preview', () {
    testWidgets('renders without crash at 375px (default deduct=true)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _pumpScreen(policy: _makePolicy(deductOnNoShow: true)),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows deduct preview when deductLessonOnNoShow=true', (
      tester,
    ) async {
      await tester.pumpWidget(
        _pumpScreen(policy: _makePolicy(deductOnNoShow: true)),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.noShowStudentPreviewDeduct), findsOneWidget);
      expect(find.text(AppStrings.noShowStudentPreviewNoDeduct), findsNothing);
    });

    testWidgets('shows no-deduct preview when deductLessonOnNoShow=false', (
      tester,
    ) async {
      await tester.pumpWidget(
        _pumpScreen(policy: _makePolicy(deductOnNoShow: false)),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(AppStrings.noShowStudentPreviewNoDeduct),
        findsOneWidget,
      );
      expect(find.text(AppStrings.noShowStudentPreviewDeduct), findsNothing);
    });

    testWidgets('renders without crash at 320px narrow viewport', (
      tester,
    ) async {
      await tester.pumpWidget(
        _pumpScreen(width: 320, policy: _makePolicy(deductOnNoShow: true)),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
