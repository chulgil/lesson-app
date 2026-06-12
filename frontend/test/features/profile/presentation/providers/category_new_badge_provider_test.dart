// Tests for category_new_badge_provider (W6 Task 6.2).
//
// Spec: .harness/spec/2026-06-11-teacher-settings-redesign.md §10.2
//   - 새 5묶음 카테고리 카드에 NEW 점 7일 표시
//   - 한 번 진입 시 해당 카드만 dismiss
//   - 7일 경과 자동 dismiss
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lessonaza/core/constants/durations.dart';
import 'package:lessonaza/features/profile/presentation/providers/category_new_badge_provider.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'lessonaza_category_new_badge_test_',
    );
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    return container;
  }

  group('categoryNewBadgeProvider — W6 NEW 배지 (Task 6.2)', () {
    test('새 카테고리 7일 윈도우 내 — NEW 표시', () async {
      final container = makeContainer();
      final notifier = container.read(categoryNewBadgeProvider.notifier);
      await container.read(categoryNewBadgeProvider.future);

      final introducedAt = DateTime(2026, 6, 12);
      await notifier.markCategoryIntroduced(
        ProfileCategoryId.operatingHours,
        introducedAt,
      );

      final state = container.read(categoryNewBadgeProvider).requireValue;
      // 윈도우 시작 시점 + 1일 경과 — 표시 유지
      expect(
        state.shouldShowNew(
          ProfileCategoryId.operatingHours,
          introducedAt.add(const Duration(days: 1)),
        ),
        isTrue,
      );
    });

    test('7일(+1) 경과 후 자동 dismiss', () async {
      final container = makeContainer();
      final notifier = container.read(categoryNewBadgeProvider.notifier);
      await container.read(categoryNewBadgeProvider.future);

      final introducedAt = DateTime(2026, 6, 12);
      await notifier.markCategoryIntroduced(
        ProfileCategoryId.operatingHours,
        introducedAt,
      );

      final state = container.read(categoryNewBadgeProvider).requireValue;
      final beyond = introducedAt.add(
        kCategoryNewBadgeWindow + const Duration(days: 1),
      );
      expect(
        state.shouldShowNew(ProfileCategoryId.operatingHours, beyond),
        isFalse,
      );
    });

    test('한 번 진입 시 해당 카드만 dismiss — 다른 카드 NEW 유지', () async {
      final container = makeContainer();
      final notifier = container.read(categoryNewBadgeProvider.notifier);
      await container.read(categoryNewBadgeProvider.future);

      final introducedAt = DateTime(2026, 6, 12);
      await notifier.markCategoryIntroduced(
        ProfileCategoryId.operatingHours,
        introducedAt,
      );
      await notifier.markCategoryIntroduced(
        ProfileCategoryId.lessonStyle,
        introducedAt,
      );

      await notifier.markEntered(ProfileCategoryId.operatingHours);

      final state = container.read(categoryNewBadgeProvider).requireValue;
      final now = introducedAt.add(const Duration(days: 1));
      expect(
        state.shouldShowNew(ProfileCategoryId.operatingHours, now),
        isFalse,
      );
      expect(state.shouldShowNew(ProfileCategoryId.lessonStyle, now), isTrue);
    });

    test('markCategoryIntroduced 멱등 — 이미 기록된 시점은 재호출해도 덮어쓰지 않음', () async {
      final container = makeContainer();
      final notifier = container.read(categoryNewBadgeProvider.notifier);
      await container.read(categoryNewBadgeProvider.future);

      final firstSeen = DateTime(2026, 6, 12);
      await notifier.markCategoryIntroduced(
        ProfileCategoryId.operatingHours,
        firstSeen,
      );

      // 6일 뒤 다시 호출해도 firstSeen 유지 → 7일 dismiss 카운트 그대로
      final laterCallTime = firstSeen.add(const Duration(days: 6));
      await notifier.markCategoryIntroduced(
        ProfileCategoryId.operatingHours,
        laterCallTime,
      );

      final state = container.read(categoryNewBadgeProvider).requireValue;
      // firstSeen + 8d 경과 시점 = laterCallTime 기준 2일만 경과인데
      // firstSeen 보존이므로 표시 종료
      final afterWindowFromFirst = firstSeen.add(
        kCategoryNewBadgeWindow + const Duration(days: 1),
      );
      expect(
        state.shouldShowNew(
          ProfileCategoryId.operatingHours,
          afterWindowFromFirst,
        ),
        isFalse,
      );
    });

    test('introducedAt 미기록 카테고리 — NEW 미표시', () async {
      final container = makeContainer();
      await container.read(categoryNewBadgeProvider.future);

      final state = container.read(categoryNewBadgeProvider).requireValue;
      expect(
        state.shouldShowNew(
          ProfileCategoryId.policyNotifications,
          DateTime(2026, 6, 12),
        ),
        isFalse,
      );
    });

    test('Hive 영속 — 재오픈 후에도 introducedAt/entered 유지', () async {
      // 1st container
      {
        final container = makeContainer();
        final notifier = container.read(categoryNewBadgeProvider.notifier);
        await container.read(categoryNewBadgeProvider.future);
        await notifier.markCategoryIntroduced(
          ProfileCategoryId.lessonStyle,
          DateTime(2026, 6, 12),
        );
        await notifier.markEntered(ProfileCategoryId.lessonStyle);
      }

      // 2nd container (재오픈) — 같은 Hive 경로 공유
      final container = makeContainer();
      await container.read(categoryNewBadgeProvider.future);
      final state = container.read(categoryNewBadgeProvider).requireValue;
      expect(
        state.shouldShowNew(
          ProfileCategoryId.lessonStyle,
          DateTime(2026, 6, 13),
        ),
        isFalse,
      );
    });
  });
}
