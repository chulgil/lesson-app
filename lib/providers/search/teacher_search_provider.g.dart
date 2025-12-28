// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'teacher_search_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$teacherSearchRepositoryHash() =>
    r'255874237ad7e5fe363640ab372879f5dccd1181';

/// Provider for teacher search repository
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
    r'f12aa36a218c44c982f1ecda7220ebbbe1863a13';

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

String _$featuredTeachersHash() => r'5af9f7246067b22bae70ab098643a7ca1e62b7ce';

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
    r'22f0ee730e0f4bafa3d67d84695f5838b2cbb6a7';

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
String _$availableAreasHash() => r'1ff6045cebffc7088f736a8645bbb4fe58e724c6';

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
String _$teacherSearchFilterStateHash() =>
    r'149c4eac6f1c6b278185e3b1c52647884a5f92db';

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
