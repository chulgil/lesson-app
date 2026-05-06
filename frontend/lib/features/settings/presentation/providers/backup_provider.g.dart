// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'backup_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$backupServiceHash() => r'c56e2190c30d5a8aecb70e2a899bdbe3b24d45dd';

/// Provider for BackupService singleton.
///
/// Copied from [backupService].
@ProviderFor(backupService)
final backupServiceProvider = Provider<BackupService>.internal(
  backupService,
  name: r'backupServiceProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$backupServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef BackupServiceRef = ProviderRef<BackupService>;
String _$backupListHash() => r'319ce6b47c2c021605edc0689b745a72a5660a1a';

/// List of available backup files.
///
/// Copied from [backupList].
@ProviderFor(backupList)
final backupListProvider = FutureProvider<List<BackupFileInfo>>.internal(
  backupList,
  name: r'backupListProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$backupListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef BackupListRef = FutureProviderRef<List<BackupFileInfo>>;
String _$backupStateNotifierHash() =>
    r'5d0171992e54ca24611c1d8b5fadfebc210a0f54';

/// Backup notifier for managing backup operations.
///
/// Copied from [BackupStateNotifier].
@ProviderFor(BackupStateNotifier)
final backupStateNotifierProvider =
    AsyncNotifierProvider<BackupStateNotifier, BackupState>.internal(
      BackupStateNotifier.new,
      name: r'backupStateNotifierProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$backupStateNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$BackupStateNotifier = AsyncNotifier<BackupState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
