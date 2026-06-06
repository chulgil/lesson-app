import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/parent_home/domain/entities/child_profile.dart';
import 'package:lessonaza/features/parent_home/presentation/providers/child_profile_provider.dart';
import 'package:lessonaza/features/parent_home/presentation/screens/parent_assignments_tab.dart';
import 'package:lessonaza/features/practice/domain/entities/practice_item.dart';
import 'package:lessonaza/features/practice/presentation/providers/practice_item_providers.dart';

ChildProfile _linkedProfile({String? linkedStudentId = 'student-1'}) {
  final now = DateTime.now();
  return ChildProfile(
    id: 'child-1',
    parentId: 'parent-1',
    name: '지우',
    birthYear: 2015,
    instrument: 'violin',
    level: 'beginner',
    teacherId: 'teacher-1',
    teacherName: '김선생님',
    linkedStudentId: linkedStudentId,
    profileColorKey: 'blue',
    createdAt: now,
  );
}

PracticeItem _item({
  required String id,
  required bool isCompleted,
  PracticePriority priority = PracticePriority.must,
}) {
  final now = DateTime.now();
  return PracticeItem(
    id: id,
    lessonId: 'lesson-1',
    studentId: 'student-1',
    teacherId: 'teacher-1',
    type: PracticeType.technique,
    title: '연습 $id',
    description: '설명 $id',
    priority: priority,
    resourceIds: const [],
    isCompleted: isCompleted,
    createdAt: now,
  );
}

void main() {
  group('ParentAssignmentsTab — 실데이터 연결 (#585)', () {
    testWidgets('미연결(linkedStudentId==null)이면 미연결 상태를 렌더한다', (tester) async {
      await tester.binding.setSurfaceSize(const Size(440, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedChildProfileProvider.overrideWith(
              () => _FakeSelectedChildProfile(
                _linkedProfile(linkedStudentId: null),
              ),
            ),
          ],
          child: const MaterialApp(home: ParentAssignmentsTab()),
        ),
      );
      await tester.pump();

      expect(find.text(AppStrings.parentHomeNotLinked), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('연결된 자녀의 실제 과제 항목과 완료율을 렌더한다', (tester) async {
      await tester.binding.setSurfaceSize(const Size(440, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedChildProfileProvider.overrideWith(
              () => _FakeSelectedChildProfile(_linkedProfile()),
            ),
            weeklyPracticeItemsProvider('student-1').overrideWith(
              (_) async => [
                _item(id: 'a', isCompleted: true),
                _item(id: 'b', isCompleted: false),
                _item(
                  id: 'c',
                  isCompleted: false,
                  priority: PracticePriority.should,
                ),
              ],
            ),
          ],
          child: const MaterialApp(home: ParentAssignmentsTab()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 3개 중 1개 완료 = 33% 완료
      expect(find.textContaining('33%'), findsOneWidget);
      expect(
        find.text(AppStrings.parentHomeIncompleteAssignment),
        findsOneWidget,
      );
      expect(
        find.text(AppStrings.parentHomeCompletedAssignment),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('과제가 없으면 빈 상태를 렌더한다', (tester) async {
      await tester.binding.setSurfaceSize(const Size(440, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedChildProfileProvider.overrideWith(
              () => _FakeSelectedChildProfile(_linkedProfile()),
            ),
            weeklyPracticeItemsProvider(
              'student-1',
            ).overrideWith((_) async => const <PracticeItem>[]),
          ],
          child: const MaterialApp(home: ParentAssignmentsTab()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text(AppStrings.parentHomeNoAssignment), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

/// Test double for the [selectedChildProfileProvider] notifier.
class _FakeSelectedChildProfile extends SelectedChildProfile {
  _FakeSelectedChildProfile(this._profile);

  final ChildProfile? _profile;

  @override
  ChildProfile? build() => _profile;
}
