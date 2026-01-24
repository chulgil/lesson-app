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

String _$subscriptionNotifierHash() =>
    r'485fe1a7522e6d4de318dcc9055a18235ef56772';

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
    r'1e75d0a27f3a6c2f169f939c7efff904c4227fb5';

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
