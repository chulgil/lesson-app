// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bulk_teacher_action_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$bulkTeacherActionServiceHash() =>
    r'3c2f94856bf7b616d29e1d48152f8eec6fc931f8';

/// §7.119 v2 BulkTeacherActionService provider.
///
/// Injects [LessonRepository] + [NotificationService] + [UnifiedLessonRequestRepository]
/// + [SubscriptionRepository] so the selection mode bottom bar can fan out operations
/// across the selected students with chat event creation.
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
