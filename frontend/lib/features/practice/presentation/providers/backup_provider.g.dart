// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'backup_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$backupServiceHash() => r'ba2c19315379c73e440f56177bc131c08331bac3';

/// Keep-alive [BackupService] instance.
///
/// Copied from [backupService].
@ProviderFor(backupService)
final backupServiceProvider = Provider<BackupService>.internal(
  backupService,
  name: r'backupServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$backupServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef BackupServiceRef = ProviderRef<BackupService>;
String _$backupProgressNotifierHash() =>
    r'f651962125f4fb149e3d98a50617618469f6b6fd';

/// Mutable progress feed driven by [BackupController].
///
/// Copied from [BackupProgressNotifier].
@ProviderFor(BackupProgressNotifier)
final backupProgressNotifierProvider = AutoDisposeNotifierProvider<
    BackupProgressNotifier, BackupProgress>.internal(
  BackupProgressNotifier.new,
  name: r'backupProgressNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$backupProgressNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$BackupProgressNotifier = AutoDisposeNotifier<BackupProgress>;
String _$backupControllerHash() => r'ba03eba964b42ed46c8dd7da4e62d8d0f2a625b0';

/// Orchestrates create/restore operations and pumps [BackupProgressNotifier].
///
/// The controller is itself a `Notifier<BackupProgress>` so that screens can
/// `ref.watch` it for state changes and `ref.read(...notifier).export()` to
/// trigger an operation.
///
/// Copied from [BackupController].
@ProviderFor(BackupController)
final backupControllerProvider =
    AutoDisposeNotifierProvider<BackupController, BackupProgress>.internal(
  BackupController.new,
  name: r'backupControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$backupControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$BackupController = AutoDisposeNotifier<BackupProgress>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
