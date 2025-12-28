// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$availableProfileTypesHash() =>
    r'5d9cd2d7e746287b5f7d867d591d3d9e3b5105aa';

/// Provider for available profile types the current user can switch to
///
/// Copied from [availableProfileTypes].
@ProviderFor(availableProfileTypes)
final availableProfileTypesProvider =
    AutoDisposeProvider<List<ProfileType>>.internal(
  availableProfileTypes,
  name: r'availableProfileTypesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$availableProfileTypesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AvailableProfileTypesRef = AutoDisposeProviderRef<List<ProfileType>>;
String _$canSwitchProfilesHash() => r'2a0dac115526390e1dfa2b40c7dc2366047f7d5e';

/// Provider for checking if profile switching is available
///
/// Copied from [canSwitchProfiles].
@ProviderFor(canSwitchProfiles)
final canSwitchProfilesProvider = AutoDisposeProvider<bool>.internal(
  canSwitchProfiles,
  name: r'canSwitchProfilesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$canSwitchProfilesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CanSwitchProfilesRef = AutoDisposeProviderRef<bool>;
String _$activeProfileTypeHash() => r'06d843c20f5dff95d16225289023d6941e897d8d';

/// Provider for the active profile type
///
/// Copied from [activeProfileType].
@ProviderFor(activeProfileType)
final activeProfileTypeProvider = AutoDisposeProvider<ProfileType>.internal(
  activeProfileType,
  name: r'activeProfileTypeProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$activeProfileTypeHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ActiveProfileTypeRef = AutoDisposeProviderRef<ProfileType>;
String _$activeChildProfileHash() =>
    r'bc25d8176e5d8df05a277e0fef31ee2ee96dab0a';

/// Provider for the active child profile (when in child mode)
///
/// Copied from [activeChildProfile].
@ProviderFor(activeChildProfile)
final activeChildProfileProvider = AutoDisposeProvider<ChildProfile?>.internal(
  activeChildProfile,
  name: r'activeChildProfileProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$activeChildProfileHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ActiveChildProfileRef = AutoDisposeProviderRef<ChildProfile?>;
String _$isUnconnectedChildModeHash() =>
    r'97ae15b9df1be9b0b521b5a0ce7e3760a72e194e';

/// Provider that indicates if the current view should show unconnected child features
///
/// Returns true when:
/// - User is in child mode AND
/// - Active child is unconnected
///
/// Copied from [isUnconnectedChildMode].
@ProviderFor(isUnconnectedChildMode)
final isUnconnectedChildModeProvider = AutoDisposeProvider<bool>.internal(
  isUnconnectedChildMode,
  name: r'isUnconnectedChildModeProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$isUnconnectedChildModeHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsUnconnectedChildModeRef = AutoDisposeProviderRef<bool>;
String _$syncUserProfileChildrenHash() =>
    r'2f80062a94aee761891009df2952e385fb5a7881';

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

/// Provider for syncing user profile with child profiles from repository
///
/// Copied from [syncUserProfileChildren].
@ProviderFor(syncUserProfileChildren)
const syncUserProfileChildrenProvider = SyncUserProfileChildrenFamily();

/// Provider for syncing user profile with child profiles from repository
///
/// Copied from [syncUserProfileChildren].
class SyncUserProfileChildrenFamily extends Family<AsyncValue<void>> {
  /// Provider for syncing user profile with child profiles from repository
  ///
  /// Copied from [syncUserProfileChildren].
  const SyncUserProfileChildrenFamily();

  /// Provider for syncing user profile with child profiles from repository
  ///
  /// Copied from [syncUserProfileChildren].
  SyncUserProfileChildrenProvider call(
    String parentId,
  ) {
    return SyncUserProfileChildrenProvider(
      parentId,
    );
  }

  @override
  SyncUserProfileChildrenProvider getProviderOverride(
    covariant SyncUserProfileChildrenProvider provider,
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
  String? get name => r'syncUserProfileChildrenProvider';
}

/// Provider for syncing user profile with child profiles from repository
///
/// Copied from [syncUserProfileChildren].
class SyncUserProfileChildrenProvider extends AutoDisposeFutureProvider<void> {
  /// Provider for syncing user profile with child profiles from repository
  ///
  /// Copied from [syncUserProfileChildren].
  SyncUserProfileChildrenProvider(
    String parentId,
  ) : this._internal(
          (ref) => syncUserProfileChildren(
            ref as SyncUserProfileChildrenRef,
            parentId,
          ),
          from: syncUserProfileChildrenProvider,
          name: r'syncUserProfileChildrenProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$syncUserProfileChildrenHash,
          dependencies: SyncUserProfileChildrenFamily._dependencies,
          allTransitiveDependencies:
              SyncUserProfileChildrenFamily._allTransitiveDependencies,
          parentId: parentId,
        );

  SyncUserProfileChildrenProvider._internal(
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
    FutureOr<void> Function(SyncUserProfileChildrenRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SyncUserProfileChildrenProvider._internal(
        (ref) => create(ref as SyncUserProfileChildrenRef),
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
  AutoDisposeFutureProviderElement<void> createElement() {
    return _SyncUserProfileChildrenProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SyncUserProfileChildrenProvider &&
        other.parentId == parentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, parentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SyncUserProfileChildrenRef on AutoDisposeFutureProviderRef<void> {
  /// The parameter `parentId` of this provider.
  String get parentId;
}

class _SyncUserProfileChildrenProviderElement
    extends AutoDisposeFutureProviderElement<void>
    with SyncUserProfileChildrenRef {
  _SyncUserProfileChildrenProviderElement(super.provider);

  @override
  String get parentId => (origin as SyncUserProfileChildrenProvider).parentId;
}

String _$currentUserProfileHash() =>
    r'898e198c53d3d6daf4fbbb417e0756a8578b99ad';

/// Provider for the current user's profile with active role context
///
/// This provider manages:
/// - Active profile type (parent, student, child)
/// - Profile switching between roles
/// - Access to child profiles
///
/// Copied from [CurrentUserProfile].
@ProviderFor(CurrentUserProfile)
final currentUserProfileProvider =
    AutoDisposeNotifierProvider<CurrentUserProfile, UserProfile>.internal(
  CurrentUserProfile.new,
  name: r'currentUserProfileProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentUserProfileHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$CurrentUserProfile = AutoDisposeNotifier<UserProfile>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
