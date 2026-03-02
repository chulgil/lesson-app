// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'follow_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$followRepositoryHash() => r'f4615e20b5345b32d520bf713ea18432c368fad9';

/// Repository provider - switches between Mock and Remote.
///
/// Copied from [followRepository].
@ProviderFor(followRepository)
final followRepositoryProvider = Provider<FollowRepository>.internal(
  followRepository,
  name: r'followRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$followRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FollowRepositoryRef = ProviderRef<FollowRepository>;
String _$followByIdHash() => r'389c523e5fd7fd0e242b0f19149da724aa5e240f';

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

/// Get follow by ID
///
/// Copied from [followById].
@ProviderFor(followById)
const followByIdProvider = FollowByIdFamily();

/// Get follow by ID
///
/// Copied from [followById].
class FollowByIdFamily extends Family<AsyncValue<Follow?>> {
  /// Get follow by ID
  ///
  /// Copied from [followById].
  const FollowByIdFamily();

  /// Get follow by ID
  ///
  /// Copied from [followById].
  FollowByIdProvider call(
    String id,
  ) {
    return FollowByIdProvider(
      id,
    );
  }

  @override
  FollowByIdProvider getProviderOverride(
    covariant FollowByIdProvider provider,
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
  String? get name => r'followByIdProvider';
}

/// Get follow by ID
///
/// Copied from [followById].
class FollowByIdProvider extends AutoDisposeFutureProvider<Follow?> {
  /// Get follow by ID
  ///
  /// Copied from [followById].
  FollowByIdProvider(
    String id,
  ) : this._internal(
          (ref) => followById(
            ref as FollowByIdRef,
            id,
          ),
          from: followByIdProvider,
          name: r'followByIdProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$followByIdHash,
          dependencies: FollowByIdFamily._dependencies,
          allTransitiveDependencies:
              FollowByIdFamily._allTransitiveDependencies,
          id: id,
        );

  FollowByIdProvider._internal(
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
    FutureOr<Follow?> Function(FollowByIdRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: FollowByIdProvider._internal(
        (ref) => create(ref as FollowByIdRef),
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
  AutoDisposeFutureProviderElement<Follow?> createElement() {
    return _FollowByIdProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FollowByIdProvider && other.id == id;
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
mixin FollowByIdRef on AutoDisposeFutureProviderRef<Follow?> {
  /// The parameter `id` of this provider.
  String get id;
}

class _FollowByIdProviderElement
    extends AutoDisposeFutureProviderElement<Follow?> with FollowByIdRef {
  _FollowByIdProviderElement(super.provider);

  @override
  String get id => (origin as FollowByIdProvider).id;
}

String _$isFollowingHash() => r'7e017c16d0605418eef08e72b1fc04ddfacebf38';

/// Check if user is following a target
///
/// Copied from [isFollowing].
@ProviderFor(isFollowing)
const isFollowingProvider = IsFollowingFamily();

/// Check if user is following a target
///
/// Copied from [isFollowing].
class IsFollowingFamily extends Family<AsyncValue<bool>> {
  /// Check if user is following a target
  ///
  /// Copied from [isFollowing].
  const IsFollowingFamily();

  /// Check if user is following a target
  ///
  /// Copied from [isFollowing].
  IsFollowingProvider call({
    required String followerId,
    required String followingId,
  }) {
    return IsFollowingProvider(
      followerId: followerId,
      followingId: followingId,
    );
  }

  @override
  IsFollowingProvider getProviderOverride(
    covariant IsFollowingProvider provider,
  ) {
    return call(
      followerId: provider.followerId,
      followingId: provider.followingId,
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
  String? get name => r'isFollowingProvider';
}

/// Check if user is following a target
///
/// Copied from [isFollowing].
class IsFollowingProvider extends AutoDisposeFutureProvider<bool> {
  /// Check if user is following a target
  ///
  /// Copied from [isFollowing].
  IsFollowingProvider({
    required String followerId,
    required String followingId,
  }) : this._internal(
          (ref) => isFollowing(
            ref as IsFollowingRef,
            followerId: followerId,
            followingId: followingId,
          ),
          from: isFollowingProvider,
          name: r'isFollowingProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$isFollowingHash,
          dependencies: IsFollowingFamily._dependencies,
          allTransitiveDependencies:
              IsFollowingFamily._allTransitiveDependencies,
          followerId: followerId,
          followingId: followingId,
        );

  IsFollowingProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.followerId,
    required this.followingId,
  }) : super.internal();

  final String followerId;
  final String followingId;

  @override
  Override overrideWith(
    FutureOr<bool> Function(IsFollowingRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: IsFollowingProvider._internal(
        (ref) => create(ref as IsFollowingRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        followerId: followerId,
        followingId: followingId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<bool> createElement() {
    return _IsFollowingProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is IsFollowingProvider &&
        other.followerId == followerId &&
        other.followingId == followingId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, followerId.hashCode);
    hash = _SystemHash.combine(hash, followingId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin IsFollowingRef on AutoDisposeFutureProviderRef<bool> {
  /// The parameter `followerId` of this provider.
  String get followerId;

  /// The parameter `followingId` of this provider.
  String get followingId;
}

class _IsFollowingProviderElement extends AutoDisposeFutureProviderElement<bool>
    with IsFollowingRef {
  _IsFollowingProviderElement(super.provider);

  @override
  String get followerId => (origin as IsFollowingProvider).followerId;
  @override
  String get followingId => (origin as IsFollowingProvider).followingId;
}

String _$userFollowingHash() => r'3c6fb6d23d8af658c9448dd85900f4478549b5d0';

/// Get all follows by a user
///
/// Copied from [userFollowing].
@ProviderFor(userFollowing)
const userFollowingProvider = UserFollowingFamily();

/// Get all follows by a user
///
/// Copied from [userFollowing].
class UserFollowingFamily extends Family<AsyncValue<List<Follow>>> {
  /// Get all follows by a user
  ///
  /// Copied from [userFollowing].
  const UserFollowingFamily();

  /// Get all follows by a user
  ///
  /// Copied from [userFollowing].
  UserFollowingProvider call(
    String followerId,
  ) {
    return UserFollowingProvider(
      followerId,
    );
  }

  @override
  UserFollowingProvider getProviderOverride(
    covariant UserFollowingProvider provider,
  ) {
    return call(
      provider.followerId,
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
  String? get name => r'userFollowingProvider';
}

/// Get all follows by a user
///
/// Copied from [userFollowing].
class UserFollowingProvider extends AutoDisposeFutureProvider<List<Follow>> {
  /// Get all follows by a user
  ///
  /// Copied from [userFollowing].
  UserFollowingProvider(
    String followerId,
  ) : this._internal(
          (ref) => userFollowing(
            ref as UserFollowingRef,
            followerId,
          ),
          from: userFollowingProvider,
          name: r'userFollowingProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$userFollowingHash,
          dependencies: UserFollowingFamily._dependencies,
          allTransitiveDependencies:
              UserFollowingFamily._allTransitiveDependencies,
          followerId: followerId,
        );

  UserFollowingProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.followerId,
  }) : super.internal();

  final String followerId;

  @override
  Override overrideWith(
    FutureOr<List<Follow>> Function(UserFollowingRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UserFollowingProvider._internal(
        (ref) => create(ref as UserFollowingRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        followerId: followerId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Follow>> createElement() {
    return _UserFollowingProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UserFollowingProvider && other.followerId == followerId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, followerId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin UserFollowingRef on AutoDisposeFutureProviderRef<List<Follow>> {
  /// The parameter `followerId` of this provider.
  String get followerId;
}

class _UserFollowingProviderElement
    extends AutoDisposeFutureProviderElement<List<Follow>>
    with UserFollowingRef {
  _UserFollowingProviderElement(super.provider);

  @override
  String get followerId => (origin as UserFollowingProvider).followerId;
}

String _$targetFollowersHash() => r'eeb93212162628b5c95e1b5201f15ad7eec2ebc1';

/// Get all followers of a target
///
/// Copied from [targetFollowers].
@ProviderFor(targetFollowers)
const targetFollowersProvider = TargetFollowersFamily();

/// Get all followers of a target
///
/// Copied from [targetFollowers].
class TargetFollowersFamily extends Family<AsyncValue<List<Follow>>> {
  /// Get all followers of a target
  ///
  /// Copied from [targetFollowers].
  const TargetFollowersFamily();

  /// Get all followers of a target
  ///
  /// Copied from [targetFollowers].
  TargetFollowersProvider call(
    String followingId,
  ) {
    return TargetFollowersProvider(
      followingId,
    );
  }

  @override
  TargetFollowersProvider getProviderOverride(
    covariant TargetFollowersProvider provider,
  ) {
    return call(
      provider.followingId,
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
  String? get name => r'targetFollowersProvider';
}

/// Get all followers of a target
///
/// Copied from [targetFollowers].
class TargetFollowersProvider extends AutoDisposeFutureProvider<List<Follow>> {
  /// Get all followers of a target
  ///
  /// Copied from [targetFollowers].
  TargetFollowersProvider(
    String followingId,
  ) : this._internal(
          (ref) => targetFollowers(
            ref as TargetFollowersRef,
            followingId,
          ),
          from: targetFollowersProvider,
          name: r'targetFollowersProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$targetFollowersHash,
          dependencies: TargetFollowersFamily._dependencies,
          allTransitiveDependencies:
              TargetFollowersFamily._allTransitiveDependencies,
          followingId: followingId,
        );

  TargetFollowersProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.followingId,
  }) : super.internal();

  final String followingId;

  @override
  Override overrideWith(
    FutureOr<List<Follow>> Function(TargetFollowersRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TargetFollowersProvider._internal(
        (ref) => create(ref as TargetFollowersRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        followingId: followingId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Follow>> createElement() {
    return _TargetFollowersProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TargetFollowersProvider && other.followingId == followingId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, followingId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin TargetFollowersRef on AutoDisposeFutureProviderRef<List<Follow>> {
  /// The parameter `followingId` of this provider.
  String get followingId;
}

class _TargetFollowersProviderElement
    extends AutoDisposeFutureProviderElement<List<Follow>>
    with TargetFollowersRef {
  _TargetFollowersProviderElement(super.provider);

  @override
  String get followingId => (origin as TargetFollowersProvider).followingId;
}

String _$userFollowingByTypeHash() =>
    r'0951f3e4484d7944aa23cf704689a9f133722ab3';

/// Get follows by follower and target type
///
/// Copied from [userFollowingByType].
@ProviderFor(userFollowingByType)
const userFollowingByTypeProvider = UserFollowingByTypeFamily();

/// Get follows by follower and target type
///
/// Copied from [userFollowingByType].
class UserFollowingByTypeFamily extends Family<AsyncValue<List<Follow>>> {
  /// Get follows by follower and target type
  ///
  /// Copied from [userFollowingByType].
  const UserFollowingByTypeFamily();

  /// Get follows by follower and target type
  ///
  /// Copied from [userFollowingByType].
  UserFollowingByTypeProvider call({
    required String followerId,
    required FollowTargetType targetType,
  }) {
    return UserFollowingByTypeProvider(
      followerId: followerId,
      targetType: targetType,
    );
  }

  @override
  UserFollowingByTypeProvider getProviderOverride(
    covariant UserFollowingByTypeProvider provider,
  ) {
    return call(
      followerId: provider.followerId,
      targetType: provider.targetType,
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
  String? get name => r'userFollowingByTypeProvider';
}

/// Get follows by follower and target type
///
/// Copied from [userFollowingByType].
class UserFollowingByTypeProvider
    extends AutoDisposeFutureProvider<List<Follow>> {
  /// Get follows by follower and target type
  ///
  /// Copied from [userFollowingByType].
  UserFollowingByTypeProvider({
    required String followerId,
    required FollowTargetType targetType,
  }) : this._internal(
          (ref) => userFollowingByType(
            ref as UserFollowingByTypeRef,
            followerId: followerId,
            targetType: targetType,
          ),
          from: userFollowingByTypeProvider,
          name: r'userFollowingByTypeProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$userFollowingByTypeHash,
          dependencies: UserFollowingByTypeFamily._dependencies,
          allTransitiveDependencies:
              UserFollowingByTypeFamily._allTransitiveDependencies,
          followerId: followerId,
          targetType: targetType,
        );

  UserFollowingByTypeProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.followerId,
    required this.targetType,
  }) : super.internal();

  final String followerId;
  final FollowTargetType targetType;

  @override
  Override overrideWith(
    FutureOr<List<Follow>> Function(UserFollowingByTypeRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UserFollowingByTypeProvider._internal(
        (ref) => create(ref as UserFollowingByTypeRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        followerId: followerId,
        targetType: targetType,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Follow>> createElement() {
    return _UserFollowingByTypeProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UserFollowingByTypeProvider &&
        other.followerId == followerId &&
        other.targetType == targetType;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, followerId.hashCode);
    hash = _SystemHash.combine(hash, targetType.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin UserFollowingByTypeRef on AutoDisposeFutureProviderRef<List<Follow>> {
  /// The parameter `followerId` of this provider.
  String get followerId;

  /// The parameter `targetType` of this provider.
  FollowTargetType get targetType;
}

class _UserFollowingByTypeProviderElement
    extends AutoDisposeFutureProviderElement<List<Follow>>
    with UserFollowingByTypeRef {
  _UserFollowingByTypeProviderElement(super.provider);

  @override
  String get followerId => (origin as UserFollowingByTypeProvider).followerId;
  @override
  FollowTargetType get targetType =>
      (origin as UserFollowingByTypeProvider).targetType;
}

String _$followerCountHash() => r'644deac4da4f73879d0b50e71730dd6ae66704df';

/// Get follower count for a target
///
/// Copied from [followerCount].
@ProviderFor(followerCount)
const followerCountProvider = FollowerCountFamily();

/// Get follower count for a target
///
/// Copied from [followerCount].
class FollowerCountFamily extends Family<AsyncValue<int>> {
  /// Get follower count for a target
  ///
  /// Copied from [followerCount].
  const FollowerCountFamily();

  /// Get follower count for a target
  ///
  /// Copied from [followerCount].
  FollowerCountProvider call(
    String followingId,
  ) {
    return FollowerCountProvider(
      followingId,
    );
  }

  @override
  FollowerCountProvider getProviderOverride(
    covariant FollowerCountProvider provider,
  ) {
    return call(
      provider.followingId,
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
  String? get name => r'followerCountProvider';
}

/// Get follower count for a target
///
/// Copied from [followerCount].
class FollowerCountProvider extends AutoDisposeFutureProvider<int> {
  /// Get follower count for a target
  ///
  /// Copied from [followerCount].
  FollowerCountProvider(
    String followingId,
  ) : this._internal(
          (ref) => followerCount(
            ref as FollowerCountRef,
            followingId,
          ),
          from: followerCountProvider,
          name: r'followerCountProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$followerCountHash,
          dependencies: FollowerCountFamily._dependencies,
          allTransitiveDependencies:
              FollowerCountFamily._allTransitiveDependencies,
          followingId: followingId,
        );

  FollowerCountProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.followingId,
  }) : super.internal();

  final String followingId;

  @override
  Override overrideWith(
    FutureOr<int> Function(FollowerCountRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: FollowerCountProvider._internal(
        (ref) => create(ref as FollowerCountRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        followingId: followingId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<int> createElement() {
    return _FollowerCountProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FollowerCountProvider && other.followingId == followingId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, followingId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin FollowerCountRef on AutoDisposeFutureProviderRef<int> {
  /// The parameter `followingId` of this provider.
  String get followingId;
}

class _FollowerCountProviderElement
    extends AutoDisposeFutureProviderElement<int> with FollowerCountRef {
  _FollowerCountProviderElement(super.provider);

  @override
  String get followingId => (origin as FollowerCountProvider).followingId;
}

String _$followingCountHash() => r'01c202c34c43a5c72801310e25e52d2d86b305fd';

/// Get following count for a user
///
/// Copied from [followingCount].
@ProviderFor(followingCount)
const followingCountProvider = FollowingCountFamily();

/// Get following count for a user
///
/// Copied from [followingCount].
class FollowingCountFamily extends Family<AsyncValue<int>> {
  /// Get following count for a user
  ///
  /// Copied from [followingCount].
  const FollowingCountFamily();

  /// Get following count for a user
  ///
  /// Copied from [followingCount].
  FollowingCountProvider call(
    String followerId,
  ) {
    return FollowingCountProvider(
      followerId,
    );
  }

  @override
  FollowingCountProvider getProviderOverride(
    covariant FollowingCountProvider provider,
  ) {
    return call(
      provider.followerId,
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
  String? get name => r'followingCountProvider';
}

/// Get following count for a user
///
/// Copied from [followingCount].
class FollowingCountProvider extends AutoDisposeFutureProvider<int> {
  /// Get following count for a user
  ///
  /// Copied from [followingCount].
  FollowingCountProvider(
    String followerId,
  ) : this._internal(
          (ref) => followingCount(
            ref as FollowingCountRef,
            followerId,
          ),
          from: followingCountProvider,
          name: r'followingCountProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$followingCountHash,
          dependencies: FollowingCountFamily._dependencies,
          allTransitiveDependencies:
              FollowingCountFamily._allTransitiveDependencies,
          followerId: followerId,
        );

  FollowingCountProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.followerId,
  }) : super.internal();

  final String followerId;

  @override
  Override overrideWith(
    FutureOr<int> Function(FollowingCountRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: FollowingCountProvider._internal(
        (ref) => create(ref as FollowingCountRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        followerId: followerId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<int> createElement() {
    return _FollowingCountProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FollowingCountProvider && other.followerId == followerId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, followerId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin FollowingCountRef on AutoDisposeFutureProviderRef<int> {
  /// The parameter `followerId` of this provider.
  String get followerId;
}

class _FollowingCountProviderElement
    extends AutoDisposeFutureProviderElement<int> with FollowingCountRef {
  _FollowingCountProviderElement(super.provider);

  @override
  String get followerId => (origin as FollowingCountProvider).followerId;
}

String _$followedTeachersHash() => r'acd3a98ca324c19b6c59255bae430498532750ed';

/// Get teachers followed by a user
///
/// Copied from [followedTeachers].
@ProviderFor(followedTeachers)
const followedTeachersProvider = FollowedTeachersFamily();

/// Get teachers followed by a user
///
/// Copied from [followedTeachers].
class FollowedTeachersFamily extends Family<AsyncValue<List<Follow>>> {
  /// Get teachers followed by a user
  ///
  /// Copied from [followedTeachers].
  const FollowedTeachersFamily();

  /// Get teachers followed by a user
  ///
  /// Copied from [followedTeachers].
  FollowedTeachersProvider call(
    String followerId,
  ) {
    return FollowedTeachersProvider(
      followerId,
    );
  }

  @override
  FollowedTeachersProvider getProviderOverride(
    covariant FollowedTeachersProvider provider,
  ) {
    return call(
      provider.followerId,
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
  String? get name => r'followedTeachersProvider';
}

/// Get teachers followed by a user
///
/// Copied from [followedTeachers].
class FollowedTeachersProvider extends AutoDisposeFutureProvider<List<Follow>> {
  /// Get teachers followed by a user
  ///
  /// Copied from [followedTeachers].
  FollowedTeachersProvider(
    String followerId,
  ) : this._internal(
          (ref) => followedTeachers(
            ref as FollowedTeachersRef,
            followerId,
          ),
          from: followedTeachersProvider,
          name: r'followedTeachersProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$followedTeachersHash,
          dependencies: FollowedTeachersFamily._dependencies,
          allTransitiveDependencies:
              FollowedTeachersFamily._allTransitiveDependencies,
          followerId: followerId,
        );

  FollowedTeachersProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.followerId,
  }) : super.internal();

  final String followerId;

  @override
  Override overrideWith(
    FutureOr<List<Follow>> Function(FollowedTeachersRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: FollowedTeachersProvider._internal(
        (ref) => create(ref as FollowedTeachersRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        followerId: followerId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Follow>> createElement() {
    return _FollowedTeachersProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FollowedTeachersProvider && other.followerId == followerId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, followerId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin FollowedTeachersRef on AutoDisposeFutureProviderRef<List<Follow>> {
  /// The parameter `followerId` of this provider.
  String get followerId;
}

class _FollowedTeachersProviderElement
    extends AutoDisposeFutureProviderElement<List<Follow>>
    with FollowedTeachersRef {
  _FollowedTeachersProviderElement(super.provider);

  @override
  String get followerId => (origin as FollowedTeachersProvider).followerId;
}

String _$followedAcademiesHash() => r'99283e0c0c424b6b1f4a63b23f0e607a751f2b15';

/// Get academies followed by a user
///
/// Copied from [followedAcademies].
@ProviderFor(followedAcademies)
const followedAcademiesProvider = FollowedAcademiesFamily();

/// Get academies followed by a user
///
/// Copied from [followedAcademies].
class FollowedAcademiesFamily extends Family<AsyncValue<List<Follow>>> {
  /// Get academies followed by a user
  ///
  /// Copied from [followedAcademies].
  const FollowedAcademiesFamily();

  /// Get academies followed by a user
  ///
  /// Copied from [followedAcademies].
  FollowedAcademiesProvider call(
    String followerId,
  ) {
    return FollowedAcademiesProvider(
      followerId,
    );
  }

  @override
  FollowedAcademiesProvider getProviderOverride(
    covariant FollowedAcademiesProvider provider,
  ) {
    return call(
      provider.followerId,
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
  String? get name => r'followedAcademiesProvider';
}

/// Get academies followed by a user
///
/// Copied from [followedAcademies].
class FollowedAcademiesProvider
    extends AutoDisposeFutureProvider<List<Follow>> {
  /// Get academies followed by a user
  ///
  /// Copied from [followedAcademies].
  FollowedAcademiesProvider(
    String followerId,
  ) : this._internal(
          (ref) => followedAcademies(
            ref as FollowedAcademiesRef,
            followerId,
          ),
          from: followedAcademiesProvider,
          name: r'followedAcademiesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$followedAcademiesHash,
          dependencies: FollowedAcademiesFamily._dependencies,
          allTransitiveDependencies:
              FollowedAcademiesFamily._allTransitiveDependencies,
          followerId: followerId,
        );

  FollowedAcademiesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.followerId,
  }) : super.internal();

  final String followerId;

  @override
  Override overrideWith(
    FutureOr<List<Follow>> Function(FollowedAcademiesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: FollowedAcademiesProvider._internal(
        (ref) => create(ref as FollowedAcademiesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        followerId: followerId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Follow>> createElement() {
    return _FollowedAcademiesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FollowedAcademiesProvider && other.followerId == followerId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, followerId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin FollowedAcademiesRef on AutoDisposeFutureProviderRef<List<Follow>> {
  /// The parameter `followerId` of this provider.
  String get followerId;
}

class _FollowedAcademiesProviderElement
    extends AutoDisposeFutureProviderElement<List<Follow>>
    with FollowedAcademiesRef {
  _FollowedAcademiesProviderElement(super.provider);

  @override
  String get followerId => (origin as FollowedAcademiesProvider).followerId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
