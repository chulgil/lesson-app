// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'membership_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$membershipRepositoryHash() =>
    r'8c8f4d87c9f1bf55a45cc9fdc9a943553f9eceff';

/// Repository provider for ClassMembership.
///
/// Copied from [membershipRepository].
@ProviderFor(membershipRepository)
final membershipRepositoryProvider =
    AutoDisposeProvider<MembershipRepository>.internal(
  membershipRepository,
  name: r'membershipRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$membershipRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MembershipRepositoryRef = AutoDisposeProviderRef<MembershipRepository>;
String _$classMembershipsHash() => r'f7ce5f9aa7f519fb0c3ad4030b9d948e49daf804';

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

/// Get all memberships for a class.
///
/// Copied from [classMemberships].
@ProviderFor(classMemberships)
const classMembershipsProvider = ClassMembershipsFamily();

/// Get all memberships for a class.
///
/// Copied from [classMemberships].
class ClassMembershipsFamily extends Family<AsyncValue<List<ClassMembership>>> {
  /// Get all memberships for a class.
  ///
  /// Copied from [classMemberships].
  const ClassMembershipsFamily();

  /// Get all memberships for a class.
  ///
  /// Copied from [classMemberships].
  ClassMembershipsProvider call(
    String classId,
  ) {
    return ClassMembershipsProvider(
      classId,
    );
  }

  @override
  ClassMembershipsProvider getProviderOverride(
    covariant ClassMembershipsProvider provider,
  ) {
    return call(
      provider.classId,
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
  String? get name => r'classMembershipsProvider';
}

/// Get all memberships for a class.
///
/// Copied from [classMemberships].
class ClassMembershipsProvider
    extends AutoDisposeFutureProvider<List<ClassMembership>> {
  /// Get all memberships for a class.
  ///
  /// Copied from [classMemberships].
  ClassMembershipsProvider(
    String classId,
  ) : this._internal(
          (ref) => classMemberships(
            ref as ClassMembershipsRef,
            classId,
          ),
          from: classMembershipsProvider,
          name: r'classMembershipsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$classMembershipsHash,
          dependencies: ClassMembershipsFamily._dependencies,
          allTransitiveDependencies:
              ClassMembershipsFamily._allTransitiveDependencies,
          classId: classId,
        );

  ClassMembershipsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.classId,
  }) : super.internal();

  final String classId;

  @override
  Override overrideWith(
    FutureOr<List<ClassMembership>> Function(ClassMembershipsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ClassMembershipsProvider._internal(
        (ref) => create(ref as ClassMembershipsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        classId: classId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<ClassMembership>> createElement() {
    return _ClassMembershipsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ClassMembershipsProvider && other.classId == classId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, classId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ClassMembershipsRef
    on AutoDisposeFutureProviderRef<List<ClassMembership>> {
  /// The parameter `classId` of this provider.
  String get classId;
}

class _ClassMembershipsProviderElement
    extends AutoDisposeFutureProviderElement<List<ClassMembership>>
    with ClassMembershipsRef {
  _ClassMembershipsProviderElement(super.provider);

  @override
  String get classId => (origin as ClassMembershipsProvider).classId;
}

String _$studentMembershipsHash() =>
    r'ed13f94e5b6fa218b60c39beb1d32325ac66a16b';

/// Get all memberships for a student.
///
/// Copied from [studentMemberships].
@ProviderFor(studentMemberships)
const studentMembershipsProvider = StudentMembershipsFamily();

/// Get all memberships for a student.
///
/// Copied from [studentMemberships].
class StudentMembershipsFamily
    extends Family<AsyncValue<List<ClassMembership>>> {
  /// Get all memberships for a student.
  ///
  /// Copied from [studentMemberships].
  const StudentMembershipsFamily();

  /// Get all memberships for a student.
  ///
  /// Copied from [studentMemberships].
  StudentMembershipsProvider call(
    String studentId,
  ) {
    return StudentMembershipsProvider(
      studentId,
    );
  }

  @override
  StudentMembershipsProvider getProviderOverride(
    covariant StudentMembershipsProvider provider,
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
  String? get name => r'studentMembershipsProvider';
}

/// Get all memberships for a student.
///
/// Copied from [studentMemberships].
class StudentMembershipsProvider
    extends AutoDisposeFutureProvider<List<ClassMembership>> {
  /// Get all memberships for a student.
  ///
  /// Copied from [studentMemberships].
  StudentMembershipsProvider(
    String studentId,
  ) : this._internal(
          (ref) => studentMemberships(
            ref as StudentMembershipsRef,
            studentId,
          ),
          from: studentMembershipsProvider,
          name: r'studentMembershipsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$studentMembershipsHash,
          dependencies: StudentMembershipsFamily._dependencies,
          allTransitiveDependencies:
              StudentMembershipsFamily._allTransitiveDependencies,
          studentId: studentId,
        );

  StudentMembershipsProvider._internal(
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
    FutureOr<List<ClassMembership>> Function(StudentMembershipsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: StudentMembershipsProvider._internal(
        (ref) => create(ref as StudentMembershipsRef),
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
  AutoDisposeFutureProviderElement<List<ClassMembership>> createElement() {
    return _StudentMembershipsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StudentMembershipsProvider && other.studentId == studentId;
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
mixin StudentMembershipsRef
    on AutoDisposeFutureProviderRef<List<ClassMembership>> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _StudentMembershipsProviderElement
    extends AutoDisposeFutureProviderElement<List<ClassMembership>>
    with StudentMembershipsRef {
  _StudentMembershipsProviderElement(super.provider);

  @override
  String get studentId => (origin as StudentMembershipsProvider).studentId;
}

String _$membershipHash() => r'2cb4047442cfb986e4da1acf8752fec89a64987d';

/// Get a single membership by ID.
///
/// Copied from [membership].
@ProviderFor(membership)
const membershipProvider = MembershipFamily();

/// Get a single membership by ID.
///
/// Copied from [membership].
class MembershipFamily extends Family<AsyncValue<ClassMembership?>> {
  /// Get a single membership by ID.
  ///
  /// Copied from [membership].
  const MembershipFamily();

  /// Get a single membership by ID.
  ///
  /// Copied from [membership].
  MembershipProvider call(
    String id,
  ) {
    return MembershipProvider(
      id,
    );
  }

  @override
  MembershipProvider getProviderOverride(
    covariant MembershipProvider provider,
  ) {
    return call(
      provider.id,
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
  String? get name => r'membershipProvider';
}

/// Get a single membership by ID.
///
/// Copied from [membership].
class MembershipProvider extends AutoDisposeFutureProvider<ClassMembership?> {
  /// Get a single membership by ID.
  ///
  /// Copied from [membership].
  MembershipProvider(
    String id,
  ) : this._internal(
          (ref) => membership(
            ref as MembershipRef,
            id,
          ),
          from: membershipProvider,
          name: r'membershipProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$membershipHash,
          dependencies: MembershipFamily._dependencies,
          allTransitiveDependencies:
              MembershipFamily._allTransitiveDependencies,
          id: id,
        );

  MembershipProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.id,
  }) : super.internal();

  final String id;

  @override
  Override overrideWith(
    FutureOr<ClassMembership?> Function(MembershipRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: MembershipProvider._internal(
        (ref) => create(ref as MembershipRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        id: id,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<ClassMembership?> createElement() {
    return _MembershipProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MembershipProvider && other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin MembershipRef on AutoDisposeFutureProviderRef<ClassMembership?> {
  /// The parameter `id` of this provider.
  String get id;
}

class _MembershipProviderElement
    extends AutoDisposeFutureProviderElement<ClassMembership?>
    with MembershipRef {
  _MembershipProviderElement(super.provider);

  @override
  String get id => (origin as MembershipProvider).id;
}

String _$activeStudentMembershipsHash() =>
    r'2673e1fa5c867eec474e50759e2212694628ca0f';

/// Get active memberships for a student (trial or active status).
///
/// Copied from [activeStudentMemberships].
@ProviderFor(activeStudentMemberships)
const activeStudentMembershipsProvider = ActiveStudentMembershipsFamily();

/// Get active memberships for a student (trial or active status).
///
/// Copied from [activeStudentMemberships].
class ActiveStudentMembershipsFamily
    extends Family<AsyncValue<List<ClassMembership>>> {
  /// Get active memberships for a student (trial or active status).
  ///
  /// Copied from [activeStudentMemberships].
  const ActiveStudentMembershipsFamily();

  /// Get active memberships for a student (trial or active status).
  ///
  /// Copied from [activeStudentMemberships].
  ActiveStudentMembershipsProvider call(
    String studentId,
  ) {
    return ActiveStudentMembershipsProvider(
      studentId,
    );
  }

  @override
  ActiveStudentMembershipsProvider getProviderOverride(
    covariant ActiveStudentMembershipsProvider provider,
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
  String? get name => r'activeStudentMembershipsProvider';
}

/// Get active memberships for a student (trial or active status).
///
/// Copied from [activeStudentMemberships].
class ActiveStudentMembershipsProvider
    extends AutoDisposeFutureProvider<List<ClassMembership>> {
  /// Get active memberships for a student (trial or active status).
  ///
  /// Copied from [activeStudentMemberships].
  ActiveStudentMembershipsProvider(
    String studentId,
  ) : this._internal(
          (ref) => activeStudentMemberships(
            ref as ActiveStudentMembershipsRef,
            studentId,
          ),
          from: activeStudentMembershipsProvider,
          name: r'activeStudentMembershipsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$activeStudentMembershipsHash,
          dependencies: ActiveStudentMembershipsFamily._dependencies,
          allTransitiveDependencies:
              ActiveStudentMembershipsFamily._allTransitiveDependencies,
          studentId: studentId,
        );

  ActiveStudentMembershipsProvider._internal(
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
    FutureOr<List<ClassMembership>> Function(
            ActiveStudentMembershipsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ActiveStudentMembershipsProvider._internal(
        (ref) => create(ref as ActiveStudentMembershipsRef),
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
  AutoDisposeFutureProviderElement<List<ClassMembership>> createElement() {
    return _ActiveStudentMembershipsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ActiveStudentMembershipsProvider &&
        other.studentId == studentId;
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
mixin ActiveStudentMembershipsRef
    on AutoDisposeFutureProviderRef<List<ClassMembership>> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _ActiveStudentMembershipsProviderElement
    extends AutoDisposeFutureProviderElement<List<ClassMembership>>
    with ActiveStudentMembershipsRef {
  _ActiveStudentMembershipsProviderElement(super.provider);

  @override
  String get studentId =>
      (origin as ActiveStudentMembershipsProvider).studentId;
}

String _$membershipNotifierHash() =>
    r'3aa0daf7c2a1d5ec812b3b78add8749337827e9e';

abstract class _$MembershipNotifier
    extends BuildlessAutoDisposeAsyncNotifier<List<ClassMembership>> {
  late final String classId;

  FutureOr<List<ClassMembership>> build(
    String classId,
  );
}

/// Notifier for managing ClassMembership CRUD operations.
///
/// Copied from [MembershipNotifier].
@ProviderFor(MembershipNotifier)
const membershipNotifierProvider = MembershipNotifierFamily();

/// Notifier for managing ClassMembership CRUD operations.
///
/// Copied from [MembershipNotifier].
class MembershipNotifierFamily
    extends Family<AsyncValue<List<ClassMembership>>> {
  /// Notifier for managing ClassMembership CRUD operations.
  ///
  /// Copied from [MembershipNotifier].
  const MembershipNotifierFamily();

  /// Notifier for managing ClassMembership CRUD operations.
  ///
  /// Copied from [MembershipNotifier].
  MembershipNotifierProvider call(
    String classId,
  ) {
    return MembershipNotifierProvider(
      classId,
    );
  }

  @override
  MembershipNotifierProvider getProviderOverride(
    covariant MembershipNotifierProvider provider,
  ) {
    return call(
      provider.classId,
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
  String? get name => r'membershipNotifierProvider';
}

/// Notifier for managing ClassMembership CRUD operations.
///
/// Copied from [MembershipNotifier].
class MembershipNotifierProvider extends AutoDisposeAsyncNotifierProviderImpl<
    MembershipNotifier, List<ClassMembership>> {
  /// Notifier for managing ClassMembership CRUD operations.
  ///
  /// Copied from [MembershipNotifier].
  MembershipNotifierProvider(
    String classId,
  ) : this._internal(
          () => MembershipNotifier()..classId = classId,
          from: membershipNotifierProvider,
          name: r'membershipNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$membershipNotifierHash,
          dependencies: MembershipNotifierFamily._dependencies,
          allTransitiveDependencies:
              MembershipNotifierFamily._allTransitiveDependencies,
          classId: classId,
        );

  MembershipNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.classId,
  }) : super.internal();

  final String classId;

  @override
  FutureOr<List<ClassMembership>> runNotifierBuild(
    covariant MembershipNotifier notifier,
  ) {
    return notifier.build(
      classId,
    );
  }

  @override
  Override overrideWith(MembershipNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: MembershipNotifierProvider._internal(
        () => create()..classId = classId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        classId: classId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<MembershipNotifier,
      List<ClassMembership>> createElement() {
    return _MembershipNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MembershipNotifierProvider && other.classId == classId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, classId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin MembershipNotifierRef
    on AutoDisposeAsyncNotifierProviderRef<List<ClassMembership>> {
  /// The parameter `classId` of this provider.
  String get classId;
}

class _MembershipNotifierProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<MembershipNotifier,
        List<ClassMembership>> with MembershipNotifierRef {
  _MembershipNotifierProviderElement(super.provider);

  @override
  String get classId => (origin as MembershipNotifierProvider).classId;
}

String _$studentMembershipNotifierHash() =>
    r'15f8e993c7c9825f12976e449b1c496d135a4b5e';

abstract class _$StudentMembershipNotifier
    extends BuildlessAutoDisposeAsyncNotifier<List<ClassMembership>> {
  late final String studentId;

  FutureOr<List<ClassMembership>> build(
    String studentId,
  );
}

/// Notifier for managing student's memberships.
///
/// Copied from [StudentMembershipNotifier].
@ProviderFor(StudentMembershipNotifier)
const studentMembershipNotifierProvider = StudentMembershipNotifierFamily();

/// Notifier for managing student's memberships.
///
/// Copied from [StudentMembershipNotifier].
class StudentMembershipNotifierFamily
    extends Family<AsyncValue<List<ClassMembership>>> {
  /// Notifier for managing student's memberships.
  ///
  /// Copied from [StudentMembershipNotifier].
  const StudentMembershipNotifierFamily();

  /// Notifier for managing student's memberships.
  ///
  /// Copied from [StudentMembershipNotifier].
  StudentMembershipNotifierProvider call(
    String studentId,
  ) {
    return StudentMembershipNotifierProvider(
      studentId,
    );
  }

  @override
  StudentMembershipNotifierProvider getProviderOverride(
    covariant StudentMembershipNotifierProvider provider,
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
  String? get name => r'studentMembershipNotifierProvider';
}

/// Notifier for managing student's memberships.
///
/// Copied from [StudentMembershipNotifier].
class StudentMembershipNotifierProvider
    extends AutoDisposeAsyncNotifierProviderImpl<StudentMembershipNotifier,
        List<ClassMembership>> {
  /// Notifier for managing student's memberships.
  ///
  /// Copied from [StudentMembershipNotifier].
  StudentMembershipNotifierProvider(
    String studentId,
  ) : this._internal(
          () => StudentMembershipNotifier()..studentId = studentId,
          from: studentMembershipNotifierProvider,
          name: r'studentMembershipNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$studentMembershipNotifierHash,
          dependencies: StudentMembershipNotifierFamily._dependencies,
          allTransitiveDependencies:
              StudentMembershipNotifierFamily._allTransitiveDependencies,
          studentId: studentId,
        );

  StudentMembershipNotifierProvider._internal(
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
  FutureOr<List<ClassMembership>> runNotifierBuild(
    covariant StudentMembershipNotifier notifier,
  ) {
    return notifier.build(
      studentId,
    );
  }

  @override
  Override overrideWith(StudentMembershipNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: StudentMembershipNotifierProvider._internal(
        () => create()..studentId = studentId,
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
  AutoDisposeAsyncNotifierProviderElement<StudentMembershipNotifier,
      List<ClassMembership>> createElement() {
    return _StudentMembershipNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StudentMembershipNotifierProvider &&
        other.studentId == studentId;
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
mixin StudentMembershipNotifierRef
    on AutoDisposeAsyncNotifierProviderRef<List<ClassMembership>> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _StudentMembershipNotifierProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<StudentMembershipNotifier,
        List<ClassMembership>> with StudentMembershipNotifierRef {
  _StudentMembershipNotifierProviderElement(super.provider);

  @override
  String get studentId =>
      (origin as StudentMembershipNotifierProvider).studentId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
