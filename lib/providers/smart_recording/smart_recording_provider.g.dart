// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'smart_recording_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$smartRecordingSettingsNotifierHash() =>
    r'7fa7f4d5edcdd4624a534a809284e656fb2723b9';

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
    r'af85a1f60cb368cdaa1027860f5f214f3cc54586';

/// Provider for smart recording state during active recording.
///
/// Copied from [SmartRecordingNotifier].
@ProviderFor(SmartRecordingNotifier)
final smartRecordingNotifierProvider = AutoDisposeNotifierProvider<
    SmartRecordingNotifier, SmartRecordingState>.internal(
  SmartRecordingNotifier.new,
  name: r'smartRecordingNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$smartRecordingNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SmartRecordingNotifier = AutoDisposeNotifier<SmartRecordingState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
