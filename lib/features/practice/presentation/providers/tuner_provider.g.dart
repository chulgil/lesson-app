// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tuner_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$currentNoteNameHash() => r'b8464364a057b25c712d3471d88c4305314e85db';

/// Provider for current note display name.
///
/// Copied from [currentNoteName].
@ProviderFor(currentNoteName)
final currentNoteNameProvider = AutoDisposeProvider<String?>.internal(
  currentNoteName,
  name: r'currentNoteNameProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentNoteNameHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentNoteNameRef = AutoDisposeProviderRef<String?>;
String _$tunerInfoDisplayHash() => r'bab37f5e37919d8eb57fcebbb3c16b561ec4d425';

/// Provider for tuner info display string (e.g., "A4 · 442Hz · +5¢").
///
/// Copied from [tunerInfoDisplay].
@ProviderFor(tunerInfoDisplay)
final tunerInfoDisplayProvider = AutoDisposeProvider<String>.internal(
  tunerInfoDisplay,
  name: r'tunerInfoDisplayProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$tunerInfoDisplayHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TunerInfoDisplayRef = AutoDisposeProviderRef<String>;
String _$tunerHash() => r'30bce4b534d4bc12d6a554d9e403d0db68fe33ac';

/// Tuner state management with Riverpod.
///
/// Provides pitch detection using the device microphone.
/// Supports both MockTunerEngine (for development) and PitchTunerEngine (real detection).
///
/// Copied from [Tuner].
@ProviderFor(Tuner)
final tunerProvider = NotifierProvider<Tuner, TunerProviderState>.internal(
  Tuner.new,
  name: r'tunerProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$tunerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Tuner = Notifier<TunerProviderState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
