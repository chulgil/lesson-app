// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tuner_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$currentNoteNameHash() => r'acda1400fbf92b98314684f5ba96d5e4d67c1e7a';

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

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TunerInfoDisplayRef = AutoDisposeProviderRef<String>;
String _$tunerHash() => r'a462946cdac569d1ad17fbf6a4b603f2c6a15796';

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
