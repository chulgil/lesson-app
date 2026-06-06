// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'academy_detail_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$academyRepositoryHash() => r'497d01e17c802d276393b0e25a5b2e5a576a7313';

/// See also [academyRepository].
@ProviderFor(academyRepository)
final academyRepositoryProvider = Provider<AcademyRepository>.internal(
  academyRepository,
  name: r'academyRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$academyRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AcademyRepositoryRef = ProviderRef<AcademyRepository>;
String _$academyByIdHash() => r'd141b9c583a46e9895a69375a2e1cd59317fa31e';

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

/// Academy base info by id.
///
/// Copied from [academyById].
@ProviderFor(academyById)
const academyByIdProvider = AcademyByIdFamily();

/// Academy base info by id.
///
/// Copied from [academyById].
class AcademyByIdFamily extends Family<AsyncValue<Academy?>> {
  /// Academy base info by id.
  ///
  /// Copied from [academyById].
  const AcademyByIdFamily();

  /// Academy base info by id.
  ///
  /// Copied from [academyById].
  AcademyByIdProvider call(
    String academyId,
  ) {
    return AcademyByIdProvider(
      academyId,
    );
  }

  @override
  AcademyByIdProvider getProviderOverride(
    covariant AcademyByIdProvider provider,
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
  String? get name => r'academyByIdProvider';
}

/// Academy base info by id.
///
/// Copied from [academyById].
class AcademyByIdProvider extends AutoDisposeFutureProvider<Academy?> {
  /// Academy base info by id.
  ///
  /// Copied from [academyById].
  AcademyByIdProvider(
    String academyId,
  ) : this._internal(
          (ref) => academyById(
            ref as AcademyByIdRef,
            academyId,
          ),
          from: academyByIdProvider,
          name: r'academyByIdProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$academyByIdHash,
          dependencies: AcademyByIdFamily._dependencies,
          allTransitiveDependencies:
              AcademyByIdFamily._allTransitiveDependencies,
          academyId: academyId,
        );

  AcademyByIdProvider._internal(
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
    FutureOr<Academy?> Function(AcademyByIdRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: AcademyByIdProvider._internal(
        (ref) => create(ref as AcademyByIdRef),
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
  AutoDisposeFutureProviderElement<Academy?> createElement() {
    return _AcademyByIdProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AcademyByIdProvider && other.academyId == academyId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, academyId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin AcademyByIdRef on AutoDisposeFutureProviderRef<Academy?> {
  /// The parameter `academyId` of this provider.
  String get academyId;
}

class _AcademyByIdProviderElement
    extends AutoDisposeFutureProviderElement<Academy?> with AcademyByIdRef {
  _AcademyByIdProviderElement(super.provider);

  @override
  String get academyId => (origin as AcademyByIdProvider).academyId;
}

String _$academyMembersHash() => r'3a1a98b2fdb6489bf535288b0843f88ba3bbd80d';

/// Academy members (teacher/owner roster).
///
/// Copied from [academyMembers].
@ProviderFor(academyMembers)
const academyMembersProvider = AcademyMembersFamily();

/// Academy members (teacher/owner roster).
///
/// Copied from [academyMembers].
class AcademyMembersFamily extends Family<AsyncValue<List<AcademyMember>>> {
  /// Academy members (teacher/owner roster).
  ///
  /// Copied from [academyMembers].
  const AcademyMembersFamily();

  /// Academy members (teacher/owner roster).
  ///
  /// Copied from [academyMembers].
  AcademyMembersProvider call(
    String academyId,
  ) {
    return AcademyMembersProvider(
      academyId,
    );
  }

  @override
  AcademyMembersProvider getProviderOverride(
    covariant AcademyMembersProvider provider,
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
  String? get name => r'academyMembersProvider';
}

/// Academy members (teacher/owner roster).
///
/// Copied from [academyMembers].
class AcademyMembersProvider
    extends AutoDisposeFutureProvider<List<AcademyMember>> {
  /// Academy members (teacher/owner roster).
  ///
  /// Copied from [academyMembers].
  AcademyMembersProvider(
    String academyId,
  ) : this._internal(
          (ref) => academyMembers(
            ref as AcademyMembersRef,
            academyId,
          ),
          from: academyMembersProvider,
          name: r'academyMembersProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$academyMembersHash,
          dependencies: AcademyMembersFamily._dependencies,
          allTransitiveDependencies:
              AcademyMembersFamily._allTransitiveDependencies,
          academyId: academyId,
        );

  AcademyMembersProvider._internal(
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
    FutureOr<List<AcademyMember>> Function(AcademyMembersRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: AcademyMembersProvider._internal(
        (ref) => create(ref as AcademyMembersRef),
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
  AutoDisposeFutureProviderElement<List<AcademyMember>> createElement() {
    return _AcademyMembersProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AcademyMembersProvider && other.academyId == academyId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, academyId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin AcademyMembersRef on AutoDisposeFutureProviderRef<List<AcademyMember>> {
  /// The parameter `academyId` of this provider.
  String get academyId;
}

class _AcademyMembersProviderElement
    extends AutoDisposeFutureProviderElement<List<AcademyMember>>
    with AcademyMembersRef {
  _AcademyMembersProviderElement(super.provider);

  @override
  String get academyId => (origin as AcademyMembersProvider).academyId;
}

String _$academyStudentsHash() => r'c6e0469543b5bf622b7fc852d7faddbdb9dd2604';

/// Academy students. 강사 모드면 백엔드가 본인 매칭 학생만 반환 (AC-M2 §6.2).
///
/// Copied from [academyStudents].
@ProviderFor(academyStudents)
const academyStudentsProvider = AcademyStudentsFamily();

/// Academy students. 강사 모드면 백엔드가 본인 매칭 학생만 반환 (AC-M2 §6.2).
///
/// Copied from [academyStudents].
class AcademyStudentsFamily extends Family<AsyncValue<List<AcademyStudent>>> {
  /// Academy students. 강사 모드면 백엔드가 본인 매칭 학생만 반환 (AC-M2 §6.2).
  ///
  /// Copied from [academyStudents].
  const AcademyStudentsFamily();

  /// Academy students. 강사 모드면 백엔드가 본인 매칭 학생만 반환 (AC-M2 §6.2).
  ///
  /// Copied from [academyStudents].
  AcademyStudentsProvider call(
    String academyId,
  ) {
    return AcademyStudentsProvider(
      academyId,
    );
  }

  @override
  AcademyStudentsProvider getProviderOverride(
    covariant AcademyStudentsProvider provider,
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
  String? get name => r'academyStudentsProvider';
}

/// Academy students. 강사 모드면 백엔드가 본인 매칭 학생만 반환 (AC-M2 §6.2).
///
/// Copied from [academyStudents].
class AcademyStudentsProvider
    extends AutoDisposeFutureProvider<List<AcademyStudent>> {
  /// Academy students. 강사 모드면 백엔드가 본인 매칭 학생만 반환 (AC-M2 §6.2).
  ///
  /// Copied from [academyStudents].
  AcademyStudentsProvider(
    String academyId,
  ) : this._internal(
          (ref) => academyStudents(
            ref as AcademyStudentsRef,
            academyId,
          ),
          from: academyStudentsProvider,
          name: r'academyStudentsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$academyStudentsHash,
          dependencies: AcademyStudentsFamily._dependencies,
          allTransitiveDependencies:
              AcademyStudentsFamily._allTransitiveDependencies,
          academyId: academyId,
        );

  AcademyStudentsProvider._internal(
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
    FutureOr<List<AcademyStudent>> Function(AcademyStudentsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: AcademyStudentsProvider._internal(
        (ref) => create(ref as AcademyStudentsRef),
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
  AutoDisposeFutureProviderElement<List<AcademyStudent>> createElement() {
    return _AcademyStudentsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AcademyStudentsProvider && other.academyId == academyId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, academyId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin AcademyStudentsRef on AutoDisposeFutureProviderRef<List<AcademyStudent>> {
  /// The parameter `academyId` of this provider.
  String get academyId;
}

class _AcademyStudentsProviderElement
    extends AutoDisposeFutureProviderElement<List<AcademyStudent>>
    with AcademyStudentsRef {
  _AcademyStudentsProviderElement(super.provider);

  @override
  String get academyId => (origin as AcademyStudentsProvider).academyId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
