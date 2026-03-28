// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tuner_combo_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$showComboHash() => r'71b01fe8f6e0659a35cf227dca2cab22b5a63e76';

/// Provider for whether combo should be shown.
///
/// Copied from [showCombo].
@ProviderFor(showCombo)
final showComboProvider = AutoDisposeProvider<bool>.internal(
  showCombo,
  name: r'showComboProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$showComboHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ShowComboRef = AutoDisposeProviderRef<bool>;
String _$comboMessageHash() => r'ddf606573e41c66e9675a762ed91a83f8e1a3928';

/// Provider for combo message (if any).
///
/// Copied from [comboMessage].
@ProviderFor(comboMessage)
final comboMessageProvider = AutoDisposeProvider<String?>.internal(
  comboMessage,
  name: r'comboMessageProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$comboMessageHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ComboMessageRef = AutoDisposeProviderRef<String?>;
String _$isCurtainFullyCoveredHash() =>
    r'13205d7a49eb3a1695a71cb89feede287bfba368';

/// Provider for whether the yellow curtain is fully covering the screen.
/// Returns true when perfect pitch has been maintained for 8+ seconds.
///
/// Copied from [isCurtainFullyCovered].
@ProviderFor(isCurtainFullyCovered)
final isCurtainFullyCoveredProvider = AutoDisposeProvider<bool>.internal(
  isCurtainFullyCovered,
  name: r'isCurtainFullyCoveredProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$isCurtainFullyCoveredHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef IsCurtainFullyCoveredRef = AutoDisposeProviderRef<bool>;
String _$tunerComboHash() => r'3c355b05f9991717cf0fbd6ad7078a1be4049f0b';

/// Combo counter and judgement management.
///
/// Copied from [TunerCombo].
@ProviderFor(TunerCombo)
final tunerComboProvider = NotifierProvider<TunerCombo, ComboState>.internal(
  TunerCombo.new,
  name: r'tunerComboProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$tunerComboHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$TunerCombo = Notifier<ComboState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
