// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$mockDataModeHash() => r'017c29aae60ceef81b473b56e853beff385119b2';

/// Convenience read-only alias for the current data mode.
///
/// UI code should watch this to show/hide mock-specific elements.
///
/// Copied from [mockDataMode].
@ProviderFor(mockDataMode)
final mockDataModeProvider = Provider<bool>.internal(
  mockDataMode,
  name: r'mockDataModeProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$mockDataModeHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef MockDataModeRef = ProviderRef<bool>;
String _$dataModeHash() => r'1a0f707a01b2678c23d19dba3b154a29f926d198';

/// Runtime data mode — determines mock vs remote repository selection.
///
/// Initial value comes from [EnvironmentConfig.useMockData] (compile-time default).
/// Changed at login time:
/// - DEV account login → `true` (mock repositories)
/// - Social login (Google/Kakao/Apple) → `false` (remote repositories)
///
/// All repository providers watch this via [createRepository] / [createSyncAwareRepository],
/// so changing this triggers automatic provider rebuilds.
///
/// Copied from [DataMode].
@ProviderFor(DataMode)
final dataModeProvider = NotifierProvider<DataMode, bool>.internal(
  DataMode.new,
  name: r'dataModeProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$dataModeHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$DataMode = Notifier<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
