// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$currentTeacherProfileHash() =>
    r'1585a560bfde2342cd3b9e4b70199920337fb7f9';

/// Current teacher profile provider
///
/// Copied from [currentTeacherProfile].
@ProviderFor(currentTeacherProfile)
final currentTeacherProfileProvider =
    AutoDisposeFutureProvider<TeacherProfile?>.internal(
  currentTeacherProfile,
  name: r'currentTeacherProfileProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentTeacherProfileHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentTeacherProfileRef
    = AutoDisposeFutureProviderRef<TeacherProfile?>;
String _$teacherProfileByIdHash() =>
    r'5faaf69ba75732d3d536044258ff6d8c733101f9';

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

/// Teacher profile by ID provider
///
/// Copied from [teacherProfileById].
@ProviderFor(teacherProfileById)
const teacherProfileByIdProvider = TeacherProfileByIdFamily();

/// Teacher profile by ID provider
///
/// Copied from [teacherProfileById].
class TeacherProfileByIdFamily extends Family<AsyncValue<TeacherProfile?>> {
  /// Teacher profile by ID provider
  ///
  /// Copied from [teacherProfileById].
  const TeacherProfileByIdFamily();

  /// Teacher profile by ID provider
  ///
  /// Copied from [teacherProfileById].
  TeacherProfileByIdProvider call(
    String profileId,
  ) {
    return TeacherProfileByIdProvider(
      profileId,
    );
  }

  @override
  TeacherProfileByIdProvider getProviderOverride(
    covariant TeacherProfileByIdProvider provider,
  ) {
    return call(
      provider.profileId,
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
  String? get name => r'teacherProfileByIdProvider';
}

/// Teacher profile by ID provider
///
/// Copied from [teacherProfileById].
class TeacherProfileByIdProvider
    extends AutoDisposeFutureProvider<TeacherProfile?> {
  /// Teacher profile by ID provider
  ///
  /// Copied from [teacherProfileById].
  TeacherProfileByIdProvider(
    String profileId,
  ) : this._internal(
          (ref) => teacherProfileById(
            ref as TeacherProfileByIdRef,
            profileId,
          ),
          from: teacherProfileByIdProvider,
          name: r'teacherProfileByIdProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$teacherProfileByIdHash,
          dependencies: TeacherProfileByIdFamily._dependencies,
          allTransitiveDependencies:
              TeacherProfileByIdFamily._allTransitiveDependencies,
          profileId: profileId,
        );

  TeacherProfileByIdProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.profileId,
  }) : super.internal();

  final String profileId;

  @override
  Override overrideWith(
    FutureOr<TeacherProfile?> Function(TeacherProfileByIdRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TeacherProfileByIdProvider._internal(
        (ref) => create(ref as TeacherProfileByIdRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        profileId: profileId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<TeacherProfile?> createElement() {
    return _TeacherProfileByIdProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TeacherProfileByIdProvider && other.profileId == profileId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, profileId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin TeacherProfileByIdRef on AutoDisposeFutureProviderRef<TeacherProfile?> {
  /// The parameter `profileId` of this provider.
  String get profileId;
}

class _TeacherProfileByIdProviderElement
    extends AutoDisposeFutureProviderElement<TeacherProfile?>
    with TeacherProfileByIdRef {
  _TeacherProfileByIdProviderElement(super.provider);

  @override
  String get profileId => (origin as TeacherProfileByIdProvider).profileId;
}

String _$featuredTeacherProfilesHash() =>
    r'0d6d638bb1bf853a2049191d8dd8af3e7c48905a';

/// Featured teacher profiles provider
///
/// Copied from [featuredTeacherProfiles].
@ProviderFor(featuredTeacherProfiles)
final featuredTeacherProfilesProvider =
    AutoDisposeFutureProvider<List<TeacherProfile>>.internal(
  featuredTeacherProfiles,
  name: r'featuredTeacherProfilesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$featuredTeacherProfilesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FeaturedTeacherProfilesRef
    = AutoDisposeFutureProviderRef<List<TeacherProfile>>;
String _$searchTeacherProfilesHash() =>
    r'929d3da2c52b2ab46fa2a47faae8b1e2d8eb8674';

/// Search teacher profiles provider
///
/// Copied from [searchTeacherProfiles].
@ProviderFor(searchTeacherProfiles)
const searchTeacherProfilesProvider = SearchTeacherProfilesFamily();

/// Search teacher profiles provider
///
/// Copied from [searchTeacherProfiles].
class SearchTeacherProfilesFamily
    extends Family<AsyncValue<List<TeacherProfile>>> {
  /// Search teacher profiles provider
  ///
  /// Copied from [searchTeacherProfiles].
  const SearchTeacherProfilesFamily();

  /// Search teacher profiles provider
  ///
  /// Copied from [searchTeacherProfiles].
  SearchTeacherProfilesProvider call(
    TeacherProfileFilter filter,
  ) {
    return SearchTeacherProfilesProvider(
      filter,
    );
  }

  @override
  SearchTeacherProfilesProvider getProviderOverride(
    covariant SearchTeacherProfilesProvider provider,
  ) {
    return call(
      provider.filter,
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
  String? get name => r'searchTeacherProfilesProvider';
}

/// Search teacher profiles provider
///
/// Copied from [searchTeacherProfiles].
class SearchTeacherProfilesProvider
    extends AutoDisposeFutureProvider<List<TeacherProfile>> {
  /// Search teacher profiles provider
  ///
  /// Copied from [searchTeacherProfiles].
  SearchTeacherProfilesProvider(
    TeacherProfileFilter filter,
  ) : this._internal(
          (ref) => searchTeacherProfiles(
            ref as SearchTeacherProfilesRef,
            filter,
          ),
          from: searchTeacherProfilesProvider,
          name: r'searchTeacherProfilesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$searchTeacherProfilesHash,
          dependencies: SearchTeacherProfilesFamily._dependencies,
          allTransitiveDependencies:
              SearchTeacherProfilesFamily._allTransitiveDependencies,
          filter: filter,
        );

  SearchTeacherProfilesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.filter,
  }) : super.internal();

  final TeacherProfileFilter filter;

  @override
  Override overrideWith(
    FutureOr<List<TeacherProfile>> Function(SearchTeacherProfilesRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SearchTeacherProfilesProvider._internal(
        (ref) => create(ref as SearchTeacherProfilesRef),
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
  AutoDisposeFutureProviderElement<List<TeacherProfile>> createElement() {
    return _SearchTeacherProfilesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SearchTeacherProfilesProvider && other.filter == filter;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, filter.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SearchTeacherProfilesRef
    on AutoDisposeFutureProviderRef<List<TeacherProfile>> {
  /// The parameter `filter` of this provider.
  TeacherProfileFilter get filter;
}

class _SearchTeacherProfilesProviderElement
    extends AutoDisposeFutureProviderElement<List<TeacherProfile>>
    with SearchTeacherProfilesRef {
  _SearchTeacherProfilesProviderElement(super.provider);

  @override
  TeacherProfileFilter get filter =>
      (origin as SearchTeacherProfilesProvider).filter;
}

String _$teacherNeedsOnboardingHash() =>
    r'18bd0fd12d57c583a198799e3deae0737b170f6f';

/// Check if teacher needs onboarding
///
/// Copied from [teacherNeedsOnboarding].
@ProviderFor(teacherNeedsOnboarding)
final teacherNeedsOnboardingProvider = AutoDisposeFutureProvider<bool>.internal(
  teacherNeedsOnboarding,
  name: r'teacherNeedsOnboardingProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$teacherNeedsOnboardingHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TeacherNeedsOnboardingRef = AutoDisposeFutureProviderRef<bool>;
String _$teacherOnboardingNotifierHash() =>
    r'8fcd92e47ae125889651d8d1a5dab907ee9c896e';

/// Teacher onboarding state notifier
///
/// Copied from [TeacherOnboardingNotifier].
@ProviderFor(TeacherOnboardingNotifier)
final teacherOnboardingNotifierProvider = NotifierProvider<
    TeacherOnboardingNotifier, TeacherOnboardingState>.internal(
  TeacherOnboardingNotifier.new,
  name: r'teacherOnboardingNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$teacherOnboardingNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$TeacherOnboardingNotifier = Notifier<TeacherOnboardingState>;
String _$currentTeacherProfileNotifierHash() =>
    r'977071d54fe5e786d42610a68928c76e68443c30';

/// Profile completion info for current teacher
///
/// Copied from [CurrentTeacherProfileNotifier].
@ProviderFor(CurrentTeacherProfileNotifier)
final currentTeacherProfileNotifierProvider = AutoDisposeAsyncNotifierProvider<
    CurrentTeacherProfileNotifier, TeacherProfile?>.internal(
  CurrentTeacherProfileNotifier.new,
  name: r'currentTeacherProfileNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentTeacherProfileNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$CurrentTeacherProfileNotifier
    = AutoDisposeAsyncNotifier<TeacherProfile?>;
String _$phoneVerificationTimerHash() =>
    r'1b9612df96f2678b41edbfa492f22bd33d2f4e00';

/// Phone verification countdown provider
///
/// Copied from [PhoneVerificationTimer].
@ProviderFor(PhoneVerificationTimer)
final phoneVerificationTimerProvider =
    AutoDisposeNotifierProvider<PhoneVerificationTimer, int>.internal(
  PhoneVerificationTimer.new,
  name: r'phoneVerificationTimerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$phoneVerificationTimerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$PhoneVerificationTimer = AutoDisposeNotifier<int>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
