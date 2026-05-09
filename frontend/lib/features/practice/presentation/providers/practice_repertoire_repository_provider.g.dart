// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'practice_repertoire_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$practiceRepertoireRepositoryHash() =>
    r'a6a466ba28b73cd3ca2e7620a326cbb3a7c024ba';

/// Practice repertoire repository provider - switches between Mock and Remote.
///
/// Copied from [practiceRepertoireRepository].
@ProviderFor(practiceRepertoireRepository)
final practiceRepertoireRepositoryProvider =
    Provider<PracticeRepertoireRepository>.internal(
  practiceRepertoireRepository,
  name: r'practiceRepertoireRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$practiceRepertoireRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef PracticeRepertoireRepositoryRef
    = ProviderRef<PracticeRepertoireRepository>;
String _$defaultRepertoireServiceHash() =>
    r'9198a7fc6fc4c74dadbefacc4daccc08e1d2fb36';

/// See also [defaultRepertoireService].
@ProviderFor(defaultRepertoireService)
final defaultRepertoireServiceProvider = FutureProvider<void>.internal(
  defaultRepertoireService,
  name: r'defaultRepertoireServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$defaultRepertoireServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef DefaultRepertoireServiceRef = FutureProviderRef<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
