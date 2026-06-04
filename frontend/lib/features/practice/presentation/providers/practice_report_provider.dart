import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/repository_provider.dart';
import '../../../../core/utils/time_format_utils.dart';
import '../../data/repositories/mock_practice_stats_repository.dart';
import '../../data/repositories/remote_practice_stats_repository.dart';
import '../../domain/entities/entities.dart';
import '../../domain/entities/practice_report.dart';
import '../../domain/repositories/practice_stats_repository.dart';
import '../../domain/services/practice_report_calculator.dart';

part 'practice_report_provider.g.dart';

/// Practice stats repository provider - switches between Mock and Remote.
@riverpod
PracticeStatsRepository practiceReportRepository(Ref ref) =>
    createRepository<PracticeStatsRepository>(
      ref: ref,
      mock: () => MockPracticeStatsRepository(),
      remote: (api) => RemotePracticeStatsRepository(api),
    );

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

  ReportDateState copyWith({DateTime? weekStart, int? year, int? month}) {
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

/// Report period selection for the practice report screen.
enum PracticeReportPeriod { weekly, monthly }

/// Currently selected report period (toggle state on the report screen).
@riverpod
class PracticeReportPeriodController extends _$PracticeReportPeriodController {
  @override
  PracticeReportPeriod build() => PracticeReportPeriod.weekly;

  void select(PracticeReportPeriod period) {
    state = period;
  }
}

/// Calculator provider (pure, no I/O).
@riverpod
PracticeReportCalculator practiceReportCalculator(Ref ref) =>
    const PracticeReportCalculator();

/// Build calculator inputs from PracticeStatsReport (a temporary adapter
/// until raw practice logs are exposed by the repository).
List<DailyPracticeInput> _inputsFromStatsReport(PracticeStatsReport source) {
  final inputs = <DailyPracticeInput>[];
  if (source.repertoireStats.isEmpty || source.dailyStats.isEmpty) {
    return inputs;
  }
  final totalSeconds = source.totalPracticeSeconds;
  if (totalSeconds == 0) return inputs;

  // Distribute repertoire seconds across days proportional to that day's share.
  for (final daily in source.dailyStats) {
    if (daily.practiceSeconds == 0) continue;
    final dayShare = daily.practiceSeconds / totalSeconds;
    for (final rep in source.repertoireStats) {
      final seconds = (rep.practiceSeconds * dayShare).round();
      if (seconds == 0) continue;
      inputs.add(
        DailyPracticeInput(
          date: daily.date,
          repertoireId: rep.repertoireId,
          repertoireName: rep.repertoireName,
          practiceSeconds: seconds,
        ),
      );
    }
  }
  return inputs;
}

/// Weekly practice report (new entity, §5.2).
@Riverpod(keepAlive: false)
Future<WeeklyReport> practiceWeeklyReport(
  Ref ref,
  WeeklyReportParams params,
) async {
  final repository = ref.watch(practiceReportRepositoryProvider);
  final statsReport = await repository.getWeeklyReport(
    params.studentId,
    params.weekStart,
  );
  final calculator = ref.watch(practiceReportCalculatorProvider);
  return calculator.calculateWeekly(
    weekStart: params.weekStart,
    inputs: _inputsFromStatsReport(statsReport),
  );
}

/// Monthly practice report (new entity, §5.2).
@Riverpod(keepAlive: false)
Future<MonthlyReport> practiceMonthlyReport(
  Ref ref,
  MonthlyReportParams params,
) async {
  final repository = ref.watch(practiceReportRepositoryProvider);
  final statsReport = await repository.getMonthlyReport(
    params.studentId,
    params.year,
    params.month,
  );
  final calculator = ref.watch(practiceReportCalculatorProvider);
  return calculator.calculateMonthly(
    year: params.year,
    month: params.month,
    inputs: _inputsFromStatsReport(statsReport),
  );
}
