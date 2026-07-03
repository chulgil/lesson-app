// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'revalidation_events_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$revalidationEventsHash() =>
    r'b6e9ac27de2dd4fd2aab86c5350cb129e5e7a14a';

/// Bus carrying stale-while-revalidate completion events.
///
/// The `ResponseCacheInterceptor` emits here (wired in `apiClient`) when a
/// background revalidation returned data that differs from the stale response a
/// caller was already served. Read providers opt in via
/// [RevalidationRefX.autoRevalidate] to refresh themselves live, so slow-network
/// users see the fresh data land without a manual pull-to-refresh.
///
/// Copied from [RevalidationEvents].
@ProviderFor(RevalidationEvents)
final revalidationEventsProvider =
    NotifierProvider<RevalidationEvents, RevalidationSignal?>.internal(
  RevalidationEvents.new,
  name: r'revalidationEventsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$revalidationEventsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$RevalidationEvents = Notifier<RevalidationSignal?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
