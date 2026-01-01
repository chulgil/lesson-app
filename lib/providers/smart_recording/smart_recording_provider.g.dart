// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'smart_recording_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$smartRecordingSettingsNotifierHash() =>
    r'9908595edccaa3a531307dc616192b938efa8ca0';

/// Provider for smart recording settings persistence.
///
/// Copied from [SmartRecordingSettingsNotifier].
@ProviderFor(SmartRecordingSettingsNotifier)
final smartRecordingSettingsNotifierProvider = AutoDisposeNotifierProvider<
    SmartRecordingSettingsNotifier, SmartRecordingSettings>.internal(
  SmartRecordingSettingsNotifier.new,
  name: r'smartRecordingSettingsNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$smartRecordingSettingsNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SmartRecordingSettingsNotifier
    = AutoDisposeNotifier<SmartRecordingSettings>;
String _$smartRecordingNotifierHash() =>
    r'4c6734aa70a4499ceaa4430484997dbbcf485da2';

/// Provider for smart recording state during active recording.
/// keepAlive: true to prevent disposal during recording session.
///
/// Copied from [SmartRecordingNotifier].
@ProviderFor(SmartRecordingNotifier)
final smartRecordingNotifierProvider =
    NotifierProvider<SmartRecordingNotifier, SmartRecordingState>.internal(
  SmartRecordingNotifier.new,
  name: r'smartRecordingNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$smartRecordingNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SmartRecordingNotifier = Notifier<SmartRecordingState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
