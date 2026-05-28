import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/academy/domain/entities/academy_activity_log.dart';
import 'package:lessonaza/features/academy/presentation/screens/academy_activity_timeline_screen.dart';

void main() {
  group('AcademyActivityTimelineScreen smoke test', () {
    testWidgets('renders and displays timeline items', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: AcademyActivityTimelineScreen(
              academyId: 'acad_001',
              actorMemberId: 'member_001',
              actorName: '김선생님',
            ),
          ),
        ),
      );

      // Initially shows loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for data to load
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // After loading, should show timeline items
      expect(find.byType(AcademyActivityTimelineItem), findsWidgets);

      // Verify no unhandled exceptions
      expect(tester.takeException(), isNull);
    });
  });

  group('AcademyActivityLog model', () {
    test('copyWith creates new instance with updated fields', () {
      final original = AcademyActivityLog(
        id: 'log_001',
        academyId: 'acad_001',
        actorMemberId: 'member_001',
        actorName: '김선생님',
        actionType: 'lesson_created',
        description: '레슨 1개 생성',
        createdAt: DateTime(2026, 5, 28),
      );

      final updated = original.copyWith(
        actionType: 'lesson_completed',
        description: '레슨 1개 완료',
      );

      expect(updated.id, original.id);
      expect(updated.academyId, original.academyId);
      expect(updated.actorMemberId, original.actorMemberId);
      expect(updated.actorName, original.actorName);
      expect(updated.actionType, 'lesson_completed');
      expect(updated.description, '레슨 1개 완료');
      expect(updated.createdAt, original.createdAt);
    });
  });

  group('AcademyActivityTimelineItem highlight', () {
    testWidgets('shows highlight badge for recent activity', (
      WidgetTester tester,
    ) async {
      final now = DateTime.now();
      final recentLog = AcademyActivityLog(
        id: 'log_001',
        academyId: 'acad_001',
        actorMemberId: 'member_001',
        actorName: '김선생님',
        actionType: 'lesson_created',
        description: '레슨 1개 생성',
        createdAt: now.subtract(const Duration(hours: 2)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AcademyActivityTimelineItem(log: recentLog)),
        ),
      );

      // Check for "12시간 이내" badge
      expect(find.text('12시간 이내'), findsOneWidget);
    });

    testWidgets('does not show highlight badge for old activity', (
      WidgetTester tester,
    ) async {
      final now = DateTime.now();
      final oldLog = AcademyActivityLog(
        id: 'log_001',
        academyId: 'acad_001',
        actorMemberId: 'member_001',
        actorName: '김선생님',
        actionType: 'lesson_created',
        description: '레슨 1개 생성',
        createdAt: now.subtract(const Duration(days: 2)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AcademyActivityTimelineItem(log: oldLog)),
        ),
      );

      // Check that badge is not present
      expect(find.text('12시간 이내'), findsNothing);
    });
  });
}
