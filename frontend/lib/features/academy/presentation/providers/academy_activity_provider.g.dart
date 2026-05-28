// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'academy_activity_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$academyActivityRepositoryHash() =>
    r'99478004a7919eca6ac0cf78652792c51b243865';

/// See also [academyActivityRepository].
@ProviderFor(academyActivityRepository)
final academyActivityRepositoryProvider =
    Provider<AcademyActivityRepository>.internal(
  academyActivityRepository,
  name: r'academyActivityRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$academyActivityRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AcademyActivityRepositoryRef = ProviderRef<AcademyActivityRepository>;
String _$academyActivityLogsHash() =>
    r'5b67eaa15381b25f30b2adf0a961a708f187a86f';

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

/// See also [academyActivityLogs].
@ProviderFor(academyActivityLogs)
const academyActivityLogsProvider = AcademyActivityLogsFamily();

/// See also [academyActivityLogs].
class AcademyActivityLogsFamily
    extends Family<AsyncValue<List<AcademyActivityLog>>> {
  /// See also [academyActivityLogs].
  const AcademyActivityLogsFamily();

  /// See also [academyActivityLogs].
  AcademyActivityLogsProvider call(
    String academyId,
    String actorMemberId,
  ) {
    return AcademyActivityLogsProvider(
      academyId,
      actorMemberId,
    );
  }

  @override
  AcademyActivityLogsProvider getProviderOverride(
    covariant AcademyActivityLogsProvider provider,
  ) {
    return call(
      provider.academyId,
      provider.actorMemberId,
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
  String? get name => r'academyActivityLogsProvider';
}

/// See also [academyActivityLogs].
class AcademyActivityLogsProvider
    extends AutoDisposeFutureProvider<List<AcademyActivityLog>> {
  /// See also [academyActivityLogs].
  AcademyActivityLogsProvider(
    String academyId,
    String actorMemberId,
  ) : this._internal(
          (ref) => academyActivityLogs(
            ref as AcademyActivityLogsRef,
            academyId,
            actorMemberId,
          ),
          from: academyActivityLogsProvider,
          name: r'academyActivityLogsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$academyActivityLogsHash,
          dependencies: AcademyActivityLogsFamily._dependencies,
          allTransitiveDependencies:
              AcademyActivityLogsFamily._allTransitiveDependencies,
          academyId: academyId,
          actorMemberId: actorMemberId,
        );

  AcademyActivityLogsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.academyId,
    required this.actorMemberId,
  }) : super.internal();

  final String academyId;
  final String actorMemberId;

  @override
  Override overrideWith(
    FutureOr<List<AcademyActivityLog>> Function(AcademyActivityLogsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: AcademyActivityLogsProvider._internal(
        (ref) => create(ref as AcademyActivityLogsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        academyId: academyId,
        actorMemberId: actorMemberId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<AcademyActivityLog>> createElement() {
    return _AcademyActivityLogsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AcademyActivityLogsProvider &&
        other.academyId == academyId &&
        other.actorMemberId == actorMemberId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, academyId.hashCode);
    hash = _SystemHash.combine(hash, actorMemberId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin AcademyActivityLogsRef
    on AutoDisposeFutureProviderRef<List<AcademyActivityLog>> {
  /// The parameter `academyId` of this provider.
  String get academyId;

  /// The parameter `actorMemberId` of this provider.
  String get actorMemberId;
}

class _AcademyActivityLogsProviderElement
    extends AutoDisposeFutureProviderElement<List<AcademyActivityLog>>
    with AcademyActivityLogsRef {
  _AcademyActivityLogsProviderElement(super.provider);

  @override
  String get academyId => (origin as AcademyActivityLogsProvider).academyId;
  @override
  String get actorMemberId =>
      (origin as AcademyActivityLogsProvider).actorMemberId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
