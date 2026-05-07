// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_issue_flow_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$subscriptionIssueStudentsHash() =>
    r'bf0d7c28ebb349cdd860b6af96c340ebd6cf27c8';

/// See also [subscriptionIssueStudents].
@ProviderFor(subscriptionIssueStudents)
final subscriptionIssueStudentsProvider =
    FutureProvider<List<Student>>.internal(
  subscriptionIssueStudents,
  name: r'subscriptionIssueStudentsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$subscriptionIssueStudentsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef SubscriptionIssueStudentsRef = FutureProviderRef<List<Student>>;
String _$subscriptionIssueStudentHash() =>
    r'17b92d835ff394e487ecf5cbcaab0ae269b43ab3';

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

/// See also [subscriptionIssueStudent].
@ProviderFor(subscriptionIssueStudent)
const subscriptionIssueStudentProvider = SubscriptionIssueStudentFamily();

/// See also [subscriptionIssueStudent].
class SubscriptionIssueStudentFamily extends Family<AsyncValue<Student?>> {
  /// See also [subscriptionIssueStudent].
  const SubscriptionIssueStudentFamily();

  /// See also [subscriptionIssueStudent].
  SubscriptionIssueStudentProvider call(
    String studentId,
  ) {
    return SubscriptionIssueStudentProvider(
      studentId,
    );
  }

  @override
  SubscriptionIssueStudentProvider getProviderOverride(
    covariant SubscriptionIssueStudentProvider provider,
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
  String? get name => r'subscriptionIssueStudentProvider';
}

/// See also [subscriptionIssueStudent].
class SubscriptionIssueStudentProvider extends FutureProvider<Student?> {
  /// See also [subscriptionIssueStudent].
  SubscriptionIssueStudentProvider(
    String studentId,
  ) : this._internal(
          (ref) => subscriptionIssueStudent(
            ref as SubscriptionIssueStudentRef,
            studentId,
          ),
          from: subscriptionIssueStudentProvider,
          name: r'subscriptionIssueStudentProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$subscriptionIssueStudentHash,
          dependencies: SubscriptionIssueStudentFamily._dependencies,
          allTransitiveDependencies:
              SubscriptionIssueStudentFamily._allTransitiveDependencies,
          studentId: studentId,
        );

  SubscriptionIssueStudentProvider._internal(
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
    FutureOr<Student?> Function(SubscriptionIssueStudentRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SubscriptionIssueStudentProvider._internal(
        (ref) => create(ref as SubscriptionIssueStudentRef),
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
  FutureProviderElement<Student?> createElement() {
    return _SubscriptionIssueStudentProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SubscriptionIssueStudentProvider &&
        other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin SubscriptionIssueStudentRef on FutureProviderRef<Student?> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _SubscriptionIssueStudentProviderElement
    extends FutureProviderElement<Student?> with SubscriptionIssueStudentRef {
  _SubscriptionIssueStudentProviderElement(super.provider);

  @override
  String get studentId =>
      (origin as SubscriptionIssueStudentProvider).studentId;
}

String _$subscriptionIssueMembershipsHash() =>
    r'dcbf5e7801a18afb1a8e7f6a1cbebdefc8c84e27';

/// See also [subscriptionIssueMemberships].
@ProviderFor(subscriptionIssueMemberships)
const subscriptionIssueMembershipsProvider =
    SubscriptionIssueMembershipsFamily();

/// See also [subscriptionIssueMemberships].
class SubscriptionIssueMembershipsFamily
    extends Family<AsyncValue<List<ClassMembership>>> {
  /// See also [subscriptionIssueMemberships].
  const SubscriptionIssueMembershipsFamily();

  /// See also [subscriptionIssueMemberships].
  SubscriptionIssueMembershipsProvider call(
    String studentId,
  ) {
    return SubscriptionIssueMembershipsProvider(
      studentId,
    );
  }

  @override
  SubscriptionIssueMembershipsProvider getProviderOverride(
    covariant SubscriptionIssueMembershipsProvider provider,
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
  String? get name => r'subscriptionIssueMembershipsProvider';
}

/// See also [subscriptionIssueMemberships].
class SubscriptionIssueMembershipsProvider
    extends FutureProvider<List<ClassMembership>> {
  /// See also [subscriptionIssueMemberships].
  SubscriptionIssueMembershipsProvider(
    String studentId,
  ) : this._internal(
          (ref) => subscriptionIssueMemberships(
            ref as SubscriptionIssueMembershipsRef,
            studentId,
          ),
          from: subscriptionIssueMembershipsProvider,
          name: r'subscriptionIssueMembershipsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$subscriptionIssueMembershipsHash,
          dependencies: SubscriptionIssueMembershipsFamily._dependencies,
          allTransitiveDependencies:
              SubscriptionIssueMembershipsFamily._allTransitiveDependencies,
          studentId: studentId,
        );

  SubscriptionIssueMembershipsProvider._internal(
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
            SubscriptionIssueMembershipsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SubscriptionIssueMembershipsProvider._internal(
        (ref) => create(ref as SubscriptionIssueMembershipsRef),
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
  FutureProviderElement<List<ClassMembership>> createElement() {
    return _SubscriptionIssueMembershipsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SubscriptionIssueMembershipsProvider &&
        other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin SubscriptionIssueMembershipsRef
    on FutureProviderRef<List<ClassMembership>> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _SubscriptionIssueMembershipsProviderElement
    extends FutureProviderElement<List<ClassMembership>>
    with SubscriptionIssueMembershipsRef {
  _SubscriptionIssueMembershipsProviderElement(super.provider);

  @override
  String get studentId =>
      (origin as SubscriptionIssueMembershipsProvider).studentId;
}

String _$subscriptionIssueEffectivePolicyHash() =>
    r'd49ef9e0628d346769f29d1fd4104aeced46f596';

/// See also [subscriptionIssueEffectivePolicy].
@ProviderFor(subscriptionIssueEffectivePolicy)
const subscriptionIssueEffectivePolicyProvider =
    SubscriptionIssueEffectivePolicyFamily();

/// See also [subscriptionIssueEffectivePolicy].
class SubscriptionIssueEffectivePolicyFamily
    extends Family<AsyncValue<LessonPolicy?>> {
  /// See also [subscriptionIssueEffectivePolicy].
  const SubscriptionIssueEffectivePolicyFamily();

  /// See also [subscriptionIssueEffectivePolicy].
  SubscriptionIssueEffectivePolicyProvider call(
    ClassMembership membership,
  ) {
    return SubscriptionIssueEffectivePolicyProvider(
      membership,
    );
  }

  @override
  SubscriptionIssueEffectivePolicyProvider getProviderOverride(
    covariant SubscriptionIssueEffectivePolicyProvider provider,
  ) {
    return call(
      provider.membership,
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
  String? get name => r'subscriptionIssueEffectivePolicyProvider';
}

/// See also [subscriptionIssueEffectivePolicy].
class SubscriptionIssueEffectivePolicyProvider
    extends FutureProvider<LessonPolicy?> {
  /// See also [subscriptionIssueEffectivePolicy].
  SubscriptionIssueEffectivePolicyProvider(
    ClassMembership membership,
  ) : this._internal(
          (ref) => subscriptionIssueEffectivePolicy(
            ref as SubscriptionIssueEffectivePolicyRef,
            membership,
          ),
          from: subscriptionIssueEffectivePolicyProvider,
          name: r'subscriptionIssueEffectivePolicyProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$subscriptionIssueEffectivePolicyHash,
          dependencies: SubscriptionIssueEffectivePolicyFamily._dependencies,
          allTransitiveDependencies:
              SubscriptionIssueEffectivePolicyFamily._allTransitiveDependencies,
          membership: membership,
        );

  SubscriptionIssueEffectivePolicyProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.membership,
  }) : super.internal();

  final ClassMembership membership;

  @override
  Override overrideWith(
    FutureOr<LessonPolicy?> Function(
            SubscriptionIssueEffectivePolicyRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SubscriptionIssueEffectivePolicyProvider._internal(
        (ref) => create(ref as SubscriptionIssueEffectivePolicyRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        membership: membership,
      ),
    );
  }

  @override
  FutureProviderElement<LessonPolicy?> createElement() {
    return _SubscriptionIssueEffectivePolicyProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SubscriptionIssueEffectivePolicyProvider &&
        other.membership == membership;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, membership.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin SubscriptionIssueEffectivePolicyRef on FutureProviderRef<LessonPolicy?> {
  /// The parameter `membership` of this provider.
  ClassMembership get membership;
}

class _SubscriptionIssueEffectivePolicyProviderElement
    extends FutureProviderElement<LessonPolicy?>
    with SubscriptionIssueEffectivePolicyRef {
  _SubscriptionIssueEffectivePolicyProviderElement(super.provider);

  @override
  ClassMembership get membership =>
      (origin as SubscriptionIssueEffectivePolicyProvider).membership;
}

String _$subscriptionIssueFlowControllerHash() =>
    r'e759b90ba5043c01c568ca061de2664dba016d9a';

/// See also [subscriptionIssueFlowController].
@ProviderFor(subscriptionIssueFlowController)
final subscriptionIssueFlowControllerProvider =
    Provider<SubscriptionIssueFlowController>.internal(
  subscriptionIssueFlowController,
  name: r'subscriptionIssueFlowControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$subscriptionIssueFlowControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef SubscriptionIssueFlowControllerRef
    = ProviderRef<SubscriptionIssueFlowController>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
