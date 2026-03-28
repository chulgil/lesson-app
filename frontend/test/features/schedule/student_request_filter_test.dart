import 'package:flutter_test/flutter_test.dart';

import 'package:lessonaza/features/schedule/data/repositories/mock_unified_lesson_request_repository.dart';
import 'package:lessonaza/features/schedule/domain/entities/unified_lesson_request.dart';

/// Tests for student-side request filtering.
/// Students use getByStudentId — verify the mock data supports it.
void main() {
  late MockUnifiedLessonRequestRepository repository;

  setUp(() {
    repository = MockUnifiedLessonRequestRepository();
  });

  group('student requests', () {
    test('getByStudentId returns requests for student_1', () async {
      final requests = await repository.getByStudentId('student_1');
      expect(requests, isNotEmpty);
      // student_1 has multiple scenarios in mock data
      expect(requests.length, greaterThanOrEqualTo(2));
    });

    test('student requests include various statuses', () async {
      final requests = await repository.getByStudentId('student_1');
      final statuses = requests.map((r) => r.status).toSet();
      // student_1 should have at least pending and one other status
      expect(statuses.length, greaterThan(1));
    });

    test('student can view request detail by ID', () async {
      final requests = await repository.getByStudentId('student_1');
      final firstId = requests.first.id;

      final detail = await repository.getById(firstId);
      expect(detail, isNotNull);
      expect(detail!.studentId, 'student_1');
    });

    test('student request events are accessible', () async {
      final requests = await repository.getByStudentId('student_1');
      final requestWithEvents = requests.firstWhere(
        (r) => r.status != UnifiedRequestStatus.pending,
        orElse: () => requests.first,
      );

      final events = await repository.getEventsByRequestId(requestWithEvents.id);
      expect(events, isNotEmpty);
    });

    test('today active requests for student', () async {
      final requests = await repository.getByStudentId('student_1');
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final todayActive = requests.where((r) {
        if (r.status.isActive) return true;
        if (r.status == UnifiedRequestStatus.completed && r.confirmedAt != null) {
          final d = DateTime(
            r.confirmedAt!.year, r.confirmedAt!.month, r.confirmedAt!.day,
          );
          return d == today;
        }
        return false;
      }).toList();

      // At least some active requests should exist
      expect(todayActive, isNotEmpty);
    });
  });
}
