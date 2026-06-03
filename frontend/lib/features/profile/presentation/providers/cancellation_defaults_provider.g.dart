// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cancellation_defaults_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$cancellationDefaultsRepositoryHash() =>
    r'85fceb0a221a42feb25b5aea28150df5f8d2ed09';

/// Repository provider for cancellation defaults.
///
/// No backend endpoint exists yet, so remote mode persists locally
/// (user-scoped) instead of returning seeded mock data (#5 D-G3).
///
/// Copied from [cancellationDefaultsRepository].
@ProviderFor(cancellationDefaultsRepository)
final cancellationDefaultsRepositoryProvider =
    Provider<CancellationDefaultsRepository>.internal(
  cancellationDefaultsRepository,
  name: r'cancellationDefaultsRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$cancellationDefaultsRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef CancellationDefaultsRepositoryRef
    = ProviderRef<CancellationDefaultsRepository>;
String _$cancellationDefaultsNotifierHash() =>
    r'317365fdd45ad0730bb27a9134767fb56c5f4a39';

/// Async notifier provider for cancellation defaults
///
/// Copied from [CancellationDefaultsNotifier].
@ProviderFor(CancellationDefaultsNotifier)
final cancellationDefaultsNotifierProvider = AutoDisposeAsyncNotifierProvider<
    CancellationDefaultsNotifier, CancellationDefaults>.internal(
  CancellationDefaultsNotifier.new,
  name: r'cancellationDefaultsNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$cancellationDefaultsNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$CancellationDefaultsNotifier
    = AutoDisposeAsyncNotifier<CancellationDefaults>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
