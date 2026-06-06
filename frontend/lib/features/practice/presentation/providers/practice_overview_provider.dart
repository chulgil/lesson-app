import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/repository_provider.dart';
import '../../domain/entities/student_practice_overview.dart';

part 'practice_overview_provider.g.dart';

/// Provider for teacher's view of student practice overview.
/// Returns weekly practice entries and shared recordings.
@riverpod
Future<StudentPracticeOverview> studentPracticeOverview(
  Ref ref,
  String studentId,
) async {
  // Remote aggregation API not yet available.
  // Mock mode: show sample data. Remote mode: return an empty overview (no
  // weekly entries) so the UI shows a "준비 중" placeholder instead of fake
  // progress.
  // TODO(remote): Replace with real repository call when backend is ready
  if (!ref.watch(mockDataModeProvider)) {
    return StudentPracticeOverview(
      studentId: studentId,
      studentName: '',
      practiceDaysThisWeek: 0,
      totalPracticeMinutes: 0,
      sharedRecordings: const [],
      weeklyEntries: const [],
    );
  }
  return _generateMockOverview(studentId);
}

/// Generate mock data for development
StudentPracticeOverview _generateMockOverview(String studentId) {
  final now = DateTime.now();

  // Find the most recent Monday
  final monday = now.subtract(Duration(days: now.weekday - 1));

  // Generate 7 daily entries (Mon-Sun)
  final weeklyEntries = List.generate(7, (i) {
    final date = DateTime(monday.year, monday.month, monday.day + i);
    // Simulate varied practice: some days practiced, some not
    final practiceMinutes = switch (i) {
      0 => 45, // Monday
      1 => 30, // Tuesday
      2 => 0, // Wednesday - rest
      3 => 60, // Thursday
      4 => 25, // Friday
      5 => 0, // Saturday - rest
      6 => 40, // Sunday
      _ => 0,
    };
    return DailyPracticeEntry(
      date: date,
      practiceMinutes: practiceMinutes,
    );
  });

  final practiceDays =
      weeklyEntries.where((e) => e.hasPracticed).length;
  final totalMinutes =
      weeklyEntries.fold<int>(0, (sum, e) => sum + e.practiceMinutes);

  // Mock shared recordings
  final sharedRecordings = [
    SharedRecording(
      recordingId: 'rec_mock_1',
      repertoireName: '비발디 사계 - 여름 1악장',
      sectionName: 'A Section',
      sharedAt: now.subtract(const Duration(days: 1)),
      durationSeconds: 42,
      bpm: 120,
    ),
    SharedRecording(
      recordingId: 'rec_mock_2',
      repertoireName: '바흐 무반주 소나타 2번',
      sectionName: 'Exposition',
      sharedAt: now.subtract(const Duration(days: 3)),
      durationSeconds: 98,
      bpm: 96,
    ),
    SharedRecording(
      recordingId: 'rec_mock_3',
      repertoireName: '슈베르트 세레나데',
      sectionName: 'Theme',
      sharedAt: now.subtract(const Duration(days: 5)),
      durationSeconds: 65,
    ),
  ];

  return StudentPracticeOverview(
    studentId: studentId,
    studentName: '', // Resolved by UI layer from student data
    practiceDaysThisWeek: practiceDays,
    totalPracticeMinutes: totalMinutes,
    sharedRecordings: sharedRecordings,
    weeklyEntries: weeklyEntries,
  );
}
