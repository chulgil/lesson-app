import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/gamification/data/repositories/mock_streak_freeze_repository.dart';
import 'package:lessonaza/features/gamification/domain/services/streak_with_freeze_calculator.dart';
import 'package:lessonaza/features/gamification/presentation/providers/effective_streak_provider.dart';
import 'package:lessonaza/features/gamification/presentation/providers/streak_freeze_provider.dart';
import 'package:lessonaza/features/practice/domain/entities/practice_streak.dart';
import 'package:lessonaza/features/practice/domain/repositories/practice_repository.dart';
import 'package:lessonaza/features/practice/presentation/providers/practice_repository_provider.dart';

/// 테스트용 stub — getStreak 만 반환, 나머지는 throw.
class _StubPracticeRepository implements PracticeRepository {
  _StubPracticeRepository(this._streak);
  final PracticeStreak _streak;

  @override
  Future<PracticeStreak> getStreak(String studentId) async => _streak;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('effectiveStreakProvider — Job 5 Task 5.1', () {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    final twoDaysAgo = today.subtract(const Duration(days: 2));

    PracticeStreak buildStreak({
      int currentStreak = 0,
      DateTime? lastPracticeDate,
    }) => PracticeStreak(
      id: 'streak_s1',
      studentId: 's1',
      currentStreak: currentStreak,
      longestStreak: currentStreak,
      lastPracticeDate: lastPracticeDate,
      updatedAt: today,
    );

    test('어제 활동 + freeze balance=2 → freezeShouldApply=false', () async {
      final freezeRepo = MockStreakFreezeRepository();
      await freezeRepo.grantWeekly('s1', amount: 2);

      final container = ProviderContainer(
        overrides: [
          practiceRepositoryProvider.overrideWithValue(
            _StubPracticeRepository(
              buildStreak(currentStreak: 7, lastPracticeDate: yesterday),
            ),
          ),
          streakFreezeRepositoryProvider.overrideWithValue(freezeRepo),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(effectiveStreakProvider('s1').future);
      expect(result, isA<StreakWithFreezeResult>());
      expect(result.freezeShouldApply, isFalse);
      expect(result.streakBroken, isFalse);
      expect(result.effectiveCurrentStreak, 7);
    });

    test('어제 결석 + freeze balance=2 → freezeShouldApply=true', () async {
      final freezeRepo = MockStreakFreezeRepository();
      await freezeRepo.grantWeekly('s1', amount: 2);

      final container = ProviderContainer(
        overrides: [
          practiceRepositoryProvider.overrideWithValue(
            _StubPracticeRepository(
              buildStreak(currentStreak: 7, lastPracticeDate: twoDaysAgo),
            ),
          ),
          streakFreezeRepositoryProvider.overrideWithValue(freezeRepo),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(effectiveStreakProvider('s1').future);
      expect(result.freezeShouldApply, isTrue);
      expect(result.streakBroken, isFalse);
    });

    test('어제 결석 + freeze balance=0 → streakBroken=true', () async {
      final container = ProviderContainer(
        overrides: [
          practiceRepositoryProvider.overrideWithValue(
            _StubPracticeRepository(
              buildStreak(currentStreak: 0, lastPracticeDate: twoDaysAgo),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(effectiveStreakProvider('s1').future);
      expect(result.streakBroken, isTrue);
      expect(result.freezeShouldApply, isFalse);
    });

    test('신규 학생 (lastPracticeDate=null) → streakBroken=false', () async {
      final container = ProviderContainer(
        overrides: [
          practiceRepositoryProvider.overrideWithValue(
            _StubPracticeRepository(buildStreak()),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(effectiveStreakProvider('s1').future);
      expect(result.streakBroken, isFalse);
      expect(result.freezeShouldApply, isFalse);
    });
  });
}
