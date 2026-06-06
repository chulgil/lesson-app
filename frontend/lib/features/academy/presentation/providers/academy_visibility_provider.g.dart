// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'academy_visibility_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$academyVisibilityRepositoryHash() =>
    r'8e46ac91923ea76a9b22b298b05a61f5448b0659';

/// See also [academyVisibilityRepository].
@ProviderFor(academyVisibilityRepository)
final academyVisibilityRepositoryProvider =
    Provider<AcademyVisibilityRepository>.internal(
  academyVisibilityRepository,
  name: r'academyVisibilityRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$academyVisibilityRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AcademyVisibilityRepositoryRef
    = ProviderRef<AcademyVisibilityRepository>;
String _$teacherAcademiesHash() => r'1880e79b7735a960fd8792d8d353c50e2125bba9';

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

/// See also [teacherAcademies].
@ProviderFor(teacherAcademies)
const teacherAcademiesProvider = TeacherAcademiesFamily();

/// See also [teacherAcademies].
class TeacherAcademiesFamily
    extends Family<AsyncValue<List<TeacherAcademyMembership>>> {
  /// See also [teacherAcademies].
  const TeacherAcademiesFamily();

  /// See also [teacherAcademies].
  TeacherAcademiesProvider call(
    String teacherId,
  ) {
    return TeacherAcademiesProvider(
      teacherId,
    );
  }

  @override
  TeacherAcademiesProvider getProviderOverride(
    covariant TeacherAcademiesProvider provider,
  ) {
    return call(
      provider.teacherId,
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
  String? get name => r'teacherAcademiesProvider';
}

/// See also [teacherAcademies].
class TeacherAcademiesProvider
    extends AutoDisposeFutureProvider<List<TeacherAcademyMembership>> {
  /// See also [teacherAcademies].
  TeacherAcademiesProvider(
    String teacherId,
  ) : this._internal(
          (ref) => teacherAcademies(
            ref as TeacherAcademiesRef,
            teacherId,
          ),
          from: teacherAcademiesProvider,
          name: r'teacherAcademiesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$teacherAcademiesHash,
          dependencies: TeacherAcademiesFamily._dependencies,
          allTransitiveDependencies:
              TeacherAcademiesFamily._allTransitiveDependencies,
          teacherId: teacherId,
        );

  TeacherAcademiesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.teacherId,
  }) : super.internal();

  final String teacherId;

  @override
  Override overrideWith(
    FutureOr<List<TeacherAcademyMembership>> Function(
            TeacherAcademiesRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TeacherAcademiesProvider._internal(
        (ref) => create(ref as TeacherAcademiesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        teacherId: teacherId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<TeacherAcademyMembership>>
      createElement() {
    return _TeacherAcademiesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TeacherAcademiesProvider && other.teacherId == teacherId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, teacherId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin TeacherAcademiesRef
    on AutoDisposeFutureProviderRef<List<TeacherAcademyMembership>> {
  /// The parameter `teacherId` of this provider.
  String get teacherId;
}

class _TeacherAcademiesProviderElement
    extends AutoDisposeFutureProviderElement<List<TeacherAcademyMembership>>
    with TeacherAcademiesRef {
  _TeacherAcademiesProviderElement(super.provider);

  @override
  String get teacherId => (origin as TeacherAcademiesProvider).teacherId;
}

String _$academyVisibilityNotifierHash() =>
    r'70dd62b5de5521b48ccd210f3ed5f63342f2707a';

/// See also [academyVisibilityNotifier].
@ProviderFor(academyVisibilityNotifier)
final academyVisibilityNotifierProvider =
    Provider<AsyncNotifier<void>>.internal(
  academyVisibilityNotifier,
  name: r'academyVisibilityNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$academyVisibilityNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AcademyVisibilityNotifierRef = ProviderRef<AsyncNotifier<void>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
