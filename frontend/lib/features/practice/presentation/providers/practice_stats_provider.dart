import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/practice.dart';
import 'practice_repository_provider.dart';
import 'practice_calendar_provider.dart';

/// Practice stats for selected month
final monthlyPracticeStatsProvider =
    FutureProvider.family<PracticeStats, String>((ref, studentId) async {
  final month = ref.watch(selectedPracticeMonthProvider);
  final repository = ref.watch(practiceRepositoryProvider);
  return repository.getPracticeStats(studentId, month.year, month.month);
});

// Note: practiceStreakProvider moved to practice_streak_provider.dart
// with full PracticeStreak model support
