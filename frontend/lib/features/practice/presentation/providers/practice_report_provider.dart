import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/time_format_utils.dart';
import '../../data/repositories/mock_practice_stats_repository.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/practice_stats_repository.dart';

part 'practice_report_provider.g.dart';

/// Practice stats repository provider
@riverpod
PracticeStatsRepository practiceReportRepository(Ref ref) {
  return MockPracticeStatsRepository();
}

/// Weekly report params
typedef WeeklyReportParams = ({String studentId, DateTime weekStart});

/// Weekly report provider
@riverpod
Future<PracticeStatsReport> weeklyReport(
  Ref ref,
  WeeklyReportParams params,
) async {
  final repository = ref.watch(practiceReportRepositoryProvider);
  return repository.getWeeklyReport(params.studentId, params.weekStart);
}

/// Monthly report params
typedef MonthlyReportParams = ({String studentId, int year, int month});

/// Monthly report provider
@riverpod
Future<PracticeStatsReport> monthlyReport(
  Ref ref,
  MonthlyReportParams params,
) async {
  final repository = ref.watch(practiceReportRepositoryProvider);
  return repository.getMonthlyReport(
    params.studentId,
    params.year,
    params.month,
  );
}

/// Current week start date provider
@riverpod
DateTime currentWeekStart(Ref ref) {
  return getMondayOfWeek(DateTime.now());
}

/// Current month provider
@riverpod
({int year, int month}) currentMonth(Ref ref) {
  final now = DateTime.now();
  return (year: now.year, month: now.month);
}

/// Selected report date state (for navigation)
class ReportDateState {
  final DateTime weekStart;
  final int year;
  final int month;

  ReportDateState({
    required this.weekStart,
    required this.year,
    required this.month,
  });

  ReportDateState copyWith({
    DateTime? weekStart,
    int? year,
    int? month,
  }) {
    return ReportDateState(
      weekStart: weekStart ?? this.weekStart,
      year: year ?? this.year,
      month: month ?? this.month,
    );
  }

  /// Navigate to previous week
  ReportDateState previousWeek() {
    final newWeekStart = weekStart.subtract(const Duration(days: 7));
    return copyWith(
      weekStart: newWeekStart,
      year: newWeekStart.year,
      month: newWeekStart.month,
    );
  }

  /// Navigate to next week
  ReportDateState nextWeek() {
    final newWeekStart = weekStart.add(const Duration(days: 7));
    return copyWith(
      weekStart: newWeekStart,
      year: newWeekStart.year,
      month: newWeekStart.month,
    );
  }

  /// Navigate to previous month
  ReportDateState previousMonth() {
    var newYear = year;
    var newMonth = month - 1;
    if (newMonth < 1) {
      newMonth = 12;
      newYear--;
    }
    return copyWith(year: newYear, month: newMonth);
  }

  /// Navigate to next month
  ReportDateState nextMonth() {
    var newYear = year;
    var newMonth = month + 1;
    if (newMonth > 12) {
      newMonth = 1;
      newYear++;
    }
    return copyWith(year: newYear, month: newMonth);
  }

  /// Check if can navigate to next (not in future)
  bool get canNavigateNextWeek {
    final now = DateTime.now();
    final currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
    return weekStart.isBefore(currentWeekStart);
  }

  bool get canNavigateNextMonth {
    final now = DateTime.now();
    return year < now.year || (year == now.year && month < now.month);
  }
}

/// Report date state notifier
@riverpod
class ReportDate extends _$ReportDate {
  @override
  ReportDateState build() {
    return ReportDateState(
      weekStart: getMondayOfWeek(DateTime.now()),
      year: DateTime.now().year,
      month: DateTime.now().month,
    );
  }

  void previousWeek() {
    state = state.previousWeek();
  }

  void nextWeek() {
    if (state.canNavigateNextWeek) {
      state = state.nextWeek();
    }
  }

  void previousMonth() {
    state = state.previousMonth();
  }

  void nextMonth() {
    if (state.canNavigateNextMonth) {
      state = state.nextMonth();
    }
  }

  void reset() {
    state = build();
  }
}
