// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$locationRepositoryHash() =>
    r'bc4d918af1ab1bbc5c61e9e2e49701d8e9b1ff23';

/// Repository provider for LessonLocation.
///
/// Copied from [locationRepository].
@ProviderFor(locationRepository)
final locationRepositoryProvider =
    AutoDisposeProvider<LocationRepository>.internal(
  locationRepository,
  name: r'locationRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$locationRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LocationRepositoryRef = AutoDisposeProviderRef<LocationRepository>;
String _$classLocationsHash() => r'e0745c91735918b0e78cd24d94ab95ac49e2d500';

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

/// Get all locations for a class.
///
/// Copied from [classLocations].
@ProviderFor(classLocations)
const classLocationsProvider = ClassLocationsFamily();

/// Get all locations for a class.
///
/// Copied from [classLocations].
class ClassLocationsFamily extends Family<AsyncValue<List<LessonLocation>>> {
  /// Get all locations for a class.
  ///
  /// Copied from [classLocations].
  const ClassLocationsFamily();

  /// Get all locations for a class.
  ///
  /// Copied from [classLocations].
  ClassLocationsProvider call(
    String classId,
  ) {
    return ClassLocationsProvider(
      classId,
    );
  }

  @override
  ClassLocationsProvider getProviderOverride(
    covariant ClassLocationsProvider provider,
  ) {
    return call(
      provider.classId,
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
  String? get name => r'classLocationsProvider';
}

/// Get all locations for a class.
///
/// Copied from [classLocations].
class ClassLocationsProvider
    extends AutoDisposeFutureProvider<List<LessonLocation>> {
  /// Get all locations for a class.
  ///
  /// Copied from [classLocations].
  ClassLocationsProvider(
    String classId,
  ) : this._internal(
          (ref) => classLocations(
            ref as ClassLocationsRef,
            classId,
          ),
          from: classLocationsProvider,
          name: r'classLocationsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$classLocationsHash,
          dependencies: ClassLocationsFamily._dependencies,
          allTransitiveDependencies:
              ClassLocationsFamily._allTransitiveDependencies,
          classId: classId,
        );

  ClassLocationsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.classId,
  }) : super.internal();

  final String classId;

  @override
  Override overrideWith(
    FutureOr<List<LessonLocation>> Function(ClassLocationsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ClassLocationsProvider._internal(
        (ref) => create(ref as ClassLocationsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        classId: classId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<LessonLocation>> createElement() {
    return _ClassLocationsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ClassLocationsProvider && other.classId == classId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, classId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ClassLocationsRef on AutoDisposeFutureProviderRef<List<LessonLocation>> {
  /// The parameter `classId` of this provider.
  String get classId;
}

class _ClassLocationsProviderElement
    extends AutoDisposeFutureProviderElement<List<LessonLocation>>
    with ClassLocationsRef {
  _ClassLocationsProviderElement(super.provider);

  @override
  String get classId => (origin as ClassLocationsProvider).classId;
}

String _$teacherLocationsHash() => r'aca03d6dbdca99239337ec1839b9f6f318bebfee';

/// Get all locations owned by a teacher.
///
/// Copied from [teacherLocations].
@ProviderFor(teacherLocations)
const teacherLocationsProvider = TeacherLocationsFamily();

/// Get all locations owned by a teacher.
///
/// Copied from [teacherLocations].
class TeacherLocationsFamily extends Family<AsyncValue<List<LessonLocation>>> {
  /// Get all locations owned by a teacher.
  ///
  /// Copied from [teacherLocations].
  const TeacherLocationsFamily();

  /// Get all locations owned by a teacher.
  ///
  /// Copied from [teacherLocations].
  TeacherLocationsProvider call(
    String teacherId,
  ) {
    return TeacherLocationsProvider(
      teacherId,
    );
  }

  @override
  TeacherLocationsProvider getProviderOverride(
    covariant TeacherLocationsProvider provider,
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
  String? get name => r'teacherLocationsProvider';
}

/// Get all locations owned by a teacher.
///
/// Copied from [teacherLocations].
class TeacherLocationsProvider
    extends AutoDisposeFutureProvider<List<LessonLocation>> {
  /// Get all locations owned by a teacher.
  ///
  /// Copied from [teacherLocations].
  TeacherLocationsProvider(
    String teacherId,
  ) : this._internal(
          (ref) => teacherLocations(
            ref as TeacherLocationsRef,
            teacherId,
          ),
          from: teacherLocationsProvider,
          name: r'teacherLocationsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$teacherLocationsHash,
          dependencies: TeacherLocationsFamily._dependencies,
          allTransitiveDependencies:
              TeacherLocationsFamily._allTransitiveDependencies,
          teacherId: teacherId,
        );

  TeacherLocationsProvider._internal(
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
    FutureOr<List<LessonLocation>> Function(TeacherLocationsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TeacherLocationsProvider._internal(
        (ref) => create(ref as TeacherLocationsRef),
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
  AutoDisposeFutureProviderElement<List<LessonLocation>> createElement() {
    return _TeacherLocationsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TeacherLocationsProvider && other.teacherId == teacherId;
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
mixin TeacherLocationsRef
    on AutoDisposeFutureProviderRef<List<LessonLocation>> {
  /// The parameter `teacherId` of this provider.
  String get teacherId;
}

class _TeacherLocationsProviderElement
    extends AutoDisposeFutureProviderElement<List<LessonLocation>>
    with TeacherLocationsRef {
  _TeacherLocationsProviderElement(super.provider);

  @override
  String get teacherId => (origin as TeacherLocationsProvider).teacherId;
}

String _$locationHash() => r'e9b903deae757308389a9cb3c680816b85699759';

/// Get a single location by ID.
///
/// Copied from [location].
@ProviderFor(location)
const locationProvider = LocationFamily();

/// Get a single location by ID.
///
/// Copied from [location].
class LocationFamily extends Family<AsyncValue<LessonLocation?>> {
  /// Get a single location by ID.
  ///
  /// Copied from [location].
  const LocationFamily();

  /// Get a single location by ID.
  ///
  /// Copied from [location].
  LocationProvider call(
    String id,
  ) {
    return LocationProvider(
      id,
    );
  }

  @override
  LocationProvider getProviderOverride(
    covariant LocationProvider provider,
  ) {
    return call(
      provider.id,
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
  String? get name => r'locationProvider';
}

/// Get a single location by ID.
///
/// Copied from [location].
class LocationProvider extends AutoDisposeFutureProvider<LessonLocation?> {
  /// Get a single location by ID.
  ///
  /// Copied from [location].
  LocationProvider(
    String id,
  ) : this._internal(
          (ref) => location(
            ref as LocationRef,
            id,
          ),
          from: locationProvider,
          name: r'locationProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$locationHash,
          dependencies: LocationFamily._dependencies,
          allTransitiveDependencies: LocationFamily._allTransitiveDependencies,
          id: id,
        );

  LocationProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.id,
  }) : super.internal();

  final String id;

  @override
  Override overrideWith(
    FutureOr<LessonLocation?> Function(LocationRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: LocationProvider._internal(
        (ref) => create(ref as LocationRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        id: id,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<LessonLocation?> createElement() {
    return _LocationProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is LocationProvider && other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin LocationRef on AutoDisposeFutureProviderRef<LessonLocation?> {
  /// The parameter `id` of this provider.
  String get id;
}

class _LocationProviderElement
    extends AutoDisposeFutureProviderElement<LessonLocation?> with LocationRef {
  _LocationProviderElement(super.provider);

  @override
  String get id => (origin as LocationProvider).id;
}

String _$defaultClassLocationHash() =>
    r'f69196a6c788f4297c6be0b0264535375685d54b';

/// Get the default location for a class.
///
/// Copied from [defaultClassLocation].
@ProviderFor(defaultClassLocation)
const defaultClassLocationProvider = DefaultClassLocationFamily();

/// Get the default location for a class.
///
/// Copied from [defaultClassLocation].
class DefaultClassLocationFamily extends Family<AsyncValue<LessonLocation?>> {
  /// Get the default location for a class.
  ///
  /// Copied from [defaultClassLocation].
  const DefaultClassLocationFamily();

  /// Get the default location for a class.
  ///
  /// Copied from [defaultClassLocation].
  DefaultClassLocationProvider call(
    String classId,
  ) {
    return DefaultClassLocationProvider(
      classId,
    );
  }

  @override
  DefaultClassLocationProvider getProviderOverride(
    covariant DefaultClassLocationProvider provider,
  ) {
    return call(
      provider.classId,
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
  String? get name => r'defaultClassLocationProvider';
}

/// Get the default location for a class.
///
/// Copied from [defaultClassLocation].
class DefaultClassLocationProvider
    extends AutoDisposeFutureProvider<LessonLocation?> {
  /// Get the default location for a class.
  ///
  /// Copied from [defaultClassLocation].
  DefaultClassLocationProvider(
    String classId,
  ) : this._internal(
          (ref) => defaultClassLocation(
            ref as DefaultClassLocationRef,
            classId,
          ),
          from: defaultClassLocationProvider,
          name: r'defaultClassLocationProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$defaultClassLocationHash,
          dependencies: DefaultClassLocationFamily._dependencies,
          allTransitiveDependencies:
              DefaultClassLocationFamily._allTransitiveDependencies,
          classId: classId,
        );

  DefaultClassLocationProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.classId,
  }) : super.internal();

  final String classId;

  @override
  Override overrideWith(
    FutureOr<LessonLocation?> Function(DefaultClassLocationRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: DefaultClassLocationProvider._internal(
        (ref) => create(ref as DefaultClassLocationRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        classId: classId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<LessonLocation?> createElement() {
    return _DefaultClassLocationProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DefaultClassLocationProvider && other.classId == classId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, classId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin DefaultClassLocationRef on AutoDisposeFutureProviderRef<LessonLocation?> {
  /// The parameter `classId` of this provider.
  String get classId;
}

class _DefaultClassLocationProviderElement
    extends AutoDisposeFutureProviderElement<LessonLocation?>
    with DefaultClassLocationRef {
  _DefaultClassLocationProviderElement(super.provider);

  @override
  String get classId => (origin as DefaultClassLocationProvider).classId;
}

String _$locationNotifierHash() => r'b5c0d583ef39ce3737bc31e92717ab2b9eb4681d';

abstract class _$LocationNotifier
    extends BuildlessAutoDisposeAsyncNotifier<List<LessonLocation>> {
  late final String classId;

  FutureOr<List<LessonLocation>> build(
    String classId,
  );
}

/// Notifier for managing LessonLocation CRUD operations for a class.
///
/// Copied from [LocationNotifier].
@ProviderFor(LocationNotifier)
const locationNotifierProvider = LocationNotifierFamily();

/// Notifier for managing LessonLocation CRUD operations for a class.
///
/// Copied from [LocationNotifier].
class LocationNotifierFamily extends Family<AsyncValue<List<LessonLocation>>> {
  /// Notifier for managing LessonLocation CRUD operations for a class.
  ///
  /// Copied from [LocationNotifier].
  const LocationNotifierFamily();

  /// Notifier for managing LessonLocation CRUD operations for a class.
  ///
  /// Copied from [LocationNotifier].
  LocationNotifierProvider call(
    String classId,
  ) {
    return LocationNotifierProvider(
      classId,
    );
  }

  @override
  LocationNotifierProvider getProviderOverride(
    covariant LocationNotifierProvider provider,
  ) {
    return call(
      provider.classId,
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
  String? get name => r'locationNotifierProvider';
}

/// Notifier for managing LessonLocation CRUD operations for a class.
///
/// Copied from [LocationNotifier].
class LocationNotifierProvider extends AutoDisposeAsyncNotifierProviderImpl<
    LocationNotifier, List<LessonLocation>> {
  /// Notifier for managing LessonLocation CRUD operations for a class.
  ///
  /// Copied from [LocationNotifier].
  LocationNotifierProvider(
    String classId,
  ) : this._internal(
          () => LocationNotifier()..classId = classId,
          from: locationNotifierProvider,
          name: r'locationNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$locationNotifierHash,
          dependencies: LocationNotifierFamily._dependencies,
          allTransitiveDependencies:
              LocationNotifierFamily._allTransitiveDependencies,
          classId: classId,
        );

  LocationNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.classId,
  }) : super.internal();

  final String classId;

  @override
  FutureOr<List<LessonLocation>> runNotifierBuild(
    covariant LocationNotifier notifier,
  ) {
    return notifier.build(
      classId,
    );
  }

  @override
  Override overrideWith(LocationNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: LocationNotifierProvider._internal(
        () => create()..classId = classId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        classId: classId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<LocationNotifier,
      List<LessonLocation>> createElement() {
    return _LocationNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is LocationNotifierProvider && other.classId == classId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, classId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin LocationNotifierRef
    on AutoDisposeAsyncNotifierProviderRef<List<LessonLocation>> {
  /// The parameter `classId` of this provider.
  String get classId;
}

class _LocationNotifierProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<LocationNotifier,
        List<LessonLocation>> with LocationNotifierRef {
  _LocationNotifierProviderElement(super.provider);

  @override
  String get classId => (origin as LocationNotifierProvider).classId;
}

String _$teacherLocationNotifierHash() =>
    r'98e0de88b6387b7d2e7f99c1506935d1fba95927';

abstract class _$TeacherLocationNotifier
    extends BuildlessAutoDisposeAsyncNotifier<List<LessonLocation>> {
  late final String teacherId;

  FutureOr<List<LessonLocation>> build(
    String teacherId,
  );
}

/// Notifier for managing teacher's owned locations.
///
/// Copied from [TeacherLocationNotifier].
@ProviderFor(TeacherLocationNotifier)
const teacherLocationNotifierProvider = TeacherLocationNotifierFamily();

/// Notifier for managing teacher's owned locations.
///
/// Copied from [TeacherLocationNotifier].
class TeacherLocationNotifierFamily
    extends Family<AsyncValue<List<LessonLocation>>> {
  /// Notifier for managing teacher's owned locations.
  ///
  /// Copied from [TeacherLocationNotifier].
  const TeacherLocationNotifierFamily();

  /// Notifier for managing teacher's owned locations.
  ///
  /// Copied from [TeacherLocationNotifier].
  TeacherLocationNotifierProvider call(
    String teacherId,
  ) {
    return TeacherLocationNotifierProvider(
      teacherId,
    );
  }

  @override
  TeacherLocationNotifierProvider getProviderOverride(
    covariant TeacherLocationNotifierProvider provider,
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
  String? get name => r'teacherLocationNotifierProvider';
}

/// Notifier for managing teacher's owned locations.
///
/// Copied from [TeacherLocationNotifier].
class TeacherLocationNotifierProvider
    extends AutoDisposeAsyncNotifierProviderImpl<TeacherLocationNotifier,
        List<LessonLocation>> {
  /// Notifier for managing teacher's owned locations.
  ///
  /// Copied from [TeacherLocationNotifier].
  TeacherLocationNotifierProvider(
    String teacherId,
  ) : this._internal(
          () => TeacherLocationNotifier()..teacherId = teacherId,
          from: teacherLocationNotifierProvider,
          name: r'teacherLocationNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$teacherLocationNotifierHash,
          dependencies: TeacherLocationNotifierFamily._dependencies,
          allTransitiveDependencies:
              TeacherLocationNotifierFamily._allTransitiveDependencies,
          teacherId: teacherId,
        );

  TeacherLocationNotifierProvider._internal(
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
  FutureOr<List<LessonLocation>> runNotifierBuild(
    covariant TeacherLocationNotifier notifier,
  ) {
    return notifier.build(
      teacherId,
    );
  }

  @override
  Override overrideWith(TeacherLocationNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: TeacherLocationNotifierProvider._internal(
        () => create()..teacherId = teacherId,
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
  AutoDisposeAsyncNotifierProviderElement<TeacherLocationNotifier,
      List<LessonLocation>> createElement() {
    return _TeacherLocationNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TeacherLocationNotifierProvider &&
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
mixin TeacherLocationNotifierRef
    on AutoDisposeAsyncNotifierProviderRef<List<LessonLocation>> {
  /// The parameter `teacherId` of this provider.
  String get teacherId;
}

class _TeacherLocationNotifierProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<TeacherLocationNotifier,
        List<LessonLocation>> with TeacherLocationNotifierRef {
  _TeacherLocationNotifierProviderElement(super.provider);

  @override
  String get teacherId => (origin as TeacherLocationNotifierProvider).teacherId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
