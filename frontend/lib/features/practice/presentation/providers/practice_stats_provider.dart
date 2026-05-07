import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../features/practice/domain/entities/practice_stats.dart';
import 'practice_calendar_provider.dart';
import 'practice_repository_provider.dart';

part 'practice_stats_provider.g.dart';

/// Practice stats for selected month
@Riverpod(keepAlive: true)
Future<PracticeStats> monthlyPracticeStats(
  MonthlyPracticeStatsRef ref,
  String studentId,
) async {
  final month = ref.watch(selectedPracticeMonthProvider);
  final repository = ref.watch(practiceRepositoryProvider);
  return repository.getPracticeStats(studentId, month.year, month.month);
}

// Note: practiceStreakProvider moved to practice_streak_provider.dart
// with full PracticeStreak model support
