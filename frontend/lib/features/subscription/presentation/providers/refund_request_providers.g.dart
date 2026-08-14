// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'refund_request_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$refundRequestRepositoryHash() =>
    r'140fbbfe19e0deae93ea28285fd2850d7064b7e2';

/// Repository provider — switches between Mock and Remote (#1271).
///
/// Copied from [refundRequestRepository].
@ProviderFor(refundRequestRepository)
final refundRequestRepositoryProvider =
    Provider<RefundRequestRepository>.internal(
  refundRequestRepository,
  name: r'refundRequestRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$refundRequestRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef RefundRequestRepositoryRef = ProviderRef<RefundRequestRepository>;
String _$studentRefundRequestsHash() =>
    r'd3202e2a30ad8eca59ffdd23a283aa648c0f2908';

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

/// Student-side: all of the signed-in student's refund requests (masked).
///
/// Copied from [studentRefundRequests].
@ProviderFor(studentRefundRequests)
const studentRefundRequestsProvider = StudentRefundRequestsFamily();

/// Student-side: all of the signed-in student's refund requests (masked).
///
/// Copied from [studentRefundRequests].
class StudentRefundRequestsFamily
    extends Family<AsyncValue<List<RefundRequest>>> {
  /// Student-side: all of the signed-in student's refund requests (masked).
  ///
  /// Copied from [studentRefundRequests].
  const StudentRefundRequestsFamily();

  /// Student-side: all of the signed-in student's refund requests (masked).
  ///
  /// Copied from [studentRefundRequests].
  StudentRefundRequestsProvider call(
    String studentId,
  ) {
    return StudentRefundRequestsProvider(
      studentId,
    );
  }

  @override
  StudentRefundRequestsProvider getProviderOverride(
    covariant StudentRefundRequestsProvider provider,
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
  String? get name => r'studentRefundRequestsProvider';
}

/// Student-side: all of the signed-in student's refund requests (masked).
///
/// Copied from [studentRefundRequests].
class StudentRefundRequestsProvider
    extends AutoDisposeFutureProvider<List<RefundRequest>> {
  /// Student-side: all of the signed-in student's refund requests (masked).
  ///
  /// Copied from [studentRefundRequests].
  StudentRefundRequestsProvider(
    String studentId,
  ) : this._internal(
          (ref) => studentRefundRequests(
            ref as StudentRefundRequestsRef,
            studentId,
          ),
          from: studentRefundRequestsProvider,
          name: r'studentRefundRequestsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$studentRefundRequestsHash,
          dependencies: StudentRefundRequestsFamily._dependencies,
          allTransitiveDependencies:
              StudentRefundRequestsFamily._allTransitiveDependencies,
          studentId: studentId,
        );

  StudentRefundRequestsProvider._internal(
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
    FutureOr<List<RefundRequest>> Function(StudentRefundRequestsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: StudentRefundRequestsProvider._internal(
        (ref) => create(ref as StudentRefundRequestsRef),
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
  AutoDisposeFutureProviderElement<List<RefundRequest>> createElement() {
    return _StudentRefundRequestsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StudentRefundRequestsProvider &&
        other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin StudentRefundRequestsRef
    on AutoDisposeFutureProviderRef<List<RefundRequest>> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _StudentRefundRequestsProviderElement
    extends AutoDisposeFutureProviderElement<List<RefundRequest>>
    with StudentRefundRequestsRef {
  _StudentRefundRequestsProviderElement(super.provider);

  @override
  String get studentId => (origin as StudentRefundRequestsProvider).studentId;
}

String _$teacherRefundRequestsHash() =>
    r'83c0f187e12754a5cb53fdf49d2345f566866947';

/// Teacher-side: all refund requests across the teacher's students.
///
/// Copied from [teacherRefundRequests].
@ProviderFor(teacherRefundRequests)
const teacherRefundRequestsProvider = TeacherRefundRequestsFamily();

/// Teacher-side: all refund requests across the teacher's students.
///
/// Copied from [teacherRefundRequests].
class TeacherRefundRequestsFamily
    extends Family<AsyncValue<List<RefundRequest>>> {
  /// Teacher-side: all refund requests across the teacher's students.
  ///
  /// Copied from [teacherRefundRequests].
  const TeacherRefundRequestsFamily();

  /// Teacher-side: all refund requests across the teacher's students.
  ///
  /// Copied from [teacherRefundRequests].
  TeacherRefundRequestsProvider call(
    String teacherId,
  ) {
    return TeacherRefundRequestsProvider(
      teacherId,
    );
  }

  @override
  TeacherRefundRequestsProvider getProviderOverride(
    covariant TeacherRefundRequestsProvider provider,
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
  String? get name => r'teacherRefundRequestsProvider';
}

/// Teacher-side: all refund requests across the teacher's students.
///
/// Copied from [teacherRefundRequests].
class TeacherRefundRequestsProvider
    extends AutoDisposeFutureProvider<List<RefundRequest>> {
  /// Teacher-side: all refund requests across the teacher's students.
  ///
  /// Copied from [teacherRefundRequests].
  TeacherRefundRequestsProvider(
    String teacherId,
  ) : this._internal(
          (ref) => teacherRefundRequests(
            ref as TeacherRefundRequestsRef,
            teacherId,
          ),
          from: teacherRefundRequestsProvider,
          name: r'teacherRefundRequestsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$teacherRefundRequestsHash,
          dependencies: TeacherRefundRequestsFamily._dependencies,
          allTransitiveDependencies:
              TeacherRefundRequestsFamily._allTransitiveDependencies,
          teacherId: teacherId,
        );

  TeacherRefundRequestsProvider._internal(
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
    FutureOr<List<RefundRequest>> Function(TeacherRefundRequestsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TeacherRefundRequestsProvider._internal(
        (ref) => create(ref as TeacherRefundRequestsRef),
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
  AutoDisposeFutureProviderElement<List<RefundRequest>> createElement() {
    return _TeacherRefundRequestsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TeacherRefundRequestsProvider &&
        other.teacherId == teacherId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, teacherId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin TeacherRefundRequestsRef
    on AutoDisposeFutureProviderRef<List<RefundRequest>> {
  /// The parameter `teacherId` of this provider.
  String get teacherId;
}

class _TeacherRefundRequestsProviderElement
    extends AutoDisposeFutureProviderElement<List<RefundRequest>>
    with TeacherRefundRequestsRef {
  _TeacherRefundRequestsProviderElement(super.provider);

  @override
  String get teacherId => (origin as TeacherRefundRequestsProvider).teacherId;
}

String _$teacherPendingRefundRequestsHash() =>
    r'4d628be37c827b55cfc5bc2debb72df56a04e38e';

/// Teacher-side: the still-actionable subset, for the pending dashboard
/// card and list screen.
///
/// Copied from [teacherPendingRefundRequests].
@ProviderFor(teacherPendingRefundRequests)
const teacherPendingRefundRequestsProvider =
    TeacherPendingRefundRequestsFamily();

/// Teacher-side: the still-actionable subset, for the pending dashboard
/// card and list screen.
///
/// Copied from [teacherPendingRefundRequests].
class TeacherPendingRefundRequestsFamily
    extends Family<AsyncValue<List<RefundRequest>>> {
  /// Teacher-side: the still-actionable subset, for the pending dashboard
  /// card and list screen.
  ///
  /// Copied from [teacherPendingRefundRequests].
  const TeacherPendingRefundRequestsFamily();

  /// Teacher-side: the still-actionable subset, for the pending dashboard
  /// card and list screen.
  ///
  /// Copied from [teacherPendingRefundRequests].
  TeacherPendingRefundRequestsProvider call(
    String teacherId,
  ) {
    return TeacherPendingRefundRequestsProvider(
      teacherId,
    );
  }

  @override
  TeacherPendingRefundRequestsProvider getProviderOverride(
    covariant TeacherPendingRefundRequestsProvider provider,
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
  String? get name => r'teacherPendingRefundRequestsProvider';
}

/// Teacher-side: the still-actionable subset, for the pending dashboard
/// card and list screen.
///
/// Copied from [teacherPendingRefundRequests].
class TeacherPendingRefundRequestsProvider
    extends AutoDisposeFutureProvider<List<RefundRequest>> {
  /// Teacher-side: the still-actionable subset, for the pending dashboard
  /// card and list screen.
  ///
  /// Copied from [teacherPendingRefundRequests].
  TeacherPendingRefundRequestsProvider(
    String teacherId,
  ) : this._internal(
          (ref) => teacherPendingRefundRequests(
            ref as TeacherPendingRefundRequestsRef,
            teacherId,
          ),
          from: teacherPendingRefundRequestsProvider,
          name: r'teacherPendingRefundRequestsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$teacherPendingRefundRequestsHash,
          dependencies: TeacherPendingRefundRequestsFamily._dependencies,
          allTransitiveDependencies:
              TeacherPendingRefundRequestsFamily._allTransitiveDependencies,
          teacherId: teacherId,
        );

  TeacherPendingRefundRequestsProvider._internal(
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
    FutureOr<List<RefundRequest>> Function(
            TeacherPendingRefundRequestsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TeacherPendingRefundRequestsProvider._internal(
        (ref) => create(ref as TeacherPendingRefundRequestsRef),
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
  AutoDisposeFutureProviderElement<List<RefundRequest>> createElement() {
    return _TeacherPendingRefundRequestsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TeacherPendingRefundRequestsProvider &&
        other.teacherId == teacherId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, teacherId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin TeacherPendingRefundRequestsRef
    on AutoDisposeFutureProviderRef<List<RefundRequest>> {
  /// The parameter `teacherId` of this provider.
  String get teacherId;
}

class _TeacherPendingRefundRequestsProviderElement
    extends AutoDisposeFutureProviderElement<List<RefundRequest>>
    with TeacherPendingRefundRequestsRef {
  _TeacherPendingRefundRequestsProviderElement(super.provider);

  @override
  String get teacherId =>
      (origin as TeacherPendingRefundRequestsProvider).teacherId;
}

String _$teacherPendingRefundRequestCountHash() =>
    r'783cef008a00a2f3c0d1c9af0aa860ace5415930';

/// Teacher-side: pending count for the dashboard badge.
///
/// Copied from [teacherPendingRefundRequestCount].
@ProviderFor(teacherPendingRefundRequestCount)
const teacherPendingRefundRequestCountProvider =
    TeacherPendingRefundRequestCountFamily();

/// Teacher-side: pending count for the dashboard badge.
///
/// Copied from [teacherPendingRefundRequestCount].
class TeacherPendingRefundRequestCountFamily extends Family<AsyncValue<int>> {
  /// Teacher-side: pending count for the dashboard badge.
  ///
  /// Copied from [teacherPendingRefundRequestCount].
  const TeacherPendingRefundRequestCountFamily();

  /// Teacher-side: pending count for the dashboard badge.
  ///
  /// Copied from [teacherPendingRefundRequestCount].
  TeacherPendingRefundRequestCountProvider call(
    String teacherId,
  ) {
    return TeacherPendingRefundRequestCountProvider(
      teacherId,
    );
  }

  @override
  TeacherPendingRefundRequestCountProvider getProviderOverride(
    covariant TeacherPendingRefundRequestCountProvider provider,
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
  String? get name => r'teacherPendingRefundRequestCountProvider';
}

/// Teacher-side: pending count for the dashboard badge.
///
/// Copied from [teacherPendingRefundRequestCount].
class TeacherPendingRefundRequestCountProvider
    extends AutoDisposeFutureProvider<int> {
  /// Teacher-side: pending count for the dashboard badge.
  ///
  /// Copied from [teacherPendingRefundRequestCount].
  TeacherPendingRefundRequestCountProvider(
    String teacherId,
  ) : this._internal(
          (ref) => teacherPendingRefundRequestCount(
            ref as TeacherPendingRefundRequestCountRef,
            teacherId,
          ),
          from: teacherPendingRefundRequestCountProvider,
          name: r'teacherPendingRefundRequestCountProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$teacherPendingRefundRequestCountHash,
          dependencies: TeacherPendingRefundRequestCountFamily._dependencies,
          allTransitiveDependencies:
              TeacherPendingRefundRequestCountFamily._allTransitiveDependencies,
          teacherId: teacherId,
        );

  TeacherPendingRefundRequestCountProvider._internal(
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
    FutureOr<int> Function(TeacherPendingRefundRequestCountRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TeacherPendingRefundRequestCountProvider._internal(
        (ref) => create(ref as TeacherPendingRefundRequestCountRef),
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
  AutoDisposeFutureProviderElement<int> createElement() {
    return _TeacherPendingRefundRequestCountProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TeacherPendingRefundRequestCountProvider &&
        other.teacherId == teacherId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, teacherId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin TeacherPendingRefundRequestCountRef on AutoDisposeFutureProviderRef<int> {
  /// The parameter `teacherId` of this provider.
  String get teacherId;
}

class _TeacherPendingRefundRequestCountProviderElement
    extends AutoDisposeFutureProviderElement<int>
    with TeacherPendingRefundRequestCountRef {
  _TeacherPendingRefundRequestCountProviderElement(super.provider);

  @override
  String get teacherId =>
      (origin as TeacherPendingRefundRequestCountProvider).teacherId;
}

String _$refundRequestForSubscriptionHash() =>
    r'e5ed0040960cedb71d10a619c7c91c6c5739d162';

/// Latest refund request (any status) for one subscription, viewer-scoped.
/// Drives the subscription-detail entry point / status badge / action box.
///
/// Copied from [refundRequestForSubscription].
@ProviderFor(refundRequestForSubscription)
const refundRequestForSubscriptionProvider =
    RefundRequestForSubscriptionFamily();

/// Latest refund request (any status) for one subscription, viewer-scoped.
/// Drives the subscription-detail entry point / status badge / action box.
///
/// Copied from [refundRequestForSubscription].
class RefundRequestForSubscriptionFamily
    extends Family<AsyncValue<RefundRequest?>> {
  /// Latest refund request (any status) for one subscription, viewer-scoped.
  /// Drives the subscription-detail entry point / status badge / action box.
  ///
  /// Copied from [refundRequestForSubscription].
  const RefundRequestForSubscriptionFamily();

  /// Latest refund request (any status) for one subscription, viewer-scoped.
  /// Drives the subscription-detail entry point / status badge / action box.
  ///
  /// Copied from [refundRequestForSubscription].
  RefundRequestForSubscriptionProvider call({
    required String subscriptionId,
    required bool asTeacher,
  }) {
    return RefundRequestForSubscriptionProvider(
      subscriptionId: subscriptionId,
      asTeacher: asTeacher,
    );
  }

  @override
  RefundRequestForSubscriptionProvider getProviderOverride(
    covariant RefundRequestForSubscriptionProvider provider,
  ) {
    return call(
      subscriptionId: provider.subscriptionId,
      asTeacher: provider.asTeacher,
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
  String? get name => r'refundRequestForSubscriptionProvider';
}

/// Latest refund request (any status) for one subscription, viewer-scoped.
/// Drives the subscription-detail entry point / status badge / action box.
///
/// Copied from [refundRequestForSubscription].
class RefundRequestForSubscriptionProvider
    extends AutoDisposeFutureProvider<RefundRequest?> {
  /// Latest refund request (any status) for one subscription, viewer-scoped.
  /// Drives the subscription-detail entry point / status badge / action box.
  ///
  /// Copied from [refundRequestForSubscription].
  RefundRequestForSubscriptionProvider({
    required String subscriptionId,
    required bool asTeacher,
  }) : this._internal(
          (ref) => refundRequestForSubscription(
            ref as RefundRequestForSubscriptionRef,
            subscriptionId: subscriptionId,
            asTeacher: asTeacher,
          ),
          from: refundRequestForSubscriptionProvider,
          name: r'refundRequestForSubscriptionProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$refundRequestForSubscriptionHash,
          dependencies: RefundRequestForSubscriptionFamily._dependencies,
          allTransitiveDependencies:
              RefundRequestForSubscriptionFamily._allTransitiveDependencies,
          subscriptionId: subscriptionId,
          asTeacher: asTeacher,
        );

  RefundRequestForSubscriptionProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.subscriptionId,
    required this.asTeacher,
  }) : super.internal();

  final String subscriptionId;
  final bool asTeacher;

  @override
  Override overrideWith(
    FutureOr<RefundRequest?> Function(RefundRequestForSubscriptionRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: RefundRequestForSubscriptionProvider._internal(
        (ref) => create(ref as RefundRequestForSubscriptionRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        subscriptionId: subscriptionId,
        asTeacher: asTeacher,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<RefundRequest?> createElement() {
    return _RefundRequestForSubscriptionProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RefundRequestForSubscriptionProvider &&
        other.subscriptionId == subscriptionId &&
        other.asTeacher == asTeacher;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, subscriptionId.hashCode);
    hash = _SystemHash.combine(hash, asTeacher.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin RefundRequestForSubscriptionRef
    on AutoDisposeFutureProviderRef<RefundRequest?> {
  /// The parameter `subscriptionId` of this provider.
  String get subscriptionId;

  /// The parameter `asTeacher` of this provider.
  bool get asTeacher;
}

class _RefundRequestForSubscriptionProviderElement
    extends AutoDisposeFutureProviderElement<RefundRequest?>
    with RefundRequestForSubscriptionRef {
  _RefundRequestForSubscriptionProviderElement(super.provider);

  @override
  String get subscriptionId =>
      (origin as RefundRequestForSubscriptionProvider).subscriptionId;
  @override
  bool get asTeacher =>
      (origin as RefundRequestForSubscriptionProvider).asTeacher;
}

String _$refundRequestActionsHash() =>
    r'479198cdfb0b4a60f781672e090ce030dcf33c59';

/// Mutation actions — create (student) / complete / reject (teacher), with
/// cache invalidation and best-effort notification dispatch.
///
/// Copied from [refundRequestActions].
@ProviderFor(refundRequestActions)
final refundRequestActionsProvider =
    AutoDisposeProvider<RefundRequestActions>.internal(
  refundRequestActions,
  name: r'refundRequestActionsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$refundRequestActionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef RefundRequestActionsRef = AutoDisposeProviderRef<RefundRequestActions>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
