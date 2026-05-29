// R2 #318 — StudentSummaryScreen widget smoke test (ux-rules HARD-GATE).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/share/presentation/screens/student_summary_screen.dart';

void main() {
  testWidgets('renders loaded lesson summary from share token', (tester) async {
    const token = 'sample-share-token-abc123';

    await tester.pumpWidget(
      MaterialApp(
        home: StudentSummaryScreen(
          token: token,
          loader:
              (_) async => const PublicLessonSummaryViewData(
                studentName: '김학생',
                instrument: 'piano',
                teacherName: '김선생님',
                lessonDate: '2026-05-29',
                startTime: '14:00',
                durationMinutes: 60,
                feedback: '스케일이 안정적입니다.',
                practiceTips: '천천히 반복하세요.',
                keyPoints: ['손목 힘 빼기', '왼손 리듬'],
              ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('김학생'), findsOneWidget);
    expect(find.text('piano'), findsOneWidget);
    expect(find.text('스케일이 안정적입니다.'), findsOneWidget);
    expect(find.text('천천히 반복하세요.'), findsOneWidget);
    expect(find.text('손목 힘 빼기'), findsOneWidget);
  });

  testWidgets('handles empty token gracefully', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: StudentSummaryScreen(
          token: '',
          loader: (_) async => throw StateError('should not load'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
