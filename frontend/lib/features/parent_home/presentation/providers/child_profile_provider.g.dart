// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'child_profile_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$childProfileRepositoryHash() =>
    r'0c96ff54e693c3aaa7cf1fca27dc909b6d6a9912';

/// Provider for the child profile repository - switches between Mock and Remote.
///
/// Copied from [childProfileRepository].
@ProviderFor(childProfileRepository)
final childProfileRepositoryProvider =
    AutoDisposeProvider<ChildProfileRepository>.internal(
  childProfileRepository,
  name: r'childProfileRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$childProfileRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ChildProfileRepositoryRef
    = AutoDisposeProviderRef<ChildProfileRepository>;
String _$childProfilesHash() => r'0d9d83d12b08cb7d023f8a7375ca9595e466a58d';

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

/// Provider for child profiles of a specific parent
///
/// Copied from [childProfiles].
@ProviderFor(childProfiles)
const childProfilesProvider = ChildProfilesFamily();

/// Provider for child profiles of a specific parent
///
/// Copied from [childProfiles].
class ChildProfilesFamily extends Family<AsyncValue<List<ChildProfile>>> {
  /// Provider for child profiles of a specific parent
  ///
  /// Copied from [childProfiles].
  const ChildProfilesFamily();

  /// Provider for child profiles of a specific parent
  ///
  /// Copied from [childProfiles].
  ChildProfilesProvider call(
    String parentId,
  ) {
    return ChildProfilesProvider(
      parentId,
    );
  }

  @override
  ChildProfilesProvider getProviderOverride(
    covariant ChildProfilesProvider provider,
  ) {
    return call(
      provider.parentId,
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
  String? get name => r'childProfilesProvider';
}

/// Provider for child profiles of a specific parent
///
/// Copied from [childProfiles].
class ChildProfilesProvider
    extends AutoDisposeFutureProvider<List<ChildProfile>> {
  /// Provider for child profiles of a specific parent
  ///
  /// Copied from [childProfiles].
  ChildProfilesProvider(
    String parentId,
  ) : this._internal(
          (ref) => childProfiles(
            ref as ChildProfilesRef,
            parentId,
          ),
          from: childProfilesProvider,
          name: r'childProfilesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$childProfilesHash,
          dependencies: ChildProfilesFamily._dependencies,
          allTransitiveDependencies:
              ChildProfilesFamily._allTransitiveDependencies,
          parentId: parentId,
        );

  ChildProfilesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.parentId,
  }) : super.internal();

  final String parentId;

  @override
  Override overrideWith(
    FutureOr<List<ChildProfile>> Function(ChildProfilesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ChildProfilesProvider._internal(
        (ref) => create(ref as ChildProfilesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        parentId: parentId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<ChildProfile>> createElement() {
    return _ChildProfilesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ChildProfilesProvider && other.parentId == parentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, parentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin ChildProfilesRef on AutoDisposeFutureProviderRef<List<ChildProfile>> {
  /// The parameter `parentId` of this provider.
  String get parentId;
}

class _ChildProfilesProviderElement
    extends AutoDisposeFutureProviderElement<List<ChildProfile>>
    with ChildProfilesRef {
  _ChildProfilesProviderElement(super.provider);

  @override
  String get parentId => (origin as ChildProfilesProvider).parentId;
}

String _$childProfileHash() => r'319220b27ced0ecae2c752a00ee40cfdc0616fc4';

/// Provider for a single child profile
///
/// Copied from [childProfile].
@ProviderFor(childProfile)
const childProfileProvider = ChildProfileFamily();

/// Provider for a single child profile
///
/// Copied from [childProfile].
class ChildProfileFamily extends Family<AsyncValue<ChildProfile?>> {
  /// Provider for a single child profile
  ///
  /// Copied from [childProfile].
  const ChildProfileFamily();

  /// Provider for a single child profile
  ///
  /// Copied from [childProfile].
  ChildProfileProvider call(
    String childId,
  ) {
    return ChildProfileProvider(
      childId,
    );
  }

  @override
  ChildProfileProvider getProviderOverride(
    covariant ChildProfileProvider provider,
  ) {
    return call(
      provider.childId,
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
  String? get name => r'childProfileProvider';
}

/// Provider for a single child profile
///
/// Copied from [childProfile].
class ChildProfileProvider extends AutoDisposeFutureProvider<ChildProfile?> {
  /// Provider for a single child profile
  ///
  /// Copied from [childProfile].
  ChildProfileProvider(
    String childId,
  ) : this._internal(
          (ref) => childProfile(
            ref as ChildProfileRef,
            childId,
          ),
          from: childProfileProvider,
          name: r'childProfileProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$childProfileHash,
          dependencies: ChildProfileFamily._dependencies,
          allTransitiveDependencies:
              ChildProfileFamily._allTransitiveDependencies,
          childId: childId,
        );

  ChildProfileProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.childId,
  }) : super.internal();

  final String childId;

  @override
  Override overrideWith(
    FutureOr<ChildProfile?> Function(ChildProfileRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ChildProfileProvider._internal(
        (ref) => create(ref as ChildProfileRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        childId: childId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<ChildProfile?> createElement() {
    return _ChildProfileProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ChildProfileProvider && other.childId == childId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, childId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin ChildProfileRef on AutoDisposeFutureProviderRef<ChildProfile?> {
  /// The parameter `childId` of this provider.
  String get childId;
}

class _ChildProfileProviderElement
    extends AutoDisposeFutureProviderElement<ChildProfile?>
    with ChildProfileRef {
  _ChildProfileProviderElement(super.provider);

  @override
  String get childId => (origin as ChildProfileProvider).childId;
}

String _$selectedChildProfileHash() =>
    r'4c9789e0defb21e8ae86d0829cddfde5325ee496';

/// Currently selected child profile for parent view
///
/// Copied from [SelectedChildProfile].
@ProviderFor(SelectedChildProfile)
final selectedChildProfileProvider =
    AutoDisposeNotifierProvider<SelectedChildProfile, ChildProfile?>.internal(
  SelectedChildProfile.new,
  name: r'selectedChildProfileProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$selectedChildProfileHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SelectedChildProfile = AutoDisposeNotifier<ChildProfile?>;
String _$childProfileManagerHash() =>
    r'dd5678916d9f7a8f5e45333a5beeaf359a664534';

/// Notifier for managing child profiles (add, update, delete)
///
/// Copied from [ChildProfileManager].
@ProviderFor(ChildProfileManager)
final childProfileManagerProvider =
    AutoDisposeAsyncNotifierProvider<ChildProfileManager, void>.internal(
  ChildProfileManager.new,
  name: r'childProfileManagerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$childProfileManagerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ChildProfileManager = AutoDisposeAsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
