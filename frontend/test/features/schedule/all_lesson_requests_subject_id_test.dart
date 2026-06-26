import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/schedule/domain/entities/unified_lesson_request.dart';
import 'package:lessonaza/features/schedule/presentation/providers/unified_lesson_request_providers.dart';
import 'package:lessonaza/features/schedule/presentation/screens/all_lesson_requests_screen.dart';

/// #524 회귀: AllLessonRequestsScreen 의 단일 식별자 필드가 `teacherId` 였던
/// 탓에, 학생 뷰(viewerRole=='student')에서 라우트가 학생 id 를 teacherId
/// 파라미터에 주입해 의미가 혼동됐다. 필드를 역할 중립 `subjectId` 로 정정한 뒤,
/// 각 뷰가 자신의 provider(teacher / student)에 **올바른 식별자**로 질의하는지
/// 검증한다.
void main() {
  // never-completing future → 화면을 loading 상태에 고정 (RequestListItem /
  // CompactWeekStrip 타이머·렌더 회피). spy 는 어느 식별자로 어느 provider 가
  // 인스턴스화됐는지만 기록한다.
  Future<AllLessonRequestsScreen> pump(
    WidgetTester tester, {
    required String viewerRole,
    required String subjectId,
    required void Function(String) onTeacherRead,
    required void Function(String) onStudentRead,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          teacherUnifiedRequestsProvider(subjectId).overrideWith((ref) {
            onTeacherRead(subjectId);
            return Completer<List<UnifiedLessonRequest>>().future;
          }),
          studentUnifiedRequestsProvider(subjectId).overrideWith((ref) {
            onStudentRead(subjectId);
            return Completer<List<UnifiedLessonRequest>>().future;
          }),
          studentNameMapProvider.overrideWithValue(const {}),
          teacherNameMapProvider.overrideWithValue(const {}),
          academyNameMapProvider.overrideWithValue(const {}),
        ],
        child: MaterialApp(
          home: AllLessonRequestsScreen(
            subjectId: subjectId,
            viewerRole: viewerRole,
          ),
        ),
      ),
    );
    await tester.pump();
    return tester.widget<AllLessonRequestsScreen>(
      find.byType(AllLessonRequestsScreen),
    );
  }

  testWidgets('학생 뷰는 studentUnifiedRequestsProvider 를 학생 id 로 질의', (
    tester,
  ) async {
    String? teacherReadWith;
    String? studentReadWith;

    final screen = await pump(
      tester,
      viewerRole: 'student',
      subjectId: 's99',
      onTeacherRead: (id) => teacherReadWith = id,
      onStudentRead: (id) => studentReadWith = id,
    );

    expect(screen.subjectId, 's99');
    expect(studentReadWith, 's99'); // student provider, student id
    expect(teacherReadWith, isNull); // teacher provider not touched
  });

  testWidgets('교사 뷰는 teacherUnifiedRequestsProvider 를 교사 id 로 질의', (
    tester,
  ) async {
    String? teacherReadWith;
    String? studentReadWith;

    await pump(
      tester,
      viewerRole: 'teacher',
      subjectId: 't1',
      onTeacherRead: (id) => teacherReadWith = id,
      onStudentRead: (id) => studentReadWith = id,
    );

    expect(teacherReadWith, 't1'); // teacher provider, teacher id
    expect(studentReadWith, isNull); // student provider not touched
  });
}
