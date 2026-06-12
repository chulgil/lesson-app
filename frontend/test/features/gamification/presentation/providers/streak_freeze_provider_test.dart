import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/gamification/data/repositories/mock_streak_freeze_repository.dart';
import 'package:lessonaza/features/gamification/domain/repositories/streak_freeze_repository.dart';
import 'package:lessonaza/features/gamification/domain/services/streak_freeze_service.dart';
import 'package:lessonaza/features/gamification/presentation/providers/streak_freeze_provider.dart';

void main() {
  group('streakFreezeProvider — Job 4 Task 4.2', () {
    test('streakFreezeRepositoryProvider returns StreakFreezeRepository '
        'instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final repo = container.read(streakFreezeRepositoryProvider);
      expect(repo, isA<StreakFreezeRepository>());
      expect(repo, isA<MockStreakFreezeRepository>());
    });

    test('streakFreezeServiceProvider wires the repository', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final service = container.read(streakFreezeServiceProvider);
      expect(service, isA<StreakFreezeService>());
      expect(
        identical(
          service.repository,
          container.read(streakFreezeRepositoryProvider),
        ),
        isTrue,
        reason: 'service must use the same repository as the repo provider',
      );
    });

    test(
      'studentStreakFreezeProvider returns empty record for new student',
      () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final freeze = await container.read(
          studentStreakFreezeProvider('s1').future,
        );

        expect(freeze.studentId, 's1');
        expect(freeze.balance, 0);
        expect(freeze.usedAt, isEmpty);
        expect(freeze.examModeUntil, isNull);
        expect(freeze.lastGrantedAt, isNull);
      },
    );

    test(
      'studentStreakFreezeProvider reflects service grants when refetched',
      () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final service = container.read(streakFreezeServiceProvider);
        final now = DateTime.utc(2026, 6, 12);
        await service.weeklyGrantIfDue(studentId: 's1', now: now);

        // Re-read provider — must reflect persisted state from repository.
        container.invalidate(studentStreakFreezeProvider('s1'));
        final updated = await container.read(
          studentStreakFreezeProvider('s1').future,
        );

        expect(updated.balance, 2);
        expect(updated.lastGrantedAt, now);
      },
    );

    test('overriding repository injects test mock', () async {
      final overrideRepo = MockStreakFreezeRepository();
      await overrideRepo.grantWeekly('s1', amount: 4);

      final container = ProviderContainer(
        overrides: [
          streakFreezeRepositoryProvider.overrideWithValue(overrideRepo),
        ],
      );
      addTearDown(container.dispose);

      final freeze = await container.read(
        studentStreakFreezeProvider('s1').future,
      );
      expect(freeze.balance, 4);
    });

    test('repository + service are keepAlive (same instance across reads)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo1 = container.read(streakFreezeRepositoryProvider);
      final repo2 = container.read(streakFreezeRepositoryProvider);
      expect(identical(repo1, repo2), isTrue);

      final svc1 = container.read(streakFreezeServiceProvider);
      final svc2 = container.read(streakFreezeServiceProvider);
      expect(identical(svc1, svc2), isTrue);
    });
  });
}
