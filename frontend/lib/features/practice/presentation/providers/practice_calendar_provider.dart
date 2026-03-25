import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/practice/domain/entities/practice_log.dart';
import 'practice_repository_provider.dart';

/// Selected month for practice calendar
final selectedPracticeMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, 1);
});

/// Practice logs for selected month
final monthlyPracticeLogsProvider = FutureProvider.family<
    Map<DateTime, PracticeLog>, String>((ref, studentId) async {
  final month = ref.watch(selectedPracticeMonthProvider);
  final repository = ref.watch(practiceRepositoryProvider);
  return repository.getPracticeLogsByMonth(
      studentId, month.year, month.month);
});
