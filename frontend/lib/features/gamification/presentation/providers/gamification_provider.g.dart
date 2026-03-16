// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gamification_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$gamificationRepositoryHash() =>
    r'9f0c9cf23dcad77067a82561378a85e2b75267e5';

/// See also [gamificationRepository].
@ProviderFor(gamificationRepository)
final gamificationRepositoryProvider =
    Provider<GamificationRepository>.internal(
  gamificationRepository,
  name: r'gamificationRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$gamificationRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef GamificationRepositoryRef = ProviderRef<GamificationRepository>;
String _$studentGamificationHash() =>
    r'd11d27a1c9113a3aebeb0ec000cf792174ee491f';

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

/// See also [studentGamification].
@ProviderFor(studentGamification)
const studentGamificationProvider = StudentGamificationFamily();

/// See also [studentGamification].
class StudentGamificationFamily
    extends Family<AsyncValue<StudentGamification>> {
  /// See also [studentGamification].
  const StudentGamificationFamily();

  /// See also [studentGamification].
  StudentGamificationProvider call(
    String studentId,
  ) {
    return StudentGamificationProvider(
      studentId,
    );
  }

  @override
  StudentGamificationProvider getProviderOverride(
    covariant StudentGamificationProvider provider,
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
  String? get name => r'studentGamificationProvider';
}

/// See also [studentGamification].
class StudentGamificationProvider
    extends AutoDisposeFutureProvider<StudentGamification> {
  /// See also [studentGamification].
  StudentGamificationProvider(
    String studentId,
  ) : this._internal(
          (ref) => studentGamification(
            ref as StudentGamificationRef,
            studentId,
          ),
          from: studentGamificationProvider,
          name: r'studentGamificationProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$studentGamificationHash,
          dependencies: StudentGamificationFamily._dependencies,
          allTransitiveDependencies:
              StudentGamificationFamily._allTransitiveDependencies,
          studentId: studentId,
        );

  StudentGamificationProvider._internal(
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
    FutureOr<StudentGamification> Function(StudentGamificationRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: StudentGamificationProvider._internal(
        (ref) => create(ref as StudentGamificationRef),
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
  AutoDisposeFutureProviderElement<StudentGamification> createElement() {
    return _StudentGamificationProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StudentGamificationProvider && other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin StudentGamificationRef
    on AutoDisposeFutureProviderRef<StudentGamification> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _StudentGamificationProviderElement
    extends AutoDisposeFutureProviderElement<StudentGamification>
    with StudentGamificationRef {
  _StudentGamificationProviderElement(super.provider);

  @override
  String get studentId => (origin as StudentGamificationProvider).studentId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
