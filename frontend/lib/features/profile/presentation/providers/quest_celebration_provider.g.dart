// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quest_celebration_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$questCelebrationHash() => r'367ab2569fe352b9e36867e088173292735ce30e';

/// 전체 완료 축하 카드의 1회성 보장 (§8.3) — BE SSOT + Hive offline fallback.
///
/// 우선순위:
/// 1. BE `User.quest_celebrated_at` (SSOT) — `markCelebrated()` 가 PATCH 호출
/// 2. Hive `celebrated_dismissed_at` (local fallback, offline / 네트워크 실패 시)
///
/// `build()` 가 반환하는 `DateTime?`:
/// - null = 아직 dismiss 안 됨 → 축하 카드 표시
/// - DateTime = 이미 dismiss 됨 → 축하 카드 숨김
///
/// SSOT: `.harness/spec/2026-06-08-teacher-quest-system.md` §8.3
///
/// Copied from [QuestCelebration].
@ProviderFor(QuestCelebration)
final questCelebrationProvider =
    AutoDisposeAsyncNotifierProvider<QuestCelebration, DateTime?>.internal(
  QuestCelebration.new,
  name: r'questCelebrationProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$questCelebrationHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$QuestCelebration = AutoDisposeAsyncNotifier<DateTime?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
