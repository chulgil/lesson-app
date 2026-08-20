// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'starter_sample_storage_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$starterSampleStorageHash() =>
    r'c5babc3736a7a286939ae024fbd9a9e84e91e7a9';

/// Remembers which rows the starter sample walkthrough created (UXB-1).
///
/// User-scoped, like [OnboardingProgressStorage]: two teachers on one device
/// must not clean up each other's sample. If the box is wiped the sample keeps
/// working as an ordinary manual student — the teacher just deletes it by hand
/// instead of by the one-tap CTA.
///
/// Copied from [StarterSampleStorage].
@ProviderFor(StarterSampleStorage)
final starterSampleStorageProvider =
    AsyncNotifierProvider<StarterSampleStorage, StarterSampleData?>.internal(
  StarterSampleStorage.new,
  name: r'starterSampleStorageProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$starterSampleStorageHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$StarterSampleStorage = AsyncNotifier<StarterSampleData?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
