// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tuner_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$currentDisplayNoteHash() =>
    r'd9f03f6366a8d41c36391d1ae0e25dda6aadb785';

/// Provider for current note display name.
///
/// Copied from [currentDisplayNote].
@ProviderFor(currentDisplayNote)
final currentDisplayNoteProvider =
    AutoDisposeProvider<TunerDisplayNote?>.internal(
  currentDisplayNote,
  name: r'currentDisplayNoteProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentDisplayNoteHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef CurrentDisplayNoteRef = AutoDisposeProviderRef<TunerDisplayNote?>;
String _$currentNoteNameHash() => r'21e776737dc0fab6ad171ed128f59f4da87f15dd';

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

typedef CurrentNoteNameRef = AutoDisposeProviderRef<String?>;
String _$tunerInfoDisplayHash() => r'3d9b0ed8e1803a35868caf81f18a094c26b295a7';

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

typedef TunerInfoDisplayRef = AutoDisposeProviderRef<String>;
String _$tunerHash() => r'45599d6116674a08e24edfdf860066fe3c4c7aad';

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
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
