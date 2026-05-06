// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'parent_crud_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$parentsHash() => r'eaf43fe5eb6bfd745343b4e2e3f4122859f47b49';

/// All parents provider
///
/// Copied from [parents].
@ProviderFor(parents)
final parentsProvider = FutureProvider<List<Parent>>.internal(
  parents,
  name: r'parentsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$parentsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ParentsRef = FutureProviderRef<List<Parent>>;
String _$parentHash() => r'705d082cbe1a7bb119ae3a39c8823e310c88b36e';

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

/// Single parent provider by ID
///
/// Copied from [parent].
@ProviderFor(parent)
const parentProvider = ParentFamily();

/// Single parent provider by ID
///
/// Copied from [parent].
class ParentFamily extends Family<AsyncValue<Parent?>> {
  /// Single parent provider by ID
  ///
  /// Copied from [parent].
  const ParentFamily();

  /// Single parent provider by ID
  ///
  /// Copied from [parent].
  ParentProvider call(String id) {
    return ParentProvider(id);
  }

  @override
  ParentProvider getProviderOverride(covariant ParentProvider provider) {
    return call(provider.id);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'parentProvider';
}

/// Single parent provider by ID
///
/// Copied from [parent].
class ParentProvider extends FutureProvider<Parent?> {
  /// Single parent provider by ID
  ///
  /// Copied from [parent].
  ParentProvider(String id)
    : this._internal(
        (ref) => parent(ref as ParentRef, id),
        from: parentProvider,
        name: r'parentProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product') ? null : _$parentHash,
        dependencies: ParentFamily._dependencies,
        allTransitiveDependencies: ParentFamily._allTransitiveDependencies,
        id: id,
      );

  ParentProvider._internal(
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
  Override overrideWith(FutureOr<Parent?> Function(ParentRef provider) create) {
    return ProviderOverride(
      origin: this,
      override: ParentProvider._internal(
        (ref) => create(ref as ParentRef),
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
  FutureProviderElement<Parent?> createElement() {
    return _ParentProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ParentProvider && other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin ParentRef on FutureProviderRef<Parent?> {
  /// The parameter `id` of this provider.
  String get id;
}

class _ParentProviderElement extends FutureProviderElement<Parent?>
    with ParentRef {
  _ParentProviderElement(super.provider);

  @override
  String get id => (origin as ParentProvider).id;
}

String _$parentByUserIdHash() => r'b6e3755772f0d44ab5bb8ef9944b8e3599855b91';

/// Parent by user ID provider
///
/// Copied from [parentByUserId].
@ProviderFor(parentByUserId)
const parentByUserIdProvider = ParentByUserIdFamily();

/// Parent by user ID provider
///
/// Copied from [parentByUserId].
class ParentByUserIdFamily extends Family<AsyncValue<Parent?>> {
  /// Parent by user ID provider
  ///
  /// Copied from [parentByUserId].
  const ParentByUserIdFamily();

  /// Parent by user ID provider
  ///
  /// Copied from [parentByUserId].
  ParentByUserIdProvider call(String userId) {
    return ParentByUserIdProvider(userId);
  }

  @override
  ParentByUserIdProvider getProviderOverride(
    covariant ParentByUserIdProvider provider,
  ) {
    return call(provider.userId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'parentByUserIdProvider';
}

/// Parent by user ID provider
///
/// Copied from [parentByUserId].
class ParentByUserIdProvider extends FutureProvider<Parent?> {
  /// Parent by user ID provider
  ///
  /// Copied from [parentByUserId].
  ParentByUserIdProvider(String userId)
    : this._internal(
        (ref) => parentByUserId(ref as ParentByUserIdRef, userId),
        from: parentByUserIdProvider,
        name: r'parentByUserIdProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$parentByUserIdHash,
        dependencies: ParentByUserIdFamily._dependencies,
        allTransitiveDependencies:
            ParentByUserIdFamily._allTransitiveDependencies,
        userId: userId,
      );

  ParentByUserIdProvider._internal(
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
  Override overrideWith(
    FutureOr<Parent?> Function(ParentByUserIdRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ParentByUserIdProvider._internal(
        (ref) => create(ref as ParentByUserIdRef),
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
  FutureProviderElement<Parent?> createElement() {
    return _ParentByUserIdProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ParentByUserIdProvider && other.userId == userId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin ParentByUserIdRef on FutureProviderRef<Parent?> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _ParentByUserIdProviderElement extends FutureProviderElement<Parent?>
    with ParentByUserIdRef {
  _ParentByUserIdProviderElement(super.provider);

  @override
  String get userId => (origin as ParentByUserIdProvider).userId;
}

String _$invitationByCodeHash() => r'fab755012bb39d29c88b6d92b2387b93af671ffe';

/// Invitation by code provider
///
/// Copied from [invitationByCode].
@ProviderFor(invitationByCode)
const invitationByCodeProvider = InvitationByCodeFamily();

/// Invitation by code provider
///
/// Copied from [invitationByCode].
class InvitationByCodeFamily extends Family<AsyncValue<ParentInvitation?>> {
  /// Invitation by code provider
  ///
  /// Copied from [invitationByCode].
  const InvitationByCodeFamily();

  /// Invitation by code provider
  ///
  /// Copied from [invitationByCode].
  InvitationByCodeProvider call(String code) {
    return InvitationByCodeProvider(code);
  }

  @override
  InvitationByCodeProvider getProviderOverride(
    covariant InvitationByCodeProvider provider,
  ) {
    return call(provider.code);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'invitationByCodeProvider';
}

/// Invitation by code provider
///
/// Copied from [invitationByCode].
class InvitationByCodeProvider extends FutureProvider<ParentInvitation?> {
  /// Invitation by code provider
  ///
  /// Copied from [invitationByCode].
  InvitationByCodeProvider(String code)
    : this._internal(
        (ref) => invitationByCode(ref as InvitationByCodeRef, code),
        from: invitationByCodeProvider,
        name: r'invitationByCodeProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$invitationByCodeHash,
        dependencies: InvitationByCodeFamily._dependencies,
        allTransitiveDependencies:
            InvitationByCodeFamily._allTransitiveDependencies,
        code: code,
      );

  InvitationByCodeProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.code,
  }) : super.internal();

  final String code;

  @override
  Override overrideWith(
    FutureOr<ParentInvitation?> Function(InvitationByCodeRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: InvitationByCodeProvider._internal(
        (ref) => create(ref as InvitationByCodeRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        code: code,
      ),
    );
  }

  @override
  FutureProviderElement<ParentInvitation?> createElement() {
    return _InvitationByCodeProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is InvitationByCodeProvider && other.code == code;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, code.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin InvitationByCodeRef on FutureProviderRef<ParentInvitation?> {
  /// The parameter `code` of this provider.
  String get code;
}

class _InvitationByCodeProviderElement
    extends FutureProviderElement<ParentInvitation?>
    with InvitationByCodeRef {
  _InvitationByCodeProviderElement(super.provider);

  @override
  String get code => (origin as InvitationByCodeProvider).code;
}

String _$pendingInvitationsHash() =>
    r'286fee35fb19aac54a5d29e05b620eaf7452eb6b';

/// Pending invitations for a student
///
/// Copied from [pendingInvitations].
@ProviderFor(pendingInvitations)
const pendingInvitationsProvider = PendingInvitationsFamily();

/// Pending invitations for a student
///
/// Copied from [pendingInvitations].
class PendingInvitationsFamily
    extends Family<AsyncValue<List<ParentInvitation>>> {
  /// Pending invitations for a student
  ///
  /// Copied from [pendingInvitations].
  const PendingInvitationsFamily();

  /// Pending invitations for a student
  ///
  /// Copied from [pendingInvitations].
  PendingInvitationsProvider call(String studentId) {
    return PendingInvitationsProvider(studentId);
  }

  @override
  PendingInvitationsProvider getProviderOverride(
    covariant PendingInvitationsProvider provider,
  ) {
    return call(provider.studentId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'pendingInvitationsProvider';
}

/// Pending invitations for a student
///
/// Copied from [pendingInvitations].
class PendingInvitationsProvider
    extends FutureProvider<List<ParentInvitation>> {
  /// Pending invitations for a student
  ///
  /// Copied from [pendingInvitations].
  PendingInvitationsProvider(String studentId)
    : this._internal(
        (ref) => pendingInvitations(ref as PendingInvitationsRef, studentId),
        from: pendingInvitationsProvider,
        name: r'pendingInvitationsProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$pendingInvitationsHash,
        dependencies: PendingInvitationsFamily._dependencies,
        allTransitiveDependencies:
            PendingInvitationsFamily._allTransitiveDependencies,
        studentId: studentId,
      );

  PendingInvitationsProvider._internal(
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
    FutureOr<List<ParentInvitation>> Function(PendingInvitationsRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PendingInvitationsProvider._internal(
        (ref) => create(ref as PendingInvitationsRef),
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
  FutureProviderElement<List<ParentInvitation>> createElement() {
    return _PendingInvitationsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PendingInvitationsProvider && other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin PendingInvitationsRef on FutureProviderRef<List<ParentInvitation>> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _PendingInvitationsProviderElement
    extends FutureProviderElement<List<ParentInvitation>>
    with PendingInvitationsRef {
  _PendingInvitationsProviderElement(super.provider);

  @override
  String get studentId => (origin as PendingInvitationsProvider).studentId;
}

String _$relationsForParentHash() =>
    r'4c4f09793acf3cd8f88c4ea9e8090e7154a5bb18';

/// Relations for a parent (their children)
///
/// Copied from [relationsForParent].
@ProviderFor(relationsForParent)
const relationsForParentProvider = RelationsForParentFamily();

/// Relations for a parent (their children)
///
/// Copied from [relationsForParent].
class RelationsForParentFamily
    extends Family<AsyncValue<List<ParentChildRelation>>> {
  /// Relations for a parent (their children)
  ///
  /// Copied from [relationsForParent].
  const RelationsForParentFamily();

  /// Relations for a parent (their children)
  ///
  /// Copied from [relationsForParent].
  RelationsForParentProvider call(String parentId) {
    return RelationsForParentProvider(parentId);
  }

  @override
  RelationsForParentProvider getProviderOverride(
    covariant RelationsForParentProvider provider,
  ) {
    return call(provider.parentId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'relationsForParentProvider';
}

/// Relations for a parent (their children)
///
/// Copied from [relationsForParent].
class RelationsForParentProvider
    extends FutureProvider<List<ParentChildRelation>> {
  /// Relations for a parent (their children)
  ///
  /// Copied from [relationsForParent].
  RelationsForParentProvider(String parentId)
    : this._internal(
        (ref) => relationsForParent(ref as RelationsForParentRef, parentId),
        from: relationsForParentProvider,
        name: r'relationsForParentProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$relationsForParentHash,
        dependencies: RelationsForParentFamily._dependencies,
        allTransitiveDependencies:
            RelationsForParentFamily._allTransitiveDependencies,
        parentId: parentId,
      );

  RelationsForParentProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.parentId,
  }) : super.internal();

  final String parentId;

  @override
  Override overrideWith(
    FutureOr<List<ParentChildRelation>> Function(RelationsForParentRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: RelationsForParentProvider._internal(
        (ref) => create(ref as RelationsForParentRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        parentId: parentId,
      ),
    );
  }

  @override
  FutureProviderElement<List<ParentChildRelation>> createElement() {
    return _RelationsForParentProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RelationsForParentProvider && other.parentId == parentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, parentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin RelationsForParentRef on FutureProviderRef<List<ParentChildRelation>> {
  /// The parameter `parentId` of this provider.
  String get parentId;
}

class _RelationsForParentProviderElement
    extends FutureProviderElement<List<ParentChildRelation>>
    with RelationsForParentRef {
  _RelationsForParentProviderElement(super.provider);

  @override
  String get parentId => (origin as RelationsForParentProvider).parentId;
}

String _$relationsForStudentHash() =>
    r'7f3c2b75dc879b2c46c2c228bb957a5b039690af';

/// Relations for a student (their parents)
///
/// Copied from [relationsForStudent].
@ProviderFor(relationsForStudent)
const relationsForStudentProvider = RelationsForStudentFamily();

/// Relations for a student (their parents)
///
/// Copied from [relationsForStudent].
class RelationsForStudentFamily
    extends Family<AsyncValue<List<ParentChildRelation>>> {
  /// Relations for a student (their parents)
  ///
  /// Copied from [relationsForStudent].
  const RelationsForStudentFamily();

  /// Relations for a student (their parents)
  ///
  /// Copied from [relationsForStudent].
  RelationsForStudentProvider call(String studentId) {
    return RelationsForStudentProvider(studentId);
  }

  @override
  RelationsForStudentProvider getProviderOverride(
    covariant RelationsForStudentProvider provider,
  ) {
    return call(provider.studentId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'relationsForStudentProvider';
}

/// Relations for a student (their parents)
///
/// Copied from [relationsForStudent].
class RelationsForStudentProvider
    extends FutureProvider<List<ParentChildRelation>> {
  /// Relations for a student (their parents)
  ///
  /// Copied from [relationsForStudent].
  RelationsForStudentProvider(String studentId)
    : this._internal(
        (ref) => relationsForStudent(ref as RelationsForStudentRef, studentId),
        from: relationsForStudentProvider,
        name: r'relationsForStudentProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$relationsForStudentHash,
        dependencies: RelationsForStudentFamily._dependencies,
        allTransitiveDependencies:
            RelationsForStudentFamily._allTransitiveDependencies,
        studentId: studentId,
      );

  RelationsForStudentProvider._internal(
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
    FutureOr<List<ParentChildRelation>> Function(
      RelationsForStudentRef provider,
    )
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: RelationsForStudentProvider._internal(
        (ref) => create(ref as RelationsForStudentRef),
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
  FutureProviderElement<List<ParentChildRelation>> createElement() {
    return _RelationsForStudentProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RelationsForStudentProvider && other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin RelationsForStudentRef on FutureProviderRef<List<ParentChildRelation>> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _RelationsForStudentProviderElement
    extends FutureProviderElement<List<ParentChildRelation>>
    with RelationsForStudentRef {
  _RelationsForStudentProviderElement(super.provider);

  @override
  String get studentId => (origin as RelationsForStudentProvider).studentId;
}

String _$parentStudentRelationHash() =>
    r'228fc4fd8d37e2d5343a53640d483b4349b4ee15';

/// Single relation between parent and student
///
/// Copied from [parentStudentRelation].
@ProviderFor(parentStudentRelation)
const parentStudentRelationProvider = ParentStudentRelationFamily();

/// Single relation between parent and student
///
/// Copied from [parentStudentRelation].
class ParentStudentRelationFamily
    extends Family<AsyncValue<ParentChildRelation?>> {
  /// Single relation between parent and student
  ///
  /// Copied from [parentStudentRelation].
  const ParentStudentRelationFamily();

  /// Single relation between parent and student
  ///
  /// Copied from [parentStudentRelation].
  ParentStudentRelationProvider call(
    ({String parentId, String studentId}) params,
  ) {
    return ParentStudentRelationProvider(params);
  }

  @override
  ParentStudentRelationProvider getProviderOverride(
    covariant ParentStudentRelationProvider provider,
  ) {
    return call(provider.params);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'parentStudentRelationProvider';
}

/// Single relation between parent and student
///
/// Copied from [parentStudentRelation].
class ParentStudentRelationProvider
    extends FutureProvider<ParentChildRelation?> {
  /// Single relation between parent and student
  ///
  /// Copied from [parentStudentRelation].
  ParentStudentRelationProvider(({String parentId, String studentId}) params)
    : this._internal(
        (ref) => parentStudentRelation(ref as ParentStudentRelationRef, params),
        from: parentStudentRelationProvider,
        name: r'parentStudentRelationProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$parentStudentRelationHash,
        dependencies: ParentStudentRelationFamily._dependencies,
        allTransitiveDependencies:
            ParentStudentRelationFamily._allTransitiveDependencies,
        params: params,
      );

  ParentStudentRelationProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.params,
  }) : super.internal();

  final ({String parentId, String studentId}) params;

  @override
  Override overrideWith(
    FutureOr<ParentChildRelation?> Function(ParentStudentRelationRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ParentStudentRelationProvider._internal(
        (ref) => create(ref as ParentStudentRelationRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        params: params,
      ),
    );
  }

  @override
  FutureProviderElement<ParentChildRelation?> createElement() {
    return _ParentStudentRelationProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ParentStudentRelationProvider && other.params == params;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, params.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin ParentStudentRelationRef on FutureProviderRef<ParentChildRelation?> {
  /// The parameter `params` of this provider.
  ({String parentId, String studentId}) get params;
}

class _ParentStudentRelationProviderElement
    extends FutureProviderElement<ParentChildRelation?>
    with ParentStudentRelationRef {
  _ParentStudentRelationProviderElement(super.provider);

  @override
  ({String parentId, String studentId}) get params =>
      (origin as ParentStudentRelationProvider).params;
}

String _$visibilitySettingsHash() =>
    r'a0e535bf54da79d514716abc817542d69bda0789';

/// Visibility settings for a student (set by teacher)
///
/// Copied from [visibilitySettings].
@ProviderFor(visibilitySettings)
const visibilitySettingsProvider = VisibilitySettingsFamily();

/// Visibility settings for a student (set by teacher)
///
/// Copied from [visibilitySettings].
class VisibilitySettingsFamily
    extends Family<AsyncValue<ParentVisibilitySettings?>> {
  /// Visibility settings for a student (set by teacher)
  ///
  /// Copied from [visibilitySettings].
  const VisibilitySettingsFamily();

  /// Visibility settings for a student (set by teacher)
  ///
  /// Copied from [visibilitySettings].
  VisibilitySettingsProvider call(
    ({String studentId, String teacherId}) params,
  ) {
    return VisibilitySettingsProvider(params);
  }

  @override
  VisibilitySettingsProvider getProviderOverride(
    covariant VisibilitySettingsProvider provider,
  ) {
    return call(provider.params);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'visibilitySettingsProvider';
}

/// Visibility settings for a student (set by teacher)
///
/// Copied from [visibilitySettings].
class VisibilitySettingsProvider
    extends FutureProvider<ParentVisibilitySettings?> {
  /// Visibility settings for a student (set by teacher)
  ///
  /// Copied from [visibilitySettings].
  VisibilitySettingsProvider(({String studentId, String teacherId}) params)
    : this._internal(
        (ref) => visibilitySettings(ref as VisibilitySettingsRef, params),
        from: visibilitySettingsProvider,
        name: r'visibilitySettingsProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$visibilitySettingsHash,
        dependencies: VisibilitySettingsFamily._dependencies,
        allTransitiveDependencies:
            VisibilitySettingsFamily._allTransitiveDependencies,
        params: params,
      );

  VisibilitySettingsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.params,
  }) : super.internal();

  final ({String studentId, String teacherId}) params;

  @override
  Override overrideWith(
    FutureOr<ParentVisibilitySettings?> Function(VisibilitySettingsRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: VisibilitySettingsProvider._internal(
        (ref) => create(ref as VisibilitySettingsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        params: params,
      ),
    );
  }

  @override
  FutureProviderElement<ParentVisibilitySettings?> createElement() {
    return _VisibilitySettingsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is VisibilitySettingsProvider && other.params == params;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, params.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin VisibilitySettingsRef on FutureProviderRef<ParentVisibilitySettings?> {
  /// The parameter `params` of this provider.
  ({String studentId, String teacherId}) get params;
}

class _VisibilitySettingsProviderElement
    extends FutureProviderElement<ParentVisibilitySettings?>
    with VisibilitySettingsRef {
  _VisibilitySettingsProviderElement(super.provider);

  @override
  ({String studentId, String teacherId}) get params =>
      (origin as VisibilitySettingsProvider).params;
}

String _$notificationSettingsHash() =>
    r'b2586cea47c1f8b4874e8bde2a957857ac4dcfba';

/// Notification settings for a parent
///
/// Copied from [notificationSettings].
@ProviderFor(notificationSettings)
const notificationSettingsProvider = NotificationSettingsFamily();

/// Notification settings for a parent
///
/// Copied from [notificationSettings].
class NotificationSettingsFamily
    extends Family<AsyncValue<ParentNotificationSettings?>> {
  /// Notification settings for a parent
  ///
  /// Copied from [notificationSettings].
  const NotificationSettingsFamily();

  /// Notification settings for a parent
  ///
  /// Copied from [notificationSettings].
  NotificationSettingsProvider call(String parentId) {
    return NotificationSettingsProvider(parentId);
  }

  @override
  NotificationSettingsProvider getProviderOverride(
    covariant NotificationSettingsProvider provider,
  ) {
    return call(provider.parentId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'notificationSettingsProvider';
}

/// Notification settings for a parent
///
/// Copied from [notificationSettings].
class NotificationSettingsProvider
    extends FutureProvider<ParentNotificationSettings?> {
  /// Notification settings for a parent
  ///
  /// Copied from [notificationSettings].
  NotificationSettingsProvider(String parentId)
    : this._internal(
        (ref) => notificationSettings(ref as NotificationSettingsRef, parentId),
        from: notificationSettingsProvider,
        name: r'notificationSettingsProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$notificationSettingsHash,
        dependencies: NotificationSettingsFamily._dependencies,
        allTransitiveDependencies:
            NotificationSettingsFamily._allTransitiveDependencies,
        parentId: parentId,
      );

  NotificationSettingsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.parentId,
  }) : super.internal();

  final String parentId;

  @override
  Override overrideWith(
    FutureOr<ParentNotificationSettings?> Function(
      NotificationSettingsRef provider,
    )
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: NotificationSettingsProvider._internal(
        (ref) => create(ref as NotificationSettingsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        parentId: parentId,
      ),
    );
  }

  @override
  FutureProviderElement<ParentNotificationSettings?> createElement() {
    return _NotificationSettingsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is NotificationSettingsProvider && other.parentId == parentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, parentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin NotificationSettingsRef
    on FutureProviderRef<ParentNotificationSettings?> {
  /// The parameter `parentId` of this provider.
  String get parentId;
}

class _NotificationSettingsProviderElement
    extends FutureProviderElement<ParentNotificationSettings?>
    with NotificationSettingsRef {
  _NotificationSettingsProviderElement(super.provider);

  @override
  String get parentId => (origin as NotificationSettingsProvider).parentId;
}

String _$billingTargetHash() => r'fd9192bd17764d82a8bbc9db473a9f8393b46815';

/// Billing target parent for a student
///
/// Copied from [billingTarget].
@ProviderFor(billingTarget)
const billingTargetProvider = BillingTargetFamily();

/// Billing target parent for a student
///
/// Copied from [billingTarget].
class BillingTargetFamily extends Family<AsyncValue<Parent?>> {
  /// Billing target parent for a student
  ///
  /// Copied from [billingTarget].
  const BillingTargetFamily();

  /// Billing target parent for a student
  ///
  /// Copied from [billingTarget].
  BillingTargetProvider call(String studentId) {
    return BillingTargetProvider(studentId);
  }

  @override
  BillingTargetProvider getProviderOverride(
    covariant BillingTargetProvider provider,
  ) {
    return call(provider.studentId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'billingTargetProvider';
}

/// Billing target parent for a student
///
/// Copied from [billingTarget].
class BillingTargetProvider extends FutureProvider<Parent?> {
  /// Billing target parent for a student
  ///
  /// Copied from [billingTarget].
  BillingTargetProvider(String studentId)
    : this._internal(
        (ref) => billingTarget(ref as BillingTargetRef, studentId),
        from: billingTargetProvider,
        name: r'billingTargetProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$billingTargetHash,
        dependencies: BillingTargetFamily._dependencies,
        allTransitiveDependencies:
            BillingTargetFamily._allTransitiveDependencies,
        studentId: studentId,
      );

  BillingTargetProvider._internal(
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
    FutureOr<Parent?> Function(BillingTargetRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: BillingTargetProvider._internal(
        (ref) => create(ref as BillingTargetRef),
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
  FutureProviderElement<Parent?> createElement() {
    return _BillingTargetProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BillingTargetProvider && other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin BillingTargetRef on FutureProviderRef<Parent?> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _BillingTargetProviderElement extends FutureProviderElement<Parent?>
    with BillingTargetRef {
  _BillingTargetProviderElement(super.provider);

  @override
  String get studentId => (origin as BillingTargetProvider).studentId;
}

String _$parentsNotifierHash() => r'43844435e10d7ec2845987048432b26f481dc294';

/// Parent list notifier for CRUD operations
///
/// Copied from [ParentsNotifier].
@ProviderFor(ParentsNotifier)
final parentsNotifierProvider =
    AsyncNotifierProvider<ParentsNotifier, List<Parent>>.internal(
      ParentsNotifier.new,
      name: r'parentsNotifierProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$parentsNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ParentsNotifier = AsyncNotifier<List<Parent>>;
String _$invitationsNotifierHash() =>
    r'aadb57214e6c8f1693a645442cb873ce2402355a';

abstract class _$InvitationsNotifier
    extends BuildlessAsyncNotifier<List<ParentInvitation>> {
  late final String studentId;

  FutureOr<List<ParentInvitation>> build(String studentId);
}

/// Invitation notifier for creating/managing invitations
///
/// Copied from [InvitationsNotifier].
@ProviderFor(InvitationsNotifier)
const invitationsNotifierProvider = InvitationsNotifierFamily();

/// Invitation notifier for creating/managing invitations
///
/// Copied from [InvitationsNotifier].
class InvitationsNotifierFamily
    extends Family<AsyncValue<List<ParentInvitation>>> {
  /// Invitation notifier for creating/managing invitations
  ///
  /// Copied from [InvitationsNotifier].
  const InvitationsNotifierFamily();

  /// Invitation notifier for creating/managing invitations
  ///
  /// Copied from [InvitationsNotifier].
  InvitationsNotifierProvider call(String studentId) {
    return InvitationsNotifierProvider(studentId);
  }

  @override
  InvitationsNotifierProvider getProviderOverride(
    covariant InvitationsNotifierProvider provider,
  ) {
    return call(provider.studentId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'invitationsNotifierProvider';
}

/// Invitation notifier for creating/managing invitations
///
/// Copied from [InvitationsNotifier].
class InvitationsNotifierProvider
    extends
        AsyncNotifierProviderImpl<InvitationsNotifier, List<ParentInvitation>> {
  /// Invitation notifier for creating/managing invitations
  ///
  /// Copied from [InvitationsNotifier].
  InvitationsNotifierProvider(String studentId)
    : this._internal(
        () => InvitationsNotifier()..studentId = studentId,
        from: invitationsNotifierProvider,
        name: r'invitationsNotifierProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$invitationsNotifierHash,
        dependencies: InvitationsNotifierFamily._dependencies,
        allTransitiveDependencies:
            InvitationsNotifierFamily._allTransitiveDependencies,
        studentId: studentId,
      );

  InvitationsNotifierProvider._internal(
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
  FutureOr<List<ParentInvitation>> runNotifierBuild(
    covariant InvitationsNotifier notifier,
  ) {
    return notifier.build(studentId);
  }

  @override
  Override overrideWith(InvitationsNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: InvitationsNotifierProvider._internal(
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
  AsyncNotifierProviderElement<InvitationsNotifier, List<ParentInvitation>>
  createElement() {
    return _InvitationsNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is InvitationsNotifierProvider && other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin InvitationsNotifierRef
    on AsyncNotifierProviderRef<List<ParentInvitation>> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _InvitationsNotifierProviderElement
    extends
        AsyncNotifierProviderElement<
          InvitationsNotifier,
          List<ParentInvitation>
        >
    with InvitationsNotifierRef {
  _InvitationsNotifierProviderElement(super.provider);

  @override
  String get studentId => (origin as InvitationsNotifierProvider).studentId;
}

String _$relationsNotifierHash() => r'98be46804786de9745e18c047537b0f0678943a4';

abstract class _$RelationsNotifier
    extends BuildlessAsyncNotifier<List<ParentChildRelation>> {
  late final String parentId;

  FutureOr<List<ParentChildRelation>> build(String parentId);
}

/// Relations notifier for managing parent-child relationships
///
/// Copied from [RelationsNotifier].
@ProviderFor(RelationsNotifier)
const relationsNotifierProvider = RelationsNotifierFamily();

/// Relations notifier for managing parent-child relationships
///
/// Copied from [RelationsNotifier].
class RelationsNotifierFamily
    extends Family<AsyncValue<List<ParentChildRelation>>> {
  /// Relations notifier for managing parent-child relationships
  ///
  /// Copied from [RelationsNotifier].
  const RelationsNotifierFamily();

  /// Relations notifier for managing parent-child relationships
  ///
  /// Copied from [RelationsNotifier].
  RelationsNotifierProvider call(String parentId) {
    return RelationsNotifierProvider(parentId);
  }

  @override
  RelationsNotifierProvider getProviderOverride(
    covariant RelationsNotifierProvider provider,
  ) {
    return call(provider.parentId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'relationsNotifierProvider';
}

/// Relations notifier for managing parent-child relationships
///
/// Copied from [RelationsNotifier].
class RelationsNotifierProvider
    extends
        AsyncNotifierProviderImpl<
          RelationsNotifier,
          List<ParentChildRelation>
        > {
  /// Relations notifier for managing parent-child relationships
  ///
  /// Copied from [RelationsNotifier].
  RelationsNotifierProvider(String parentId)
    : this._internal(
        () => RelationsNotifier()..parentId = parentId,
        from: relationsNotifierProvider,
        name: r'relationsNotifierProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$relationsNotifierHash,
        dependencies: RelationsNotifierFamily._dependencies,
        allTransitiveDependencies:
            RelationsNotifierFamily._allTransitiveDependencies,
        parentId: parentId,
      );

  RelationsNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.parentId,
  }) : super.internal();

  final String parentId;

  @override
  FutureOr<List<ParentChildRelation>> runNotifierBuild(
    covariant RelationsNotifier notifier,
  ) {
    return notifier.build(parentId);
  }

  @override
  Override overrideWith(RelationsNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: RelationsNotifierProvider._internal(
        () => create()..parentId = parentId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        parentId: parentId,
      ),
    );
  }

  @override
  AsyncNotifierProviderElement<RelationsNotifier, List<ParentChildRelation>>
  createElement() {
    return _RelationsNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RelationsNotifierProvider && other.parentId == parentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, parentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin RelationsNotifierRef
    on AsyncNotifierProviderRef<List<ParentChildRelation>> {
  /// The parameter `parentId` of this provider.
  String get parentId;
}

class _RelationsNotifierProviderElement
    extends
        AsyncNotifierProviderElement<
          RelationsNotifier,
          List<ParentChildRelation>
        >
    with RelationsNotifierRef {
  _RelationsNotifierProviderElement(super.provider);

  @override
  String get parentId => (origin as RelationsNotifierProvider).parentId;
}

String _$visibilitySettingsNotifierHash() =>
    r'52d29f7f950eecb0fee5bee2e2bfd856c5ddafd0';

abstract class _$VisibilitySettingsNotifier
    extends BuildlessAsyncNotifier<ParentVisibilitySettings?> {
  late final ({String studentId, String teacherId}) params;

  FutureOr<ParentVisibilitySettings?> build(
    ({String studentId, String teacherId}) params,
  );
}

/// Visibility settings notifier for teacher to manage parent access
///
/// Copied from [VisibilitySettingsNotifier].
@ProviderFor(VisibilitySettingsNotifier)
const visibilitySettingsNotifierProvider = VisibilitySettingsNotifierFamily();

/// Visibility settings notifier for teacher to manage parent access
///
/// Copied from [VisibilitySettingsNotifier].
class VisibilitySettingsNotifierFamily
    extends Family<AsyncValue<ParentVisibilitySettings?>> {
  /// Visibility settings notifier for teacher to manage parent access
  ///
  /// Copied from [VisibilitySettingsNotifier].
  const VisibilitySettingsNotifierFamily();

  /// Visibility settings notifier for teacher to manage parent access
  ///
  /// Copied from [VisibilitySettingsNotifier].
  VisibilitySettingsNotifierProvider call(
    ({String studentId, String teacherId}) params,
  ) {
    return VisibilitySettingsNotifierProvider(params);
  }

  @override
  VisibilitySettingsNotifierProvider getProviderOverride(
    covariant VisibilitySettingsNotifierProvider provider,
  ) {
    return call(provider.params);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'visibilitySettingsNotifierProvider';
}

/// Visibility settings notifier for teacher to manage parent access
///
/// Copied from [VisibilitySettingsNotifier].
class VisibilitySettingsNotifierProvider
    extends
        AsyncNotifierProviderImpl<
          VisibilitySettingsNotifier,
          ParentVisibilitySettings?
        > {
  /// Visibility settings notifier for teacher to manage parent access
  ///
  /// Copied from [VisibilitySettingsNotifier].
  VisibilitySettingsNotifierProvider(
    ({String studentId, String teacherId}) params,
  ) : this._internal(
        () => VisibilitySettingsNotifier()..params = params,
        from: visibilitySettingsNotifierProvider,
        name: r'visibilitySettingsNotifierProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$visibilitySettingsNotifierHash,
        dependencies: VisibilitySettingsNotifierFamily._dependencies,
        allTransitiveDependencies:
            VisibilitySettingsNotifierFamily._allTransitiveDependencies,
        params: params,
      );

  VisibilitySettingsNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.params,
  }) : super.internal();

  final ({String studentId, String teacherId}) params;

  @override
  FutureOr<ParentVisibilitySettings?> runNotifierBuild(
    covariant VisibilitySettingsNotifier notifier,
  ) {
    return notifier.build(params);
  }

  @override
  Override overrideWith(VisibilitySettingsNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: VisibilitySettingsNotifierProvider._internal(
        () => create()..params = params,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        params: params,
      ),
    );
  }

  @override
  AsyncNotifierProviderElement<
    VisibilitySettingsNotifier,
    ParentVisibilitySettings?
  >
  createElement() {
    return _VisibilitySettingsNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is VisibilitySettingsNotifierProvider &&
        other.params == params;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, params.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin VisibilitySettingsNotifierRef
    on AsyncNotifierProviderRef<ParentVisibilitySettings?> {
  /// The parameter `params` of this provider.
  ({String studentId, String teacherId}) get params;
}

class _VisibilitySettingsNotifierProviderElement
    extends
        AsyncNotifierProviderElement<
          VisibilitySettingsNotifier,
          ParentVisibilitySettings?
        >
    with VisibilitySettingsNotifierRef {
  _VisibilitySettingsNotifierProviderElement(super.provider);

  @override
  ({String studentId, String teacherId}) get params =>
      (origin as VisibilitySettingsNotifierProvider).params;
}

String _$notificationSettingsNotifierHash() =>
    r'5548c36dfee56ff2dfc4ee2546877bd84e8d0cb6';

abstract class _$NotificationSettingsNotifier
    extends BuildlessAsyncNotifier<ParentNotificationSettings?> {
  late final String parentId;

  FutureOr<ParentNotificationSettings?> build(String parentId);
}

/// Notification settings notifier for parent to customize their preferences
///
/// Copied from [NotificationSettingsNotifier].
@ProviderFor(NotificationSettingsNotifier)
const notificationSettingsNotifierProvider =
    NotificationSettingsNotifierFamily();

/// Notification settings notifier for parent to customize their preferences
///
/// Copied from [NotificationSettingsNotifier].
class NotificationSettingsNotifierFamily
    extends Family<AsyncValue<ParentNotificationSettings?>> {
  /// Notification settings notifier for parent to customize their preferences
  ///
  /// Copied from [NotificationSettingsNotifier].
  const NotificationSettingsNotifierFamily();

  /// Notification settings notifier for parent to customize their preferences
  ///
  /// Copied from [NotificationSettingsNotifier].
  NotificationSettingsNotifierProvider call(String parentId) {
    return NotificationSettingsNotifierProvider(parentId);
  }

  @override
  NotificationSettingsNotifierProvider getProviderOverride(
    covariant NotificationSettingsNotifierProvider provider,
  ) {
    return call(provider.parentId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'notificationSettingsNotifierProvider';
}

/// Notification settings notifier for parent to customize their preferences
///
/// Copied from [NotificationSettingsNotifier].
class NotificationSettingsNotifierProvider
    extends
        AsyncNotifierProviderImpl<
          NotificationSettingsNotifier,
          ParentNotificationSettings?
        > {
  /// Notification settings notifier for parent to customize their preferences
  ///
  /// Copied from [NotificationSettingsNotifier].
  NotificationSettingsNotifierProvider(String parentId)
    : this._internal(
        () => NotificationSettingsNotifier()..parentId = parentId,
        from: notificationSettingsNotifierProvider,
        name: r'notificationSettingsNotifierProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$notificationSettingsNotifierHash,
        dependencies: NotificationSettingsNotifierFamily._dependencies,
        allTransitiveDependencies:
            NotificationSettingsNotifierFamily._allTransitiveDependencies,
        parentId: parentId,
      );

  NotificationSettingsNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.parentId,
  }) : super.internal();

  final String parentId;

  @override
  FutureOr<ParentNotificationSettings?> runNotifierBuild(
    covariant NotificationSettingsNotifier notifier,
  ) {
    return notifier.build(parentId);
  }

  @override
  Override overrideWith(NotificationSettingsNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: NotificationSettingsNotifierProvider._internal(
        () => create()..parentId = parentId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        parentId: parentId,
      ),
    );
  }

  @override
  AsyncNotifierProviderElement<
    NotificationSettingsNotifier,
    ParentNotificationSettings?
  >
  createElement() {
    return _NotificationSettingsNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is NotificationSettingsNotifierProvider &&
        other.parentId == parentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, parentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin NotificationSettingsNotifierRef
    on AsyncNotifierProviderRef<ParentNotificationSettings?> {
  /// The parameter `parentId` of this provider.
  String get parentId;
}

class _NotificationSettingsNotifierProviderElement
    extends
        AsyncNotifierProviderElement<
          NotificationSettingsNotifier,
          ParentNotificationSettings?
        >
    with NotificationSettingsNotifierRef {
  _NotificationSettingsNotifierProviderElement(super.provider);

  @override
  String get parentId =>
      (origin as NotificationSettingsNotifierProvider).parentId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
