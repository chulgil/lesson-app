// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_review_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$appReviewBoxHash() => r'83563027a656554467ed6d94f50950832eeb6d21';

/// Singleton Hive box for app review state.
/// Box opened in `app_bootstrap.dart` at startup.
///
/// Copied from [appReviewBox].
@ProviderFor(appReviewBox)
final appReviewBoxProvider = Provider<Box<String>>.internal(
  appReviewBox,
  name: r'appReviewBoxProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$appReviewBoxHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AppReviewBoxRef = ProviderRef<Box<String>>;
String _$appReviewStateRepositoryHash() =>
    r'03baaf23a2923d83083c960d94e2eeda2f17ab9e';

/// State repository (Hive-backed).
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
String _$appReviewClientHash() => r'36a7ac52f116c9f84f46ceb2d0be6e7bec65225a';

/// Native review client (in_app_review).
///
/// Copied from [appReviewClient].
@ProviderFor(appReviewClient)
final appReviewClientProvider = Provider<AppReviewClient>.internal(
  appReviewClient,
  name: r'appReviewClientProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$appReviewClientHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AppReviewClientRef = ProviderRef<AppReviewClient>;
String _$appReviewTriggerServiceHash() =>
    r'a3648bd1b4ee509253291df0d210c8ad2e6a4e13';

/// Trigger service — wraps state repo + review client.
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
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
