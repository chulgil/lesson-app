import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../features/practice/domain/entities/practice_streak.dart';
import '../../../../features/auth/auth_facade.dart';
import 'practice_repository_provider.dart';

part 'practice_streak_provider.g.dart';

/// Provider for getting practice streak by student ID
@riverpod
Future<PracticeStreak> practiceStreak(Ref ref, String studentId) async {
  final repository = ref.watch(practiceRepositoryProvider);
  return repository.getStreak(studentId);
}

/// Provider for recording practice and updating streak
@riverpod
Future<PracticeStreak> recordPractice(Ref ref, String studentId) async {
  final repository = ref.watch(practiceRepositoryProvider);
  return repository.recordPractice(studentId);
}

/// State notifier for managing streak updates
@riverpod
class StreakNotifier extends _$StreakNotifier {
  @override
  Future<PracticeStreak> build(String studentId) async {
    final repository = ref.watch(practiceRepositoryProvider);
    return repository.getStreak(studentId);
  }

  Future<void> recordPractice() async {
    final repository = ref.read(practiceRepositoryProvider);
    final streak = await repository.recordPractice(studentId);
    state = AsyncValue.data(streak);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

/// Provider for current user's streak
@riverpod
Future<PracticeStreak> currentUserStreak(Ref ref) async {
  final currentUserId = ref.watch(currentUserIdProvider);
  final repository = ref.watch(practiceRepositoryProvider);
  return repository.getStreak(currentUserId);
}
