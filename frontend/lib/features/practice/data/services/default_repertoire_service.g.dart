// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'default_repertoire_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$defaultRepertoireServiceHash() =>
    r'bf676997d5c51425118532a030da46889a4238ed';

/// Service that ensures the default repertoire and quick-record section exist.
///
/// This is used by the quick recording feature to provide a destination
/// for recordings when the user is not on a specific section screen.
///
/// Copied from [DefaultRepertoireService].
@ProviderFor(DefaultRepertoireService)
final defaultRepertoireServiceProvider =
    AsyncNotifierProvider<DefaultRepertoireService, void>.internal(
  DefaultRepertoireService.new,
  name: r'defaultRepertoireServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$defaultRepertoireServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$DefaultRepertoireService = AsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
