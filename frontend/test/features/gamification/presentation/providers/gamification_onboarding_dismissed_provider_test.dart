// Tests for the gamification onboarding dismiss flag (#81).
//
// 계약:
// - 저장소 미설정 학생은 dismissed=false (기본값).
// - markDismissed 후 isDismissed=true (영속).
// - FutureProvider.family 는 주입된 store 를 그대로 반영한다.
//
// 실제 Hive 영속 대신 in-memory fake 를 주입한다 (테스트 격리).
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/gamification/presentation/providers/gamification_onboarding_dismissed_provider.dart';

/// In-memory fake — set 으로 해제된 studentId 를 추적.
class FakeGamificationOnboardingDismissStore
    implements GamificationOnboardingDismissStore {
  final Set<String> dismissed;

  FakeGamificationOnboardingDismissStore({Set<String>? seed})
    : dismissed = seed ?? <String>{};

  @override
  Future<bool> isDismissed(String studentId) async =>
      dismissed.contains(studentId);

  @override
  Future<void> markDismissed(String studentId) async {
    dismissed.add(studentId);
  }
}

void main() {
  group('GamificationOnboardingDismissStore (fake) 계약', () {
    test('미설정 학생은 dismissed=false', () async {
      final store = FakeGamificationOnboardingDismissStore();
      expect(await store.isDismissed('student_1'), isFalse);
    });

    test('markDismissed 후 isDismissed=true', () async {
      final store = FakeGamificationOnboardingDismissStore();
      await store.markDismissed('student_1');
      expect(await store.isDismissed('student_1'), isTrue);
      // 다른 학생은 영향 없음 (user-scoped).
      expect(await store.isDismissed('student_2'), isFalse);
    });
  });

  group('gamificationOnboardingDismissedProvider', () {
    test('기본값 false', () async {
      final container = ProviderContainer(
        overrides: [
          gamificationOnboardingDismissStoreProvider.overrideWithValue(
            FakeGamificationOnboardingDismissStore(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final value = await container.read(
        gamificationOnboardingDismissedProvider('student_1').future,
      );
      expect(value, isFalse);
    });

    test('seed 된 학생은 true', () async {
      final container = ProviderContainer(
        overrides: [
          gamificationOnboardingDismissStoreProvider.overrideWithValue(
            FakeGamificationOnboardingDismissStore(seed: {'student_1'}),
          ),
        ],
      );
      addTearDown(container.dispose);

      final value = await container.read(
        gamificationOnboardingDismissedProvider('student_1').future,
      );
      expect(value, isTrue);
    });
  });
}
