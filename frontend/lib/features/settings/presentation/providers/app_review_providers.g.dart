// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_review_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$appReviewBoxHash() => r'd60afacf5e87f73a5867bf8f300b514e638b8885';

/// Opens (or returns) the Hive box used for [AppReviewState] storage.
///
/// Copied from [appReviewBox].
@ProviderFor(appReviewBox)
final appReviewBoxProvider = FutureProvider<Box<String>>.internal(
  appReviewBox,
  name: r'appReviewBoxProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$appReviewBoxHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AppReviewBoxRef = FutureProviderRef<Box<String>>;
String _$appReviewStateRepositoryHash() =>
    r'2f8abddf5fd91e102029f5ff0fcad998fe615517';

/// [AppReviewStateRepository] backed by Hive.
///
/// Copied from [appReviewStateRepository].
@ProviderFor(appReviewStateRepository)
final appReviewStateRepositoryProvider =
    Provider<AppReviewStateRepository>.internal(
  appReviewStateRepository,
  name: r'appReviewStateRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$appReviewStateRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AppReviewStateRepositoryRef = ProviderRef<AppReviewStateRepository>;
String _$appReviewClientInstanceHash() =>
    r'cd6335a957ef5ef9374c3bf5fff7614878eb1be6';

/// [AppReviewClient] — uses the existing [LocalAppReviewClient].
///
/// Copied from [appReviewClientInstance].
@ProviderFor(appReviewClientInstance)
final appReviewClientInstanceProvider = Provider<AppReviewClient>.internal(
  appReviewClientInstance,
  name: r'appReviewClientInstanceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$appReviewClientInstanceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AppReviewClientInstanceRef = ProviderRef<AppReviewClient>;
String _$appReviewTriggerServiceHash() =>
    r'f7eed502a14ce6f44c4eaec27f682adc808f5ebb';

/// [AppReviewTriggerService] wired with repository and client.
///
/// Copied from [appReviewTriggerService].
@ProviderFor(appReviewTriggerService)
final appReviewTriggerServiceProvider =
    Provider<AppReviewTriggerService>.internal(
  appReviewTriggerService,
  name: r'appReviewTriggerServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$appReviewTriggerServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AppReviewTriggerServiceRef = ProviderRef<AppReviewTriggerService>;
String _$appReviewStateHash() => r'50ccdd3c42efdc2a306f4d9ef9af36a958f29042';

/// Current [AppReviewState] — invalidate after any state mutation.
///
/// Copied from [appReviewState].
@ProviderFor(appReviewState)
final appReviewStateProvider =
    AutoDisposeFutureProvider<AppReviewState>.internal(
  appReviewState,
  name: r'appReviewStateProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$appReviewStateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AppReviewStateRef = AutoDisposeFutureProviderRef<AppReviewState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
