// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$mockDataModeHash() => r'2b81ad6dd2ee6f76e054dc7ad6c7deef76d8b923';

/// App-wide data mode boundary.
///
/// UI/application code should read this provider instead of importing
/// [EnvironmentConfig] directly, so environment branching stays centralized.
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
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
