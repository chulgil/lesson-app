// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'starter_sample_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$starterSampleDataServiceHash() =>
    r'e0305c4152a3481084b531fc7bb9685d203c8f1b';

/// See also [starterSampleDataService].
@ProviderFor(starterSampleDataService)
final starterSampleDataServiceProvider =
    Provider<StarterSampleDataService>.internal(
  starterSampleDataService,
  name: r'starterSampleDataServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$starterSampleDataServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef StarterSampleDataServiceRef = ProviderRef<StarterSampleDataService>;
String _$starterSampleCleanupVisibleHash() =>
    r'b1669f04e6bbc7c04b79557a48e66593f707e362';

/// True once the sample exists alongside at least one real student — the point
/// where the sample stops being scaffolding and starts being clutter.
///
/// Copied from [starterSampleCleanupVisible].
@ProviderFor(starterSampleCleanupVisible)
final starterSampleCleanupVisibleProvider =
    AutoDisposeFutureProvider<bool>.internal(
  starterSampleCleanupVisible,
  name: r'starterSampleCleanupVisibleProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$starterSampleCleanupVisibleHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef StarterSampleCleanupVisibleRef = AutoDisposeFutureProviderRef<bool>;
String _$starterSampleOfferVisibleHash() =>
    r'e03054c0b86ce218938f4a6427725ce269bde8e0';

/// True while the teacher has no students and has not run the walkthrough yet.
///
/// Copied from [starterSampleOfferVisible].
@ProviderFor(starterSampleOfferVisible)
final starterSampleOfferVisibleProvider =
    AutoDisposeFutureProvider<bool>.internal(
  starterSampleOfferVisible,
  name: r'starterSampleOfferVisibleProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$starterSampleOfferVisibleHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef StarterSampleOfferVisibleRef = AutoDisposeFutureProviderRef<bool>;
String _$starterSampleControllerHash() =>
    r'f31a673918f05be4f11db3183cf326e9c16dd3a9';

/// Drives the opt-in walkthrough (UXB-1).
///
/// Nothing runs without an explicit tap. The [AsyncValue] state carries only
/// progress — loading while the rows are being written, error when the write
/// failed — while the returned [StarterSampleOutcome] tells the caller which
/// message to show.
///
/// Copied from [StarterSampleController].
@ProviderFor(StarterSampleController)
final starterSampleControllerProvider =
    AutoDisposeAsyncNotifierProvider<StarterSampleController, void>.internal(
  StarterSampleController.new,
  name: r'starterSampleControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$starterSampleControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$StarterSampleController = AutoDisposeAsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
