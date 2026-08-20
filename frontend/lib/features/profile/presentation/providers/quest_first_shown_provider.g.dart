// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quest_first_shown_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$questFirstShownHash() => r'88f94047237ad016b44674df8a2ba6afb6f30891';

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
String _$nextMissionSpotlightDismissedHash() =>
    r'ed697d81671c790dbc87d3ef8fd6d917509b2db1';

/// NextMissionSpotlight 소거 여부를 영속화하는 provider (UXC-2).
///
/// [QuestFirstShown] 의 타임스탬프와 분리된 별개의 플래그다. 첫 도착 기록은
/// home 진입 즉시(post-frame) 남고 QuestBoardCard 의 5분 윈도우가 그 값을
/// 쓰기 때문에, spotlight 노출 조건까지 같은 값에 묶어 두면 기록되는 순간
/// spotlight 가 사라진다 (플래시 또는 미노출). 이 플래그는 사용자가
/// [시작]/[나중에] 를 실제로 탭했을 때만 true 가 된다.
///
/// Copied from [NextMissionSpotlightDismissed].
@ProviderFor(NextMissionSpotlightDismissed)
final nextMissionSpotlightDismissedProvider = AutoDisposeAsyncNotifierProvider<
    NextMissionSpotlightDismissed, bool>.internal(
  NextMissionSpotlightDismissed.new,
  name: r'nextMissionSpotlightDismissedProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$nextMissionSpotlightDismissedHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$NextMissionSpotlightDismissed = AutoDisposeAsyncNotifier<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
