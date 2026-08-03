// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cancellation_defaults_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$cancellationDefaultsRepositoryHash() =>
    r'52ec02512801d6c39f2661cfae779e3a12fd9039';

/// Repository provider for cancellation defaults.
///
/// Remote mode targets GET/PUT /settings/cancellation (#1178) — the server
/// row is what drives late-cancel compensation notifications.
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
    r'10cbc856f70f21ed8e34e53e7ebe4afd3bd54e6e';

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
