import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../features/practice/domain/entities/practice_log.dart';
import 'practice_repository_provider.dart';

part 'practice_calendar_provider.g.dart';

/// Selected month for practice calendar
@Riverpod(keepAlive: true)
DateTime selectedPracticeMonth(SelectedPracticeMonthRef ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, 1);
}

/// Practice logs for selected month
@Riverpod(keepAlive: true)
Future<Map<DateTime, PracticeLog>> monthlyPracticeLogs(
  MonthlyPracticeLogsRef ref,
  String studentId,
) async {
  final month = ref.watch(selectedPracticeMonthProvider);
  final repository = ref.watch(practiceRepositoryProvider);
  return repository.getPracticeLogsByMonth(studentId, month.year, month.month);
}
