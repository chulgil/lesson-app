// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vocab_sets_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$vocabSetsHash() => r'82c49064a8b1b4e28080e0391ffd903f9f0f5505';

/// The current user's vocabulary sets, oldest first (#1124).
///
/// Copied from [vocabSets].
@ProviderFor(vocabSets)
final vocabSetsProvider = AutoDisposeFutureProvider<List<VocabSet>>.internal(
  vocabSets,
  name: r'vocabSetsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$vocabSetsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef VocabSetsRef = AutoDisposeFutureProviderRef<List<VocabSet>>;
String _$vocabSummaryHash() => r'33c90058b55e74f95426113357668217dbb9a04f';

/// Aggregate [VocabSummary] over every set (#1124). Recomputed on demand; the
/// panel autoDisposes it when the practice modal closes.
///
/// Copied from [vocabSummary].
@ProviderFor(vocabSummary)
final vocabSummaryProvider = AutoDisposeFutureProvider<VocabSummary>.internal(
  vocabSummary,
  name: r'vocabSummaryProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$vocabSummaryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef VocabSummaryRef = AutoDisposeFutureProviderRef<VocabSummary>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
