// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'academy_announcement_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$academyAnnouncementRepositoryHash() =>
    r'fba9d0495ebed0f09f45c8bdd6d86ca37ef927b9';

/// See also [academyAnnouncementRepository].
@ProviderFor(academyAnnouncementRepository)
final academyAnnouncementRepositoryProvider =
    Provider<AcademyAnnouncementRepository>.internal(
  academyAnnouncementRepository,
  name: r'academyAnnouncementRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$academyAnnouncementRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AcademyAnnouncementRepositoryRef
    = ProviderRef<AcademyAnnouncementRepository>;
String _$academyAnnouncementsHash() =>
    r'3eb873edfe6acb00e54fbae08d643937d189ea63';

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

/// See also [academyAnnouncements].
@ProviderFor(academyAnnouncements)
const academyAnnouncementsProvider = AcademyAnnouncementsFamily();

/// See also [academyAnnouncements].
class AcademyAnnouncementsFamily
    extends Family<AsyncValue<List<AcademyAnnouncement>>> {
  /// See also [academyAnnouncements].
  const AcademyAnnouncementsFamily();

  /// See also [academyAnnouncements].
  AcademyAnnouncementsProvider call(
    String academyId,
  ) {
    return AcademyAnnouncementsProvider(
      academyId,
    );
  }

  @override
  AcademyAnnouncementsProvider getProviderOverride(
    covariant AcademyAnnouncementsProvider provider,
  ) {
    return call(
      provider.academyId,
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
  String? get name => r'academyAnnouncementsProvider';
}

/// See also [academyAnnouncements].
class AcademyAnnouncementsProvider
    extends AutoDisposeFutureProvider<List<AcademyAnnouncement>> {
  /// See also [academyAnnouncements].
  AcademyAnnouncementsProvider(
    String academyId,
  ) : this._internal(
          (ref) => academyAnnouncements(
            ref as AcademyAnnouncementsRef,
            academyId,
          ),
          from: academyAnnouncementsProvider,
          name: r'academyAnnouncementsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$academyAnnouncementsHash,
          dependencies: AcademyAnnouncementsFamily._dependencies,
          allTransitiveDependencies:
              AcademyAnnouncementsFamily._allTransitiveDependencies,
          academyId: academyId,
        );

  AcademyAnnouncementsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.academyId,
  }) : super.internal();

  final String academyId;

  @override
  Override overrideWith(
    FutureOr<List<AcademyAnnouncement>> Function(
            AcademyAnnouncementsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: AcademyAnnouncementsProvider._internal(
        (ref) => create(ref as AcademyAnnouncementsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        academyId: academyId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<AcademyAnnouncement>> createElement() {
    return _AcademyAnnouncementsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AcademyAnnouncementsProvider &&
        other.academyId == academyId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, academyId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin AcademyAnnouncementsRef
    on AutoDisposeFutureProviderRef<List<AcademyAnnouncement>> {
  /// The parameter `academyId` of this provider.
  String get academyId;
}

class _AcademyAnnouncementsProviderElement
    extends AutoDisposeFutureProviderElement<List<AcademyAnnouncement>>
    with AcademyAnnouncementsRef {
  _AcademyAnnouncementsProviderElement(super.provider);

  @override
  String get academyId => (origin as AcademyAnnouncementsProvider).academyId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
