import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/student_home/domain/entities/student_lesson_progress_item.dart';
import 'package:lessonaza/features/student_home/presentation/providers/student_lesson_progress_provider.dart';
import 'package:lessonaza/features/student_home/presentation/widgets/student_lesson_progress_section.dart';

void main() {
  testWidgets('renders action item before waiting item', (tester) async {
    await _pumpSection(tester, _items());

    expect(find.text('레슨 진행 · 2'), findsOneWidget);
    expect(find.text('내가 할 일 1 · 대기 1'), findsOneWidget);
    expect(find.text('수강권이 준비됐어요'), findsOneWidget);
    expect(find.text('레슨 신청을 보냈어요'), findsOneWidget);

    final actionTop = tester.getTopLeft(find.text('수강권이 준비됐어요')).dy;
    final waitingTop = tester.getTopLeft(find.text('레슨 신청을 보냈어요')).dy;
    expect(actionTop, lessThan(waitingTop));
  });

  testWidgets('uses ready copy and hides legacy issued copy', (tester) async {
    await _pumpSection(tester, _items());

    expect(find.text('수강권이 준비됐어요'), findsOneWidget);
    expect(find.textContaining('수강권이 발급되었습니다'), findsNothing);
    expect(find.textContaining('수강권이 발행되었습니다'), findsNothing);
  });

  testWidgets('empty list hides section', (tester) async {
    await _pumpSection(tester, const []);

    expect(find.textContaining('레슨 진행'), findsNothing);
  });

  testWidgets('lays out on narrow width without RenderBox errors', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpSection(tester, _items());

    expect(tester.takeException(), isNull);
    expect(find.text('레슨 진행 · 2'), findsOneWidget);
  });
}

Future<void> _pumpSection(
  WidgetTester tester,
  List<StudentLessonProgressItem> items,
) async {
  const studentId = 'student_1';
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        studentLessonProgressProvider(
          studentId,
        ).overrideWith((ref) async => items),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: EdgeInsets.all(16),
            child: StudentLessonProgressSection(studentId: studentId),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

List<StudentLessonProgressItem> _items() {
  final now = DateTime.now();
  return [
    StudentLessonProgressItem(
      id: 'waiting',
      kind: StudentLessonProgressKind.request,
      priority: StudentLessonProgressPriority.waiting,
      title: '레슨 신청을 보냈어요',
      subtitle: '선생님 답변을 기다리고 있어요',
      statusLabel: '대기',
      createdAt: now.subtract(const Duration(hours: 3)),
    ),
    StudentLessonProgressItem(
      id: 'action',
      kind: StudentLessonProgressKind.scheduleConfirmation,
      priority: StudentLessonProgressPriority.actionRequired,
      title: '수강권이 준비됐어요',
      subtitle: '첫 레슨 시간을 확인해주세요',
      statusLabel: '확인 필요',
      createdAt: now.subtract(const Duration(minutes: 20)),
    ),
  ];
}
