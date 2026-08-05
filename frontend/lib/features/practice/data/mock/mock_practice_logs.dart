import 'package:uuid/uuid.dart';

import '../../domain/entities/practice_log.dart';

/// Per-student practice patterns as day offsets from "today" plus a daily
/// minute count. This is the single seed for every mock surface so the streak
/// derived by [StreakCalculator] is identical wherever it is shown.
const Map<String, ({List<int> daysAgo, int minutes})> _mockPracticePatterns = {
  'student_1': (daysAgo: [0, 1, 2, 3, 5], minutes: 30), // 이번 주 5/7일
  'student_2': (daysAgo: [0, 1, 2, 3, 4, 6], minutes: 45), // 이번 주 6/7일
  'student_3': (daysAgo: [0, 2, 4], minutes: 20), // 이번 주 3/7일
  'student_4': (daysAgo: [1], minutes: 15), // 체험 1/7일
  'student_5': (daysAgo: [0, 1, 3, 5], minutes: 25), // 이번 주 4/7일
  'student_11': (daysAgo: [0, 1, 2, 3, 4, 5, 6], minutes: 40), // 모범생 7/7일
  'student_12': (daysAgo: [1, 4], minutes: 15), // 이번 주 2/7일
};

const List<(String title, int target, bool completed)> _taskTemplates = [
  ('음계 연습', 10, true),
  ('활 연습', 15, true),
  ('에튀드 #3', 20, true),
  ('비브라토 연습', 10, false),
  ('시창·청음', 10, true),
  ('곡 통주', 25, false),
  ('포지션 이동', 15, true),
  ('스타카토 연습', 10, true),
  ('레가토 보잉', 15, false),
  ('리듬 훈련', 10, true),
];

/// Build the shared mock practice-log dataset.
///
/// Returns a fresh, mutable map on each call so a caller (e.g. the mock
/// repository) can own and mutate its own copy. [now] is injectable for
/// deterministic tests; it defaults to the current time so the most recent
/// entries land on today.
Map<String, List<PracticeLog>> buildMockPracticeLogs({DateTime? now}) {
  const uuid = Uuid();
  final reference = now ?? DateTime.now();
  final today = DateTime(reference.year, reference.month, reference.day);

  PracticeLog makeLog(String studentId, int daysAgo, int minutes) {
    final date = today.subtract(Duration(days: daysAgo));
    // Pick 1-3 tasks deterministically from the hash of studentId + daysAgo.
    final seed = studentId.hashCode + daysAgo * 7;
    final taskCount = (seed.abs() % 3) + 1;
    final tasks = <PracticeTask>[];
    for (int i = 0; i < taskCount; i++) {
      final idx = (seed.abs() + i * 13) % _taskTemplates.length;
      final (title, target, completed) = _taskTemplates[idx];
      tasks.add(
        PracticeTask(
          id: uuid.v4(),
          title: title,
          targetMinutes: target,
          isCompleted: completed,
          completedAt: completed ? date : null,
        ),
      );
    }
    return PracticeLog(
      id: uuid.v4(),
      studentId: studentId,
      date: date,
      totalMinutes: minutes,
      tasks: tasks,
      createdAt: date,
    );
  }

  final logs = <String, List<PracticeLog>>{};
  _mockPracticePatterns.forEach((studentId, pattern) {
    logs[studentId] = [
      for (final daysAgo in pattern.daysAgo)
        makeLog(studentId, daysAgo, pattern.minutes),
    ];
  });
  return logs;
}
