// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quest_first_shown_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$questFirstShownHash() => r'438f43f7b1a2de4ca4f2687f9c6653ded6746251';

/// 가입 직후 첫 도착 시점을 Hive 에 영속화하는 provider.
///
/// `markShown()` 호출 시 현재 시각을 ISO8601 으로 저장. 이후 5분 윈도우
/// 내 재진입 시 `isWithinFirstArrivalWindow == true` 가 되어 퀘스트 카드
/// 2초 표시 예외 적용.
///
/// SSOT: §13 퀘스트 시스템 — 가입 직후 첫 도착 (Signup First Arrival).
///
/// Copied from [QuestFirstShown].
@ProviderFor(QuestFirstShown)
final questFirstShownProvider =
    AutoDisposeAsyncNotifierProvider<QuestFirstShown, DateTime?>.internal(
  QuestFirstShown.new,
  name: r'questFirstShownProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$questFirstShownHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$QuestFirstShown = AutoDisposeAsyncNotifier<DateTime?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
