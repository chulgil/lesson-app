// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quest_celebration_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$questCelebrationHash() => r'b7fac506c63e021678852295a6ffb0e450118da5';

/// 전체 완료 축하 카드의 1회성 보장 (§8.3) — Hive local fallback.
///
/// 우선순위:
/// 1. `AuthUser.questCelebratedAt` (BE 필드, SSOT) — null 이 아니면 표시 X
/// 2. Hive `celebrated_dismissed_at` (local, BE 엔드포인트 미완성 임시) — 값 있으면 표시 X
///
/// **TODO (Issue #608 BE 완료 후)**:
/// - `markCelebrated()` 가 BE `PATCH /users/me/quest-celebrated` 호출 + AuthUser invalidate
/// - Hive local fallback 은 BE 의존 제거 시 삭제 또는 유지 (offline 안전망)
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
