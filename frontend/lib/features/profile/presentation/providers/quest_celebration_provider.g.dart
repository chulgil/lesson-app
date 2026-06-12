// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quest_celebration_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$questCelebrationHash() => r'00042b392665031e9f281ca4f8545ea65234b522';

/// 퀘스트 졸업 상태 + 1회성 보장 (§8.2 — W5 의미 재정의).
///
/// SSOT 우선순위:
/// 1. BE `User.quest_celebrated_at` (졸업 시점) — `markCelebrated()` /
///    `onRequiredCompleted()` PATCH 응답에서 캐시
/// 2. Hive `celebrated_at` (local cache, offline / 다음 진입 시 즉시 반영)
/// 3. Hive `celebrated_dismissed_at` (사용자 명시 dismiss)
///
/// 자동 트리거 흐름 (W5):
/// 1. `QuestBoardCard` 가 `allMandatoryQuestsCompletedProvider` listen
/// 2. true 전환 시 `onRequiredCompleted()` 호출
/// 3. BE PATCH → 응답의 questCelebratedAt 을 Hive 캐시 + state 반영
/// 4. 졸업 카드 7일간 노출, 이후 자동 hide
///
/// SSOT: `.harness/spec/2026-06-11-teacher-settings-redesign.md` §8.2 / §9.4
///
/// Copied from [QuestCelebration].
@ProviderFor(QuestCelebration)
final questCelebrationProvider = AutoDisposeAsyncNotifierProvider<
    QuestCelebration, QuestCelebrationState>.internal(
  QuestCelebration.new,
  name: r'questCelebrationProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$questCelebrationHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$QuestCelebration = AutoDisposeAsyncNotifier<QuestCelebrationState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
