// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vocab_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$vocabRepositoryHash() => r'0e77821cb1a3898386d5a5252cb8ed4548769791';

/// The vocabulary persistence layer for the logged-in user (#1124).
///
/// Local-first Hive (no backend yet). Watches [currentUserIdProvider] through the
/// auth facade (cross-feature = facade), so switching accounts rebuilds the repo
/// with a fresh user-scoped key and cascades every dependent provider.
///
/// Copied from [vocabRepository].
@ProviderFor(vocabRepository)
final vocabRepositoryProvider = Provider<VocabRepository>.internal(
  vocabRepository,
  name: r'vocabRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$vocabRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef VocabRepositoryRef = ProviderRef<VocabRepository>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
