import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/practice.dart';
import 'practice_repository_provider.dart';
import 'practice_calendar_provider.dart';
import 'practice_crud_provider.dart';

/// Practice stats for selected month
final monthlyPracticeStatsProvider =
    FutureProvider.family<PracticeStats, String>((ref, studentId) async {
  final month = ref.watch(selectedPracticeMonthProvider);
  final repository = ref.watch(practiceRepositoryProvider);
  return repository.getPracticeStats(studentId, month.year, month.month);
});

/// Practice streak (consecutive days)
final practiceStreakProvider =
    Provider.family<AsyncValue<int>, String>((ref, studentId) {
  final logsAsync = ref.watch(practiceNotifierProvider(studentId));

  return logsAsync.when(
    data: (logs) {
      if (logs.isEmpty) return const AsyncValue.data(0);

      final sortedLogs = logs.where((l) => l.totalMinutes > 0).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

      if (sortedLogs.isEmpty) return const AsyncValue.data(0);

      int streak = 0;
      DateTime expectedDate = DateTime.now();

      for (final log in sortedLogs) {
        final logDate = DateTime(log.date.year, log.date.month, log.date.day);
        final expected = DateTime(
            expectedDate.year, expectedDate.month, expectedDate.day);

        if (logDate == expected ||
            logDate == expected.subtract(const Duration(days: 1))) {
          streak++;
          expectedDate = logDate.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }

      return AsyncValue.data(streak);
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});
