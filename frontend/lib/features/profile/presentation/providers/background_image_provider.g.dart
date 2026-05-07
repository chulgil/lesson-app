// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'background_image_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$backgroundImageNotifierHash() =>
    r'fd8c4c0b90467be066111b5c8e6c40f78db37686';

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

abstract class _$BackgroundImageNotifier
    extends BuildlessAutoDisposeAsyncNotifier<String?> {
  late final String userId;

  FutureOr<String?> build(
    String userId,
  );
}

/// Background image state — holds the current local file path.
///
/// Copied from [BackgroundImageNotifier].
@ProviderFor(BackgroundImageNotifier)
const backgroundImageNotifierProvider = BackgroundImageNotifierFamily();

/// Background image state — holds the current local file path.
///
/// Copied from [BackgroundImageNotifier].
class BackgroundImageNotifierFamily extends Family<AsyncValue<String?>> {
  /// Background image state — holds the current local file path.
  ///
  /// Copied from [BackgroundImageNotifier].
  const BackgroundImageNotifierFamily();

  /// Background image state — holds the current local file path.
  ///
  /// Copied from [BackgroundImageNotifier].
  BackgroundImageNotifierProvider call(
    String userId,
  ) {
    return BackgroundImageNotifierProvider(
      userId,
    );
  }

  @override
  BackgroundImageNotifierProvider getProviderOverride(
    covariant BackgroundImageNotifierProvider provider,
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
  String? get name => r'backgroundImageNotifierProvider';
}

/// Background image state — holds the current local file path.
///
/// Copied from [BackgroundImageNotifier].
class BackgroundImageNotifierProvider
    extends AutoDisposeAsyncNotifierProviderImpl<BackgroundImageNotifier,
        String?> {
  /// Background image state — holds the current local file path.
  ///
  /// Copied from [BackgroundImageNotifier].
  BackgroundImageNotifierProvider(
    String userId,
  ) : this._internal(
          () => BackgroundImageNotifier()..userId = userId,
          from: backgroundImageNotifierProvider,
          name: r'backgroundImageNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$backgroundImageNotifierHash,
          dependencies: BackgroundImageNotifierFamily._dependencies,
          allTransitiveDependencies:
              BackgroundImageNotifierFamily._allTransitiveDependencies,
          userId: userId,
        );

  BackgroundImageNotifierProvider._internal(
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
    covariant BackgroundImageNotifier notifier,
  ) {
    return notifier.build(
      userId,
    );
  }

  @override
  Override overrideWith(BackgroundImageNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: BackgroundImageNotifierProvider._internal(
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
  AutoDisposeAsyncNotifierProviderElement<BackgroundImageNotifier, String?>
      createElement() {
    return _BackgroundImageNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BackgroundImageNotifierProvider && other.userId == userId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin BackgroundImageNotifierRef
    on AutoDisposeAsyncNotifierProviderRef<String?> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _BackgroundImageNotifierProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<BackgroundImageNotifier,
        String?> with BackgroundImageNotifierRef {
  _BackgroundImageNotifierProviderElement(super.provider);

  @override
  String get userId => (origin as BackgroundImageNotifierProvider).userId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
