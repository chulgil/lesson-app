// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'teacher_search_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$teacherSearchRepositoryHash() =>
    r'213e6de24c1bd62f3c06821fc5a7001b585c6dcc';

/// Provider for teacher search repository - switches between Mock and Remote.
///
/// Copied from [teacherSearchRepository].
@ProviderFor(teacherSearchRepository)
final teacherSearchRepositoryProvider =
    Provider<TeacherSearchRepository>.internal(
  teacherSearchRepository,
  name: r'teacherSearchRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$teacherSearchRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TeacherSearchRepositoryRef = ProviderRef<TeacherSearchRepository>;
String _$teacherPublicProfileHash() =>
    r'e9caba23fdfec94b632bfa62321fb0e95cba04b4';

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

/// Teacher public profile provider
///
/// Copied from [teacherPublicProfile].
@ProviderFor(teacherPublicProfile)
const teacherPublicProfileProvider = TeacherPublicProfileFamily();

/// Teacher public profile provider
///
/// Copied from [teacherPublicProfile].
class TeacherPublicProfileFamily
    extends Family<AsyncValue<TeacherPublicProfile?>> {
  /// Teacher public profile provider
  ///
  /// Copied from [teacherPublicProfile].
  const TeacherPublicProfileFamily();

  /// Teacher public profile provider
  ///
  /// Copied from [teacherPublicProfile].
  TeacherPublicProfileProvider call(
    String teacherId,
  ) {
    return TeacherPublicProfileProvider(
      teacherId,
    );
  }

  @override
  TeacherPublicProfileProvider getProviderOverride(
    covariant TeacherPublicProfileProvider provider,
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
  String? get name => r'teacherPublicProfileProvider';
}

/// Teacher public profile provider
///
/// Copied from [teacherPublicProfile].
class TeacherPublicProfileProvider
    extends AutoDisposeFutureProvider<TeacherPublicProfile?> {
  /// Teacher public profile provider
  ///
  /// Copied from [teacherPublicProfile].
  TeacherPublicProfileProvider(
    String teacherId,
  ) : this._internal(
          (ref) => teacherPublicProfile(
            ref as TeacherPublicProfileRef,
            teacherId,
          ),
          from: teacherPublicProfileProvider,
          name: r'teacherPublicProfileProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$teacherPublicProfileHash,
          dependencies: TeacherPublicProfileFamily._dependencies,
          allTransitiveDependencies:
              TeacherPublicProfileFamily._allTransitiveDependencies,
          teacherId: teacherId,
        );

  TeacherPublicProfileProvider._internal(
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
    FutureOr<TeacherPublicProfile?> Function(TeacherPublicProfileRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TeacherPublicProfileProvider._internal(
        (ref) => create(ref as TeacherPublicProfileRef),
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
  AutoDisposeFutureProviderElement<TeacherPublicProfile?> createElement() {
    return _TeacherPublicProfileProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TeacherPublicProfileProvider &&
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
mixin TeacherPublicProfileRef
    on AutoDisposeFutureProviderRef<TeacherPublicProfile?> {
  /// The parameter `teacherId` of this provider.
  String get teacherId;
}

class _TeacherPublicProfileProviderElement
    extends AutoDisposeFutureProviderElement<TeacherPublicProfile?>
    with TeacherPublicProfileRef {
  _TeacherPublicProfileProviderElement(super.provider);

  @override
  String get teacherId => (origin as TeacherPublicProfileProvider).teacherId;
}

String _$teacherFullProfileHash() =>
    r'c8a67d652cb82e4a11abbd3286786b2c45b0c95d';

/// Teacher full profile provider (for connected students - includes bank account)
///
/// Copied from [teacherFullProfile].
@ProviderFor(teacherFullProfile)
const teacherFullProfileProvider = TeacherFullProfileFamily();

/// Teacher full profile provider (for connected students - includes bank account)
///
/// Copied from [teacherFullProfile].
class TeacherFullProfileFamily extends Family<AsyncValue<TeacherProfile?>> {
  /// Teacher full profile provider (for connected students - includes bank account)
  ///
  /// Copied from [teacherFullProfile].
  const TeacherFullProfileFamily();

  /// Teacher full profile provider (for connected students - includes bank account)
  ///
  /// Copied from [teacherFullProfile].
  TeacherFullProfileProvider call(
    String teacherId,
  ) {
    return TeacherFullProfileProvider(
      teacherId,
    );
  }

  @override
  TeacherFullProfileProvider getProviderOverride(
    covariant TeacherFullProfileProvider provider,
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
  String? get name => r'teacherFullProfileProvider';
}

/// Teacher full profile provider (for connected students - includes bank account)
///
/// Copied from [teacherFullProfile].
class TeacherFullProfileProvider
    extends AutoDisposeFutureProvider<TeacherProfile?> {
  /// Teacher full profile provider (for connected students - includes bank account)
  ///
  /// Copied from [teacherFullProfile].
  TeacherFullProfileProvider(
    String teacherId,
  ) : this._internal(
          (ref) => teacherFullProfile(
            ref as TeacherFullProfileRef,
            teacherId,
          ),
          from: teacherFullProfileProvider,
          name: r'teacherFullProfileProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$teacherFullProfileHash,
          dependencies: TeacherFullProfileFamily._dependencies,
          allTransitiveDependencies:
              TeacherFullProfileFamily._allTransitiveDependencies,
          teacherId: teacherId,
        );

  TeacherFullProfileProvider._internal(
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
    FutureOr<TeacherProfile?> Function(TeacherFullProfileRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TeacherFullProfileProvider._internal(
        (ref) => create(ref as TeacherFullProfileRef),
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
  AutoDisposeFutureProviderElement<TeacherProfile?> createElement() {
    return _TeacherFullProfileProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TeacherFullProfileProvider && other.teacherId == teacherId;
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
mixin TeacherFullProfileRef on AutoDisposeFutureProviderRef<TeacherProfile?> {
  /// The parameter `teacherId` of this provider.
  String get teacherId;
}

class _TeacherFullProfileProviderElement
    extends AutoDisposeFutureProviderElement<TeacherProfile?>
    with TeacherFullProfileRef {
  _TeacherFullProfileProviderElement(super.provider);

  @override
  String get teacherId => (origin as TeacherFullProfileProvider).teacherId;
}

String _$featuredTeachersHash() => r'777030417d311ff6e5419d66e2f3ff1f1005d0c9';

/// Featured teachers provider
///
/// Copied from [featuredTeachers].
@ProviderFor(featuredTeachers)
final featuredTeachersProvider =
    AutoDisposeFutureProvider<List<TeacherPublicProfile>>.internal(
  featuredTeachers,
  name: r'featuredTeachersProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$featuredTeachersHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FeaturedTeachersRef
    = AutoDisposeFutureProviderRef<List<TeacherPublicProfile>>;
String _$availableInstrumentsHash() =>
    r'8a8ecf8b56ba33a41eb3cb82904f26e13833a294';

/// Available instruments for filter
///
/// Copied from [availableInstruments].
@ProviderFor(availableInstruments)
final availableInstrumentsProvider =
    AutoDisposeFutureProvider<List<String>>.internal(
  availableInstruments,
  name: r'availableInstrumentsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$availableInstrumentsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AvailableInstrumentsRef = AutoDisposeFutureProviderRef<List<String>>;
String _$availableAreasHash() => r'f00b5c0b64ca4155437faa7f0659910ee7e6e4eb';

/// Available areas for filter
///
/// Copied from [availableAreas].
@ProviderFor(availableAreas)
final availableAreasProvider = AutoDisposeFutureProvider<List<String>>.internal(
  availableAreas,
  name: r'availableAreasProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$availableAreasHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AvailableAreasRef = AutoDisposeFutureProviderRef<List<String>>;
String _$academyInfoHash() => r'a09a3a34bbc39263614524564df355b3ca227947';

/// Academy info provider - get academy details by organization ID
///
/// Copied from [academyInfo].
@ProviderFor(academyInfo)
const academyInfoProvider = AcademyInfoFamily();

/// Academy info provider - get academy details by organization ID
///
/// Copied from [academyInfo].
class AcademyInfoFamily extends Family<AsyncValue<AcademyInfo?>> {
  /// Academy info provider - get academy details by organization ID
  ///
  /// Copied from [academyInfo].
  const AcademyInfoFamily();

  /// Academy info provider - get academy details by organization ID
  ///
  /// Copied from [academyInfo].
  AcademyInfoProvider call(
    String organizationId,
  ) {
    return AcademyInfoProvider(
      organizationId,
    );
  }

  @override
  AcademyInfoProvider getProviderOverride(
    covariant AcademyInfoProvider provider,
  ) {
    return call(
      provider.organizationId,
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
  String? get name => r'academyInfoProvider';
}

/// Academy info provider - get academy details by organization ID
///
/// Copied from [academyInfo].
class AcademyInfoProvider extends AutoDisposeFutureProvider<AcademyInfo?> {
  /// Academy info provider - get academy details by organization ID
  ///
  /// Copied from [academyInfo].
  AcademyInfoProvider(
    String organizationId,
  ) : this._internal(
          (ref) => academyInfo(
            ref as AcademyInfoRef,
            organizationId,
          ),
          from: academyInfoProvider,
          name: r'academyInfoProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$academyInfoHash,
          dependencies: AcademyInfoFamily._dependencies,
          allTransitiveDependencies:
              AcademyInfoFamily._allTransitiveDependencies,
          organizationId: organizationId,
        );

  AcademyInfoProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.organizationId,
  }) : super.internal();

  final String organizationId;

  @override
  Override overrideWith(
    FutureOr<AcademyInfo?> Function(AcademyInfoRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: AcademyInfoProvider._internal(
        (ref) => create(ref as AcademyInfoRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        organizationId: organizationId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<AcademyInfo?> createElement() {
    return _AcademyInfoProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AcademyInfoProvider &&
        other.organizationId == organizationId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, organizationId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin AcademyInfoRef on AutoDisposeFutureProviderRef<AcademyInfo?> {
  /// The parameter `organizationId` of this provider.
  String get organizationId;
}

class _AcademyInfoProviderElement
    extends AutoDisposeFutureProviderElement<AcademyInfo?> with AcademyInfoRef {
  _AcademyInfoProviderElement(super.provider);

  @override
  String get organizationId => (origin as AcademyInfoProvider).organizationId;
}

String _$academyTeachersHash() => r'410afda8649528d8ac58c4c534b5e9c19bdcff02';

/// Academy teachers provider - get all teachers in an academy
///
/// Copied from [academyTeachers].
@ProviderFor(academyTeachers)
const academyTeachersProvider = AcademyTeachersFamily();

/// Academy teachers provider - get all teachers in an academy
///
/// Copied from [academyTeachers].
class AcademyTeachersFamily
    extends Family<AsyncValue<List<TeacherPublicProfile>>> {
  /// Academy teachers provider - get all teachers in an academy
  ///
  /// Copied from [academyTeachers].
  const AcademyTeachersFamily();

  /// Academy teachers provider - get all teachers in an academy
  ///
  /// Copied from [academyTeachers].
  AcademyTeachersProvider call(
    String organizationId,
  ) {
    return AcademyTeachersProvider(
      organizationId,
    );
  }

  @override
  AcademyTeachersProvider getProviderOverride(
    covariant AcademyTeachersProvider provider,
  ) {
    return call(
      provider.organizationId,
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
  String? get name => r'academyTeachersProvider';
}

/// Academy teachers provider - get all teachers in an academy
///
/// Copied from [academyTeachers].
class AcademyTeachersProvider
    extends AutoDisposeFutureProvider<List<TeacherPublicProfile>> {
  /// Academy teachers provider - get all teachers in an academy
  ///
  /// Copied from [academyTeachers].
  AcademyTeachersProvider(
    String organizationId,
  ) : this._internal(
          (ref) => academyTeachers(
            ref as AcademyTeachersRef,
            organizationId,
          ),
          from: academyTeachersProvider,
          name: r'academyTeachersProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$academyTeachersHash,
          dependencies: AcademyTeachersFamily._dependencies,
          allTransitiveDependencies:
              AcademyTeachersFamily._allTransitiveDependencies,
          organizationId: organizationId,
        );

  AcademyTeachersProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.organizationId,
  }) : super.internal();

  final String organizationId;

  @override
  Override overrideWith(
    FutureOr<List<TeacherPublicProfile>> Function(AcademyTeachersRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: AcademyTeachersProvider._internal(
        (ref) => create(ref as AcademyTeachersRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        organizationId: organizationId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<TeacherPublicProfile>> createElement() {
    return _AcademyTeachersProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AcademyTeachersProvider &&
        other.organizationId == organizationId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, organizationId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin AcademyTeachersRef
    on AutoDisposeFutureProviderRef<List<TeacherPublicProfile>> {
  /// The parameter `organizationId` of this provider.
  String get organizationId;
}

class _AcademyTeachersProviderElement
    extends AutoDisposeFutureProviderElement<List<TeacherPublicProfile>>
    with AcademyTeachersRef {
  _AcademyTeachersProviderElement(super.provider);

  @override
  String get organizationId =>
      (origin as AcademyTeachersProvider).organizationId;
}

String _$allAcademiesHash() => r'8c72abba34ea7873c4293830abec50234dd06eb9';

/// All academies provider - get list of all academies
///
/// Copied from [allAcademies].
@ProviderFor(allAcademies)
final allAcademiesProvider =
    AutoDisposeFutureProvider<List<AcademyInfo>>.internal(
  allAcademies,
  name: r'allAcademiesProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$allAcademiesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AllAcademiesRef = AutoDisposeFutureProviderRef<List<AcademyInfo>>;
String _$teacherSearchTabStateHash() =>
    r'4db4fb24b8517e3bc40659d0265822bbf9b8346d';

/// Current search tab state (academy vs individual)
///
/// Copied from [TeacherSearchTabState].
@ProviderFor(TeacherSearchTabState)
final teacherSearchTabStateProvider = AutoDisposeNotifierProvider<
    TeacherSearchTabState, TeacherSearchType>.internal(
  TeacherSearchTabState.new,
  name: r'teacherSearchTabStateProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$teacherSearchTabStateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$TeacherSearchTabState = AutoDisposeNotifier<TeacherSearchType>;
String _$teacherSearchFilterStateHash() =>
    r'ead91ff78703c92b9cc7ba99999644e2fe573cd3';

/// Current search filter state
///
/// Copied from [TeacherSearchFilterState].
@ProviderFor(TeacherSearchFilterState)
final teacherSearchFilterStateProvider = AutoDisposeNotifierProvider<
    TeacherSearchFilterState, TeacherSearchFilter>.internal(
  TeacherSearchFilterState.new,
  name: r'teacherSearchFilterStateProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$teacherSearchFilterStateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$TeacherSearchFilterState = AutoDisposeNotifier<TeacherSearchFilter>;
String _$teacherSearchSortStateHash() =>
    r'00bbae3e0621aa433ce4d1f747fd311a1228d765';

/// Current sort option
///
/// Copied from [TeacherSearchSortState].
@ProviderFor(TeacherSearchSortState)
final teacherSearchSortStateProvider = AutoDisposeNotifierProvider<
    TeacherSearchSortState, TeacherSortOption>.internal(
  TeacherSearchSortState.new,
  name: r'teacherSearchSortStateProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$teacherSearchSortStateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$TeacherSearchSortState = AutoDisposeNotifier<TeacherSortOption>;
String _$teacherSearchResultsHash() =>
    r'b2a9c5842e63fa0b03aa0923ac0c8cb6c57aed6e';

/// Search results provider
///
/// Copied from [TeacherSearchResults].
@ProviderFor(TeacherSearchResults)
final teacherSearchResultsProvider = AutoDisposeAsyncNotifierProvider<
    TeacherSearchResults, TeacherSearchResult>.internal(
  TeacherSearchResults.new,
  name: r'teacherSearchResultsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$teacherSearchResultsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$TeacherSearchResults = AutoDisposeAsyncNotifier<TeacherSearchResult>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
