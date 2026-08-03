// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'active_discipline_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$activeDisciplineHash() => r'02f6e2a74a4270b39412ee7baf23b1bd42c3c559';

/// The active coaching discipline for the logged-in user (#979-A).
///
/// Resolves the persisted [SelectedDisciplineStorage] id through
/// [DisciplineRegistry], falling back to music for null / legacy / unknown ids
/// (including while the async storage is still loading). Music-only today, so
/// this always resolves to music = byte-identical; it is the seam the practice
/// tools modal reads to pick a discipline's tool set.
///
/// Copied from [activeDiscipline].
@ProviderFor(activeDiscipline)
final activeDisciplineProvider = AutoDisposeProvider<Discipline>.internal(
  activeDiscipline,
  name: r'activeDisciplineProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$activeDisciplineHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ActiveDisciplineRef = AutoDisposeProviderRef<Discipline>;
String _$selectedDisciplineStorageHash() =>
    r'5a4a13aaee7812a4e8c02cb2f156473b80cc8eee';

/// Persists the coaching discipline the user chose at sign-up (#979-A, Phase 4).
///
/// User-scoped (mirrors `OnboardingProgressStorage`): the Hive key carries the
/// current user id, so choices never cross-contaminate between accounts. With
/// music as the only registered discipline the selection screen auto-skips, so
/// nothing is persisted yet and [build] returns null — [activeDiscipline] then
/// falls back to music (byte-identical). Phase 4 (#979-B) registers a 2nd
/// discipline, the selection screen goes live, and this stores the choice.
///
/// Copied from [SelectedDisciplineStorage].
@ProviderFor(SelectedDisciplineStorage)
final selectedDisciplineStorageProvider =
    AsyncNotifierProvider<SelectedDisciplineStorage, String?>.internal(
  SelectedDisciplineStorage.new,
  name: r'selectedDisciplineStorageProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$selectedDisciplineStorageHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SelectedDisciplineStorage = AsyncNotifier<String?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
