// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bulk_teacher_action_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$bulkTeacherActionServiceHash() =>
    r'39ad182151d5e1c66682d040fc5828611e567bf7';

/// §7.119 BulkTeacherActionService provider.
///
/// Injects [LessonRepository] + [NotificationService] so the selection mode
/// bottom bar ([BulkCancelScreen] / [BulkMessageSheet]) can fan out operations
/// across the selected students.
///
/// Copied from [bulkTeacherActionService].
@ProviderFor(bulkTeacherActionService)
final bulkTeacherActionServiceProvider =
    AutoDisposeProvider<BulkTeacherActionService>.internal(
  bulkTeacherActionService,
  name: r'bulkTeacherActionServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$bulkTeacherActionServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef BulkTeacherActionServiceRef
    = AutoDisposeProviderRef<BulkTeacherActionService>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
