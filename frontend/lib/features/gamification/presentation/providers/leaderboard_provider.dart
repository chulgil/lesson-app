// Leaderboard provider for weekly class ranking.

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/weekly_ranking.dart';

part 'leaderboard_provider.g.dart';

/// Calculates tier for each student based on rank position.
/// Top 30% = gold, next 30% = silver, rest = bronze.
RankingTier _calculateTier(int rank, int totalStudents) {
  if (totalStudents <= 0) return RankingTier.bronze;
  final percentile = rank / totalStudents;
  if (percentile <= 0.3) return RankingTier.gold;
  if (percentile <= 0.6) return RankingTier.silver;
  return RankingTier.bronze;
}

/// Provides weekly class ranking with mock data.
@riverpod
Future<WeeklyRanking> weeklyClassRanking(
  WeeklyClassRankingRef ref,
  String classId,
) async {
  await Future.delayed(const Duration(milliseconds: 200));

  // Mock student data sorted by weekly points descending.
  final mockStudents = <({String id, String name, int points})>[
    (id: 'student_11', name: '이하은', points: 520),
    (id: 'student_1', name: '김민준', points: 480),
    (id: 'student_13', name: '이서연', points: 320),
    (id: 'student_14', name: '정다은', points: 280),
    (id: 'student_12', name: '박준혁', points: 150),
  ];

  final total = mockStudents.length;
  final entries = <WeeklyRankingEntry>[];
  for (int i = 0; i < total; i++) {
    final student = mockStudents[i];
    entries.add(
      WeeklyRankingEntry(
        studentId: student.id,
        studentName: student.name,
        weeklyPoints: student.points,
        tier: _calculateTier(i + 1, total),
        rank: i + 1,
      ),
    );
  }

  // Week start date: most recent Monday.
  final now = DateTime.now();
  final weekStart = now.subtract(Duration(days: now.weekday - 1));

  return WeeklyRanking(
    classId: classId,
    weekStartDate: DateTime(weekStart.year, weekStart.month, weekStart.day),
    entries: entries,
  );
}
