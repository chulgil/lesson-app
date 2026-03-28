// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'metronome_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$metronomeHash() => r'06216ddccc0d7eee8de6e00f7fe6912703ab2bd8';

/// Metronome state management with Riverpod.
///
/// Uses flutter_soloud (C++ SoLoud via FFI) for low-latency native audio
/// on all platforms (iOS, Android, Mac, Windows, Linux, Web).
///
/// Copied from [Metronome].
@ProviderFor(Metronome)
final metronomeProvider = NotifierProvider<Metronome, MetronomeState>.internal(
  Metronome.new,
  name: r'metronomeProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$metronomeHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Metronome = Notifier<MetronomeState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
