// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$subscriptionRepositoryHash() =>
    r'c56e0bbd90157c9653efda4ae19f54e0e352d6e6';

/// Repository provider for Subscription.
///
/// Copied from [subscriptionRepository].
@ProviderFor(subscriptionRepository)
final subscriptionRepositoryProvider =
    AutoDisposeProvider<SubscriptionRepository>.internal(
  subscriptionRepository,
  name: r'subscriptionRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$subscriptionRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SubscriptionRepositoryRef
    = AutoDisposeProviderRef<SubscriptionRepository>;
String _$studentSubscriptionsHash() =>
    r'7d9d99eabed4bbd20dac63a7de85a2b6ee911c0a';

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

/// Get all subscriptions for a student.
///
/// Copied from [studentSubscriptions].
@ProviderFor(studentSubscriptions)
const studentSubscriptionsProvider = StudentSubscriptionsFamily();

/// Get all subscriptions for a student.
///
/// Copied from [studentSubscriptions].
class StudentSubscriptionsFamily
    extends Family<AsyncValue<List<Subscription>>> {
  /// Get all subscriptions for a student.
  ///
  /// Copied from [studentSubscriptions].
  const StudentSubscriptionsFamily();

  /// Get all subscriptions for a student.
  ///
  /// Copied from [studentSubscriptions].
  StudentSubscriptionsProvider call(
    String studentId,
  ) {
    return StudentSubscriptionsProvider(
      studentId,
    );
  }

  @override
  StudentSubscriptionsProvider getProviderOverride(
    covariant StudentSubscriptionsProvider provider,
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
  String? get name => r'studentSubscriptionsProvider';
}

/// Get all subscriptions for a student.
///
/// Copied from [studentSubscriptions].
class StudentSubscriptionsProvider
    extends AutoDisposeFutureProvider<List<Subscription>> {
  /// Get all subscriptions for a student.
  ///
  /// Copied from [studentSubscriptions].
  StudentSubscriptionsProvider(
    String studentId,
  ) : this._internal(
          (ref) => studentSubscriptions(
            ref as StudentSubscriptionsRef,
            studentId,
          ),
          from: studentSubscriptionsProvider,
          name: r'studentSubscriptionsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$studentSubscriptionsHash,
          dependencies: StudentSubscriptionsFamily._dependencies,
          allTransitiveDependencies:
              StudentSubscriptionsFamily._allTransitiveDependencies,
          studentId: studentId,
        );

  StudentSubscriptionsProvider._internal(
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
    FutureOr<List<Subscription>> Function(StudentSubscriptionsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: StudentSubscriptionsProvider._internal(
        (ref) => create(ref as StudentSubscriptionsRef),
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
  AutoDisposeFutureProviderElement<List<Subscription>> createElement() {
    return _StudentSubscriptionsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StudentSubscriptionsProvider &&
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
mixin StudentSubscriptionsRef
    on AutoDisposeFutureProviderRef<List<Subscription>> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _StudentSubscriptionsProviderElement
    extends AutoDisposeFutureProviderElement<List<Subscription>>
    with StudentSubscriptionsRef {
  _StudentSubscriptionsProviderElement(super.provider);

  @override
  String get studentId => (origin as StudentSubscriptionsProvider).studentId;
}

String _$activeStudentSubscriptionsHash() =>
    r'17049b334c99dd66359deb3dbf672202166ea353';

/// Get active subscriptions for a student (active or expiring soon).
///
/// Copied from [activeStudentSubscriptions].
@ProviderFor(activeStudentSubscriptions)
const activeStudentSubscriptionsProvider = ActiveStudentSubscriptionsFamily();

/// Get active subscriptions for a student (active or expiring soon).
///
/// Copied from [activeStudentSubscriptions].
class ActiveStudentSubscriptionsFamily
    extends Family<AsyncValue<List<Subscription>>> {
  /// Get active subscriptions for a student (active or expiring soon).
  ///
  /// Copied from [activeStudentSubscriptions].
  const ActiveStudentSubscriptionsFamily();

  /// Get active subscriptions for a student (active or expiring soon).
  ///
  /// Copied from [activeStudentSubscriptions].
  ActiveStudentSubscriptionsProvider call(
    String studentId,
  ) {
    return ActiveStudentSubscriptionsProvider(
      studentId,
    );
  }

  @override
  ActiveStudentSubscriptionsProvider getProviderOverride(
    covariant ActiveStudentSubscriptionsProvider provider,
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
  String? get name => r'activeStudentSubscriptionsProvider';
}

/// Get active subscriptions for a student (active or expiring soon).
///
/// Copied from [activeStudentSubscriptions].
class ActiveStudentSubscriptionsProvider
    extends AutoDisposeFutureProvider<List<Subscription>> {
  /// Get active subscriptions for a student (active or expiring soon).
  ///
  /// Copied from [activeStudentSubscriptions].
  ActiveStudentSubscriptionsProvider(
    String studentId,
  ) : this._internal(
          (ref) => activeStudentSubscriptions(
            ref as ActiveStudentSubscriptionsRef,
            studentId,
          ),
          from: activeStudentSubscriptionsProvider,
          name: r'activeStudentSubscriptionsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$activeStudentSubscriptionsHash,
          dependencies: ActiveStudentSubscriptionsFamily._dependencies,
          allTransitiveDependencies:
              ActiveStudentSubscriptionsFamily._allTransitiveDependencies,
          studentId: studentId,
        );

  ActiveStudentSubscriptionsProvider._internal(
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
    FutureOr<List<Subscription>> Function(
            ActiveStudentSubscriptionsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ActiveStudentSubscriptionsProvider._internal(
        (ref) => create(ref as ActiveStudentSubscriptionsRef),
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
  AutoDisposeFutureProviderElement<List<Subscription>> createElement() {
    return _ActiveStudentSubscriptionsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ActiveStudentSubscriptionsProvider &&
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
mixin ActiveStudentSubscriptionsRef
    on AutoDisposeFutureProviderRef<List<Subscription>> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _ActiveStudentSubscriptionsProviderElement
    extends AutoDisposeFutureProviderElement<List<Subscription>>
    with ActiveStudentSubscriptionsRef {
  _ActiveStudentSubscriptionsProviderElement(super.provider);

  @override
  String get studentId =>
      (origin as ActiveStudentSubscriptionsProvider).studentId;
}

String _$membershipSubscriptionHash() =>
    r'52fd385c50027b83766a8820c9338ccd32031da7';

/// Get active subscription for a membership.
///
/// Copied from [membershipSubscription].
@ProviderFor(membershipSubscription)
const membershipSubscriptionProvider = MembershipSubscriptionFamily();

/// Get active subscription for a membership.
///
/// Copied from [membershipSubscription].
class MembershipSubscriptionFamily extends Family<AsyncValue<Subscription?>> {
  /// Get active subscription for a membership.
  ///
  /// Copied from [membershipSubscription].
  const MembershipSubscriptionFamily();

  /// Get active subscription for a membership.
  ///
  /// Copied from [membershipSubscription].
  MembershipSubscriptionProvider call(
    String membershipId,
  ) {
    return MembershipSubscriptionProvider(
      membershipId,
    );
  }

  @override
  MembershipSubscriptionProvider getProviderOverride(
    covariant MembershipSubscriptionProvider provider,
  ) {
    return call(
      provider.membershipId,
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
  String? get name => r'membershipSubscriptionProvider';
}

/// Get active subscription for a membership.
///
/// Copied from [membershipSubscription].
class MembershipSubscriptionProvider
    extends AutoDisposeFutureProvider<Subscription?> {
  /// Get active subscription for a membership.
  ///
  /// Copied from [membershipSubscription].
  MembershipSubscriptionProvider(
    String membershipId,
  ) : this._internal(
          (ref) => membershipSubscription(
            ref as MembershipSubscriptionRef,
            membershipId,
          ),
          from: membershipSubscriptionProvider,
          name: r'membershipSubscriptionProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$membershipSubscriptionHash,
          dependencies: MembershipSubscriptionFamily._dependencies,
          allTransitiveDependencies:
              MembershipSubscriptionFamily._allTransitiveDependencies,
          membershipId: membershipId,
        );

  MembershipSubscriptionProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.membershipId,
  }) : super.internal();

  final String membershipId;

  @override
  Override overrideWith(
    FutureOr<Subscription?> Function(MembershipSubscriptionRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: MembershipSubscriptionProvider._internal(
        (ref) => create(ref as MembershipSubscriptionRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        membershipId: membershipId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Subscription?> createElement() {
    return _MembershipSubscriptionProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MembershipSubscriptionProvider &&
        other.membershipId == membershipId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, membershipId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin MembershipSubscriptionRef on AutoDisposeFutureProviderRef<Subscription?> {
  /// The parameter `membershipId` of this provider.
  String get membershipId;
}

class _MembershipSubscriptionProviderElement
    extends AutoDisposeFutureProviderElement<Subscription?>
    with MembershipSubscriptionRef {
  _MembershipSubscriptionProviderElement(super.provider);

  @override
  String get membershipId =>
      (origin as MembershipSubscriptionProvider).membershipId;
}

String _$subscriptionHash() => r'd6a7d5c3955308d1e090b6275879dc0a1c5f280d';

/// Get a single subscription by ID.
///
/// Copied from [subscription].
@ProviderFor(subscription)
const subscriptionProvider = SubscriptionFamily();

/// Get a single subscription by ID.
///
/// Copied from [subscription].
class SubscriptionFamily extends Family<AsyncValue<Subscription?>> {
  /// Get a single subscription by ID.
  ///
  /// Copied from [subscription].
  const SubscriptionFamily();

  /// Get a single subscription by ID.
  ///
  /// Copied from [subscription].
  SubscriptionProvider call(
    String id,
  ) {
    return SubscriptionProvider(
      id,
    );
  }

  @override
  SubscriptionProvider getProviderOverride(
    covariant SubscriptionProvider provider,
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
  String? get name => r'subscriptionProvider';
}

/// Get a single subscription by ID.
///
/// Copied from [subscription].
class SubscriptionProvider extends AutoDisposeFutureProvider<Subscription?> {
  /// Get a single subscription by ID.
  ///
  /// Copied from [subscription].
  SubscriptionProvider(
    String id,
  ) : this._internal(
          (ref) => subscription(
            ref as SubscriptionRef,
            id,
          ),
          from: subscriptionProvider,
          name: r'subscriptionProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$subscriptionHash,
          dependencies: SubscriptionFamily._dependencies,
          allTransitiveDependencies:
              SubscriptionFamily._allTransitiveDependencies,
          id: id,
        );

  SubscriptionProvider._internal(
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
    FutureOr<Subscription?> Function(SubscriptionRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SubscriptionProvider._internal(
        (ref) => create(ref as SubscriptionRef),
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
  AutoDisposeFutureProviderElement<Subscription?> createElement() {
    return _SubscriptionProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SubscriptionProvider && other.id == id;
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
mixin SubscriptionRef on AutoDisposeFutureProviderRef<Subscription?> {
  /// The parameter `id` of this provider.
  String get id;
}

class _SubscriptionProviderElement
    extends AutoDisposeFutureProviderElement<Subscription?>
    with SubscriptionRef {
  _SubscriptionProviderElement(super.provider);

  @override
  String get id => (origin as SubscriptionProvider).id;
}

String _$expiringSoonSubscriptionsHash() =>
    r'69902e366a318de4d29bcd3062c37613b2025bf2';

/// Get subscriptions expiring soon (for notifications/alerts).
///
/// Copied from [expiringSoonSubscriptions].
@ProviderFor(expiringSoonSubscriptions)
final expiringSoonSubscriptionsProvider =
    AutoDisposeFutureProvider<List<Subscription>>.internal(
  expiringSoonSubscriptions,
  name: r'expiringSoonSubscriptionsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$expiringSoonSubscriptionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ExpiringSoonSubscriptionsRef
    = AutoDisposeFutureProviderRef<List<Subscription>>;
String _$subscriptionUsageHistoryHash() =>
    r'6a391a951c5487c9d05abe777cfdbb49a456a07c';

/// Get usage history for a subscription.
///
/// Copied from [subscriptionUsageHistory].
@ProviderFor(subscriptionUsageHistory)
const subscriptionUsageHistoryProvider = SubscriptionUsageHistoryFamily();

/// Get usage history for a subscription.
///
/// Copied from [subscriptionUsageHistory].
class SubscriptionUsageHistoryFamily
    extends Family<AsyncValue<List<SubscriptionUsage>>> {
  /// Get usage history for a subscription.
  ///
  /// Copied from [subscriptionUsageHistory].
  const SubscriptionUsageHistoryFamily();

  /// Get usage history for a subscription.
  ///
  /// Copied from [subscriptionUsageHistory].
  SubscriptionUsageHistoryProvider call(
    String subscriptionId,
  ) {
    return SubscriptionUsageHistoryProvider(
      subscriptionId,
    );
  }

  @override
  SubscriptionUsageHistoryProvider getProviderOverride(
    covariant SubscriptionUsageHistoryProvider provider,
  ) {
    return call(
      provider.subscriptionId,
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
  String? get name => r'subscriptionUsageHistoryProvider';
}

/// Get usage history for a subscription.
///
/// Copied from [subscriptionUsageHistory].
class SubscriptionUsageHistoryProvider
    extends AutoDisposeFutureProvider<List<SubscriptionUsage>> {
  /// Get usage history for a subscription.
  ///
  /// Copied from [subscriptionUsageHistory].
  SubscriptionUsageHistoryProvider(
    String subscriptionId,
  ) : this._internal(
          (ref) => subscriptionUsageHistory(
            ref as SubscriptionUsageHistoryRef,
            subscriptionId,
          ),
          from: subscriptionUsageHistoryProvider,
          name: r'subscriptionUsageHistoryProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$subscriptionUsageHistoryHash,
          dependencies: SubscriptionUsageHistoryFamily._dependencies,
          allTransitiveDependencies:
              SubscriptionUsageHistoryFamily._allTransitiveDependencies,
          subscriptionId: subscriptionId,
        );

  SubscriptionUsageHistoryProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.subscriptionId,
  }) : super.internal();

  final String subscriptionId;

  @override
  Override overrideWith(
    FutureOr<List<SubscriptionUsage>> Function(
            SubscriptionUsageHistoryRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SubscriptionUsageHistoryProvider._internal(
        (ref) => create(ref as SubscriptionUsageHistoryRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        subscriptionId: subscriptionId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<SubscriptionUsage>> createElement() {
    return _SubscriptionUsageHistoryProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SubscriptionUsageHistoryProvider &&
        other.subscriptionId == subscriptionId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, subscriptionId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SubscriptionUsageHistoryRef
    on AutoDisposeFutureProviderRef<List<SubscriptionUsage>> {
  /// The parameter `subscriptionId` of this provider.
  String get subscriptionId;
}

class _SubscriptionUsageHistoryProviderElement
    extends AutoDisposeFutureProviderElement<List<SubscriptionUsage>>
    with SubscriptionUsageHistoryRef {
  _SubscriptionUsageHistoryProviderElement(super.provider);

  @override
  String get subscriptionId =>
      (origin as SubscriptionUsageHistoryProvider).subscriptionId;
}

String _$teacherStudentSubscriptionsHash() =>
    r'57e0db746b9ac021da6817be4207b318ca8b6ee9';

/// Get all subscriptions for a teacher's students.
///
/// Copied from [teacherStudentSubscriptions].
@ProviderFor(teacherStudentSubscriptions)
const teacherStudentSubscriptionsProvider = TeacherStudentSubscriptionsFamily();

/// Get all subscriptions for a teacher's students.
///
/// Copied from [teacherStudentSubscriptions].
class TeacherStudentSubscriptionsFamily
    extends Family<AsyncValue<List<Subscription>>> {
  /// Get all subscriptions for a teacher's students.
  ///
  /// Copied from [teacherStudentSubscriptions].
  const TeacherStudentSubscriptionsFamily();

  /// Get all subscriptions for a teacher's students.
  ///
  /// Copied from [teacherStudentSubscriptions].
  TeacherStudentSubscriptionsProvider call(
    String teacherId,
  ) {
    return TeacherStudentSubscriptionsProvider(
      teacherId,
    );
  }

  @override
  TeacherStudentSubscriptionsProvider getProviderOverride(
    covariant TeacherStudentSubscriptionsProvider provider,
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
  String? get name => r'teacherStudentSubscriptionsProvider';
}

/// Get all subscriptions for a teacher's students.
///
/// Copied from [teacherStudentSubscriptions].
class TeacherStudentSubscriptionsProvider
    extends AutoDisposeFutureProvider<List<Subscription>> {
  /// Get all subscriptions for a teacher's students.
  ///
  /// Copied from [teacherStudentSubscriptions].
  TeacherStudentSubscriptionsProvider(
    String teacherId,
  ) : this._internal(
          (ref) => teacherStudentSubscriptions(
            ref as TeacherStudentSubscriptionsRef,
            teacherId,
          ),
          from: teacherStudentSubscriptionsProvider,
          name: r'teacherStudentSubscriptionsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$teacherStudentSubscriptionsHash,
          dependencies: TeacherStudentSubscriptionsFamily._dependencies,
          allTransitiveDependencies:
              TeacherStudentSubscriptionsFamily._allTransitiveDependencies,
          teacherId: teacherId,
        );

  TeacherStudentSubscriptionsProvider._internal(
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
    FutureOr<List<Subscription>> Function(
            TeacherStudentSubscriptionsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TeacherStudentSubscriptionsProvider._internal(
        (ref) => create(ref as TeacherStudentSubscriptionsRef),
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
  AutoDisposeFutureProviderElement<List<Subscription>> createElement() {
    return _TeacherStudentSubscriptionsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TeacherStudentSubscriptionsProvider &&
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
mixin TeacherStudentSubscriptionsRef
    on AutoDisposeFutureProviderRef<List<Subscription>> {
  /// The parameter `teacherId` of this provider.
  String get teacherId;
}

class _TeacherStudentSubscriptionsProviderElement
    extends AutoDisposeFutureProviderElement<List<Subscription>>
    with TeacherStudentSubscriptionsRef {
  _TeacherStudentSubscriptionsProviderElement(super.provider);

  @override
  String get teacherId =>
      (origin as TeacherStudentSubscriptionsProvider).teacherId;
}

String _$unpaidSubscriptionsHash() =>
    r'af205ce203e95861c646305d0ee209e2c0c6d19b';

/// Get unpaid subscriptions for a teacher.
///
/// Copied from [unpaidSubscriptions].
@ProviderFor(unpaidSubscriptions)
const unpaidSubscriptionsProvider = UnpaidSubscriptionsFamily();

/// Get unpaid subscriptions for a teacher.
///
/// Copied from [unpaidSubscriptions].
class UnpaidSubscriptionsFamily extends Family<AsyncValue<List<Subscription>>> {
  /// Get unpaid subscriptions for a teacher.
  ///
  /// Copied from [unpaidSubscriptions].
  const UnpaidSubscriptionsFamily();

  /// Get unpaid subscriptions for a teacher.
  ///
  /// Copied from [unpaidSubscriptions].
  UnpaidSubscriptionsProvider call(
    String teacherId,
  ) {
    return UnpaidSubscriptionsProvider(
      teacherId,
    );
  }

  @override
  UnpaidSubscriptionsProvider getProviderOverride(
    covariant UnpaidSubscriptionsProvider provider,
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
  String? get name => r'unpaidSubscriptionsProvider';
}

/// Get unpaid subscriptions for a teacher.
///
/// Copied from [unpaidSubscriptions].
class UnpaidSubscriptionsProvider
    extends AutoDisposeFutureProvider<List<Subscription>> {
  /// Get unpaid subscriptions for a teacher.
  ///
  /// Copied from [unpaidSubscriptions].
  UnpaidSubscriptionsProvider(
    String teacherId,
  ) : this._internal(
          (ref) => unpaidSubscriptions(
            ref as UnpaidSubscriptionsRef,
            teacherId,
          ),
          from: unpaidSubscriptionsProvider,
          name: r'unpaidSubscriptionsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$unpaidSubscriptionsHash,
          dependencies: UnpaidSubscriptionsFamily._dependencies,
          allTransitiveDependencies:
              UnpaidSubscriptionsFamily._allTransitiveDependencies,
          teacherId: teacherId,
        );

  UnpaidSubscriptionsProvider._internal(
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
    FutureOr<List<Subscription>> Function(UnpaidSubscriptionsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UnpaidSubscriptionsProvider._internal(
        (ref) => create(ref as UnpaidSubscriptionsRef),
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
  AutoDisposeFutureProviderElement<List<Subscription>> createElement() {
    return _UnpaidSubscriptionsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UnpaidSubscriptionsProvider && other.teacherId == teacherId;
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
mixin UnpaidSubscriptionsRef
    on AutoDisposeFutureProviderRef<List<Subscription>> {
  /// The parameter `teacherId` of this provider.
  String get teacherId;
}

class _UnpaidSubscriptionsProviderElement
    extends AutoDisposeFutureProviderElement<List<Subscription>>
    with UnpaidSubscriptionsRef {
  _UnpaidSubscriptionsProviderElement(super.provider);

  @override
  String get teacherId => (origin as UnpaidSubscriptionsProvider).teacherId;
}

String _$unpaidSummaryHash() => r'8c5bbae1c1adeb686d26785e109361c210f40cdf';

/// Get unpaid summary (total amount + student count) for a teacher.
///
/// Copied from [unpaidSummary].
@ProviderFor(unpaidSummary)
const unpaidSummaryProvider = UnpaidSummaryFamily();

/// Get unpaid summary (total amount + student count) for a teacher.
///
/// Copied from [unpaidSummary].
class UnpaidSummaryFamily
    extends Family<AsyncValue<({int totalAmount, int studentCount})>> {
  /// Get unpaid summary (total amount + student count) for a teacher.
  ///
  /// Copied from [unpaidSummary].
  const UnpaidSummaryFamily();

  /// Get unpaid summary (total amount + student count) for a teacher.
  ///
  /// Copied from [unpaidSummary].
  UnpaidSummaryProvider call(
    String teacherId,
  ) {
    return UnpaidSummaryProvider(
      teacherId,
    );
  }

  @override
  UnpaidSummaryProvider getProviderOverride(
    covariant UnpaidSummaryProvider provider,
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
  String? get name => r'unpaidSummaryProvider';
}

/// Get unpaid summary (total amount + student count) for a teacher.
///
/// Copied from [unpaidSummary].
class UnpaidSummaryProvider
    extends AutoDisposeFutureProvider<({int totalAmount, int studentCount})> {
  /// Get unpaid summary (total amount + student count) for a teacher.
  ///
  /// Copied from [unpaidSummary].
  UnpaidSummaryProvider(
    String teacherId,
  ) : this._internal(
          (ref) => unpaidSummary(
            ref as UnpaidSummaryRef,
            teacherId,
          ),
          from: unpaidSummaryProvider,
          name: r'unpaidSummaryProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$unpaidSummaryHash,
          dependencies: UnpaidSummaryFamily._dependencies,
          allTransitiveDependencies:
              UnpaidSummaryFamily._allTransitiveDependencies,
          teacherId: teacherId,
        );

  UnpaidSummaryProvider._internal(
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
    FutureOr<({int totalAmount, int studentCount})> Function(
            UnpaidSummaryRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UnpaidSummaryProvider._internal(
        (ref) => create(ref as UnpaidSummaryRef),
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
  AutoDisposeFutureProviderElement<({int totalAmount, int studentCount})>
      createElement() {
    return _UnpaidSummaryProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UnpaidSummaryProvider && other.teacherId == teacherId;
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
mixin UnpaidSummaryRef
    on AutoDisposeFutureProviderRef<({int totalAmount, int studentCount})> {
  /// The parameter `teacherId` of this provider.
  String get teacherId;
}

class _UnpaidSummaryProviderElement extends AutoDisposeFutureProviderElement<
    ({int totalAmount, int studentCount})> with UnpaidSummaryRef {
  _UnpaidSummaryProviderElement(super.provider);

  @override
  String get teacherId => (origin as UnpaidSummaryProvider).teacherId;
}

String _$activeSubscriptionBetweenHash() =>
    r'2a378dcd8f74f700997e85e662357c06e5ac38ed';

/// Check if a student has an active subscription with a teacher.
/// Returns the active subscription if found, null otherwise.
///
/// Copied from [activeSubscriptionBetween].
@ProviderFor(activeSubscriptionBetween)
const activeSubscriptionBetweenProvider = ActiveSubscriptionBetweenFamily();

/// Check if a student has an active subscription with a teacher.
/// Returns the active subscription if found, null otherwise.
///
/// Copied from [activeSubscriptionBetween].
class ActiveSubscriptionBetweenFamily
    extends Family<AsyncValue<Subscription?>> {
  /// Check if a student has an active subscription with a teacher.
  /// Returns the active subscription if found, null otherwise.
  ///
  /// Copied from [activeSubscriptionBetween].
  const ActiveSubscriptionBetweenFamily();

  /// Check if a student has an active subscription with a teacher.
  /// Returns the active subscription if found, null otherwise.
  ///
  /// Copied from [activeSubscriptionBetween].
  ActiveSubscriptionBetweenProvider call({
    required String studentId,
    required String teacherId,
  }) {
    return ActiveSubscriptionBetweenProvider(
      studentId: studentId,
      teacherId: teacherId,
    );
  }

  @override
  ActiveSubscriptionBetweenProvider getProviderOverride(
    covariant ActiveSubscriptionBetweenProvider provider,
  ) {
    return call(
      studentId: provider.studentId,
      teacherId: provider.teacherId,
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
  String? get name => r'activeSubscriptionBetweenProvider';
}

/// Check if a student has an active subscription with a teacher.
/// Returns the active subscription if found, null otherwise.
///
/// Copied from [activeSubscriptionBetween].
class ActiveSubscriptionBetweenProvider
    extends AutoDisposeFutureProvider<Subscription?> {
  /// Check if a student has an active subscription with a teacher.
  /// Returns the active subscription if found, null otherwise.
  ///
  /// Copied from [activeSubscriptionBetween].
  ActiveSubscriptionBetweenProvider({
    required String studentId,
    required String teacherId,
  }) : this._internal(
          (ref) => activeSubscriptionBetween(
            ref as ActiveSubscriptionBetweenRef,
            studentId: studentId,
            teacherId: teacherId,
          ),
          from: activeSubscriptionBetweenProvider,
          name: r'activeSubscriptionBetweenProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$activeSubscriptionBetweenHash,
          dependencies: ActiveSubscriptionBetweenFamily._dependencies,
          allTransitiveDependencies:
              ActiveSubscriptionBetweenFamily._allTransitiveDependencies,
          studentId: studentId,
          teacherId: teacherId,
        );

  ActiveSubscriptionBetweenProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.studentId,
    required this.teacherId,
  }) : super.internal();

  final String studentId;
  final String teacherId;

  @override
  Override overrideWith(
    FutureOr<Subscription?> Function(ActiveSubscriptionBetweenRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ActiveSubscriptionBetweenProvider._internal(
        (ref) => create(ref as ActiveSubscriptionBetweenRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        studentId: studentId,
        teacherId: teacherId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Subscription?> createElement() {
    return _ActiveSubscriptionBetweenProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ActiveSubscriptionBetweenProvider &&
        other.studentId == studentId &&
        other.teacherId == teacherId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);
    hash = _SystemHash.combine(hash, teacherId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ActiveSubscriptionBetweenRef
    on AutoDisposeFutureProviderRef<Subscription?> {
  /// The parameter `studentId` of this provider.
  String get studentId;

  /// The parameter `teacherId` of this provider.
  String get teacherId;
}

class _ActiveSubscriptionBetweenProviderElement
    extends AutoDisposeFutureProviderElement<Subscription?>
    with ActiveSubscriptionBetweenRef {
  _ActiveSubscriptionBetweenProviderElement(super.provider);

  @override
  String get studentId =>
      (origin as ActiveSubscriptionBetweenProvider).studentId;
  @override
  String get teacherId =>
      (origin as ActiveSubscriptionBetweenProvider).teacherId;
}

String _$canBookLessonHash() => r'1cef46eb828bdd44b759fb973593c0186b120aca';

/// Check if a student can book a lesson with a teacher.
/// Returns true if:
/// - It's a trial lesson (no subscription needed)
/// - Student has an active subscription with remaining lessons
///
/// Copied from [canBookLesson].
@ProviderFor(canBookLesson)
const canBookLessonProvider = CanBookLessonFamily();

/// Check if a student can book a lesson with a teacher.
/// Returns true if:
/// - It's a trial lesson (no subscription needed)
/// - Student has an active subscription with remaining lessons
///
/// Copied from [canBookLesson].
class CanBookLessonFamily extends Family<AsyncValue<bool>> {
  /// Check if a student can book a lesson with a teacher.
  /// Returns true if:
  /// - It's a trial lesson (no subscription needed)
  /// - Student has an active subscription with remaining lessons
  ///
  /// Copied from [canBookLesson].
  const CanBookLessonFamily();

  /// Check if a student can book a lesson with a teacher.
  /// Returns true if:
  /// - It's a trial lesson (no subscription needed)
  /// - Student has an active subscription with remaining lessons
  ///
  /// Copied from [canBookLesson].
  CanBookLessonProvider call({
    required String studentId,
    required String teacherId,
    required bool isTrialLesson,
  }) {
    return CanBookLessonProvider(
      studentId: studentId,
      teacherId: teacherId,
      isTrialLesson: isTrialLesson,
    );
  }

  @override
  CanBookLessonProvider getProviderOverride(
    covariant CanBookLessonProvider provider,
  ) {
    return call(
      studentId: provider.studentId,
      teacherId: provider.teacherId,
      isTrialLesson: provider.isTrialLesson,
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
  String? get name => r'canBookLessonProvider';
}

/// Check if a student can book a lesson with a teacher.
/// Returns true if:
/// - It's a trial lesson (no subscription needed)
/// - Student has an active subscription with remaining lessons
///
/// Copied from [canBookLesson].
class CanBookLessonProvider extends AutoDisposeFutureProvider<bool> {
  /// Check if a student can book a lesson with a teacher.
  /// Returns true if:
  /// - It's a trial lesson (no subscription needed)
  /// - Student has an active subscription with remaining lessons
  ///
  /// Copied from [canBookLesson].
  CanBookLessonProvider({
    required String studentId,
    required String teacherId,
    required bool isTrialLesson,
  }) : this._internal(
          (ref) => canBookLesson(
            ref as CanBookLessonRef,
            studentId: studentId,
            teacherId: teacherId,
            isTrialLesson: isTrialLesson,
          ),
          from: canBookLessonProvider,
          name: r'canBookLessonProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$canBookLessonHash,
          dependencies: CanBookLessonFamily._dependencies,
          allTransitiveDependencies:
              CanBookLessonFamily._allTransitiveDependencies,
          studentId: studentId,
          teacherId: teacherId,
          isTrialLesson: isTrialLesson,
        );

  CanBookLessonProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.studentId,
    required this.teacherId,
    required this.isTrialLesson,
  }) : super.internal();

  final String studentId;
  final String teacherId;
  final bool isTrialLesson;

  @override
  Override overrideWith(
    FutureOr<bool> Function(CanBookLessonRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CanBookLessonProvider._internal(
        (ref) => create(ref as CanBookLessonRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        studentId: studentId,
        teacherId: teacherId,
        isTrialLesson: isTrialLesson,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<bool> createElement() {
    return _CanBookLessonProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CanBookLessonProvider &&
        other.studentId == studentId &&
        other.teacherId == teacherId &&
        other.isTrialLesson == isTrialLesson;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);
    hash = _SystemHash.combine(hash, teacherId.hashCode);
    hash = _SystemHash.combine(hash, isTrialLesson.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CanBookLessonRef on AutoDisposeFutureProviderRef<bool> {
  /// The parameter `studentId` of this provider.
  String get studentId;

  /// The parameter `teacherId` of this provider.
  String get teacherId;

  /// The parameter `isTrialLesson` of this provider.
  bool get isTrialLesson;
}

class _CanBookLessonProviderElement
    extends AutoDisposeFutureProviderElement<bool> with CanBookLessonRef {
  _CanBookLessonProviderElement(super.provider);

  @override
  String get studentId => (origin as CanBookLessonProvider).studentId;
  @override
  String get teacherId => (origin as CanBookLessonProvider).teacherId;
  @override
  bool get isTrialLesson => (origin as CanBookLessonProvider).isTrialLesson;
}

String _$subscriptionNotifierHash() =>
    r'03fca4a3bb48fcf5bad1ba660640dbbca8d4cc7e';

abstract class _$SubscriptionNotifier
    extends BuildlessAutoDisposeAsyncNotifier<List<Subscription>> {
  late final String studentId;

  FutureOr<List<Subscription>> build(
    String studentId,
  );
}

/// Notifier for managing Subscription CRUD operations for a student.
///
/// Copied from [SubscriptionNotifier].
@ProviderFor(SubscriptionNotifier)
const subscriptionNotifierProvider = SubscriptionNotifierFamily();

/// Notifier for managing Subscription CRUD operations for a student.
///
/// Copied from [SubscriptionNotifier].
class SubscriptionNotifierFamily
    extends Family<AsyncValue<List<Subscription>>> {
  /// Notifier for managing Subscription CRUD operations for a student.
  ///
  /// Copied from [SubscriptionNotifier].
  const SubscriptionNotifierFamily();

  /// Notifier for managing Subscription CRUD operations for a student.
  ///
  /// Copied from [SubscriptionNotifier].
  SubscriptionNotifierProvider call(
    String studentId,
  ) {
    return SubscriptionNotifierProvider(
      studentId,
    );
  }

  @override
  SubscriptionNotifierProvider getProviderOverride(
    covariant SubscriptionNotifierProvider provider,
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
  String? get name => r'subscriptionNotifierProvider';
}

/// Notifier for managing Subscription CRUD operations for a student.
///
/// Copied from [SubscriptionNotifier].
class SubscriptionNotifierProvider extends AutoDisposeAsyncNotifierProviderImpl<
    SubscriptionNotifier, List<Subscription>> {
  /// Notifier for managing Subscription CRUD operations for a student.
  ///
  /// Copied from [SubscriptionNotifier].
  SubscriptionNotifierProvider(
    String studentId,
  ) : this._internal(
          () => SubscriptionNotifier()..studentId = studentId,
          from: subscriptionNotifierProvider,
          name: r'subscriptionNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$subscriptionNotifierHash,
          dependencies: SubscriptionNotifierFamily._dependencies,
          allTransitiveDependencies:
              SubscriptionNotifierFamily._allTransitiveDependencies,
          studentId: studentId,
        );

  SubscriptionNotifierProvider._internal(
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
  FutureOr<List<Subscription>> runNotifierBuild(
    covariant SubscriptionNotifier notifier,
  ) {
    return notifier.build(
      studentId,
    );
  }

  @override
  Override overrideWith(SubscriptionNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: SubscriptionNotifierProvider._internal(
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
  AutoDisposeAsyncNotifierProviderElement<SubscriptionNotifier,
      List<Subscription>> createElement() {
    return _SubscriptionNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SubscriptionNotifierProvider &&
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
mixin SubscriptionNotifierRef
    on AutoDisposeAsyncNotifierProviderRef<List<Subscription>> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _SubscriptionNotifierProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<SubscriptionNotifier,
        List<Subscription>> with SubscriptionNotifierRef {
  _SubscriptionNotifierProviderElement(super.provider);

  @override
  String get studentId => (origin as SubscriptionNotifierProvider).studentId;
}

String _$membershipSubscriptionNotifierHash() =>
    r'0472ba42b286ca3bee1228e9e9ef0389b4401883';

abstract class _$MembershipSubscriptionNotifier
    extends BuildlessAutoDisposeAsyncNotifier<Subscription?> {
  late final String membershipId;

  FutureOr<Subscription?> build(
    String membershipId,
  );
}

/// Notifier for managing a single subscription (for membership).
///
/// Copied from [MembershipSubscriptionNotifier].
@ProviderFor(MembershipSubscriptionNotifier)
const membershipSubscriptionNotifierProvider =
    MembershipSubscriptionNotifierFamily();

/// Notifier for managing a single subscription (for membership).
///
/// Copied from [MembershipSubscriptionNotifier].
class MembershipSubscriptionNotifierFamily
    extends Family<AsyncValue<Subscription?>> {
  /// Notifier for managing a single subscription (for membership).
  ///
  /// Copied from [MembershipSubscriptionNotifier].
  const MembershipSubscriptionNotifierFamily();

  /// Notifier for managing a single subscription (for membership).
  ///
  /// Copied from [MembershipSubscriptionNotifier].
  MembershipSubscriptionNotifierProvider call(
    String membershipId,
  ) {
    return MembershipSubscriptionNotifierProvider(
      membershipId,
    );
  }

  @override
  MembershipSubscriptionNotifierProvider getProviderOverride(
    covariant MembershipSubscriptionNotifierProvider provider,
  ) {
    return call(
      provider.membershipId,
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
  String? get name => r'membershipSubscriptionNotifierProvider';
}

/// Notifier for managing a single subscription (for membership).
///
/// Copied from [MembershipSubscriptionNotifier].
class MembershipSubscriptionNotifierProvider
    extends AutoDisposeAsyncNotifierProviderImpl<MembershipSubscriptionNotifier,
        Subscription?> {
  /// Notifier for managing a single subscription (for membership).
  ///
  /// Copied from [MembershipSubscriptionNotifier].
  MembershipSubscriptionNotifierProvider(
    String membershipId,
  ) : this._internal(
          () => MembershipSubscriptionNotifier()..membershipId = membershipId,
          from: membershipSubscriptionNotifierProvider,
          name: r'membershipSubscriptionNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$membershipSubscriptionNotifierHash,
          dependencies: MembershipSubscriptionNotifierFamily._dependencies,
          allTransitiveDependencies:
              MembershipSubscriptionNotifierFamily._allTransitiveDependencies,
          membershipId: membershipId,
        );

  MembershipSubscriptionNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.membershipId,
  }) : super.internal();

  final String membershipId;

  @override
  FutureOr<Subscription?> runNotifierBuild(
    covariant MembershipSubscriptionNotifier notifier,
  ) {
    return notifier.build(
      membershipId,
    );
  }

  @override
  Override overrideWith(MembershipSubscriptionNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: MembershipSubscriptionNotifierProvider._internal(
        () => create()..membershipId = membershipId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        membershipId: membershipId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<MembershipSubscriptionNotifier,
      Subscription?> createElement() {
    return _MembershipSubscriptionNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MembershipSubscriptionNotifierProvider &&
        other.membershipId == membershipId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, membershipId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin MembershipSubscriptionNotifierRef
    on AutoDisposeAsyncNotifierProviderRef<Subscription?> {
  /// The parameter `membershipId` of this provider.
  String get membershipId;
}

class _MembershipSubscriptionNotifierProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<
        MembershipSubscriptionNotifier,
        Subscription?> with MembershipSubscriptionNotifierRef {
  _MembershipSubscriptionNotifierProviderElement(super.provider);

  @override
  String get membershipId =>
      (origin as MembershipSubscriptionNotifierProvider).membershipId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
