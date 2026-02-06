// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'grouped_students_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$groupedStudentsHash() => r'd3289654aafb4b253bb4af3f1b0f8252696efd17';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// Groups students by their LessonClass membership.
///
/// Copied from [groupedStudents].
@ProviderFor(groupedStudents)
const groupedStudentsProvider = GroupedStudentsFamily();

/// Groups students by their LessonClass membership.
///
/// Copied from [groupedStudents].
class GroupedStudentsFamily extends Family<AsyncValue<List<StudentGroup>>> {
  /// Groups students by their LessonClass membership.
  ///
  /// Copied from [groupedStudents].
  const GroupedStudentsFamily();

  /// Groups students by their LessonClass membership.
  ///
  /// Copied from [groupedStudents].
  GroupedStudentsProvider call(
    String teacherId,
  ) {
    return GroupedStudentsProvider(
      teacherId,
    );
  }

  @override
  GroupedStudentsProvider getProviderOverride(
    covariant GroupedStudentsProvider provider,
  ) {
    return call(
      provider.teacherId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'groupedStudentsProvider';
}

/// Groups students by their LessonClass membership.
///
/// Copied from [groupedStudents].
class GroupedStudentsProvider
    extends AutoDisposeFutureProvider<List<StudentGroup>> {
  /// Groups students by their LessonClass membership.
  ///
  /// Copied from [groupedStudents].
  GroupedStudentsProvider(
    String teacherId,
  ) : this._internal(
          (ref) => groupedStudents(
            ref as GroupedStudentsRef,
            teacherId,
          ),
          from: groupedStudentsProvider,
          name: r'groupedStudentsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$groupedStudentsHash,
          dependencies: GroupedStudentsFamily._dependencies,
          allTransitiveDependencies:
              GroupedStudentsFamily._allTransitiveDependencies,
          teacherId: teacherId,
        );

  GroupedStudentsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.teacherId,
  }) : super.internal();

  final String teacherId;

  @override
  Override overrideWith(
    FutureOr<List<StudentGroup>> Function(GroupedStudentsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: GroupedStudentsProvider._internal(
        (ref) => create(ref as GroupedStudentsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        teacherId: teacherId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<StudentGroup>> createElement() {
    return _GroupedStudentsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GroupedStudentsProvider && other.teacherId == teacherId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, teacherId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin GroupedStudentsRef on AutoDisposeFutureProviderRef<List<StudentGroup>> {
  /// The parameter `teacherId` of this provider.
  String get teacherId;
}

class _GroupedStudentsProviderElement
    extends AutoDisposeFutureProviderElement<List<StudentGroup>>
    with GroupedStudentsRef {
  _GroupedStudentsProviderElement(super.provider);

  @override
  String get teacherId => (origin as GroupedStudentsProvider).teacherId;
}

String _$filteredGroupedStudentsHash() =>
    r'b4f6bbc37042ba86965e0eb150a24f9fec9219ca';

/// Filtered grouped students - applies ClassTypeFilter and search query.
///
/// Copied from [filteredGroupedStudents].
@ProviderFor(filteredGroupedStudents)
const filteredGroupedStudentsProvider = FilteredGroupedStudentsFamily();

/// Filtered grouped students - applies ClassTypeFilter and search query.
///
/// Copied from [filteredGroupedStudents].
class FilteredGroupedStudentsFamily
    extends Family<AsyncValue<List<StudentGroup>>> {
  /// Filtered grouped students - applies ClassTypeFilter and search query.
  ///
  /// Copied from [filteredGroupedStudents].
  const FilteredGroupedStudentsFamily();

  /// Filtered grouped students - applies ClassTypeFilter and search query.
  ///
  /// Copied from [filteredGroupedStudents].
  FilteredGroupedStudentsProvider call(
    String teacherId,
  ) {
    return FilteredGroupedStudentsProvider(
      teacherId,
    );
  }

  @override
  FilteredGroupedStudentsProvider getProviderOverride(
    covariant FilteredGroupedStudentsProvider provider,
  ) {
    return call(
      provider.teacherId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'filteredGroupedStudentsProvider';
}

/// Filtered grouped students - applies ClassTypeFilter and search query.
///
/// Copied from [filteredGroupedStudents].
class FilteredGroupedStudentsProvider
    extends AutoDisposeFutureProvider<List<StudentGroup>> {
  /// Filtered grouped students - applies ClassTypeFilter and search query.
  ///
  /// Copied from [filteredGroupedStudents].
  FilteredGroupedStudentsProvider(
    String teacherId,
  ) : this._internal(
          (ref) => filteredGroupedStudents(
            ref as FilteredGroupedStudentsRef,
            teacherId,
          ),
          from: filteredGroupedStudentsProvider,
          name: r'filteredGroupedStudentsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$filteredGroupedStudentsHash,
          dependencies: FilteredGroupedStudentsFamily._dependencies,
          allTransitiveDependencies:
              FilteredGroupedStudentsFamily._allTransitiveDependencies,
          teacherId: teacherId,
        );

  FilteredGroupedStudentsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.teacherId,
  }) : super.internal();

  final String teacherId;

  @override
  Override overrideWith(
    FutureOr<List<StudentGroup>> Function(FilteredGroupedStudentsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: FilteredGroupedStudentsProvider._internal(
        (ref) => create(ref as FilteredGroupedStudentsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        teacherId: teacherId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<StudentGroup>> createElement() {
    return _FilteredGroupedStudentsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FilteredGroupedStudentsProvider &&
        other.teacherId == teacherId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, teacherId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin FilteredGroupedStudentsRef
    on AutoDisposeFutureProviderRef<List<StudentGroup>> {
  /// The parameter `teacherId` of this provider.
  String get teacherId;
}

class _FilteredGroupedStudentsProviderElement
    extends AutoDisposeFutureProviderElement<List<StudentGroup>>
    with FilteredGroupedStudentsRef {
  _FilteredGroupedStudentsProviderElement(super.provider);

  @override
  String get teacherId => (origin as FilteredGroupedStudentsProvider).teacherId;
}

String _$classTypeFilterNotifierHash() =>
    r'0fefa042fe6b773f9bd2b49450d351dc793d36af';

/// ClassTypeFilter state managed by Riverpod.
///
/// Copied from [ClassTypeFilterNotifier].
@ProviderFor(ClassTypeFilterNotifier)
final classTypeFilterNotifierProvider = AutoDisposeNotifierProvider<
    ClassTypeFilterNotifier, ClassTypeFilter>.internal(
  ClassTypeFilterNotifier.new,
  name: r'classTypeFilterNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$classTypeFilterNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ClassTypeFilterNotifier = AutoDisposeNotifier<ClassTypeFilter>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
