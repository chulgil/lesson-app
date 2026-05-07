// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'teaching_resource_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$teachingResourceRepositoryHash() =>
    r'73f20de1c40e6e2859564fabd1a266de67358af1';

/// Repository provider
///
/// Copied from [teachingResourceRepository].
@ProviderFor(teachingResourceRepository)
final teachingResourceRepositoryProvider =
    Provider<TeachingResourceRepository>.internal(
      teachingResourceRepository,
      name: r'teachingResourceRepositoryProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$teachingResourceRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef TeachingResourceRepositoryRef = ProviderRef<TeachingResourceRepository>;
String _$teacherResourcesHash() => r'059a8403031564ff5a14a121aaa6528cbefb7d9c';

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

/// All resources for current teacher
///
/// Copied from [teacherResources].
@ProviderFor(teacherResources)
const teacherResourcesProvider = TeacherResourcesFamily();

/// All resources for current teacher
///
/// Copied from [teacherResources].
class TeacherResourcesFamily
    extends Family<AsyncValue<List<TeachingResource>>> {
  /// All resources for current teacher
  ///
  /// Copied from [teacherResources].
  const TeacherResourcesFamily();

  /// All resources for current teacher
  ///
  /// Copied from [teacherResources].
  TeacherResourcesProvider call(String teacherId) {
    return TeacherResourcesProvider(teacherId);
  }

  @override
  TeacherResourcesProvider getProviderOverride(
    covariant TeacherResourcesProvider provider,
  ) {
    return call(provider.teacherId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'teacherResourcesProvider';
}

/// All resources for current teacher
///
/// Copied from [teacherResources].
class TeacherResourcesProvider extends FutureProvider<List<TeachingResource>> {
  /// All resources for current teacher
  ///
  /// Copied from [teacherResources].
  TeacherResourcesProvider(String teacherId)
    : this._internal(
        (ref) => teacherResources(ref as TeacherResourcesRef, teacherId),
        from: teacherResourcesProvider,
        name: r'teacherResourcesProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$teacherResourcesHash,
        dependencies: TeacherResourcesFamily._dependencies,
        allTransitiveDependencies:
            TeacherResourcesFamily._allTransitiveDependencies,
        teacherId: teacherId,
      );

  TeacherResourcesProvider._internal(
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
    FutureOr<List<TeachingResource>> Function(TeacherResourcesRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TeacherResourcesProvider._internal(
        (ref) => create(ref as TeacherResourcesRef),
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
  FutureProviderElement<List<TeachingResource>> createElement() {
    return _TeacherResourcesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TeacherResourcesProvider && other.teacherId == teacherId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, teacherId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin TeacherResourcesRef on FutureProviderRef<List<TeachingResource>> {
  /// The parameter `teacherId` of this provider.
  String get teacherId;
}

class _TeacherResourcesProviderElement
    extends FutureProviderElement<List<TeachingResource>>
    with TeacherResourcesRef {
  _TeacherResourcesProviderElement(super.provider);

  @override
  String get teacherId => (origin as TeacherResourcesProvider).teacherId;
}

String _$resourcesByIdsHash() => r'c8c48a49f18b60dd67e40a8d35366c653b02c9ea';

/// Resources by IDs (for displaying attached resources on practice items)
///
/// Copied from [resourcesByIds].
@ProviderFor(resourcesByIds)
const resourcesByIdsProvider = ResourcesByIdsFamily();

/// Resources by IDs (for displaying attached resources on practice items)
///
/// Copied from [resourcesByIds].
class ResourcesByIdsFamily extends Family<AsyncValue<List<TeachingResource>>> {
  /// Resources by IDs (for displaying attached resources on practice items)
  ///
  /// Copied from [resourcesByIds].
  const ResourcesByIdsFamily();

  /// Resources by IDs (for displaying attached resources on practice items)
  ///
  /// Copied from [resourcesByIds].
  ResourcesByIdsProvider call(List<String> ids) {
    return ResourcesByIdsProvider(ids);
  }

  @override
  ResourcesByIdsProvider getProviderOverride(
    covariant ResourcesByIdsProvider provider,
  ) {
    return call(provider.ids);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'resourcesByIdsProvider';
}

/// Resources by IDs (for displaying attached resources on practice items)
///
/// Copied from [resourcesByIds].
class ResourcesByIdsProvider extends FutureProvider<List<TeachingResource>> {
  /// Resources by IDs (for displaying attached resources on practice items)
  ///
  /// Copied from [resourcesByIds].
  ResourcesByIdsProvider(List<String> ids)
    : this._internal(
        (ref) => resourcesByIds(ref as ResourcesByIdsRef, ids),
        from: resourcesByIdsProvider,
        name: r'resourcesByIdsProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$resourcesByIdsHash,
        dependencies: ResourcesByIdsFamily._dependencies,
        allTransitiveDependencies:
            ResourcesByIdsFamily._allTransitiveDependencies,
        ids: ids,
      );

  ResourcesByIdsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.ids,
  }) : super.internal();

  final List<String> ids;

  @override
  Override overrideWith(
    FutureOr<List<TeachingResource>> Function(ResourcesByIdsRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ResourcesByIdsProvider._internal(
        (ref) => create(ref as ResourcesByIdsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        ids: ids,
      ),
    );
  }

  @override
  FutureProviderElement<List<TeachingResource>> createElement() {
    return _ResourcesByIdsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ResourcesByIdsProvider && other.ids == ids;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, ids.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin ResourcesByIdsRef on FutureProviderRef<List<TeachingResource>> {
  /// The parameter `ids` of this provider.
  List<String> get ids;
}

class _ResourcesByIdsProviderElement
    extends FutureProviderElement<List<TeachingResource>>
    with ResourcesByIdsRef {
  _ResourcesByIdsProviderElement(super.provider);

  @override
  List<String> get ids => (origin as ResourcesByIdsProvider).ids;
}

String _$teachingResourceNotifierHash() =>
    r'461bc062d73c6629d4c749bff3202f50f62fb595';

/// Notifier for CRUD operations on teaching resources
///
/// Copied from [TeachingResourceNotifier].
@ProviderFor(TeachingResourceNotifier)
final teachingResourceNotifierProvider = AsyncNotifierProvider<
  TeachingResourceNotifier,
  List<TeachingResource>
>.internal(
  TeachingResourceNotifier.new,
  name: r'teachingResourceNotifierProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$teachingResourceNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$TeachingResourceNotifier = AsyncNotifier<List<TeachingResource>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
