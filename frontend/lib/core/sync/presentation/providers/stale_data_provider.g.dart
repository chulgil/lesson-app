// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stale_data_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$lastServedFromCacheAtHash() =>
    r'9773f258e43be01111b8c8e0ac722aee24b544b6';

/// `cachedAt` of the most recently cache-served HTTP response (D2 배너 입력).
///
/// Written by the ResponseCacheInterceptor's `onCacheServed` callback (wired
/// in the apiClient provider); read by the offline banner to render
/// "마지막 동기화 HH:MM" while stale data is on screen. Null until the first
/// offline cache serve of the session.
///
/// Copied from [LastServedFromCacheAt].
@ProviderFor(LastServedFromCacheAt)
final lastServedFromCacheAtProvider =
    NotifierProvider<LastServedFromCacheAt, DateTime?>.internal(
  LastServedFromCacheAt.new,
  name: r'lastServedFromCacheAtProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$lastServedFromCacheAtHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$LastServedFromCacheAt = Notifier<DateTime?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
