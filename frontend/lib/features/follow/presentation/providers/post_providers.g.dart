// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$postRepositoryHash() => r'db6c4efd2308131d42f6f7cf8e460dc9ffb48b9d';

/// Repository provider for posts.
///
/// Copied from [postRepository].
@ProviderFor(postRepository)
final postRepositoryProvider = Provider<PostRepository>.internal(
  postRepository,
  name: r'postRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$postRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef PostRepositoryRef = ProviderRef<PostRepository>;
String _$followFeedHash() => r'c6f3a06ff972476e11b0fa5ca75dd05035ed6cb5';

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

/// Get feed posts for a user's followed accounts.
///
/// Aggregates posts from all followed teachers/academies, sorted newest first.
///
/// Copied from [followFeed].
@ProviderFor(followFeed)
const followFeedProvider = FollowFeedFamily();

/// Get feed posts for a user's followed accounts.
///
/// Aggregates posts from all followed teachers/academies, sorted newest first.
///
/// Copied from [followFeed].
class FollowFeedFamily extends Family<AsyncValue<List<TeacherPost>>> {
  /// Get feed posts for a user's followed accounts.
  ///
  /// Aggregates posts from all followed teachers/academies, sorted newest first.
  ///
  /// Copied from [followFeed].
  const FollowFeedFamily();

  /// Get feed posts for a user's followed accounts.
  ///
  /// Aggregates posts from all followed teachers/academies, sorted newest first.
  ///
  /// Copied from [followFeed].
  FollowFeedProvider call(
    String followerId,
  ) {
    return FollowFeedProvider(
      followerId,
    );
  }

  @override
  FollowFeedProvider getProviderOverride(
    covariant FollowFeedProvider provider,
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
  String? get name => r'followFeedProvider';
}

/// Get feed posts for a user's followed accounts.
///
/// Aggregates posts from all followed teachers/academies, sorted newest first.
///
/// Copied from [followFeed].
class FollowFeedProvider extends AutoDisposeFutureProvider<List<TeacherPost>> {
  /// Get feed posts for a user's followed accounts.
  ///
  /// Aggregates posts from all followed teachers/academies, sorted newest first.
  ///
  /// Copied from [followFeed].
  FollowFeedProvider(
    String followerId,
  ) : this._internal(
          (ref) => followFeed(
            ref as FollowFeedRef,
            followerId,
          ),
          from: followFeedProvider,
          name: r'followFeedProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$followFeedHash,
          dependencies: FollowFeedFamily._dependencies,
          allTransitiveDependencies:
              FollowFeedFamily._allTransitiveDependencies,
          followerId: followerId,
        );

  FollowFeedProvider._internal(
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
    FutureOr<List<TeacherPost>> Function(FollowFeedRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: FollowFeedProvider._internal(
        (ref) => create(ref as FollowFeedRef),
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
  AutoDisposeFutureProviderElement<List<TeacherPost>> createElement() {
    return _FollowFeedProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FollowFeedProvider && other.followerId == followerId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, followerId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin FollowFeedRef on AutoDisposeFutureProviderRef<List<TeacherPost>> {
  /// The parameter `followerId` of this provider.
  String get followerId;
}

class _FollowFeedProviderElement
    extends AutoDisposeFutureProviderElement<List<TeacherPost>>
    with FollowFeedRef {
  _FollowFeedProviderElement(super.provider);

  @override
  String get followerId => (origin as FollowFeedProvider).followerId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
