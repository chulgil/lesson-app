// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quest_bonus_shown_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$questBonusShownHash() => r'cd2d67d4a345396f54edf6c1868b9e6284af1fc6';

/// Q11 (전화인증, 보너스) 보너스 배지 1회 노출 영속 provider (W5 Task 5.2).
///
/// SSOT: `.harness/spec/2026-06-11-teacher-settings-redesign.md` §9.4
///
/// `quest_celebrated_at` 의 의미가 "Q1~Q10 (필수) 100% 완료 = 졸업" 으로
/// 재정의되었기 때문에, Q11 보너스 표시는 별도 영속 신호가 필요하다.
/// (glossary §1 — 졸업/보너스는 별개 개념).
///
/// `markShown()` 호출 시 true 로 영속. 이후 같은 사용자가 다시 진입해도
/// 보너스 배지 노출 1회 제어를 위해 호출 측이 값 확인.
///
/// Copied from [QuestBonusShown].
@ProviderFor(QuestBonusShown)
final questBonusShownProvider =
    AutoDisposeAsyncNotifierProvider<QuestBonusShown, bool>.internal(
  QuestBonusShown.new,
  name: r'questBonusShownProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$questBonusShownHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$QuestBonusShown = AutoDisposeAsyncNotifier<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
