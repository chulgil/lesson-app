// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cancellation_defaults_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$cancellationDefaultsRepositoryHash() =>
    r'b32ab37528ff9c782db4ed2ac3b40e1f1a84f4df';

/// Repository provider for cancellation defaults
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
