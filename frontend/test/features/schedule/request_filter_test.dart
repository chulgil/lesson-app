import 'package:flutter_test/flutter_test.dart';

import 'package:lessonaza/features/schedule/domain/entities/unified_lesson_request.dart';
import 'package:lessonaza/features/schedule/domain/entities/request_filter.dart';

void main() {
  late List<UnifiedLessonRequest> allRequests;

  setUp(() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    allRequests = [
      _makeRequest(
        'r1',
        status: UnifiedRequestStatus.pending,
        createdAt: today,
        studentId: 's_김',
      ),
      _makeRequest(
        'r2',
        status: UnifiedRequestStatus.negotiating,
        createdAt: today.subtract(const Duration(days: 1)),
        studentId: 's_박',
      ),
      _makeRequest(
        'r3',
        status: UnifiedRequestStatus.completed,
        createdAt: today.subtract(const Duration(days: 5)),
        studentId: 's_이',
      ),
      _makeRequest(
        'r4',
        status: UnifiedRequestStatus.cancelled,
        createdAt: today.subtract(const Duration(days: 10)),
        studentId: 's_최',
      ),
      _makeRequest(
        'r5',
        status: UnifiedRequestStatus.expired,
        createdAt: today.subtract(const Duration(days: 35)),
        studentId: 's_정',
      ),
      _makeRequest(
        'r6',
        status: UnifiedRequestStatus.pending,
        createdAt: today.subtract(const Duration(days: 2)),
        studentId: 's_안',
      ),
    ];
  });

  group('RequestFilter', () {
    test('default filter returns all requests', () {
      const filter = RequestFilter();
      final result = filter.apply(allRequests);
      expect(result.length, allRequests.length);
    });

    test('filter by status', () {
      const filter = RequestFilter(status: UnifiedRequestStatus.pending);
      final result = filter.apply(allRequests);
      expect(result.length, 2);
      expect(
        result.every((r) => r.status == UnifiedRequestStatus.pending),
        isTrue,
      );
    });

    test('filter by date range (1 week)', () {
      final now = DateTime.now();
      final oneWeekAgo = now.subtract(const Duration(days: 7));
      final filter = RequestFilter(startDate: oneWeekAgo, endDate: now);
      final result = filter.apply(allRequests);
      // r1 (today), r2 (1 day ago), r3 (5 days ago), r6 (2 days ago)
      expect(result.length, 4);
    });

    test('filter by date range (1 month)', () {
      final now = DateTime.now();
      final oneMonthAgo = now.subtract(const Duration(days: 30));
      final filter = RequestFilter(startDate: oneMonthAgo, endDate: now);
      final result = filter.apply(allRequests);
      // r5 is 35 days ago, excluded
      expect(result.length, 5);
    });

    test(
      'P1 — active (non-terminal) requests survive the date range regardless '
      'of window, terminal requests outside the window stay excluded',
      () {
        final now = DateTime.now();
        final oldActive = _makeRequest(
          'r_old_active',
          status: UnifiedRequestStatus.pending,
          createdAt: now.subtract(const Duration(days: 40)),
        );
        final oldTerminal = _makeRequest(
          'r_old_terminal',
          status: UnifiedRequestStatus.cancelled,
          createdAt: now.subtract(const Duration(days: 40)),
        );
        final oneWeekAgo = now.subtract(const Duration(days: 7));
        final filter = RequestFilter(startDate: oneWeekAgo, endDate: now);

        final result = filter.apply([oldActive, oldTerminal]);

        expect(result.map((r) => r.id), contains('r_old_active'));
        expect(result.map((r) => r.id), isNot(contains('r_old_terminal')));
      },
    );

    test('filter by specific day', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final filter = RequestFilter(specificDate: today);
      final result = filter.apply(allRequests);
      expect(result.length, 1);
      expect(result.first.id, 'r1');
    });

    test('combined status + date filter', () {
      final now = DateTime.now();
      final oneWeekAgo = now.subtract(const Duration(days: 7));
      final filter = RequestFilter(
        status: UnifiedRequestStatus.pending,
        startDate: oneWeekAgo,
        endDate: now,
      );
      final result = filter.apply(allRequests);
      // r1 (pending, today), r6 (pending, 2 days ago)
      expect(result.length, 2);
    });

    test('sort by createdAt descending (default)', () {
      const filter = RequestFilter(sortBy: RequestSortBy.createdAtDesc);
      final result = filter.apply(allRequests);
      for (int i = 1; i < result.length; i++) {
        expect(
          result[i].createdAt.isBefore(result[i - 1].createdAt) ||
              result[i].createdAt.isAtSameMomentAs(result[i - 1].createdAt),
          isTrue,
        );
      }
    });

    test('sort by studentId ascending (name order)', () {
      const filter = RequestFilter(sortBy: RequestSortBy.studentNameAsc);
      final result = filter.apply(allRequests);
      for (int i = 1; i < result.length; i++) {
        expect(
          result[i].studentId.compareTo(result[i - 1].studentId) >= 0,
          isTrue,
        );
      }
    });

    test('pagination — page 1 of 3 items', () {
      const filter = RequestFilter(pageSize: 3, page: 0);
      final result = filter.apply(allRequests);
      expect(result.length, 3);
    });

    test('pagination — page 2 gets remaining', () {
      const filter = RequestFilter(pageSize: 3, page: 1);
      final result = filter.apply(allRequests);
      expect(result.length, 3); // 6 total, page 2 gets 3
    });

    test('pagination — beyond last page returns empty', () {
      const filter = RequestFilter(pageSize: 3, page: 5);
      final result = filter.apply(allRequests);
      expect(result, isEmpty);
    });
  });

  group('RequestFilterPreset', () {
    test('oneWeek preset sets correct date range', () {
      final filter = RequestFilter.preset(RequestFilterPreset.oneWeek);
      expect(filter.startDate, isNotNull);
      expect(filter.endDate, isNotNull);
      final diff = filter.endDate!.difference(filter.startDate!).inDays;
      expect(diff, 7);
    });

    test('oneMonth preset sets 30 day range', () {
      final filter = RequestFilter.preset(RequestFilterPreset.oneMonth);
      final diff = filter.endDate!.difference(filter.startDate!).inDays;
      expect(diff, 30);
    });

    test('threeMonths preset sets 90 day range', () {
      final filter = RequestFilter.preset(RequestFilterPreset.threeMonths);
      final diff = filter.endDate!.difference(filter.startDate!).inDays;
      expect(diff, 90);
    });
  });
}

UnifiedLessonRequest _makeRequest(
  String id, {
  required UnifiedRequestStatus status,
  required DateTime createdAt,
  String studentId = 'student_1',
}) {
  return UnifiedLessonRequest(
    id: id,
    studentId: studentId,
    teacherId: 'teacher_1',
    type: LessonRequestType.regular,
    instrument: '바이올린',
    goal: UnifiedLessonGoal.hobby,
    experience: UnifiedExperienceLevel.beginner,
    status: status,
    createdAt: createdAt,
  );
}
