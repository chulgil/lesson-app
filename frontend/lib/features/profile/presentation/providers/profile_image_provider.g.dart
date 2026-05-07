// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_image_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$profileImageNotifierHash() =>
    r'0e093742c480351b559cbe504db3541abbf6089e';

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

abstract class _$ProfileImageNotifier
    extends BuildlessAutoDisposeAsyncNotifier<String?> {
  late final String userId;

  FutureOr<String?> build(
    String userId,
  );
}

/// Profile image state — holds the current local file path.
///
/// Copied from [ProfileImageNotifier].
@ProviderFor(ProfileImageNotifier)
const profileImageNotifierProvider = ProfileImageNotifierFamily();

/// Profile image state — holds the current local file path.
///
/// Copied from [ProfileImageNotifier].
class ProfileImageNotifierFamily extends Family<AsyncValue<String?>> {
  /// Profile image state — holds the current local file path.
  ///
  /// Copied from [ProfileImageNotifier].
  const ProfileImageNotifierFamily();

  /// Profile image state — holds the current local file path.
  ///
  /// Copied from [ProfileImageNotifier].
  ProfileImageNotifierProvider call(
    String userId,
  ) {
    return ProfileImageNotifierProvider(
      userId,
    );
  }

  @override
  ProfileImageNotifierProvider getProviderOverride(
    covariant ProfileImageNotifierProvider provider,
  ) {
    return call(
      provider.userId,
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
  String? get name => r'profileImageNotifierProvider';
}

/// Profile image state — holds the current local file path.
///
/// Copied from [ProfileImageNotifier].
class ProfileImageNotifierProvider extends AutoDisposeAsyncNotifierProviderImpl<
    ProfileImageNotifier, String?> {
  /// Profile image state — holds the current local file path.
  ///
  /// Copied from [ProfileImageNotifier].
  ProfileImageNotifierProvider(
    String userId,
  ) : this._internal(
          () => ProfileImageNotifier()..userId = userId,
          from: profileImageNotifierProvider,
          name: r'profileImageNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$profileImageNotifierHash,
          dependencies: ProfileImageNotifierFamily._dependencies,
          allTransitiveDependencies:
              ProfileImageNotifierFamily._allTransitiveDependencies,
          userId: userId,
        );

  ProfileImageNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.userId,
  }) : super.internal();

  final String userId;

  @override
  FutureOr<String?> runNotifierBuild(
    covariant ProfileImageNotifier notifier,
  ) {
    return notifier.build(
      userId,
    );
  }

  @override
  Override overrideWith(ProfileImageNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: ProfileImageNotifierProvider._internal(
        () => create()..userId = userId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        userId: userId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<ProfileImageNotifier, String?>
      createElement() {
    return _ProfileImageNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ProfileImageNotifierProvider && other.userId == userId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin ProfileImageNotifierRef on AutoDisposeAsyncNotifierProviderRef<String?> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _ProfileImageNotifierProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<ProfileImageNotifier,
        String?> with ProfileImageNotifierRef {
  _ProfileImageNotifierProviderElement(super.provider);

  @override
  String get userId => (origin as ProfileImageNotifierProvider).userId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
