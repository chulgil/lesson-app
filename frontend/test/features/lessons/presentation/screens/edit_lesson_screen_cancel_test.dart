import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/lessons/domain/entities/lesson.dart';
import 'package:lessonaza/features/lessons/presentation/providers/lesson_crud_provider.dart';
import 'package:lessonaza/features/lessons/presentation/screens/edit_lesson_screen.dart';
import 'package:lessonaza/features/students/presentation/providers/student_crud_provider.dart';

/// #766 후속 — 레슨 수정 화면 취소가 수강권 차감·정책 우회 회귀 가드.
///
/// `EditLessonScreen` 의 취소는 plain `cancelLesson` 만 호출해 수강권 차감
/// 되돌림/변경권/휴강 이벤트를 우회한다. 수강권 레슨은 하단 취소 버튼(및 앱바
/// 메뉴 취소)을 노출하지 않아야 한다 — 취소/휴강은 수강권 배너 → 구독 플로우로만.
/// 수동(비수강권) 레슨은 기존대로 취소 버튼 유지.

const _lessonId = 'lesson_766b';
const _studentId = 'stu_766b';

Lesson _lesson({String? subscriptionId}) => Lesson(
  id: _lessonId,
  studentId: _studentId,
  studentName: '학생 A',
  teacherId: 'teacher_1',
  instrument: '바이올린',
  date: DateTime(2026, 6, 20),
  startTime: '14:00',
  status: LessonStatus.scheduled,
  subscriptionId: subscriptionId,
  createdAt: DateTime(2026, 1, 1),
);

Future<void> _pumpEdit(WidgetTester tester, Lesson lesson) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        lessonProvider(_lessonId).overrideWith((ref) async => lesson),
        // profileColor 폴백(inkTertiary) 허용 — Student 없이도 렌더.
        studentProvider(_studentId).overrideWith((ref) async => null),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: const EditLessonScreen(lessonId: _lessonId),
      ),
    ),
  );
  // _loadLessonData 의 FutureProvider 들이 resolve + setState 완료될 때까지.
  await tester.pumpAndSettle();
}

void main() {
  final cancelButton = find.widgetWithText(
    OutlinedButton,
    AppStrings.actionLessonCancel,
  );
  final archiveButton = find.widgetWithText(
    OutlinedButton,
    AppStrings.archiveLessonTitle,
  );

  testWidgets('수강권 레슨 — 하단 취소 버튼 미노출(plain cancel 우회 차단)', (tester) async {
    await _pumpEdit(tester, _lesson(subscriptionId: 'sub_1'));

    expect(tester.takeException(), isNull);
    expect(
      cancelButton,
      findsNothing,
      reason:
          '수강권 레슨은 edit 화면 plain-cancel affordance 를 노출하면 안 됨 — '
          'cancelLesson 이 차감/변경권/휴강 이벤트를 우회 (#766 후속)',
    );
    // 보관(archive) 은 유지.
    expect(archiveButton, findsOneWidget);
  });

  testWidgets('수동(비수강권) 레슨 — 하단 취소 버튼 유지', (tester) async {
    await _pumpEdit(tester, _lesson(subscriptionId: null));

    expect(tester.takeException(), isNull);
    expect(
      cancelButton,
      findsOneWidget,
      reason: '수동 레슨은 기존대로 취소 버튼 유지(plain cancelLesson 정당)',
    );
    expect(archiveButton, findsOneWidget);
  });
}
