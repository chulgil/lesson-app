// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'practice_repertoire_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$practiceRepertoireRepositoryHash() =>
    r'8c59e60d2e0a4846dd2f9e9194b8b1ff09584ad0';

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
