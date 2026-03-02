// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'relationship_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$teacherStudentRelationRepositoryHash() =>
    r'93fa0da06a54ed3a4840676597205de2710c2a30';

/// Repository provider - switches between Mock and Remote.
///
/// Copied from [teacherStudentRelationRepository].
@ProviderFor(teacherStudentRelationRepository)
final teacherStudentRelationRepositoryProvider =
    Provider<TeacherStudentRelationRepository>.internal(
  teacherStudentRelationRepository,
  name: r'teacherStudentRelationRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$teacherStudentRelationRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TeacherStudentRelationRepositoryRef
    = ProviderRef<TeacherStudentRelationRepository>;
String _$relationshipByIdHash() => r'65f8eeb965dce5e4394f7960ebe015d2be7373c2';

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

/// Get relationship by ID
///
/// Copied from [relationshipById].
@ProviderFor(relationshipById)
const relationshipByIdProvider = RelationshipByIdFamily();

/// Get relationship by ID
///
/// Copied from [relationshipById].
class RelationshipByIdFamily
    extends Family<AsyncValue<TeacherStudentRelation?>> {
  /// Get relationship by ID
  ///
  /// Copied from [relationshipById].
  const RelationshipByIdFamily();

  /// Get relationship by ID
  ///
  /// Copied from [relationshipById].
  RelationshipByIdProvider call(
    String id,
  ) {
    return RelationshipByIdProvider(
      id,
    );
  }

  @override
  RelationshipByIdProvider getProviderOverride(
    covariant RelationshipByIdProvider provider,
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
  String? get name => r'relationshipByIdProvider';
}

/// Get relationship by ID
///
/// Copied from [relationshipById].
class RelationshipByIdProvider
    extends AutoDisposeFutureProvider<TeacherStudentRelation?> {
  /// Get relationship by ID
  ///
  /// Copied from [relationshipById].
  RelationshipByIdProvider(
    String id,
  ) : this._internal(
          (ref) => relationshipById(
            ref as RelationshipByIdRef,
            id,
          ),
          from: relationshipByIdProvider,
          name: r'relationshipByIdProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$relationshipByIdHash,
          dependencies: RelationshipByIdFamily._dependencies,
          allTransitiveDependencies:
              RelationshipByIdFamily._allTransitiveDependencies,
          id: id,
        );

  RelationshipByIdProvider._internal(
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
    FutureOr<TeacherStudentRelation?> Function(RelationshipByIdRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: RelationshipByIdProvider._internal(
        (ref) => create(ref as RelationshipByIdRef),
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
  AutoDisposeFutureProviderElement<TeacherStudentRelation?> createElement() {
    return _RelationshipByIdProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RelationshipByIdProvider && other.id == id;
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
mixin RelationshipByIdRef
    on AutoDisposeFutureProviderRef<TeacherStudentRelation?> {
  /// The parameter `id` of this provider.
  String get id;
}

class _RelationshipByIdProviderElement
    extends AutoDisposeFutureProviderElement<TeacherStudentRelation?>
    with RelationshipByIdRef {
  _RelationshipByIdProviderElement(super.provider);

  @override
  String get id => (origin as RelationshipByIdProvider).id;
}

String _$teacherStudentRelationHash() =>
    r'30c13c61a4b1b7bd4b385c158a35f97bb2cfe728';

/// Get relationship between teacher and student
///
/// Copied from [teacherStudentRelation].
@ProviderFor(teacherStudentRelation)
const teacherStudentRelationProvider = TeacherStudentRelationFamily();

/// Get relationship between teacher and student
///
/// Copied from [teacherStudentRelation].
class TeacherStudentRelationFamily
    extends Family<AsyncValue<TeacherStudentRelation?>> {
  /// Get relationship between teacher and student
  ///
  /// Copied from [teacherStudentRelation].
  const TeacherStudentRelationFamily();

  /// Get relationship between teacher and student
  ///
  /// Copied from [teacherStudentRelation].
  TeacherStudentRelationProvider call({
    required String teacherId,
    required String studentId,
  }) {
    return TeacherStudentRelationProvider(
      teacherId: teacherId,
      studentId: studentId,
    );
  }

  @override
  TeacherStudentRelationProvider getProviderOverride(
    covariant TeacherStudentRelationProvider provider,
  ) {
    return call(
      teacherId: provider.teacherId,
      studentId: provider.studentId,
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
  String? get name => r'teacherStudentRelationProvider';
}

/// Get relationship between teacher and student
///
/// Copied from [teacherStudentRelation].
class TeacherStudentRelationProvider
    extends AutoDisposeFutureProvider<TeacherStudentRelation?> {
  /// Get relationship between teacher and student
  ///
  /// Copied from [teacherStudentRelation].
  TeacherStudentRelationProvider({
    required String teacherId,
    required String studentId,
  }) : this._internal(
          (ref) => teacherStudentRelation(
            ref as TeacherStudentRelationRef,
            teacherId: teacherId,
            studentId: studentId,
          ),
          from: teacherStudentRelationProvider,
          name: r'teacherStudentRelationProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$teacherStudentRelationHash,
          dependencies: TeacherStudentRelationFamily._dependencies,
          allTransitiveDependencies:
              TeacherStudentRelationFamily._allTransitiveDependencies,
          teacherId: teacherId,
          studentId: studentId,
        );

  TeacherStudentRelationProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.teacherId,
    required this.studentId,
  }) : super.internal();

  final String teacherId;
  final String studentId;

  @override
  Override overrideWith(
    FutureOr<TeacherStudentRelation?> Function(
            TeacherStudentRelationRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TeacherStudentRelationProvider._internal(
        (ref) => create(ref as TeacherStudentRelationRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        teacherId: teacherId,
        studentId: studentId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<TeacherStudentRelation?> createElement() {
    return _TeacherStudentRelationProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TeacherStudentRelationProvider &&
        other.teacherId == teacherId &&
        other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, teacherId.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin TeacherStudentRelationRef
    on AutoDisposeFutureProviderRef<TeacherStudentRelation?> {
  /// The parameter `teacherId` of this provider.
  String get teacherId;

  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _TeacherStudentRelationProviderElement
    extends AutoDisposeFutureProviderElement<TeacherStudentRelation?>
    with TeacherStudentRelationRef {
  _TeacherStudentRelationProviderElement(super.provider);

  @override
  String get teacherId => (origin as TeacherStudentRelationProvider).teacherId;
  @override
  String get studentId => (origin as TeacherStudentRelationProvider).studentId;
}

String _$teacherRelationshipsHash() =>
    r'784a329ffdcb130a0d58f063348575c18a386b4a';

/// Get all relationships for a teacher
///
/// Copied from [teacherRelationships].
@ProviderFor(teacherRelationships)
const teacherRelationshipsProvider = TeacherRelationshipsFamily();

/// Get all relationships for a teacher
///
/// Copied from [teacherRelationships].
class TeacherRelationshipsFamily
    extends Family<AsyncValue<List<TeacherStudentRelation>>> {
  /// Get all relationships for a teacher
  ///
  /// Copied from [teacherRelationships].
  const TeacherRelationshipsFamily();

  /// Get all relationships for a teacher
  ///
  /// Copied from [teacherRelationships].
  TeacherRelationshipsProvider call(
    String teacherId,
  ) {
    return TeacherRelationshipsProvider(
      teacherId,
    );
  }

  @override
  TeacherRelationshipsProvider getProviderOverride(
    covariant TeacherRelationshipsProvider provider,
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
  String? get name => r'teacherRelationshipsProvider';
}

/// Get all relationships for a teacher
///
/// Copied from [teacherRelationships].
class TeacherRelationshipsProvider
    extends AutoDisposeFutureProvider<List<TeacherStudentRelation>> {
  /// Get all relationships for a teacher
  ///
  /// Copied from [teacherRelationships].
  TeacherRelationshipsProvider(
    String teacherId,
  ) : this._internal(
          (ref) => teacherRelationships(
            ref as TeacherRelationshipsRef,
            teacherId,
          ),
          from: teacherRelationshipsProvider,
          name: r'teacherRelationshipsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$teacherRelationshipsHash,
          dependencies: TeacherRelationshipsFamily._dependencies,
          allTransitiveDependencies:
              TeacherRelationshipsFamily._allTransitiveDependencies,
          teacherId: teacherId,
        );

  TeacherRelationshipsProvider._internal(
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
    FutureOr<List<TeacherStudentRelation>> Function(
            TeacherRelationshipsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TeacherRelationshipsProvider._internal(
        (ref) => create(ref as TeacherRelationshipsRef),
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
  AutoDisposeFutureProviderElement<List<TeacherStudentRelation>>
      createElement() {
    return _TeacherRelationshipsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TeacherRelationshipsProvider &&
        other.teacherId == teacherId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, teacherId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin TeacherRelationshipsRef
    on AutoDisposeFutureProviderRef<List<TeacherStudentRelation>> {
  /// The parameter `teacherId` of this provider.
  String get teacherId;
}

class _TeacherRelationshipsProviderElement
    extends AutoDisposeFutureProviderElement<List<TeacherStudentRelation>>
    with TeacherRelationshipsRef {
  _TeacherRelationshipsProviderElement(super.provider);

  @override
  String get teacherId => (origin as TeacherRelationshipsProvider).teacherId;
}

String _$studentRelationshipsHash() =>
    r'744eb3013652d17ebf0b533eb5c80fb8931aaf9f';

/// Get all relationships for a student
///
/// Copied from [studentRelationships].
@ProviderFor(studentRelationships)
const studentRelationshipsProvider = StudentRelationshipsFamily();

/// Get all relationships for a student
///
/// Copied from [studentRelationships].
class StudentRelationshipsFamily
    extends Family<AsyncValue<List<TeacherStudentRelation>>> {
  /// Get all relationships for a student
  ///
  /// Copied from [studentRelationships].
  const StudentRelationshipsFamily();

  /// Get all relationships for a student
  ///
  /// Copied from [studentRelationships].
  StudentRelationshipsProvider call(
    String studentId,
  ) {
    return StudentRelationshipsProvider(
      studentId,
    );
  }

  @override
  StudentRelationshipsProvider getProviderOverride(
    covariant StudentRelationshipsProvider provider,
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
  String? get name => r'studentRelationshipsProvider';
}

/// Get all relationships for a student
///
/// Copied from [studentRelationships].
class StudentRelationshipsProvider
    extends AutoDisposeFutureProvider<List<TeacherStudentRelation>> {
  /// Get all relationships for a student
  ///
  /// Copied from [studentRelationships].
  StudentRelationshipsProvider(
    String studentId,
  ) : this._internal(
          (ref) => studentRelationships(
            ref as StudentRelationshipsRef,
            studentId,
          ),
          from: studentRelationshipsProvider,
          name: r'studentRelationshipsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$studentRelationshipsHash,
          dependencies: StudentRelationshipsFamily._dependencies,
          allTransitiveDependencies:
              StudentRelationshipsFamily._allTransitiveDependencies,
          studentId: studentId,
        );

  StudentRelationshipsProvider._internal(
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
    FutureOr<List<TeacherStudentRelation>> Function(
            StudentRelationshipsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: StudentRelationshipsProvider._internal(
        (ref) => create(ref as StudentRelationshipsRef),
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
  AutoDisposeFutureProviderElement<List<TeacherStudentRelation>>
      createElement() {
    return _StudentRelationshipsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StudentRelationshipsProvider &&
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
mixin StudentRelationshipsRef
    on AutoDisposeFutureProviderRef<List<TeacherStudentRelation>> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _StudentRelationshipsProviderElement
    extends AutoDisposeFutureProviderElement<List<TeacherStudentRelation>>
    with StudentRelationshipsRef {
  _StudentRelationshipsProviderElement(super.provider);

  @override
  String get studentId => (origin as StudentRelationshipsProvider).studentId;
}

String _$teacherRelationshipsByStatusHash() =>
    r'30985430f14e112cc8c3c9014bd970bde30b93ed';

/// Get relationships by status for a teacher
///
/// Copied from [teacherRelationshipsByStatus].
@ProviderFor(teacherRelationshipsByStatus)
const teacherRelationshipsByStatusProvider =
    TeacherRelationshipsByStatusFamily();

/// Get relationships by status for a teacher
///
/// Copied from [teacherRelationshipsByStatus].
class TeacherRelationshipsByStatusFamily
    extends Family<AsyncValue<List<TeacherStudentRelation>>> {
  /// Get relationships by status for a teacher
  ///
  /// Copied from [teacherRelationshipsByStatus].
  const TeacherRelationshipsByStatusFamily();

  /// Get relationships by status for a teacher
  ///
  /// Copied from [teacherRelationshipsByStatus].
  TeacherRelationshipsByStatusProvider call({
    required String teacherId,
    required RelationshipStatus status,
  }) {
    return TeacherRelationshipsByStatusProvider(
      teacherId: teacherId,
      status: status,
    );
  }

  @override
  TeacherRelationshipsByStatusProvider getProviderOverride(
    covariant TeacherRelationshipsByStatusProvider provider,
  ) {
    return call(
      teacherId: provider.teacherId,
      status: provider.status,
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
  String? get name => r'teacherRelationshipsByStatusProvider';
}

/// Get relationships by status for a teacher
///
/// Copied from [teacherRelationshipsByStatus].
class TeacherRelationshipsByStatusProvider
    extends AutoDisposeFutureProvider<List<TeacherStudentRelation>> {
  /// Get relationships by status for a teacher
  ///
  /// Copied from [teacherRelationshipsByStatus].
  TeacherRelationshipsByStatusProvider({
    required String teacherId,
    required RelationshipStatus status,
  }) : this._internal(
          (ref) => teacherRelationshipsByStatus(
            ref as TeacherRelationshipsByStatusRef,
            teacherId: teacherId,
            status: status,
          ),
          from: teacherRelationshipsByStatusProvider,
          name: r'teacherRelationshipsByStatusProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$teacherRelationshipsByStatusHash,
          dependencies: TeacherRelationshipsByStatusFamily._dependencies,
          allTransitiveDependencies:
              TeacherRelationshipsByStatusFamily._allTransitiveDependencies,
          teacherId: teacherId,
          status: status,
        );

  TeacherRelationshipsByStatusProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.teacherId,
    required this.status,
  }) : super.internal();

  final String teacherId;
  final RelationshipStatus status;

  @override
  Override overrideWith(
    FutureOr<List<TeacherStudentRelation>> Function(
            TeacherRelationshipsByStatusRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TeacherRelationshipsByStatusProvider._internal(
        (ref) => create(ref as TeacherRelationshipsByStatusRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        teacherId: teacherId,
        status: status,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<TeacherStudentRelation>>
      createElement() {
    return _TeacherRelationshipsByStatusProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TeacherRelationshipsByStatusProvider &&
        other.teacherId == teacherId &&
        other.status == status;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, teacherId.hashCode);
    hash = _SystemHash.combine(hash, status.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin TeacherRelationshipsByStatusRef
    on AutoDisposeFutureProviderRef<List<TeacherStudentRelation>> {
  /// The parameter `teacherId` of this provider.
  String get teacherId;

  /// The parameter `status` of this provider.
  RelationshipStatus get status;
}

class _TeacherRelationshipsByStatusProviderElement
    extends AutoDisposeFutureProviderElement<List<TeacherStudentRelation>>
    with TeacherRelationshipsByStatusRef {
  _TeacherRelationshipsByStatusProviderElement(super.provider);

  @override
  String get teacherId =>
      (origin as TeacherRelationshipsByStatusProvider).teacherId;
  @override
  RelationshipStatus get status =>
      (origin as TeacherRelationshipsByStatusProvider).status;
}

String _$activeStudentsHash() => r'38e1ec1b82d974c31b58e8c02383fe4c849a08c7';

/// Get active students for a teacher
///
/// Copied from [activeStudents].
@ProviderFor(activeStudents)
const activeStudentsProvider = ActiveStudentsFamily();

/// Get active students for a teacher
///
/// Copied from [activeStudents].
class ActiveStudentsFamily
    extends Family<AsyncValue<List<TeacherStudentRelation>>> {
  /// Get active students for a teacher
  ///
  /// Copied from [activeStudents].
  const ActiveStudentsFamily();

  /// Get active students for a teacher
  ///
  /// Copied from [activeStudents].
  ActiveStudentsProvider call(
    String teacherId,
  ) {
    return ActiveStudentsProvider(
      teacherId,
    );
  }

  @override
  ActiveStudentsProvider getProviderOverride(
    covariant ActiveStudentsProvider provider,
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
  String? get name => r'activeStudentsProvider';
}

/// Get active students for a teacher
///
/// Copied from [activeStudents].
class ActiveStudentsProvider
    extends AutoDisposeFutureProvider<List<TeacherStudentRelation>> {
  /// Get active students for a teacher
  ///
  /// Copied from [activeStudents].
  ActiveStudentsProvider(
    String teacherId,
  ) : this._internal(
          (ref) => activeStudents(
            ref as ActiveStudentsRef,
            teacherId,
          ),
          from: activeStudentsProvider,
          name: r'activeStudentsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$activeStudentsHash,
          dependencies: ActiveStudentsFamily._dependencies,
          allTransitiveDependencies:
              ActiveStudentsFamily._allTransitiveDependencies,
          teacherId: teacherId,
        );

  ActiveStudentsProvider._internal(
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
    FutureOr<List<TeacherStudentRelation>> Function(ActiveStudentsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ActiveStudentsProvider._internal(
        (ref) => create(ref as ActiveStudentsRef),
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
  AutoDisposeFutureProviderElement<List<TeacherStudentRelation>>
      createElement() {
    return _ActiveStudentsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ActiveStudentsProvider && other.teacherId == teacherId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, teacherId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ActiveStudentsRef
    on AutoDisposeFutureProviderRef<List<TeacherStudentRelation>> {
  /// The parameter `teacherId` of this provider.
  String get teacherId;
}

class _ActiveStudentsProviderElement
    extends AutoDisposeFutureProviderElement<List<TeacherStudentRelation>>
    with ActiveStudentsRef {
  _ActiveStudentsProviderElement(super.provider);

  @override
  String get teacherId => (origin as ActiveStudentsProvider).teacherId;
}

String _$expiredStudentsHash() => r'bc5340dd3e784b9675a50d75cec1fb0cc6984868';

/// Get expired students for a teacher (within grace period)
///
/// Copied from [expiredStudents].
@ProviderFor(expiredStudents)
const expiredStudentsProvider = ExpiredStudentsFamily();

/// Get expired students for a teacher (within grace period)
///
/// Copied from [expiredStudents].
class ExpiredStudentsFamily
    extends Family<AsyncValue<List<TeacherStudentRelation>>> {
  /// Get expired students for a teacher (within grace period)
  ///
  /// Copied from [expiredStudents].
  const ExpiredStudentsFamily();

  /// Get expired students for a teacher (within grace period)
  ///
  /// Copied from [expiredStudents].
  ExpiredStudentsProvider call(
    String teacherId,
  ) {
    return ExpiredStudentsProvider(
      teacherId,
    );
  }

  @override
  ExpiredStudentsProvider getProviderOverride(
    covariant ExpiredStudentsProvider provider,
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
  String? get name => r'expiredStudentsProvider';
}

/// Get expired students for a teacher (within grace period)
///
/// Copied from [expiredStudents].
class ExpiredStudentsProvider
    extends AutoDisposeFutureProvider<List<TeacherStudentRelation>> {
  /// Get expired students for a teacher (within grace period)
  ///
  /// Copied from [expiredStudents].
  ExpiredStudentsProvider(
    String teacherId,
  ) : this._internal(
          (ref) => expiredStudents(
            ref as ExpiredStudentsRef,
            teacherId,
          ),
          from: expiredStudentsProvider,
          name: r'expiredStudentsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$expiredStudentsHash,
          dependencies: ExpiredStudentsFamily._dependencies,
          allTransitiveDependencies:
              ExpiredStudentsFamily._allTransitiveDependencies,
          teacherId: teacherId,
        );

  ExpiredStudentsProvider._internal(
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
    FutureOr<List<TeacherStudentRelation>> Function(ExpiredStudentsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ExpiredStudentsProvider._internal(
        (ref) => create(ref as ExpiredStudentsRef),
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
  AutoDisposeFutureProviderElement<List<TeacherStudentRelation>>
      createElement() {
    return _ExpiredStudentsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ExpiredStudentsProvider && other.teacherId == teacherId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, teacherId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ExpiredStudentsRef
    on AutoDisposeFutureProviderRef<List<TeacherStudentRelation>> {
  /// The parameter `teacherId` of this provider.
  String get teacherId;
}

class _ExpiredStudentsProviderElement
    extends AutoDisposeFutureProviderElement<List<TeacherStudentRelation>>
    with ExpiredStudentsRef {
  _ExpiredStudentsProviderElement(super.provider);

  @override
  String get teacherId => (origin as ExpiredStudentsProvider).teacherId;
}

String _$pastStudentsHash() => r'd8fed19e5cb166e74d6c0a2a6abc55c0fa5fbcbc';

/// Get past students for a teacher
///
/// Copied from [pastStudents].
@ProviderFor(pastStudents)
const pastStudentsProvider = PastStudentsFamily();

/// Get past students for a teacher
///
/// Copied from [pastStudents].
class PastStudentsFamily
    extends Family<AsyncValue<List<TeacherStudentRelation>>> {
  /// Get past students for a teacher
  ///
  /// Copied from [pastStudents].
  const PastStudentsFamily();

  /// Get past students for a teacher
  ///
  /// Copied from [pastStudents].
  PastStudentsProvider call(
    String teacherId,
  ) {
    return PastStudentsProvider(
      teacherId,
    );
  }

  @override
  PastStudentsProvider getProviderOverride(
    covariant PastStudentsProvider provider,
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
  String? get name => r'pastStudentsProvider';
}

/// Get past students for a teacher
///
/// Copied from [pastStudents].
class PastStudentsProvider
    extends AutoDisposeFutureProvider<List<TeacherStudentRelation>> {
  /// Get past students for a teacher
  ///
  /// Copied from [pastStudents].
  PastStudentsProvider(
    String teacherId,
  ) : this._internal(
          (ref) => pastStudents(
            ref as PastStudentsRef,
            teacherId,
          ),
          from: pastStudentsProvider,
          name: r'pastStudentsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$pastStudentsHash,
          dependencies: PastStudentsFamily._dependencies,
          allTransitiveDependencies:
              PastStudentsFamily._allTransitiveDependencies,
          teacherId: teacherId,
        );

  PastStudentsProvider._internal(
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
    FutureOr<List<TeacherStudentRelation>> Function(PastStudentsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PastStudentsProvider._internal(
        (ref) => create(ref as PastStudentsRef),
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
  AutoDisposeFutureProviderElement<List<TeacherStudentRelation>>
      createElement() {
    return _PastStudentsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PastStudentsProvider && other.teacherId == teacherId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, teacherId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PastStudentsRef
    on AutoDisposeFutureProviderRef<List<TeacherStudentRelation>> {
  /// The parameter `teacherId` of this provider.
  String get teacherId;
}

class _PastStudentsProviderElement
    extends AutoDisposeFutureProviderElement<List<TeacherStudentRelation>>
    with PastStudentsRef {
  _PastStudentsProviderElement(super.provider);

  @override
  String get teacherId => (origin as PastStudentsProvider).teacherId;
}

String _$trialBookedStudentsHash() =>
    r'43ceb75810e1f78c437235eb87b72da72232ed79';

/// Get trial-booked students for a teacher
///
/// Copied from [trialBookedStudents].
@ProviderFor(trialBookedStudents)
const trialBookedStudentsProvider = TrialBookedStudentsFamily();

/// Get trial-booked students for a teacher
///
/// Copied from [trialBookedStudents].
class TrialBookedStudentsFamily
    extends Family<AsyncValue<List<TeacherStudentRelation>>> {
  /// Get trial-booked students for a teacher
  ///
  /// Copied from [trialBookedStudents].
  const TrialBookedStudentsFamily();

  /// Get trial-booked students for a teacher
  ///
  /// Copied from [trialBookedStudents].
  TrialBookedStudentsProvider call(
    String teacherId,
  ) {
    return TrialBookedStudentsProvider(
      teacherId,
    );
  }

  @override
  TrialBookedStudentsProvider getProviderOverride(
    covariant TrialBookedStudentsProvider provider,
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
  String? get name => r'trialBookedStudentsProvider';
}

/// Get trial-booked students for a teacher
///
/// Copied from [trialBookedStudents].
class TrialBookedStudentsProvider
    extends AutoDisposeFutureProvider<List<TeacherStudentRelation>> {
  /// Get trial-booked students for a teacher
  ///
  /// Copied from [trialBookedStudents].
  TrialBookedStudentsProvider(
    String teacherId,
  ) : this._internal(
          (ref) => trialBookedStudents(
            ref as TrialBookedStudentsRef,
            teacherId,
          ),
          from: trialBookedStudentsProvider,
          name: r'trialBookedStudentsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$trialBookedStudentsHash,
          dependencies: TrialBookedStudentsFamily._dependencies,
          allTransitiveDependencies:
              TrialBookedStudentsFamily._allTransitiveDependencies,
          teacherId: teacherId,
        );

  TrialBookedStudentsProvider._internal(
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
    FutureOr<List<TeacherStudentRelation>> Function(
            TrialBookedStudentsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TrialBookedStudentsProvider._internal(
        (ref) => create(ref as TrialBookedStudentsRef),
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
  AutoDisposeFutureProviderElement<List<TeacherStudentRelation>>
      createElement() {
    return _TrialBookedStudentsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TrialBookedStudentsProvider && other.teacherId == teacherId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, teacherId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin TrialBookedStudentsRef
    on AutoDisposeFutureProviderRef<List<TeacherStudentRelation>> {
  /// The parameter `teacherId` of this provider.
  String get teacherId;
}

class _TrialBookedStudentsProviderElement
    extends AutoDisposeFutureProviderElement<List<TeacherStudentRelation>>
    with TrialBookedStudentsRef {
  _TrialBookedStudentsProviderElement(super.provider);

  @override
  String get teacherId => (origin as TrialBookedStudentsProvider).teacherId;
}

String _$manuallyRegisteredStudentsHash() =>
    r'6601cf21b1cd36d57698424b848e007ede761f52';

/// Get manually registered (offline) students for a teacher
///
/// Copied from [manuallyRegisteredStudents].
@ProviderFor(manuallyRegisteredStudents)
const manuallyRegisteredStudentsProvider = ManuallyRegisteredStudentsFamily();

/// Get manually registered (offline) students for a teacher
///
/// Copied from [manuallyRegisteredStudents].
class ManuallyRegisteredStudentsFamily
    extends Family<AsyncValue<List<TeacherStudentRelation>>> {
  /// Get manually registered (offline) students for a teacher
  ///
  /// Copied from [manuallyRegisteredStudents].
  const ManuallyRegisteredStudentsFamily();

  /// Get manually registered (offline) students for a teacher
  ///
  /// Copied from [manuallyRegisteredStudents].
  ManuallyRegisteredStudentsProvider call(
    String teacherId,
  ) {
    return ManuallyRegisteredStudentsProvider(
      teacherId,
    );
  }

  @override
  ManuallyRegisteredStudentsProvider getProviderOverride(
    covariant ManuallyRegisteredStudentsProvider provider,
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
  String? get name => r'manuallyRegisteredStudentsProvider';
}

/// Get manually registered (offline) students for a teacher
///
/// Copied from [manuallyRegisteredStudents].
class ManuallyRegisteredStudentsProvider
    extends AutoDisposeFutureProvider<List<TeacherStudentRelation>> {
  /// Get manually registered (offline) students for a teacher
  ///
  /// Copied from [manuallyRegisteredStudents].
  ManuallyRegisteredStudentsProvider(
    String teacherId,
  ) : this._internal(
          (ref) => manuallyRegisteredStudents(
            ref as ManuallyRegisteredStudentsRef,
            teacherId,
          ),
          from: manuallyRegisteredStudentsProvider,
          name: r'manuallyRegisteredStudentsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$manuallyRegisteredStudentsHash,
          dependencies: ManuallyRegisteredStudentsFamily._dependencies,
          allTransitiveDependencies:
              ManuallyRegisteredStudentsFamily._allTransitiveDependencies,
          teacherId: teacherId,
        );

  ManuallyRegisteredStudentsProvider._internal(
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
    FutureOr<List<TeacherStudentRelation>> Function(
            ManuallyRegisteredStudentsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ManuallyRegisteredStudentsProvider._internal(
        (ref) => create(ref as ManuallyRegisteredStudentsRef),
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
  AutoDisposeFutureProviderElement<List<TeacherStudentRelation>>
      createElement() {
    return _ManuallyRegisteredStudentsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ManuallyRegisteredStudentsProvider &&
        other.teacherId == teacherId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, teacherId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ManuallyRegisteredStudentsRef
    on AutoDisposeFutureProviderRef<List<TeacherStudentRelation>> {
  /// The parameter `teacherId` of this provider.
  String get teacherId;
}

class _ManuallyRegisteredStudentsProviderElement
    extends AutoDisposeFutureProviderElement<List<TeacherStudentRelation>>
    with ManuallyRegisteredStudentsRef {
  _ManuallyRegisteredStudentsProviderElement(super.provider);

  @override
  String get teacherId =>
      (origin as ManuallyRegisteredStudentsProvider).teacherId;
}

String _$relationshipNotificationSettingHash() =>
    r'36100d67b9e59fe8c318fea2353e85f934b383e1';

/// Get notification setting for a relationship
///
/// Copied from [relationshipNotificationSetting].
@ProviderFor(relationshipNotificationSetting)
const relationshipNotificationSettingProvider =
    RelationshipNotificationSettingFamily();

/// Get notification setting for a relationship
///
/// Copied from [relationshipNotificationSetting].
class RelationshipNotificationSettingFamily
    extends Family<AsyncValue<NotificationSetting?>> {
  /// Get notification setting for a relationship
  ///
  /// Copied from [relationshipNotificationSetting].
  const RelationshipNotificationSettingFamily();

  /// Get notification setting for a relationship
  ///
  /// Copied from [relationshipNotificationSetting].
  RelationshipNotificationSettingProvider call({
    required String userId,
    required String targetUserId,
  }) {
    return RelationshipNotificationSettingProvider(
      userId: userId,
      targetUserId: targetUserId,
    );
  }

  @override
  RelationshipNotificationSettingProvider getProviderOverride(
    covariant RelationshipNotificationSettingProvider provider,
  ) {
    return call(
      userId: provider.userId,
      targetUserId: provider.targetUserId,
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
  String? get name => r'relationshipNotificationSettingProvider';
}

/// Get notification setting for a relationship
///
/// Copied from [relationshipNotificationSetting].
class RelationshipNotificationSettingProvider
    extends AutoDisposeFutureProvider<NotificationSetting?> {
  /// Get notification setting for a relationship
  ///
  /// Copied from [relationshipNotificationSetting].
  RelationshipNotificationSettingProvider({
    required String userId,
    required String targetUserId,
  }) : this._internal(
          (ref) => relationshipNotificationSetting(
            ref as RelationshipNotificationSettingRef,
            userId: userId,
            targetUserId: targetUserId,
          ),
          from: relationshipNotificationSettingProvider,
          name: r'relationshipNotificationSettingProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$relationshipNotificationSettingHash,
          dependencies: RelationshipNotificationSettingFamily._dependencies,
          allTransitiveDependencies:
              RelationshipNotificationSettingFamily._allTransitiveDependencies,
          userId: userId,
          targetUserId: targetUserId,
        );

  RelationshipNotificationSettingProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.userId,
    required this.targetUserId,
  }) : super.internal();

  final String userId;
  final String targetUserId;

  @override
  Override overrideWith(
    FutureOr<NotificationSetting?> Function(
            RelationshipNotificationSettingRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: RelationshipNotificationSettingProvider._internal(
        (ref) => create(ref as RelationshipNotificationSettingRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        userId: userId,
        targetUserId: targetUserId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<NotificationSetting?> createElement() {
    return _RelationshipNotificationSettingProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RelationshipNotificationSettingProvider &&
        other.userId == userId &&
        other.targetUserId == targetUserId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);
    hash = _SystemHash.combine(hash, targetUserId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin RelationshipNotificationSettingRef
    on AutoDisposeFutureProviderRef<NotificationSetting?> {
  /// The parameter `userId` of this provider.
  String get userId;

  /// The parameter `targetUserId` of this provider.
  String get targetUserId;
}

class _RelationshipNotificationSettingProviderElement
    extends AutoDisposeFutureProviderElement<NotificationSetting?>
    with RelationshipNotificationSettingRef {
  _RelationshipNotificationSettingProviderElement(super.provider);

  @override
  String get userId =>
      (origin as RelationshipNotificationSettingProvider).userId;
  @override
  String get targetUserId =>
      (origin as RelationshipNotificationSettingProvider).targetUserId;
}

String _$previousScheduleHash() => r'5bed7718bdc1b9ee2eec193267cfe4e7ad120e55';

/// Get previous schedule for a student-teacher pair.
/// Returns the last known regular lesson schedule for re-enrollment restoration.
///
/// Copied from [previousSchedule].
@ProviderFor(previousSchedule)
const previousScheduleProvider = PreviousScheduleFamily();

/// Get previous schedule for a student-teacher pair.
/// Returns the last known regular lesson schedule for re-enrollment restoration.
///
/// Copied from [previousSchedule].
class PreviousScheduleFamily extends Family<AsyncValue<PreviousSchedule?>> {
  /// Get previous schedule for a student-teacher pair.
  /// Returns the last known regular lesson schedule for re-enrollment restoration.
  ///
  /// Copied from [previousSchedule].
  const PreviousScheduleFamily();

  /// Get previous schedule for a student-teacher pair.
  /// Returns the last known regular lesson schedule for re-enrollment restoration.
  ///
  /// Copied from [previousSchedule].
  PreviousScheduleProvider call({
    required String teacherId,
    required String studentId,
  }) {
    return PreviousScheduleProvider(
      teacherId: teacherId,
      studentId: studentId,
    );
  }

  @override
  PreviousScheduleProvider getProviderOverride(
    covariant PreviousScheduleProvider provider,
  ) {
    return call(
      teacherId: provider.teacherId,
      studentId: provider.studentId,
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
  String? get name => r'previousScheduleProvider';
}

/// Get previous schedule for a student-teacher pair.
/// Returns the last known regular lesson schedule for re-enrollment restoration.
///
/// Copied from [previousSchedule].
class PreviousScheduleProvider
    extends AutoDisposeFutureProvider<PreviousSchedule?> {
  /// Get previous schedule for a student-teacher pair.
  /// Returns the last known regular lesson schedule for re-enrollment restoration.
  ///
  /// Copied from [previousSchedule].
  PreviousScheduleProvider({
    required String teacherId,
    required String studentId,
  }) : this._internal(
          (ref) => previousSchedule(
            ref as PreviousScheduleRef,
            teacherId: teacherId,
            studentId: studentId,
          ),
          from: previousScheduleProvider,
          name: r'previousScheduleProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$previousScheduleHash,
          dependencies: PreviousScheduleFamily._dependencies,
          allTransitiveDependencies:
              PreviousScheduleFamily._allTransitiveDependencies,
          teacherId: teacherId,
          studentId: studentId,
        );

  PreviousScheduleProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.teacherId,
    required this.studentId,
  }) : super.internal();

  final String teacherId;
  final String studentId;

  @override
  Override overrideWith(
    FutureOr<PreviousSchedule?> Function(PreviousScheduleRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PreviousScheduleProvider._internal(
        (ref) => create(ref as PreviousScheduleRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        teacherId: teacherId,
        studentId: studentId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<PreviousSchedule?> createElement() {
    return _PreviousScheduleProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PreviousScheduleProvider &&
        other.teacherId == teacherId &&
        other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, teacherId.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PreviousScheduleRef on AutoDisposeFutureProviderRef<PreviousSchedule?> {
  /// The parameter `teacherId` of this provider.
  String get teacherId;

  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _PreviousScheduleProviderElement
    extends AutoDisposeFutureProviderElement<PreviousSchedule?>
    with PreviousScheduleRef {
  _PreviousScheduleProviderElement(super.provider);

  @override
  String get teacherId => (origin as PreviousScheduleProvider).teacherId;
  @override
  String get studentId => (origin as PreviousScheduleProvider).studentId;
}

String _$scheduleRecorderHash() => r'810a009f67b762bb886bcdbec5820f69f742cef3';

/// Record schedule for a student-teacher relationship.
/// Call this when regular lessons are confirmed or schedule changes.
///
/// Copied from [ScheduleRecorder].
@ProviderFor(ScheduleRecorder)
final scheduleRecorderProvider =
    AutoDisposeAsyncNotifierProvider<ScheduleRecorder, void>.internal(
  ScheduleRecorder.new,
  name: r'scheduleRecorderProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$scheduleRecorderHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ScheduleRecorder = AutoDisposeAsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
