// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vocab_library_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$vocabLibraryHash() => r'b79852dcfeffca1a49ef6412ac481e9f246fb862';

/// Imperative write API for vocabulary sets and cards (#1124).
///
/// The single mutation entry point: every create / edit / delete persists
/// through the repository and then invalidates the affected read providers, so
/// lists and due badges refresh without callers wiring invalidation themselves
/// (write → read invalidation).
///
/// Copied from [VocabLibrary].
@ProviderFor(VocabLibrary)
final vocabLibraryProvider =
    AutoDisposeNotifierProvider<VocabLibrary, void>.internal(
  VocabLibrary.new,
  name: r'vocabLibraryProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$vocabLibraryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$VocabLibrary = AutoDisposeNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
