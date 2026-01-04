// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tuner_combo_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$showComboHash() => r'35ce2551d9cfe6d0251758f565123a0904318c30';

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

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ShowComboRef = AutoDisposeProviderRef<bool>;
String _$comboMessageHash() => r'05fcc66da4005231f3ffcc3e5e0a446822481d8f';

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

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ComboMessageRef = AutoDisposeProviderRef<String?>;
String _$tunerComboHash() => r'43117a068235ca98542a7d737a6a5a5672f58cb1';

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
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
