import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/practice.dart';
import 'practice_repository_provider.dart';

/// Provider for getting practice streak by student ID
final practiceStreakProvider =
    FutureProvider.family<PracticeStreak, String>((ref, studentId) async {
  final repository = ref.watch(practiceRepositoryProvider);
  return repository.getStreak(studentId);
});

/// Provider for recording practice and updating streak
final recordPracticeProvider =
    FutureProvider.family<PracticeStreak, String>((ref, studentId) async {
  final repository = ref.watch(practiceRepositoryProvider);
  return repository.recordPractice(studentId);
});

/// State notifier for managing streak updates
class StreakNotifier extends StateNotifier<AsyncValue<PracticeStreak>> {
  final Ref _ref;
  final String _studentId;

  StreakNotifier(this._ref, this._studentId) : super(const AsyncValue.loading()) {
    _loadStreak();
  }

  Future<void> _loadStreak() async {
    state = const AsyncValue.loading();
    try {
      final repository = _ref.read(practiceRepositoryProvider);
      final streak = await repository.getStreak(_studentId);
      state = AsyncValue.data(streak);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> recordPractice() async {
    try {
      final repository = _ref.read(practiceRepositoryProvider);
      final streak = await repository.recordPractice(_studentId);
      state = AsyncValue.data(streak);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    await _loadStreak();
  }
}

/// Provider for streak notifier by student ID
final streakNotifierProvider = StateNotifierProvider.family<StreakNotifier,
    AsyncValue<PracticeStreak>, String>(
  (ref, studentId) => StreakNotifier(ref, studentId),
);

/// Simple provider for current user's streak (assuming student_1 for now)
/// In production, this would use the authenticated user's ID
final currentUserStreakProvider = FutureProvider<PracticeStreak>((ref) async {
  // TODO: Replace with actual current user ID from auth provider
  const currentUserId = 'student_1';
  final repository = ref.watch(practiceRepositoryProvider);
  return repository.getStreak(currentUserId);
});
