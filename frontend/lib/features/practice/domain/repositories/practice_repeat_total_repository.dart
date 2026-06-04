/// Repository interface for cumulative repeat-section counts per student.
///
/// Used by #508: badge system tracks lifetime `completedRepeatCount`
/// increments to award `practiceRepeat10/50/100` badges.
abstract class PracticeRepeatTotalRepository {
  /// Current cumulative count for [studentUserId]. Defaults to 0.
  Future<int> getTotal(String studentUserId);

  /// Persists [total] as the new cumulative value.
  Future<void> setTotal({required String studentUserId, required int total});

  /// Increments and returns the new total. Atomic at the box level.
  Future<int> increment({required String studentUserId, int by = 1});
}
