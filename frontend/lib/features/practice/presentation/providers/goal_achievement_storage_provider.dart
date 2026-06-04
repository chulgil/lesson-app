import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'goal_achievement_storage_provider.g.dart';

/// Per-user storage of the most recent daily / weekly goal achievement
/// celebrations.
///
/// The widget tier reads this to ensure the achievement dialog is shown at
/// most once per achievement window (one day for daily goals, one ISO week
/// for weekly goals). Without this dedupe the dialog would re-pop on every
/// tab rebuild while the goal stays achieved.
///
/// Keys follow the user-scoped convention so multiple students on the same
/// device do not share celebration history.
@Riverpod(keepAlive: true)
class GoalAchievementStorage extends _$GoalAchievementStorage {
  static const _boxName = 'goal_achievement_storage';

  @override
  Future<GoalAchievementState> build(String studentId) async {
    return _load();
  }

  Future<GoalAchievementState> _load() async {
    try {
      final box = await Hive.openBox<Map>(_boxName);
      final raw = box.get(_keyForStudent(studentId));
      if (raw == null) return const GoalAchievementState();
      final map = Map<String, dynamic>.from(raw);
      return GoalAchievementState(
        lastDailyAchievedDate: _parseDate(map['lastDailyAchievedDate']),
        lastWeeklyAchievedWeekStart: _parseDate(
          map['lastWeeklyAchievedWeekStart'],
        ),
      );
    } catch (_) {
      return const GoalAchievementState();
    }
  }

  Future<void> markDailyAchieved(DateTime date) async {
    final dayOnly = DateTime(date.year, date.month, date.day);
    final current = state.valueOrNull ?? const GoalAchievementState();
    final next = current.copyWith(lastDailyAchievedDate: dayOnly);
    state = AsyncData(next);
    await _persist(next);
  }

  Future<void> markWeeklyAchieved(DateTime weekStart) async {
    final dayOnly = DateTime(weekStart.year, weekStart.month, weekStart.day);
    final current = state.valueOrNull ?? const GoalAchievementState();
    final next = current.copyWith(lastWeeklyAchievedWeekStart: dayOnly);
    state = AsyncData(next);
    await _persist(next);
  }

  Future<void> _persist(GoalAchievementState next) async {
    try {
      final box = await Hive.openBox<Map>(_boxName);
      await box.put(_keyForStudent(studentId), {
        'lastDailyAchievedDate': next.lastDailyAchievedDate?.toIso8601String(),
        'lastWeeklyAchievedWeekStart': next.lastWeeklyAchievedWeekStart
            ?.toIso8601String(),
      });
    } catch (_) {
      // Persistence best-effort; in-memory state already updated.
    }
  }

  static String _keyForStudent(String studentId) =>
      'student:$studentId:goal_achievement';

  static DateTime? _parseDate(Object? value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}

/// Immutable snapshot of when the achievement dialog was last shown for a
/// given student.
class GoalAchievementState {
  final DateTime? lastDailyAchievedDate;
  final DateTime? lastWeeklyAchievedWeekStart;

  const GoalAchievementState({
    this.lastDailyAchievedDate,
    this.lastWeeklyAchievedWeekStart,
  });

  bool isDailyAlreadyShown(DateTime date) {
    final last = lastDailyAchievedDate;
    if (last == null) return false;
    return last.year == date.year &&
        last.month == date.month &&
        last.day == date.day;
  }

  bool isWeeklyAlreadyShown(DateTime weekStart) {
    final last = lastWeeklyAchievedWeekStart;
    if (last == null) return false;
    return last.year == weekStart.year &&
        last.month == weekStart.month &&
        last.day == weekStart.day;
  }

  GoalAchievementState copyWith({
    DateTime? lastDailyAchievedDate,
    DateTime? lastWeeklyAchievedWeekStart,
  }) {
    return GoalAchievementState(
      lastDailyAchievedDate:
          lastDailyAchievedDate ?? this.lastDailyAchievedDate,
      lastWeeklyAchievedWeekStart:
          lastWeeklyAchievedWeekStart ?? this.lastWeeklyAchievedWeekStart,
    );
  }
}
