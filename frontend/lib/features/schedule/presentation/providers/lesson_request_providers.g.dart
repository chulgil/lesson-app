// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lesson_request_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$lessonRequestRepositoryHash() =>
    r'0a2fcd48a81ae901d721196df6d4607ca99949cf';

/// Repository provider
///
/// Copied from [lessonRequestRepository].
@ProviderFor(lessonRequestRepository)
final lessonRequestRepositoryProvider =
    AutoDisposeProvider<LessonRequestRepository>.internal(
  lessonRequestRepository,
  name: r'lessonRequestRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$lessonRequestRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LessonRequestRepositoryRef
    = AutoDisposeProviderRef<LessonRequestRepository>;
String _$teacherLessonRequestsHash() =>
    r'39cc1b79ccffd3ec0a1b5cdc3f8da67d7e8eac35';

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

/// Get all lesson requests for a teacher
///
/// Copied from [teacherLessonRequests].
@ProviderFor(teacherLessonRequests)
const teacherLessonRequestsProvider = TeacherLessonRequestsFamily();

/// Get all lesson requests for a teacher
///
/// Copied from [teacherLessonRequests].
class TeacherLessonRequestsFamily
    extends Family<AsyncValue<List<LessonRequest>>> {
  /// Get all lesson requests for a teacher
  ///
  /// Copied from [teacherLessonRequests].
  const TeacherLessonRequestsFamily();

  /// Get all lesson requests for a teacher
  ///
  /// Copied from [teacherLessonRequests].
  TeacherLessonRequestsProvider call(
    String teacherId,
  ) {
    return TeacherLessonRequestsProvider(
      teacherId,
    );
  }

  @override
  TeacherLessonRequestsProvider getProviderOverride(
    covariant TeacherLessonRequestsProvider provider,
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
  String? get name => r'teacherLessonRequestsProvider';
}

/// Get all lesson requests for a teacher
///
/// Copied from [teacherLessonRequests].
class TeacherLessonRequestsProvider
    extends AutoDisposeFutureProvider<List<LessonRequest>> {
  /// Get all lesson requests for a teacher
  ///
  /// Copied from [teacherLessonRequests].
  TeacherLessonRequestsProvider(
    String teacherId,
  ) : this._internal(
          (ref) => teacherLessonRequests(
            ref as TeacherLessonRequestsRef,
            teacherId,
          ),
          from: teacherLessonRequestsProvider,
          name: r'teacherLessonRequestsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$teacherLessonRequestsHash,
          dependencies: TeacherLessonRequestsFamily._dependencies,
          allTransitiveDependencies:
              TeacherLessonRequestsFamily._allTransitiveDependencies,
          teacherId: teacherId,
        );

  TeacherLessonRequestsProvider._internal(
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
    FutureOr<List<LessonRequest>> Function(TeacherLessonRequestsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TeacherLessonRequestsProvider._internal(
        (ref) => create(ref as TeacherLessonRequestsRef),
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
  AutoDisposeFutureProviderElement<List<LessonRequest>> createElement() {
    return _TeacherLessonRequestsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TeacherLessonRequestsProvider &&
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
mixin TeacherLessonRequestsRef
    on AutoDisposeFutureProviderRef<List<LessonRequest>> {
  /// The parameter `teacherId` of this provider.
  String get teacherId;
}

class _TeacherLessonRequestsProviderElement
    extends AutoDisposeFutureProviderElement<List<LessonRequest>>
    with TeacherLessonRequestsRef {
  _TeacherLessonRequestsProviderElement(super.provider);

  @override
  String get teacherId => (origin as TeacherLessonRequestsProvider).teacherId;
}

String _$pendingLessonRequestsHash() =>
    r'b4876fecae27b3594707c5674b9a8b030401ecb1';

/// Get pending lesson requests for a teacher
///
/// Copied from [pendingLessonRequests].
@ProviderFor(pendingLessonRequests)
const pendingLessonRequestsProvider = PendingLessonRequestsFamily();

/// Get pending lesson requests for a teacher
///
/// Copied from [pendingLessonRequests].
class PendingLessonRequestsFamily
    extends Family<AsyncValue<List<LessonRequest>>> {
  /// Get pending lesson requests for a teacher
  ///
  /// Copied from [pendingLessonRequests].
  const PendingLessonRequestsFamily();

  /// Get pending lesson requests for a teacher
  ///
  /// Copied from [pendingLessonRequests].
  PendingLessonRequestsProvider call(
    String teacherId,
  ) {
    return PendingLessonRequestsProvider(
      teacherId,
    );
  }

  @override
  PendingLessonRequestsProvider getProviderOverride(
    covariant PendingLessonRequestsProvider provider,
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
  String? get name => r'pendingLessonRequestsProvider';
}

/// Get pending lesson requests for a teacher
///
/// Copied from [pendingLessonRequests].
class PendingLessonRequestsProvider
    extends AutoDisposeFutureProvider<List<LessonRequest>> {
  /// Get pending lesson requests for a teacher
  ///
  /// Copied from [pendingLessonRequests].
  PendingLessonRequestsProvider(
    String teacherId,
  ) : this._internal(
          (ref) => pendingLessonRequests(
            ref as PendingLessonRequestsRef,
            teacherId,
          ),
          from: pendingLessonRequestsProvider,
          name: r'pendingLessonRequestsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$pendingLessonRequestsHash,
          dependencies: PendingLessonRequestsFamily._dependencies,
          allTransitiveDependencies:
              PendingLessonRequestsFamily._allTransitiveDependencies,
          teacherId: teacherId,
        );

  PendingLessonRequestsProvider._internal(
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
    FutureOr<List<LessonRequest>> Function(PendingLessonRequestsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PendingLessonRequestsProvider._internal(
        (ref) => create(ref as PendingLessonRequestsRef),
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
  AutoDisposeFutureProviderElement<List<LessonRequest>> createElement() {
    return _PendingLessonRequestsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PendingLessonRequestsProvider &&
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
mixin PendingLessonRequestsRef
    on AutoDisposeFutureProviderRef<List<LessonRequest>> {
  /// The parameter `teacherId` of this provider.
  String get teacherId;
}

class _PendingLessonRequestsProviderElement
    extends AutoDisposeFutureProviderElement<List<LessonRequest>>
    with PendingLessonRequestsRef {
  _PendingLessonRequestsProviderElement(super.provider);

  @override
  String get teacherId => (origin as PendingLessonRequestsProvider).teacherId;
}

String _$pendingLessonRequestCountHash() =>
    r'f49bbcd7c6bc7b8c9431b25abfa5c797a8f87cf3';

/// Get pending request count for a teacher (for badge)
///
/// Copied from [pendingLessonRequestCount].
@ProviderFor(pendingLessonRequestCount)
const pendingLessonRequestCountProvider = PendingLessonRequestCountFamily();

/// Get pending request count for a teacher (for badge)
///
/// Copied from [pendingLessonRequestCount].
class PendingLessonRequestCountFamily extends Family<AsyncValue<int>> {
  /// Get pending request count for a teacher (for badge)
  ///
  /// Copied from [pendingLessonRequestCount].
  const PendingLessonRequestCountFamily();

  /// Get pending request count for a teacher (for badge)
  ///
  /// Copied from [pendingLessonRequestCount].
  PendingLessonRequestCountProvider call(
    String teacherId,
  ) {
    return PendingLessonRequestCountProvider(
      teacherId,
    );
  }

  @override
  PendingLessonRequestCountProvider getProviderOverride(
    covariant PendingLessonRequestCountProvider provider,
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
  String? get name => r'pendingLessonRequestCountProvider';
}

/// Get pending request count for a teacher (for badge)
///
/// Copied from [pendingLessonRequestCount].
class PendingLessonRequestCountProvider extends AutoDisposeFutureProvider<int> {
  /// Get pending request count for a teacher (for badge)
  ///
  /// Copied from [pendingLessonRequestCount].
  PendingLessonRequestCountProvider(
    String teacherId,
  ) : this._internal(
          (ref) => pendingLessonRequestCount(
            ref as PendingLessonRequestCountRef,
            teacherId,
          ),
          from: pendingLessonRequestCountProvider,
          name: r'pendingLessonRequestCountProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$pendingLessonRequestCountHash,
          dependencies: PendingLessonRequestCountFamily._dependencies,
          allTransitiveDependencies:
              PendingLessonRequestCountFamily._allTransitiveDependencies,
          teacherId: teacherId,
        );

  PendingLessonRequestCountProvider._internal(
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
    FutureOr<int> Function(PendingLessonRequestCountRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PendingLessonRequestCountProvider._internal(
        (ref) => create(ref as PendingLessonRequestCountRef),
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
    return _PendingLessonRequestCountProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PendingLessonRequestCountProvider &&
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
mixin PendingLessonRequestCountRef on AutoDisposeFutureProviderRef<int> {
  /// The parameter `teacherId` of this provider.
  String get teacherId;
}

class _PendingLessonRequestCountProviderElement
    extends AutoDisposeFutureProviderElement<int>
    with PendingLessonRequestCountRef {
  _PendingLessonRequestCountProviderElement(super.provider);

  @override
  String get teacherId =>
      (origin as PendingLessonRequestCountProvider).teacherId;
}

String _$studentLessonRequestsHash() =>
    r'266e4350df0121a9c68fed13f642e265674a8492';

/// Get all lesson requests sent by a student
///
/// Copied from [studentLessonRequests].
@ProviderFor(studentLessonRequests)
const studentLessonRequestsProvider = StudentLessonRequestsFamily();

/// Get all lesson requests sent by a student
///
/// Copied from [studentLessonRequests].
class StudentLessonRequestsFamily
    extends Family<AsyncValue<List<LessonRequest>>> {
  /// Get all lesson requests sent by a student
  ///
  /// Copied from [studentLessonRequests].
  const StudentLessonRequestsFamily();

  /// Get all lesson requests sent by a student
  ///
  /// Copied from [studentLessonRequests].
  StudentLessonRequestsProvider call(
    String studentId,
  ) {
    return StudentLessonRequestsProvider(
      studentId,
    );
  }

  @override
  StudentLessonRequestsProvider getProviderOverride(
    covariant StudentLessonRequestsProvider provider,
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
  String? get name => r'studentLessonRequestsProvider';
}

/// Get all lesson requests sent by a student
///
/// Copied from [studentLessonRequests].
class StudentLessonRequestsProvider
    extends AutoDisposeFutureProvider<List<LessonRequest>> {
  /// Get all lesson requests sent by a student
  ///
  /// Copied from [studentLessonRequests].
  StudentLessonRequestsProvider(
    String studentId,
  ) : this._internal(
          (ref) => studentLessonRequests(
            ref as StudentLessonRequestsRef,
            studentId,
          ),
          from: studentLessonRequestsProvider,
          name: r'studentLessonRequestsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$studentLessonRequestsHash,
          dependencies: StudentLessonRequestsFamily._dependencies,
          allTransitiveDependencies:
              StudentLessonRequestsFamily._allTransitiveDependencies,
          studentId: studentId,
        );

  StudentLessonRequestsProvider._internal(
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
    FutureOr<List<LessonRequest>> Function(StudentLessonRequestsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: StudentLessonRequestsProvider._internal(
        (ref) => create(ref as StudentLessonRequestsRef),
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
  AutoDisposeFutureProviderElement<List<LessonRequest>> createElement() {
    return _StudentLessonRequestsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StudentLessonRequestsProvider &&
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
mixin StudentLessonRequestsRef
    on AutoDisposeFutureProviderRef<List<LessonRequest>> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _StudentLessonRequestsProviderElement
    extends AutoDisposeFutureProviderElement<List<LessonRequest>>
    with StudentLessonRequestsRef {
  _StudentLessonRequestsProviderElement(super.provider);

  @override
  String get studentId => (origin as StudentLessonRequestsProvider).studentId;
}

String _$lessonRequestByIdHash() => r'3e29c5f6fedacffa50d4202749f31fa401f1d422';

/// Get a single lesson request by ID
///
/// Copied from [lessonRequestById].
@ProviderFor(lessonRequestById)
const lessonRequestByIdProvider = LessonRequestByIdFamily();

/// Get a single lesson request by ID
///
/// Copied from [lessonRequestById].
class LessonRequestByIdFamily extends Family<AsyncValue<LessonRequest?>> {
  /// Get a single lesson request by ID
  ///
  /// Copied from [lessonRequestById].
  const LessonRequestByIdFamily();

  /// Get a single lesson request by ID
  ///
  /// Copied from [lessonRequestById].
  LessonRequestByIdProvider call(
    String requestId,
  ) {
    return LessonRequestByIdProvider(
      requestId,
    );
  }

  @override
  LessonRequestByIdProvider getProviderOverride(
    covariant LessonRequestByIdProvider provider,
  ) {
    return call(
      provider.requestId,
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
  String? get name => r'lessonRequestByIdProvider';
}

/// Get a single lesson request by ID
///
/// Copied from [lessonRequestById].
class LessonRequestByIdProvider
    extends AutoDisposeFutureProvider<LessonRequest?> {
  /// Get a single lesson request by ID
  ///
  /// Copied from [lessonRequestById].
  LessonRequestByIdProvider(
    String requestId,
  ) : this._internal(
          (ref) => lessonRequestById(
            ref as LessonRequestByIdRef,
            requestId,
          ),
          from: lessonRequestByIdProvider,
          name: r'lessonRequestByIdProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$lessonRequestByIdHash,
          dependencies: LessonRequestByIdFamily._dependencies,
          allTransitiveDependencies:
              LessonRequestByIdFamily._allTransitiveDependencies,
          requestId: requestId,
        );

  LessonRequestByIdProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.requestId,
  }) : super.internal();

  final String requestId;

  @override
  Override overrideWith(
    FutureOr<LessonRequest?> Function(LessonRequestByIdRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: LessonRequestByIdProvider._internal(
        (ref) => create(ref as LessonRequestByIdRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        requestId: requestId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<LessonRequest?> createElement() {
    return _LessonRequestByIdProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is LessonRequestByIdProvider && other.requestId == requestId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, requestId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin LessonRequestByIdRef on AutoDisposeFutureProviderRef<LessonRequest?> {
  /// The parameter `requestId` of this provider.
  String get requestId;
}

class _LessonRequestByIdProviderElement
    extends AutoDisposeFutureProviderElement<LessonRequest?>
    with LessonRequestByIdRef {
  _LessonRequestByIdProviderElement(super.provider);

  @override
  String get requestId => (origin as LessonRequestByIdProvider).requestId;
}

String _$lessonRequestActionsHash() =>
    r'910bb27eef95f6721058dc9a1756edd0d12be176';

/// Lesson request actions (create, update, respond)
///
/// Copied from [LessonRequestActions].
@ProviderFor(LessonRequestActions)
final lessonRequestActionsProvider =
    AutoDisposeAsyncNotifierProvider<LessonRequestActions, void>.internal(
  LessonRequestActions.new,
  name: r'lessonRequestActionsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$lessonRequestActionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$LessonRequestActions = AutoDisposeAsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
