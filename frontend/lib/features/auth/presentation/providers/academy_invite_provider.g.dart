// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'academy_invite_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$academyInviteRepositoryHash() =>
    r'b514f0ce6d418458f0dca84afcd5c0aa5cda73e4';

/// Mock academy invite repository provider
///
/// Copied from [academyInviteRepository].
@ProviderFor(academyInviteRepository)
final academyInviteRepositoryProvider =
    AutoDisposeProvider<AcademyInviteRepository>.internal(
  academyInviteRepository,
  name: r'academyInviteRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$academyInviteRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AcademyInviteRepositoryRef
    = AutoDisposeProviderRef<AcademyInviteRepository>;
String _$academyInvitePreviewHash() =>
    r'beae58670cc87738d3fec24f8afe98a18e9d9a66';

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

/// Academy invite preview provider — loads invite details by token
///
/// Copied from [academyInvitePreview].
@ProviderFor(academyInvitePreview)
const academyInvitePreviewProvider = AcademyInvitePreviewFamily();

/// Academy invite preview provider — loads invite details by token
///
/// Copied from [academyInvitePreview].
class AcademyInvitePreviewFamily
    extends Family<AsyncValue<AcademyInvitePreview>> {
  /// Academy invite preview provider — loads invite details by token
  ///
  /// Copied from [academyInvitePreview].
  const AcademyInvitePreviewFamily();

  /// Academy invite preview provider — loads invite details by token
  ///
  /// Copied from [academyInvitePreview].
  AcademyInvitePreviewProvider call(
    String token,
  ) {
    return AcademyInvitePreviewProvider(
      token,
    );
  }

  @override
  AcademyInvitePreviewProvider getProviderOverride(
    covariant AcademyInvitePreviewProvider provider,
  ) {
    return call(
      provider.token,
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
  String? get name => r'academyInvitePreviewProvider';
}

/// Academy invite preview provider — loads invite details by token
///
/// Copied from [academyInvitePreview].
class AcademyInvitePreviewProvider
    extends AutoDisposeFutureProvider<AcademyInvitePreview> {
  /// Academy invite preview provider — loads invite details by token
  ///
  /// Copied from [academyInvitePreview].
  AcademyInvitePreviewProvider(
    String token,
  ) : this._internal(
          (ref) => academyInvitePreview(
            ref as AcademyInvitePreviewRef,
            token,
          ),
          from: academyInvitePreviewProvider,
          name: r'academyInvitePreviewProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$academyInvitePreviewHash,
          dependencies: AcademyInvitePreviewFamily._dependencies,
          allTransitiveDependencies:
              AcademyInvitePreviewFamily._allTransitiveDependencies,
          token: token,
        );

  AcademyInvitePreviewProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.token,
  }) : super.internal();

  final String token;

  @override
  Override overrideWith(
    FutureOr<AcademyInvitePreview> Function(AcademyInvitePreviewRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: AcademyInvitePreviewProvider._internal(
        (ref) => create(ref as AcademyInvitePreviewRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        token: token,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<AcademyInvitePreview> createElement() {
    return _AcademyInvitePreviewProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AcademyInvitePreviewProvider && other.token == token;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, token.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin AcademyInvitePreviewRef
    on AutoDisposeFutureProviderRef<AcademyInvitePreview> {
  /// The parameter `token` of this provider.
  String get token;
}

class _AcademyInvitePreviewProviderElement
    extends AutoDisposeFutureProviderElement<AcademyInvitePreview>
    with AcademyInvitePreviewRef {
  _AcademyInvitePreviewProviderElement(super.provider);

  @override
  String get token => (origin as AcademyInvitePreviewProvider).token;
}

String _$academyInviteAcceptHash() =>
    r'0c9ad036d1044fab1e0d9c7442510734783bd8c2';

/// Academy invite accept provider — accepts invite and creates membership
///
/// Copied from [academyInviteAccept].
@ProviderFor(academyInviteAccept)
const academyInviteAcceptProvider = AcademyInviteAcceptFamily();

/// Academy invite accept provider — accepts invite and creates membership
///
/// Copied from [academyInviteAccept].
class AcademyInviteAcceptFamily extends Family<AsyncValue<void>> {
  /// Academy invite accept provider — accepts invite and creates membership
  ///
  /// Copied from [academyInviteAccept].
  const AcademyInviteAcceptFamily();

  /// Academy invite accept provider — accepts invite and creates membership
  ///
  /// Copied from [academyInviteAccept].
  AcademyInviteAcceptProvider call(
    String token,
  ) {
    return AcademyInviteAcceptProvider(
      token,
    );
  }

  @override
  AcademyInviteAcceptProvider getProviderOverride(
    covariant AcademyInviteAcceptProvider provider,
  ) {
    return call(
      provider.token,
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
  String? get name => r'academyInviteAcceptProvider';
}

/// Academy invite accept provider — accepts invite and creates membership
///
/// Copied from [academyInviteAccept].
class AcademyInviteAcceptProvider extends AutoDisposeFutureProvider<void> {
  /// Academy invite accept provider — accepts invite and creates membership
  ///
  /// Copied from [academyInviteAccept].
  AcademyInviteAcceptProvider(
    String token,
  ) : this._internal(
          (ref) => academyInviteAccept(
            ref as AcademyInviteAcceptRef,
            token,
          ),
          from: academyInviteAcceptProvider,
          name: r'academyInviteAcceptProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$academyInviteAcceptHash,
          dependencies: AcademyInviteAcceptFamily._dependencies,
          allTransitiveDependencies:
              AcademyInviteAcceptFamily._allTransitiveDependencies,
          token: token,
        );

  AcademyInviteAcceptProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.token,
  }) : super.internal();

  final String token;

  @override
  Override overrideWith(
    FutureOr<void> Function(AcademyInviteAcceptRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: AcademyInviteAcceptProvider._internal(
        (ref) => create(ref as AcademyInviteAcceptRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        token: token,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<void> createElement() {
    return _AcademyInviteAcceptProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AcademyInviteAcceptProvider && other.token == token;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, token.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin AcademyInviteAcceptRef on AutoDisposeFutureProviderRef<void> {
  /// The parameter `token` of this provider.
  String get token;
}

class _AcademyInviteAcceptProviderElement
    extends AutoDisposeFutureProviderElement<void> with AcademyInviteAcceptRef {
  _AcademyInviteAcceptProviderElement(super.provider);

  @override
  String get token => (origin as AcademyInviteAcceptProvider).token;
}

String _$academyInviteRejectHash() =>
    r'fcc0b84c8d19f939c34b72c5217f311d2e9668c0';

/// Academy invite reject provider — rejects invite
///
/// Copied from [academyInviteReject].
@ProviderFor(academyInviteReject)
const academyInviteRejectProvider = AcademyInviteRejectFamily();

/// Academy invite reject provider — rejects invite
///
/// Copied from [academyInviteReject].
class AcademyInviteRejectFamily extends Family<AsyncValue<void>> {
  /// Academy invite reject provider — rejects invite
  ///
  /// Copied from [academyInviteReject].
  const AcademyInviteRejectFamily();

  /// Academy invite reject provider — rejects invite
  ///
  /// Copied from [academyInviteReject].
  AcademyInviteRejectProvider call(
    String token,
  ) {
    return AcademyInviteRejectProvider(
      token,
    );
  }

  @override
  AcademyInviteRejectProvider getProviderOverride(
    covariant AcademyInviteRejectProvider provider,
  ) {
    return call(
      provider.token,
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
  String? get name => r'academyInviteRejectProvider';
}

/// Academy invite reject provider — rejects invite
///
/// Copied from [academyInviteReject].
class AcademyInviteRejectProvider extends AutoDisposeFutureProvider<void> {
  /// Academy invite reject provider — rejects invite
  ///
  /// Copied from [academyInviteReject].
  AcademyInviteRejectProvider(
    String token,
  ) : this._internal(
          (ref) => academyInviteReject(
            ref as AcademyInviteRejectRef,
            token,
          ),
          from: academyInviteRejectProvider,
          name: r'academyInviteRejectProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$academyInviteRejectHash,
          dependencies: AcademyInviteRejectFamily._dependencies,
          allTransitiveDependencies:
              AcademyInviteRejectFamily._allTransitiveDependencies,
          token: token,
        );

  AcademyInviteRejectProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.token,
  }) : super.internal();

  final String token;

  @override
  Override overrideWith(
    FutureOr<void> Function(AcademyInviteRejectRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: AcademyInviteRejectProvider._internal(
        (ref) => create(ref as AcademyInviteRejectRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        token: token,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<void> createElement() {
    return _AcademyInviteRejectProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AcademyInviteRejectProvider && other.token == token;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, token.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin AcademyInviteRejectRef on AutoDisposeFutureProviderRef<void> {
  /// The parameter `token` of this provider.
  String get token;
}

class _AcademyInviteRejectProviderElement
    extends AutoDisposeFutureProviderElement<void> with AcademyInviteRejectRef {
  _AcademyInviteRejectProviderElement(super.provider);

  @override
  String get token => (origin as AcademyInviteRejectProvider).token;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
