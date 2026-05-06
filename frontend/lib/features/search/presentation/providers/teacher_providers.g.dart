// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'teacher_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$teacherRepositoryHash() => r'3c40c0584987848e3023552bedd98c5a208f6064';

/// Teacher repository provider
///
/// Copied from [teacherRepository].
@ProviderFor(teacherRepository)
final teacherRepositoryProvider = Provider<TeacherRepository>.internal(
  teacherRepository,
  name: r'teacherRepositoryProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$teacherRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef TeacherRepositoryRef = ProviderRef<TeacherRepository>;
String _$allTeachersHash() => r'67dbf218f597c88f30f71826d6775634f74c977a';

/// All teachers provider
///
/// Copied from [allTeachers].
@ProviderFor(allTeachers)
final allTeachersProvider = FutureProvider<List<Teacher>>.internal(
  allTeachers,
  name: r'allTeachersProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$allTeachersHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AllTeachersRef = FutureProviderRef<List<Teacher>>;
String _$teacherHash() => r'edd5e891780e493128640821cbd7c151161a9dad';

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

/// Single teacher provider
///
/// Copied from [teacher].
@ProviderFor(teacher)
const teacherProvider = TeacherFamily();

/// Single teacher provider
///
/// Copied from [teacher].
class TeacherFamily extends Family<AsyncValue<Teacher?>> {
  /// Single teacher provider
  ///
  /// Copied from [teacher].
  const TeacherFamily();

  /// Single teacher provider
  ///
  /// Copied from [teacher].
  TeacherProvider call(String teacherId) {
    return TeacherProvider(teacherId);
  }

  @override
  TeacherProvider getProviderOverride(covariant TeacherProvider provider) {
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
  String? get name => r'teacherProvider';
}

/// Single teacher provider
///
/// Copied from [teacher].
class TeacherProvider extends FutureProvider<Teacher?> {
  /// Single teacher provider
  ///
  /// Copied from [teacher].
  TeacherProvider(String teacherId)
    : this._internal(
        (ref) => teacher(ref as TeacherRef, teacherId),
        from: teacherProvider,
        name: r'teacherProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$teacherHash,
        dependencies: TeacherFamily._dependencies,
        allTransitiveDependencies: TeacherFamily._allTransitiveDependencies,
        teacherId: teacherId,
      );

  TeacherProvider._internal(
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
    FutureOr<Teacher?> Function(TeacherRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TeacherProvider._internal(
        (ref) => create(ref as TeacherRef),
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
  FutureProviderElement<Teacher?> createElement() {
    return _TeacherProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TeacherProvider && other.teacherId == teacherId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, teacherId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin TeacherRef on FutureProviderRef<Teacher?> {
  /// The parameter `teacherId` of this provider.
  String get teacherId;
}

class _TeacherProviderElement extends FutureProviderElement<Teacher?>
    with TeacherRef {
  _TeacherProviderElement(super.provider);

  @override
  String get teacherId => (origin as TeacherProvider).teacherId;
}

String _$featuredTeachersHash() => r'2b83005b6f0a98203f5fc0a4379d5284de008fb2';

/// Featured teachers provider
///
/// Copied from [featuredTeachers].
@ProviderFor(featuredTeachers)
final featuredTeachersProvider = FutureProvider<List<Teacher>>.internal(
  featuredTeachers,
  name: r'featuredTeachersProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$featuredTeachersHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef FeaturedTeachersRef = FutureProviderRef<List<Teacher>>;
String _$teachersByInstrumentHash() =>
    r'712f1250aa4730af75f151e698c26c831d1e9623';

/// Teachers by instrument provider
///
/// Copied from [teachersByInstrument].
@ProviderFor(teachersByInstrument)
const teachersByInstrumentProvider = TeachersByInstrumentFamily();

/// Teachers by instrument provider
///
/// Copied from [teachersByInstrument].
class TeachersByInstrumentFamily extends Family<AsyncValue<List<Teacher>>> {
  /// Teachers by instrument provider
  ///
  /// Copied from [teachersByInstrument].
  const TeachersByInstrumentFamily();

  /// Teachers by instrument provider
  ///
  /// Copied from [teachersByInstrument].
  TeachersByInstrumentProvider call(String instrument) {
    return TeachersByInstrumentProvider(instrument);
  }

  @override
  TeachersByInstrumentProvider getProviderOverride(
    covariant TeachersByInstrumentProvider provider,
  ) {
    return call(provider.instrument);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'teachersByInstrumentProvider';
}

/// Teachers by instrument provider
///
/// Copied from [teachersByInstrument].
class TeachersByInstrumentProvider extends FutureProvider<List<Teacher>> {
  /// Teachers by instrument provider
  ///
  /// Copied from [teachersByInstrument].
  TeachersByInstrumentProvider(String instrument)
    : this._internal(
        (ref) =>
            teachersByInstrument(ref as TeachersByInstrumentRef, instrument),
        from: teachersByInstrumentProvider,
        name: r'teachersByInstrumentProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$teachersByInstrumentHash,
        dependencies: TeachersByInstrumentFamily._dependencies,
        allTransitiveDependencies:
            TeachersByInstrumentFamily._allTransitiveDependencies,
        instrument: instrument,
      );

  TeachersByInstrumentProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.instrument,
  }) : super.internal();

  final String instrument;

  @override
  Override overrideWith(
    FutureOr<List<Teacher>> Function(TeachersByInstrumentRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TeachersByInstrumentProvider._internal(
        (ref) => create(ref as TeachersByInstrumentRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        instrument: instrument,
      ),
    );
  }

  @override
  FutureProviderElement<List<Teacher>> createElement() {
    return _TeachersByInstrumentProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TeachersByInstrumentProvider &&
        other.instrument == instrument;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, instrument.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin TeachersByInstrumentRef on FutureProviderRef<List<Teacher>> {
  /// The parameter `instrument` of this provider.
  String get instrument;
}

class _TeachersByInstrumentProviderElement
    extends FutureProviderElement<List<Teacher>>
    with TeachersByInstrumentRef {
  _TeachersByInstrumentProviderElement(super.provider);

  @override
  String get instrument => (origin as TeachersByInstrumentProvider).instrument;
}

String _$filteredTeachersHash() => r'e3c69a1668bb12773401fc0daf2248276ef0d800';

/// Filtered teachers provider
///
/// Copied from [filteredTeachers].
@ProviderFor(filteredTeachers)
const filteredTeachersProvider = FilteredTeachersFamily();

/// Filtered teachers provider
///
/// Copied from [filteredTeachers].
class FilteredTeachersFamily extends Family<AsyncValue<List<Teacher>>> {
  /// Filtered teachers provider
  ///
  /// Copied from [filteredTeachers].
  const FilteredTeachersFamily();

  /// Filtered teachers provider
  ///
  /// Copied from [filteredTeachers].
  FilteredTeachersProvider call(TeacherFilter filter) {
    return FilteredTeachersProvider(filter);
  }

  @override
  FilteredTeachersProvider getProviderOverride(
    covariant FilteredTeachersProvider provider,
  ) {
    return call(provider.filter);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'filteredTeachersProvider';
}

/// Filtered teachers provider
///
/// Copied from [filteredTeachers].
class FilteredTeachersProvider extends FutureProvider<List<Teacher>> {
  /// Filtered teachers provider
  ///
  /// Copied from [filteredTeachers].
  FilteredTeachersProvider(TeacherFilter filter)
    : this._internal(
        (ref) => filteredTeachers(ref as FilteredTeachersRef, filter),
        from: filteredTeachersProvider,
        name: r'filteredTeachersProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$filteredTeachersHash,
        dependencies: FilteredTeachersFamily._dependencies,
        allTransitiveDependencies:
            FilteredTeachersFamily._allTransitiveDependencies,
        filter: filter,
      );

  FilteredTeachersProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.filter,
  }) : super.internal();

  final TeacherFilter filter;

  @override
  Override overrideWith(
    FutureOr<List<Teacher>> Function(FilteredTeachersRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: FilteredTeachersProvider._internal(
        (ref) => create(ref as FilteredTeachersRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        filter: filter,
      ),
    );
  }

  @override
  FutureProviderElement<List<Teacher>> createElement() {
    return _FilteredTeachersProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FilteredTeachersProvider && other.filter == filter;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, filter.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin FilteredTeachersRef on FutureProviderRef<List<Teacher>> {
  /// The parameter `filter` of this provider.
  TeacherFilter get filter;
}

class _FilteredTeachersProviderElement
    extends FutureProviderElement<List<Teacher>>
    with FilteredTeachersRef {
  _FilteredTeachersProviderElement(super.provider);

  @override
  TeacherFilter get filter => (origin as FilteredTeachersProvider).filter;
}

String _$availableTeachersHash() => r'b7f5bb16c09b85b65c900d354fd0b4097d241c94';

/// Available teachers (filtered by instrument and search)
///
/// Copied from [availableTeachers].
@ProviderFor(availableTeachers)
final availableTeachersProvider = FutureProvider<List<Teacher>>.internal(
  availableTeachers,
  name: r'availableTeachersProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$availableTeachersHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AvailableTeachersRef = FutureProviderRef<List<Teacher>>;
String _$selectedInstrumentFilterHash() =>
    r'eee9b04135fac1a001633fabaa45942d22be854a';

/// Selected instrument filter
///
/// Copied from [SelectedInstrumentFilter].
@ProviderFor(SelectedInstrumentFilter)
final selectedInstrumentFilterProvider =
    NotifierProvider<SelectedInstrumentFilter, String?>.internal(
      SelectedInstrumentFilter.new,
      name: r'selectedInstrumentFilterProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$selectedInstrumentFilterHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SelectedInstrumentFilter = Notifier<String?>;
String _$teacherSearchQueryHash() =>
    r'9accd0abfbff26494d7ab7c55828d34040b70ba4';

/// Search query for teachers
///
/// Copied from [TeacherSearchQuery].
@ProviderFor(TeacherSearchQuery)
final teacherSearchQueryProvider =
    NotifierProvider<TeacherSearchQuery, String>.internal(
      TeacherSearchQuery.new,
      name: r'teacherSearchQueryProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$teacherSearchQueryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$TeacherSearchQuery = Notifier<String>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
