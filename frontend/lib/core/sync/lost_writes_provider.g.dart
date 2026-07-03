// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lost_writes_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$lostWritesHash() => r'195075651d4cc4e2060b8e4e1765ecd5ea927125';

/// Surfaces silently-dropped unsent writes so the UI can tell the user, honoring
/// "no silent loss" (INV-3/INV-4). Fed by [SyncService] (cleanup expiry) and the
/// auth logout flow (queue clear); consumed by a global UI listener that shows a
/// notice and then calls [clear].
///
/// Copied from [LostWrites].
@ProviderFor(LostWrites)
final lostWritesProvider =
    NotifierProvider<LostWrites, LostWritesEvent?>.internal(
  LostWrites.new,
  name: r'lostWritesProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$lostWritesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$LostWrites = Notifier<LostWritesEvent?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
