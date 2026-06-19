// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connectivity_banner_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$offlineBannerHash() => r'dcfd77737d7eae68b2cc837ffc2593396bfdcd7d';

/// Streams the current offline state for the global banner.
///
/// Emits `true` when the device is offline, `false` when online or unknown.
/// keepAlive so the stream subscription lives for the app lifetime.
///
/// Copied from [offlineBanner].
@ProviderFor(offlineBanner)
final offlineBannerProvider = StreamProvider<bool>.internal(
  offlineBanner,
  name: r'offlineBannerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$offlineBannerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef OfflineBannerRef = StreamProviderRef<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
