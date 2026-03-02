// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_proposal_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$teacherProposalsHash() => r'cb636e8ef7832c9d5798fba5ccbbd90b6d3a6ba8';

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

/// See also [teacherProposals].
@ProviderFor(teacherProposals)
const teacherProposalsProvider = TeacherProposalsFamily();

/// See also [teacherProposals].
class TeacherProposalsFamily
    extends Family<AsyncValue<List<SubscriptionProposal>>> {
  /// See also [teacherProposals].
  const TeacherProposalsFamily();

  /// See also [teacherProposals].
  TeacherProposalsProvider call(
    String teacherId,
  ) {
    return TeacherProposalsProvider(
      teacherId,
    );
  }

  @override
  TeacherProposalsProvider getProviderOverride(
    covariant TeacherProposalsProvider provider,
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
  String? get name => r'teacherProposalsProvider';
}

/// See also [teacherProposals].
class TeacherProposalsProvider
    extends AutoDisposeFutureProvider<List<SubscriptionProposal>> {
  /// See also [teacherProposals].
  TeacherProposalsProvider(
    String teacherId,
  ) : this._internal(
          (ref) => teacherProposals(
            ref as TeacherProposalsRef,
            teacherId,
          ),
          from: teacherProposalsProvider,
          name: r'teacherProposalsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$teacherProposalsHash,
          dependencies: TeacherProposalsFamily._dependencies,
          allTransitiveDependencies:
              TeacherProposalsFamily._allTransitiveDependencies,
          teacherId: teacherId,
        );

  TeacherProposalsProvider._internal(
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
    FutureOr<List<SubscriptionProposal>> Function(TeacherProposalsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TeacherProposalsProvider._internal(
        (ref) => create(ref as TeacherProposalsRef),
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
  AutoDisposeFutureProviderElement<List<SubscriptionProposal>> createElement() {
    return _TeacherProposalsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TeacherProposalsProvider && other.teacherId == teacherId;
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
mixin TeacherProposalsRef
    on AutoDisposeFutureProviderRef<List<SubscriptionProposal>> {
  /// The parameter `teacherId` of this provider.
  String get teacherId;
}

class _TeacherProposalsProviderElement
    extends AutoDisposeFutureProviderElement<List<SubscriptionProposal>>
    with TeacherProposalsRef {
  _TeacherProposalsProviderElement(super.provider);

  @override
  String get teacherId => (origin as TeacherProposalsProvider).teacherId;
}

String _$activeTeacherProposalsHash() =>
    r'4e1798cead99b76551c2a21267feafac4005a307';

/// See also [activeTeacherProposals].
@ProviderFor(activeTeacherProposals)
const activeTeacherProposalsProvider = ActiveTeacherProposalsFamily();

/// See also [activeTeacherProposals].
class ActiveTeacherProposalsFamily
    extends Family<AsyncValue<List<SubscriptionProposal>>> {
  /// See also [activeTeacherProposals].
  const ActiveTeacherProposalsFamily();

  /// See also [activeTeacherProposals].
  ActiveTeacherProposalsProvider call(
    String teacherId,
  ) {
    return ActiveTeacherProposalsProvider(
      teacherId,
    );
  }

  @override
  ActiveTeacherProposalsProvider getProviderOverride(
    covariant ActiveTeacherProposalsProvider provider,
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
  String? get name => r'activeTeacherProposalsProvider';
}

/// See also [activeTeacherProposals].
class ActiveTeacherProposalsProvider
    extends AutoDisposeFutureProvider<List<SubscriptionProposal>> {
  /// See also [activeTeacherProposals].
  ActiveTeacherProposalsProvider(
    String teacherId,
  ) : this._internal(
          (ref) => activeTeacherProposals(
            ref as ActiveTeacherProposalsRef,
            teacherId,
          ),
          from: activeTeacherProposalsProvider,
          name: r'activeTeacherProposalsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$activeTeacherProposalsHash,
          dependencies: ActiveTeacherProposalsFamily._dependencies,
          allTransitiveDependencies:
              ActiveTeacherProposalsFamily._allTransitiveDependencies,
          teacherId: teacherId,
        );

  ActiveTeacherProposalsProvider._internal(
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
    FutureOr<List<SubscriptionProposal>> Function(
            ActiveTeacherProposalsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ActiveTeacherProposalsProvider._internal(
        (ref) => create(ref as ActiveTeacherProposalsRef),
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
  AutoDisposeFutureProviderElement<List<SubscriptionProposal>> createElement() {
    return _ActiveTeacherProposalsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ActiveTeacherProposalsProvider &&
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
mixin ActiveTeacherProposalsRef
    on AutoDisposeFutureProviderRef<List<SubscriptionProposal>> {
  /// The parameter `teacherId` of this provider.
  String get teacherId;
}

class _ActiveTeacherProposalsProviderElement
    extends AutoDisposeFutureProviderElement<List<SubscriptionProposal>>
    with ActiveTeacherProposalsRef {
  _ActiveTeacherProposalsProviderElement(super.provider);

  @override
  String get teacherId => (origin as ActiveTeacherProposalsProvider).teacherId;
}

String _$awaitingConfirmationProposalsHash() =>
    r'8df7e0a1fd2c9de1201df2d247399388a38d426a';

/// See also [awaitingConfirmationProposals].
@ProviderFor(awaitingConfirmationProposals)
const awaitingConfirmationProposalsProvider =
    AwaitingConfirmationProposalsFamily();

/// See also [awaitingConfirmationProposals].
class AwaitingConfirmationProposalsFamily
    extends Family<AsyncValue<List<SubscriptionProposal>>> {
  /// See also [awaitingConfirmationProposals].
  const AwaitingConfirmationProposalsFamily();

  /// See also [awaitingConfirmationProposals].
  AwaitingConfirmationProposalsProvider call(
    String teacherId,
  ) {
    return AwaitingConfirmationProposalsProvider(
      teacherId,
    );
  }

  @override
  AwaitingConfirmationProposalsProvider getProviderOverride(
    covariant AwaitingConfirmationProposalsProvider provider,
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
  String? get name => r'awaitingConfirmationProposalsProvider';
}

/// See also [awaitingConfirmationProposals].
class AwaitingConfirmationProposalsProvider
    extends AutoDisposeFutureProvider<List<SubscriptionProposal>> {
  /// See also [awaitingConfirmationProposals].
  AwaitingConfirmationProposalsProvider(
    String teacherId,
  ) : this._internal(
          (ref) => awaitingConfirmationProposals(
            ref as AwaitingConfirmationProposalsRef,
            teacherId,
          ),
          from: awaitingConfirmationProposalsProvider,
          name: r'awaitingConfirmationProposalsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$awaitingConfirmationProposalsHash,
          dependencies: AwaitingConfirmationProposalsFamily._dependencies,
          allTransitiveDependencies:
              AwaitingConfirmationProposalsFamily._allTransitiveDependencies,
          teacherId: teacherId,
        );

  AwaitingConfirmationProposalsProvider._internal(
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
    FutureOr<List<SubscriptionProposal>> Function(
            AwaitingConfirmationProposalsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: AwaitingConfirmationProposalsProvider._internal(
        (ref) => create(ref as AwaitingConfirmationProposalsRef),
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
  AutoDisposeFutureProviderElement<List<SubscriptionProposal>> createElement() {
    return _AwaitingConfirmationProposalsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AwaitingConfirmationProposalsProvider &&
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
mixin AwaitingConfirmationProposalsRef
    on AutoDisposeFutureProviderRef<List<SubscriptionProposal>> {
  /// The parameter `teacherId` of this provider.
  String get teacherId;
}

class _AwaitingConfirmationProposalsProviderElement
    extends AutoDisposeFutureProviderElement<List<SubscriptionProposal>>
    with AwaitingConfirmationProposalsRef {
  _AwaitingConfirmationProposalsProviderElement(super.provider);

  @override
  String get teacherId =>
      (origin as AwaitingConfirmationProposalsProvider).teacherId;
}

String _$studentProposalsHash() => r'e198974be221e311e5d33dd5bed35cfb09019f26';

/// See also [studentProposals].
@ProviderFor(studentProposals)
const studentProposalsProvider = StudentProposalsFamily();

/// See also [studentProposals].
class StudentProposalsFamily
    extends Family<AsyncValue<List<SubscriptionProposal>>> {
  /// See also [studentProposals].
  const StudentProposalsFamily();

  /// See also [studentProposals].
  StudentProposalsProvider call(
    String studentId,
  ) {
    return StudentProposalsProvider(
      studentId,
    );
  }

  @override
  StudentProposalsProvider getProviderOverride(
    covariant StudentProposalsProvider provider,
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
  String? get name => r'studentProposalsProvider';
}

/// See also [studentProposals].
class StudentProposalsProvider
    extends AutoDisposeFutureProvider<List<SubscriptionProposal>> {
  /// See also [studentProposals].
  StudentProposalsProvider(
    String studentId,
  ) : this._internal(
          (ref) => studentProposals(
            ref as StudentProposalsRef,
            studentId,
          ),
          from: studentProposalsProvider,
          name: r'studentProposalsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$studentProposalsHash,
          dependencies: StudentProposalsFamily._dependencies,
          allTransitiveDependencies:
              StudentProposalsFamily._allTransitiveDependencies,
          studentId: studentId,
        );

  StudentProposalsProvider._internal(
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
    FutureOr<List<SubscriptionProposal>> Function(StudentProposalsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: StudentProposalsProvider._internal(
        (ref) => create(ref as StudentProposalsRef),
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
  AutoDisposeFutureProviderElement<List<SubscriptionProposal>> createElement() {
    return _StudentProposalsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StudentProposalsProvider && other.studentId == studentId;
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
mixin StudentProposalsRef
    on AutoDisposeFutureProviderRef<List<SubscriptionProposal>> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _StudentProposalsProviderElement
    extends AutoDisposeFutureProviderElement<List<SubscriptionProposal>>
    with StudentProposalsRef {
  _StudentProposalsProviderElement(super.provider);

  @override
  String get studentId => (origin as StudentProposalsProvider).studentId;
}

String _$activeStudentProposalsHash() =>
    r'ad73c9a6ccc62231215c2c63437792315ebf2d95';

/// See also [activeStudentProposals].
@ProviderFor(activeStudentProposals)
const activeStudentProposalsProvider = ActiveStudentProposalsFamily();

/// See also [activeStudentProposals].
class ActiveStudentProposalsFamily
    extends Family<AsyncValue<List<SubscriptionProposal>>> {
  /// See also [activeStudentProposals].
  const ActiveStudentProposalsFamily();

  /// See also [activeStudentProposals].
  ActiveStudentProposalsProvider call(
    String studentId,
  ) {
    return ActiveStudentProposalsProvider(
      studentId,
    );
  }

  @override
  ActiveStudentProposalsProvider getProviderOverride(
    covariant ActiveStudentProposalsProvider provider,
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
  String? get name => r'activeStudentProposalsProvider';
}

/// See also [activeStudentProposals].
class ActiveStudentProposalsProvider
    extends AutoDisposeFutureProvider<List<SubscriptionProposal>> {
  /// See also [activeStudentProposals].
  ActiveStudentProposalsProvider(
    String studentId,
  ) : this._internal(
          (ref) => activeStudentProposals(
            ref as ActiveStudentProposalsRef,
            studentId,
          ),
          from: activeStudentProposalsProvider,
          name: r'activeStudentProposalsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$activeStudentProposalsHash,
          dependencies: ActiveStudentProposalsFamily._dependencies,
          allTransitiveDependencies:
              ActiveStudentProposalsFamily._allTransitiveDependencies,
          studentId: studentId,
        );

  ActiveStudentProposalsProvider._internal(
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
    FutureOr<List<SubscriptionProposal>> Function(
            ActiveStudentProposalsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ActiveStudentProposalsProvider._internal(
        (ref) => create(ref as ActiveStudentProposalsRef),
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
  AutoDisposeFutureProviderElement<List<SubscriptionProposal>> createElement() {
    return _ActiveStudentProposalsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ActiveStudentProposalsProvider &&
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
mixin ActiveStudentProposalsRef
    on AutoDisposeFutureProviderRef<List<SubscriptionProposal>> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _ActiveStudentProposalsProviderElement
    extends AutoDisposeFutureProviderElement<List<SubscriptionProposal>>
    with ActiveStudentProposalsRef {
  _ActiveStudentProposalsProviderElement(super.provider);

  @override
  String get studentId => (origin as ActiveStudentProposalsProvider).studentId;
}

String _$pendingStudentProposalsHash() =>
    r'acac1888f8250bc72248da13adb47ee63ead91a4';

/// See also [pendingStudentProposals].
@ProviderFor(pendingStudentProposals)
const pendingStudentProposalsProvider = PendingStudentProposalsFamily();

/// See also [pendingStudentProposals].
class PendingStudentProposalsFamily
    extends Family<AsyncValue<List<SubscriptionProposal>>> {
  /// See also [pendingStudentProposals].
  const PendingStudentProposalsFamily();

  /// See also [pendingStudentProposals].
  PendingStudentProposalsProvider call(
    String studentId,
  ) {
    return PendingStudentProposalsProvider(
      studentId,
    );
  }

  @override
  PendingStudentProposalsProvider getProviderOverride(
    covariant PendingStudentProposalsProvider provider,
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
  String? get name => r'pendingStudentProposalsProvider';
}

/// See also [pendingStudentProposals].
class PendingStudentProposalsProvider
    extends AutoDisposeFutureProvider<List<SubscriptionProposal>> {
  /// See also [pendingStudentProposals].
  PendingStudentProposalsProvider(
    String studentId,
  ) : this._internal(
          (ref) => pendingStudentProposals(
            ref as PendingStudentProposalsRef,
            studentId,
          ),
          from: pendingStudentProposalsProvider,
          name: r'pendingStudentProposalsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$pendingStudentProposalsHash,
          dependencies: PendingStudentProposalsFamily._dependencies,
          allTransitiveDependencies:
              PendingStudentProposalsFamily._allTransitiveDependencies,
          studentId: studentId,
        );

  PendingStudentProposalsProvider._internal(
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
    FutureOr<List<SubscriptionProposal>> Function(
            PendingStudentProposalsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PendingStudentProposalsProvider._internal(
        (ref) => create(ref as PendingStudentProposalsRef),
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
  AutoDisposeFutureProviderElement<List<SubscriptionProposal>> createElement() {
    return _PendingStudentProposalsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PendingStudentProposalsProvider &&
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
mixin PendingStudentProposalsRef
    on AutoDisposeFutureProviderRef<List<SubscriptionProposal>> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _PendingStudentProposalsProviderElement
    extends AutoDisposeFutureProviderElement<List<SubscriptionProposal>>
    with PendingStudentProposalsRef {
  _PendingStudentProposalsProviderElement(super.provider);

  @override
  String get studentId => (origin as PendingStudentProposalsProvider).studentId;
}

String _$subscriptionProposalHash() =>
    r'254fb16b144f7fbfa64596e6f9d0cd2b6f063da8';

/// See also [subscriptionProposal].
@ProviderFor(subscriptionProposal)
const subscriptionProposalProvider = SubscriptionProposalFamily();

/// See also [subscriptionProposal].
class SubscriptionProposalFamily
    extends Family<AsyncValue<SubscriptionProposal?>> {
  /// See also [subscriptionProposal].
  const SubscriptionProposalFamily();

  /// See also [subscriptionProposal].
  SubscriptionProposalProvider call(
    String proposalId,
  ) {
    return SubscriptionProposalProvider(
      proposalId,
    );
  }

  @override
  SubscriptionProposalProvider getProviderOverride(
    covariant SubscriptionProposalProvider provider,
  ) {
    return call(
      provider.proposalId,
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
  String? get name => r'subscriptionProposalProvider';
}

/// See also [subscriptionProposal].
class SubscriptionProposalProvider
    extends AutoDisposeFutureProvider<SubscriptionProposal?> {
  /// See also [subscriptionProposal].
  SubscriptionProposalProvider(
    String proposalId,
  ) : this._internal(
          (ref) => subscriptionProposal(
            ref as SubscriptionProposalRef,
            proposalId,
          ),
          from: subscriptionProposalProvider,
          name: r'subscriptionProposalProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$subscriptionProposalHash,
          dependencies: SubscriptionProposalFamily._dependencies,
          allTransitiveDependencies:
              SubscriptionProposalFamily._allTransitiveDependencies,
          proposalId: proposalId,
        );

  SubscriptionProposalProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.proposalId,
  }) : super.internal();

  final String proposalId;

  @override
  Override overrideWith(
    FutureOr<SubscriptionProposal?> Function(SubscriptionProposalRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SubscriptionProposalProvider._internal(
        (ref) => create(ref as SubscriptionProposalRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        proposalId: proposalId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<SubscriptionProposal?> createElement() {
    return _SubscriptionProposalProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SubscriptionProposalProvider &&
        other.proposalId == proposalId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, proposalId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SubscriptionProposalRef
    on AutoDisposeFutureProviderRef<SubscriptionProposal?> {
  /// The parameter `proposalId` of this provider.
  String get proposalId;
}

class _SubscriptionProposalProviderElement
    extends AutoDisposeFutureProviderElement<SubscriptionProposal?>
    with SubscriptionProposalRef {
  _SubscriptionProposalProviderElement(super.provider);

  @override
  String get proposalId => (origin as SubscriptionProposalProvider).proposalId;
}

String _$activeProposalBetweenHash() =>
    r'682dfa8d229a662e2cadec093f913dd0e905c3ec';

/// See also [activeProposalBetween].
@ProviderFor(activeProposalBetween)
const activeProposalBetweenProvider = ActiveProposalBetweenFamily();

/// See also [activeProposalBetween].
class ActiveProposalBetweenFamily
    extends Family<AsyncValue<SubscriptionProposal?>> {
  /// See also [activeProposalBetween].
  const ActiveProposalBetweenFamily();

  /// See also [activeProposalBetween].
  ActiveProposalBetweenProvider call(
    String teacherId,
    String studentId,
  ) {
    return ActiveProposalBetweenProvider(
      teacherId,
      studentId,
    );
  }

  @override
  ActiveProposalBetweenProvider getProviderOverride(
    covariant ActiveProposalBetweenProvider provider,
  ) {
    return call(
      provider.teacherId,
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
  String? get name => r'activeProposalBetweenProvider';
}

/// See also [activeProposalBetween].
class ActiveProposalBetweenProvider
    extends AutoDisposeFutureProvider<SubscriptionProposal?> {
  /// See also [activeProposalBetween].
  ActiveProposalBetweenProvider(
    String teacherId,
    String studentId,
  ) : this._internal(
          (ref) => activeProposalBetween(
            ref as ActiveProposalBetweenRef,
            teacherId,
            studentId,
          ),
          from: activeProposalBetweenProvider,
          name: r'activeProposalBetweenProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$activeProposalBetweenHash,
          dependencies: ActiveProposalBetweenFamily._dependencies,
          allTransitiveDependencies:
              ActiveProposalBetweenFamily._allTransitiveDependencies,
          teacherId: teacherId,
          studentId: studentId,
        );

  ActiveProposalBetweenProvider._internal(
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
    FutureOr<SubscriptionProposal?> Function(ActiveProposalBetweenRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ActiveProposalBetweenProvider._internal(
        (ref) => create(ref as ActiveProposalBetweenRef),
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
  AutoDisposeFutureProviderElement<SubscriptionProposal?> createElement() {
    return _ActiveProposalBetweenProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ActiveProposalBetweenProvider &&
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
mixin ActiveProposalBetweenRef
    on AutoDisposeFutureProviderRef<SubscriptionProposal?> {
  /// The parameter `teacherId` of this provider.
  String get teacherId;

  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _ActiveProposalBetweenProviderElement
    extends AutoDisposeFutureProviderElement<SubscriptionProposal?>
    with ActiveProposalBetweenRef {
  _ActiveProposalBetweenProviderElement(super.provider);

  @override
  String get teacherId => (origin as ActiveProposalBetweenProvider).teacherId;
  @override
  String get studentId => (origin as ActiveProposalBetweenProvider).studentId;
}

String _$subscriptionProposalNotifierHash() =>
    r'57b88acd8618f9476c538d83c4c1744518393f2e';

/// See also [SubscriptionProposalNotifier].
@ProviderFor(SubscriptionProposalNotifier)
final subscriptionProposalNotifierProvider = AutoDisposeNotifierProvider<
    SubscriptionProposalNotifier, AsyncValue<SubscriptionProposal?>>.internal(
  SubscriptionProposalNotifier.new,
  name: r'subscriptionProposalNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$subscriptionProposalNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SubscriptionProposalNotifier
    = AutoDisposeNotifier<AsyncValue<SubscriptionProposal?>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
