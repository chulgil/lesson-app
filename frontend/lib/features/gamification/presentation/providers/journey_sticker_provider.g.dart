// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'journey_sticker_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$journeyStickerRepositoryHash() =>
    r'80917837a9c849045ffc120bed7293d8230d8363';

/// See also [journeyStickerRepository].
@ProviderFor(journeyStickerRepository)
final journeyStickerRepositoryProvider =
    Provider<JourneyStickerRepository>.internal(
  journeyStickerRepository,
  name: r'journeyStickerRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$journeyStickerRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef JourneyStickerRepositoryRef = ProviderRef<JourneyStickerRepository>;
String _$journeyStickerCatalogHash() =>
    r'b2ba434018bbe003a410e35e7c2d0872337d99d4';

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

/// See also [journeyStickerCatalog].
@ProviderFor(journeyStickerCatalog)
const journeyStickerCatalogProvider = JourneyStickerCatalogFamily();

/// See also [journeyStickerCatalog].
class JourneyStickerCatalogFamily
    extends Family<AsyncValue<JourneyStickerCatalog>> {
  /// See also [journeyStickerCatalog].
  const JourneyStickerCatalogFamily();

  /// See also [journeyStickerCatalog].
  JourneyStickerCatalogProvider call(
    String studentId,
  ) {
    return JourneyStickerCatalogProvider(
      studentId,
    );
  }

  @override
  JourneyStickerCatalogProvider getProviderOverride(
    covariant JourneyStickerCatalogProvider provider,
  ) {
    return call(
      provider.studentId,
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
  String? get name => r'journeyStickerCatalogProvider';
}

/// See also [journeyStickerCatalog].
class JourneyStickerCatalogProvider
    extends AutoDisposeFutureProvider<JourneyStickerCatalog> {
  /// See also [journeyStickerCatalog].
  JourneyStickerCatalogProvider(
    String studentId,
  ) : this._internal(
          (ref) => journeyStickerCatalog(
            ref as JourneyStickerCatalogRef,
            studentId,
          ),
          from: journeyStickerCatalogProvider,
          name: r'journeyStickerCatalogProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$journeyStickerCatalogHash,
          dependencies: JourneyStickerCatalogFamily._dependencies,
          allTransitiveDependencies:
              JourneyStickerCatalogFamily._allTransitiveDependencies,
          studentId: studentId,
        );

  JourneyStickerCatalogProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.studentId,
  }) : super.internal();

  final String studentId;

  @override
  Override overrideWith(
    FutureOr<JourneyStickerCatalog> Function(JourneyStickerCatalogRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: JourneyStickerCatalogProvider._internal(
        (ref) => create(ref as JourneyStickerCatalogRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        studentId: studentId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<JourneyStickerCatalog> createElement() {
    return _JourneyStickerCatalogProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is JourneyStickerCatalogProvider &&
        other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin JourneyStickerCatalogRef
    on AutoDisposeFutureProviderRef<JourneyStickerCatalog> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _JourneyStickerCatalogProviderElement
    extends AutoDisposeFutureProviderElement<JourneyStickerCatalog>
    with JourneyStickerCatalogRef {
  _JourneyStickerCatalogProviderElement(super.provider);

  @override
  String get studentId => (origin as JourneyStickerCatalogProvider).studentId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
