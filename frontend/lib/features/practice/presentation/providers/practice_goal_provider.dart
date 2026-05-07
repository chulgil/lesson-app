import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/repository_provider.dart';
import '../../data/repositories/mock_practice_goal_repository.dart';
import '../../data/repositories/remote_practice_goal_repository.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/practice_goal_repository.dart';

part 'practice_goal_provider.g.dart';

/// Practice goal repository provider - switches between Mock and Remote.
@Riverpod(keepAlive: true)
PracticeGoalRepository practiceGoalRepository(PracticeGoalRepositoryRef ref) {
  return createRepository<PracticeGoalRepository>(
    ref: ref,
    mock: () => MockPracticeGoalRepository(),
    remote: (api) => RemotePracticeGoalRepository(api),
  );
}

/// Student's current active goal
@Riverpod(keepAlive: true)
Future<PracticeGoal?> practiceGoal(PracticeGoalRef ref, String studentId) {
  final repository = ref.watch(practiceGoalRepositoryProvider);
  return repository.getActiveGoal(studentId);
}

/// Today's progress
@Riverpod(keepAlive: true)
Future<DailyPracticeProgress> todayProgress(
  TodayProgressRef ref,
  String studentId,
) {
  final repository = ref.watch(practiceGoalRepositoryProvider);
  return repository.getDailyProgress(studentId, DateTime.now());
}

/// This week's progress
@Riverpod(keepAlive: true)
Future<WeeklyPracticeProgress> weeklyProgress(
  WeeklyProgressRef ref,
  String studentId,
) {
  final repository = ref.watch(practiceGoalRepositoryProvider);
  final now = DateTime.now();
  // Calculate this Monday
  final weekStart = now.subtract(Duration(days: now.weekday - 1));
  final normalizedWeekStart = DateTime(
    weekStart.year,
    weekStart.month,
    weekStart.day,
  );
  return repository.getWeeklyProgress(studentId, normalizedWeekStart);
}

/// Goal CRUD notifier
@Riverpod(keepAlive: true)
class PracticeGoalCrud extends _$PracticeGoalCrud {
  @override
  Future<void> build() async {}

  /// Save a goal (create or update)
  Future<PracticeGoal> saveGoal(PracticeGoal goal) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(practiceGoalRepositoryProvider);
      final result = await repository.saveGoal(goal);

      // Invalidate related providers
      ref.invalidate(practiceGoalProvider(goal.studentId));
      ref.invalidate(todayProgressProvider(goal.studentId));
      ref.invalidate(weeklyProgressProvider(goal.studentId));

      state = const AsyncData(null);
      return result;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Deactivate a goal
  Future<void> deactivateGoal(String goalId, String studentId) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(practiceGoalRepositoryProvider);
      await repository.deactivateGoal(goalId);

      // Invalidate related providers
      ref.invalidate(practiceGoalProvider(studentId));

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

typedef PracticeGoalCrudNotifier = PracticeGoalCrud;

/// Combined goal status provider for widgets
@Riverpod(keepAlive: true)
Future<GoalStatus> goalStatus(GoalStatusRef ref, String studentId) async {
  final goal = await ref.watch(practiceGoalProvider(studentId).future);
  final todayProgress = await ref.watch(
    todayProgressProvider(studentId).future,
  );
  final weeklyProgress = await ref.watch(
    weeklyProgressProvider(studentId).future,
  );

  return GoalStatus(
    goal: goal,
    todayProgress: todayProgress,
    weeklyProgress: weeklyProgress,
  );
}

/// Combined goal status for widgets
class GoalStatus {
  final PracticeGoal? goal;
  final DailyPracticeProgress todayProgress;
  final WeeklyPracticeProgress weeklyProgress;

  GoalStatus({
    required this.goal,
    required this.todayProgress,
    required this.weeklyProgress,
  });

  /// Whether goal is set
  bool get hasGoal => goal != null && goal!.hasAnyGoal;

  /// Whether daily goal is achieved
  bool get isDailyGoalAchieved {
    if (goal == null || !goal!.hasDailyGoal) return false;
    return todayProgress.isDailyGoalAchieved(goal!);
  }

  /// Whether weekly goal is achieved
  bool get isWeeklyGoalAchieved {
    if (goal == null || !goal!.hasWeeklyGoal) return false;
    return weeklyProgress.isWeeklyGoalAchieved(goal!);
  }

  /// Daily time progress percentage (0-100+)
  int get dailyTimeProgressPercent {
    if (goal?.dailyTimeMinutes == null) return 0;
    return (todayProgress.timeProgressRate(goal!.dailyTimeMinutes) * 100)
        .round();
  }

  /// Daily section progress percentage (0-100+)
  int get dailySectionProgressPercent {
    if (goal?.dailySectionCount == null) return 0;
    return (todayProgress.sectionProgressRate(goal!.dailySectionCount) * 100)
        .round();
  }

  /// Weekly time progress percentage (0-100+)
  int get weeklyTimeProgressPercent {
    if (goal?.weeklyTimeMinutes == null) return 0;
    return (weeklyProgress.timeProgressRate(goal!.weeklyTimeMinutes) * 100)
        .round();
  }

  /// Weekly day progress percentage (0-100+)
  int get weeklyDayProgressPercent {
    if (goal?.weeklyDayCount == null) return 0;
    return (weeklyProgress.dayProgressRate(goal!.weeklyDayCount) * 100).round();
  }
}
