import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lessonaza/features/subscription/data/repositories/mock_makeup_credit_repository.dart';
import 'package:lessonaza/features/subscription/presentation/providers/makeup_credit_providers.dart';

void main() {
  group('MakeupCreditActions.useOldestCredit (#928)', () {
    test('spends earliest-expiry credit and decrements the balance', () async {
      final repo = MockMakeupCreditRepository();
      final container = ProviderContainer(
        overrides: [makeupCreditRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      final before = await container.read(
        studentMakeupCreditBalanceProvider.future,
      );
      expect(before.hasAny, isTrue);
      final earliest = before.available.first;

      final spent = await container
          .read(makeupCreditActionsProvider)
          .useOldestCredit(lessonId: 'lesson-77');
      expect(spent, isTrue);

      final after = await container.read(
        studentMakeupCreditBalanceProvider.future,
      );
      expect(after.availableCount, before.availableCount - 1);
      expect(after.available.any((c) => c.id == earliest.id), isFalse);
    });

    test('returns false when the student has no available credit', () async {
      final repo = MockMakeupCreditRepository();
      // Drain all seeded spendable credits up front (deterministic empty state).
      final now = DateTime.now();
      final spendable =
          (await repo.listStudentCredits())
              .where((c) => !c.isUsed && !c.isExpired(now))
              .toList();
      for (final c in spendable) {
        await repo.useCredit(creditId: c.id, lessonId: 'pre-${c.id}');
      }

      final container = ProviderContainer(
        overrides: [makeupCreditRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      final spent = await container
          .read(makeupCreditActionsProvider)
          .useOldestCredit(lessonId: 'lesson-1');
      expect(spent, isFalse);
    });
  });
}
