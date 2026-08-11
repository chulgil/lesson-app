import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/schedule/domain/entities/request_event.dart';
import 'package:lessonaza/features/schedule/domain/entities/unified_lesson_request.dart';
import 'package:lessonaza/features/schedule/presentation/providers/unified_lesson_request_providers.dart';
import 'package:lessonaza/features/schedule/presentation/screens/request_detail_screen.dart';
import 'package:lessonaza/features/subscription/presentation/providers/subscription_template_providers.dart';

// #P1 detail split — smoke test for the newly extracted app bar / event
// strip / chapter-summaries widgets. Renders through the real screen so a
// runtime layout crash (RenderBox/BoxConstraints) in any extracted piece
// surfaces here, matching the ux-rules.md widget-smoke-test contract.
void main() {
  final request = UnifiedLessonRequest(
    id: 'request_1',
    studentId: 'student_1',
    teacherId: 'teacher_1',
    instrument: '피아노',
    goal: UnifiedLessonGoal.hobby,
    experience: UnifiedExperienceLevel.beginner,
    type: LessonRequestType.regular,
    status: UnifiedRequestStatus.pending,
    createdAt: DateTime(2026, 5, 4),
  );

  Widget buildTestable() {
    return ProviderScope(
      overrides: [
        unifiedRequestByIdProvider(
          request.id,
        ).overrideWith((ref) async => request),
        requestEventsProvider(
          request.id,
        ).overrideWith((ref) async => <RequestEvent>[]),
        studentNameMapProvider.overrideWithValue(const {'student_1': '김민준'}),
        teacherNameMapProvider.overrideWithValue(const {'teacher_1': '박선생'}),
        academyNameMapProvider.overrideWithValue(const {}),
        activeTeacherTemplatesProvider(
          request.teacherId,
        ).overrideWith((ref) async => const []),
      ],
      child: const MaterialApp(
        home: RequestDetailScreen(
          requestId: 'request_1',
          viewerRole: 'teacher',
        ),
      ),
    );
  }

  testWidgets('renders a pending request without throwing', (tester) async {
    await tester.pumpWidget(buildTestable());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('김민준 (정규레슨)'), findsOneWidget);
  });

  testWidgets('opens the more-actions menu without throwing', (tester) async {
    await tester.pumpWidget(buildTestable());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
