// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unified_lesson_request_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$studentNameMapHash() => r'2e5d34770957b17c5e4ad08ec38c86711efc40af';

/// Student name lookup — Mock only (Remote: fetch from API).
/// Returns student name by studentId.
///
/// Copied from [studentNameMap].
@ProviderFor(studentNameMap)
final studentNameMapProvider = Provider<Map<String, String>>.internal(
  studentNameMap,
  name: r'studentNameMapProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$studentNameMapHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef StudentNameMapRef = ProviderRef<Map<String, String>>;
String _$teacherNameMapHash() => r'db94ce1bbb83dfe67d04bfe578c7d64e063057e0';

/// Teacher name lookup — Mock only (Remote: fetch from API).
/// Returns teacher name by teacherId.
///
/// Copied from [teacherNameMap].
@ProviderFor(teacherNameMap)
final teacherNameMapProvider = Provider<Map<String, String>>.internal(
  teacherNameMap,
  name: r'teacherNameMapProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$teacherNameMapHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef TeacherNameMapRef = ProviderRef<Map<String, String>>;
String _$academyNameMapHash() => r'94e2c267d5203f7f3692c6f64f3b931f20ee0f6d';

/// Academy name lookup — Mock only.
///
/// Copied from [academyNameMap].
@ProviderFor(academyNameMap)
final academyNameMapProvider = Provider<Map<String, String>>.internal(
  academyNameMap,
  name: r'academyNameMapProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$academyNameMapHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AcademyNameMapRef = ProviderRef<Map<String, String>>;
String _$unifiedLessonRequestRepositoryHash() =>
    r'3af059d7f54f1e1b4551aca7b3ec528e38bfb4ab';

/// Repository provider — switches between Mock and Remote.
///
/// Copied from [unifiedLessonRequestRepository].
@ProviderFor(unifiedLessonRequestRepository)
final unifiedLessonRequestRepositoryProvider =
    Provider<UnifiedLessonRequestRepository>.internal(
  unifiedLessonRequestRepository,
  name: r'unifiedLessonRequestRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$unifiedLessonRequestRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef UnifiedLessonRequestRepositoryRef
    = ProviderRef<UnifiedLessonRequestRepository>;
String _$unifiedLessonRequestWorkflowServiceHash() =>
    r'5a3b2e51b584bf503379a76756fe951f30fffb96';

/// See also [unifiedLessonRequestWorkflowService].
@ProviderFor(unifiedLessonRequestWorkflowService)
final unifiedLessonRequestWorkflowServiceProvider =
    Provider<UnifiedLessonRequestWorkflowService>.internal(
  unifiedLessonRequestWorkflowService,
  name: r'unifiedLessonRequestWorkflowServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$unifiedLessonRequestWorkflowServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef UnifiedLessonRequestWorkflowServiceRef
    = ProviderRef<UnifiedLessonRequestWorkflowService>;
String _$teacherUnifiedRequestsHash() =>
    r'7badd2579857d2673986c6e63733671f710edddc';

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

/// Get all unified lesson requests for a teacher
///
/// Copied from [teacherUnifiedRequests].
@ProviderFor(teacherUnifiedRequests)
const teacherUnifiedRequestsProvider = TeacherUnifiedRequestsFamily();

/// Get all unified lesson requests for a teacher
///
/// Copied from [teacherUnifiedRequests].
class TeacherUnifiedRequestsFamily
    extends Family<AsyncValue<List<UnifiedLessonRequest>>> {
  /// Get all unified lesson requests for a teacher
  ///
  /// Copied from [teacherUnifiedRequests].
  const TeacherUnifiedRequestsFamily();

  /// Get all unified lesson requests for a teacher
  ///
  /// Copied from [teacherUnifiedRequests].
  TeacherUnifiedRequestsProvider call(
    String teacherId,
  ) {
    return TeacherUnifiedRequestsProvider(
      teacherId,
    );
  }

  @override
  TeacherUnifiedRequestsProvider getProviderOverride(
    covariant TeacherUnifiedRequestsProvider provider,
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
  String? get name => r'teacherUnifiedRequestsProvider';
}

/// Get all unified lesson requests for a teacher
///
/// Copied from [teacherUnifiedRequests].
class TeacherUnifiedRequestsProvider
    extends AutoDisposeFutureProvider<List<UnifiedLessonRequest>> {
  /// Get all unified lesson requests for a teacher
  ///
  /// Copied from [teacherUnifiedRequests].
  TeacherUnifiedRequestsProvider(
    String teacherId,
  ) : this._internal(
          (ref) => teacherUnifiedRequests(
            ref as TeacherUnifiedRequestsRef,
            teacherId,
          ),
          from: teacherUnifiedRequestsProvider,
          name: r'teacherUnifiedRequestsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$teacherUnifiedRequestsHash,
          dependencies: TeacherUnifiedRequestsFamily._dependencies,
          allTransitiveDependencies:
              TeacherUnifiedRequestsFamily._allTransitiveDependencies,
          teacherId: teacherId,
        );

  TeacherUnifiedRequestsProvider._internal(
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
    FutureOr<List<UnifiedLessonRequest>> Function(
            TeacherUnifiedRequestsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TeacherUnifiedRequestsProvider._internal(
        (ref) => create(ref as TeacherUnifiedRequestsRef),
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
  AutoDisposeFutureProviderElement<List<UnifiedLessonRequest>> createElement() {
    return _TeacherUnifiedRequestsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TeacherUnifiedRequestsProvider &&
        other.teacherId == teacherId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, teacherId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin TeacherUnifiedRequestsRef
    on AutoDisposeFutureProviderRef<List<UnifiedLessonRequest>> {
  /// The parameter `teacherId` of this provider.
  String get teacherId;
}

class _TeacherUnifiedRequestsProviderElement
    extends AutoDisposeFutureProviderElement<List<UnifiedLessonRequest>>
    with TeacherUnifiedRequestsRef {
  _TeacherUnifiedRequestsProviderElement(super.provider);

  @override
  String get teacherId => (origin as TeacherUnifiedRequestsProvider).teacherId;
}

String _$pendingUnifiedRequestsHash() =>
    r'95aad8bd2f15766cbed1bc8dd2141ff8c1fb1fbc';

/// Get pending unified requests for a teacher
///
/// Copied from [pendingUnifiedRequests].
@ProviderFor(pendingUnifiedRequests)
const pendingUnifiedRequestsProvider = PendingUnifiedRequestsFamily();

/// Get pending unified requests for a teacher
///
/// Copied from [pendingUnifiedRequests].
class PendingUnifiedRequestsFamily
    extends Family<AsyncValue<List<UnifiedLessonRequest>>> {
  /// Get pending unified requests for a teacher
  ///
  /// Copied from [pendingUnifiedRequests].
  const PendingUnifiedRequestsFamily();

  /// Get pending unified requests for a teacher
  ///
  /// Copied from [pendingUnifiedRequests].
  PendingUnifiedRequestsProvider call(
    String teacherId,
  ) {
    return PendingUnifiedRequestsProvider(
      teacherId,
    );
  }

  @override
  PendingUnifiedRequestsProvider getProviderOverride(
    covariant PendingUnifiedRequestsProvider provider,
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
  String? get name => r'pendingUnifiedRequestsProvider';
}

/// Get pending unified requests for a teacher
///
/// Copied from [pendingUnifiedRequests].
class PendingUnifiedRequestsProvider
    extends AutoDisposeFutureProvider<List<UnifiedLessonRequest>> {
  /// Get pending unified requests for a teacher
  ///
  /// Copied from [pendingUnifiedRequests].
  PendingUnifiedRequestsProvider(
    String teacherId,
  ) : this._internal(
          (ref) => pendingUnifiedRequests(
            ref as PendingUnifiedRequestsRef,
            teacherId,
          ),
          from: pendingUnifiedRequestsProvider,
          name: r'pendingUnifiedRequestsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$pendingUnifiedRequestsHash,
          dependencies: PendingUnifiedRequestsFamily._dependencies,
          allTransitiveDependencies:
              PendingUnifiedRequestsFamily._allTransitiveDependencies,
          teacherId: teacherId,
        );

  PendingUnifiedRequestsProvider._internal(
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
    FutureOr<List<UnifiedLessonRequest>> Function(
            PendingUnifiedRequestsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PendingUnifiedRequestsProvider._internal(
        (ref) => create(ref as PendingUnifiedRequestsRef),
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
  AutoDisposeFutureProviderElement<List<UnifiedLessonRequest>> createElement() {
    return _PendingUnifiedRequestsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PendingUnifiedRequestsProvider &&
        other.teacherId == teacherId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, teacherId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin PendingUnifiedRequestsRef
    on AutoDisposeFutureProviderRef<List<UnifiedLessonRequest>> {
  /// The parameter `teacherId` of this provider.
  String get teacherId;
}

class _PendingUnifiedRequestsProviderElement
    extends AutoDisposeFutureProviderElement<List<UnifiedLessonRequest>>
    with PendingUnifiedRequestsRef {
  _PendingUnifiedRequestsProviderElement(super.provider);

  @override
  String get teacherId => (origin as PendingUnifiedRequestsProvider).teacherId;
}

String _$pendingUnifiedRequestCountHash() =>
    r'6f97be486f15a369f1aae0f6b2cf9e8441cf5828';

/// Get pending unified request count (for badge)
///
/// Copied from [pendingUnifiedRequestCount].
@ProviderFor(pendingUnifiedRequestCount)
const pendingUnifiedRequestCountProvider = PendingUnifiedRequestCountFamily();

/// Get pending unified request count (for badge)
///
/// Copied from [pendingUnifiedRequestCount].
class PendingUnifiedRequestCountFamily extends Family<AsyncValue<int>> {
  /// Get pending unified request count (for badge)
  ///
  /// Copied from [pendingUnifiedRequestCount].
  const PendingUnifiedRequestCountFamily();

  /// Get pending unified request count (for badge)
  ///
  /// Copied from [pendingUnifiedRequestCount].
  PendingUnifiedRequestCountProvider call(
    String teacherId,
  ) {
    return PendingUnifiedRequestCountProvider(
      teacherId,
    );
  }

  @override
  PendingUnifiedRequestCountProvider getProviderOverride(
    covariant PendingUnifiedRequestCountProvider provider,
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
  String? get name => r'pendingUnifiedRequestCountProvider';
}

/// Get pending unified request count (for badge)
///
/// Copied from [pendingUnifiedRequestCount].
class PendingUnifiedRequestCountProvider
    extends AutoDisposeFutureProvider<int> {
  /// Get pending unified request count (for badge)
  ///
  /// Copied from [pendingUnifiedRequestCount].
  PendingUnifiedRequestCountProvider(
    String teacherId,
  ) : this._internal(
          (ref) => pendingUnifiedRequestCount(
            ref as PendingUnifiedRequestCountRef,
            teacherId,
          ),
          from: pendingUnifiedRequestCountProvider,
          name: r'pendingUnifiedRequestCountProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$pendingUnifiedRequestCountHash,
          dependencies: PendingUnifiedRequestCountFamily._dependencies,
          allTransitiveDependencies:
              PendingUnifiedRequestCountFamily._allTransitiveDependencies,
          teacherId: teacherId,
        );

  PendingUnifiedRequestCountProvider._internal(
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
    FutureOr<int> Function(PendingUnifiedRequestCountRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PendingUnifiedRequestCountProvider._internal(
        (ref) => create(ref as PendingUnifiedRequestCountRef),
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
    return _PendingUnifiedRequestCountProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PendingUnifiedRequestCountProvider &&
        other.teacherId == teacherId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, teacherId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin PendingUnifiedRequestCountRef on AutoDisposeFutureProviderRef<int> {
  /// The parameter `teacherId` of this provider.
  String get teacherId;
}

class _PendingUnifiedRequestCountProviderElement
    extends AutoDisposeFutureProviderElement<int>
    with PendingUnifiedRequestCountRef {
  _PendingUnifiedRequestCountProviderElement(super.provider);

  @override
  String get teacherId =>
      (origin as PendingUnifiedRequestCountProvider).teacherId;
}

String _$studentUnifiedRequestsHash() =>
    r'63ffd43d11d17f4c625d2259481c9afd12802b8d';

/// Get unified requests sent by a student
///
/// Copied from [studentUnifiedRequests].
@ProviderFor(studentUnifiedRequests)
const studentUnifiedRequestsProvider = StudentUnifiedRequestsFamily();

/// Get unified requests sent by a student
///
/// Copied from [studentUnifiedRequests].
class StudentUnifiedRequestsFamily
    extends Family<AsyncValue<List<UnifiedLessonRequest>>> {
  /// Get unified requests sent by a student
  ///
  /// Copied from [studentUnifiedRequests].
  const StudentUnifiedRequestsFamily();

  /// Get unified requests sent by a student
  ///
  /// Copied from [studentUnifiedRequests].
  StudentUnifiedRequestsProvider call(
    String studentId,
  ) {
    return StudentUnifiedRequestsProvider(
      studentId,
    );
  }

  @override
  StudentUnifiedRequestsProvider getProviderOverride(
    covariant StudentUnifiedRequestsProvider provider,
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
  String? get name => r'studentUnifiedRequestsProvider';
}

/// Get unified requests sent by a student
///
/// Copied from [studentUnifiedRequests].
class StudentUnifiedRequestsProvider
    extends AutoDisposeFutureProvider<List<UnifiedLessonRequest>> {
  /// Get unified requests sent by a student
  ///
  /// Copied from [studentUnifiedRequests].
  StudentUnifiedRequestsProvider(
    String studentId,
  ) : this._internal(
          (ref) => studentUnifiedRequests(
            ref as StudentUnifiedRequestsRef,
            studentId,
          ),
          from: studentUnifiedRequestsProvider,
          name: r'studentUnifiedRequestsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$studentUnifiedRequestsHash,
          dependencies: StudentUnifiedRequestsFamily._dependencies,
          allTransitiveDependencies:
              StudentUnifiedRequestsFamily._allTransitiveDependencies,
          studentId: studentId,
        );

  StudentUnifiedRequestsProvider._internal(
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
    FutureOr<List<UnifiedLessonRequest>> Function(
            StudentUnifiedRequestsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: StudentUnifiedRequestsProvider._internal(
        (ref) => create(ref as StudentUnifiedRequestsRef),
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
  AutoDisposeFutureProviderElement<List<UnifiedLessonRequest>> createElement() {
    return _StudentUnifiedRequestsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StudentUnifiedRequestsProvider &&
        other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin StudentUnifiedRequestsRef
    on AutoDisposeFutureProviderRef<List<UnifiedLessonRequest>> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _StudentUnifiedRequestsProviderElement
    extends AutoDisposeFutureProviderElement<List<UnifiedLessonRequest>>
    with StudentUnifiedRequestsRef {
  _StudentUnifiedRequestsProviderElement(super.provider);

  @override
  String get studentId => (origin as StudentUnifiedRequestsProvider).studentId;
}

String _$unifiedRequestByIdHash() =>
    r'e31943daeab7e2b56df0eb5185ab1e3d6b46ff7b';

/// Get a single unified request by ID
///
/// Copied from [unifiedRequestById].
@ProviderFor(unifiedRequestById)
const unifiedRequestByIdProvider = UnifiedRequestByIdFamily();

/// Get a single unified request by ID
///
/// Copied from [unifiedRequestById].
class UnifiedRequestByIdFamily
    extends Family<AsyncValue<UnifiedLessonRequest?>> {
  /// Get a single unified request by ID
  ///
  /// Copied from [unifiedRequestById].
  const UnifiedRequestByIdFamily();

  /// Get a single unified request by ID
  ///
  /// Copied from [unifiedRequestById].
  UnifiedRequestByIdProvider call(
    String requestId,
  ) {
    return UnifiedRequestByIdProvider(
      requestId,
    );
  }

  @override
  UnifiedRequestByIdProvider getProviderOverride(
    covariant UnifiedRequestByIdProvider provider,
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
  String? get name => r'unifiedRequestByIdProvider';
}

/// Get a single unified request by ID
///
/// Copied from [unifiedRequestById].
class UnifiedRequestByIdProvider
    extends AutoDisposeFutureProvider<UnifiedLessonRequest?> {
  /// Get a single unified request by ID
  ///
  /// Copied from [unifiedRequestById].
  UnifiedRequestByIdProvider(
    String requestId,
  ) : this._internal(
          (ref) => unifiedRequestById(
            ref as UnifiedRequestByIdRef,
            requestId,
          ),
          from: unifiedRequestByIdProvider,
          name: r'unifiedRequestByIdProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$unifiedRequestByIdHash,
          dependencies: UnifiedRequestByIdFamily._dependencies,
          allTransitiveDependencies:
              UnifiedRequestByIdFamily._allTransitiveDependencies,
          requestId: requestId,
        );

  UnifiedRequestByIdProvider._internal(
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
    FutureOr<UnifiedLessonRequest?> Function(UnifiedRequestByIdRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UnifiedRequestByIdProvider._internal(
        (ref) => create(ref as UnifiedRequestByIdRef),
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
  AutoDisposeFutureProviderElement<UnifiedLessonRequest?> createElement() {
    return _UnifiedRequestByIdProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UnifiedRequestByIdProvider && other.requestId == requestId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, requestId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin UnifiedRequestByIdRef
    on AutoDisposeFutureProviderRef<UnifiedLessonRequest?> {
  /// The parameter `requestId` of this provider.
  String get requestId;
}

class _UnifiedRequestByIdProviderElement
    extends AutoDisposeFutureProviderElement<UnifiedLessonRequest?>
    with UnifiedRequestByIdRef {
  _UnifiedRequestByIdProviderElement(super.provider);

  @override
  String get requestId => (origin as UnifiedRequestByIdProvider).requestId;
}

String _$requestEventsHash() => r'da1fea94f522371ad2dacd163c90617b8064052c';

/// Get all events for a specific request (chat history).
///
/// Copied from [requestEvents].
@ProviderFor(requestEvents)
const requestEventsProvider = RequestEventsFamily();

/// Get all events for a specific request (chat history).
///
/// Copied from [requestEvents].
class RequestEventsFamily extends Family<AsyncValue<List<RequestEvent>>> {
  /// Get all events for a specific request (chat history).
  ///
  /// Copied from [requestEvents].
  const RequestEventsFamily();

  /// Get all events for a specific request (chat history).
  ///
  /// Copied from [requestEvents].
  RequestEventsProvider call(
    String requestId,
  ) {
    return RequestEventsProvider(
      requestId,
    );
  }

  @override
  RequestEventsProvider getProviderOverride(
    covariant RequestEventsProvider provider,
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
  String? get name => r'requestEventsProvider';
}

/// Get all events for a specific request (chat history).
///
/// Copied from [requestEvents].
class RequestEventsProvider
    extends AutoDisposeFutureProvider<List<RequestEvent>> {
  /// Get all events for a specific request (chat history).
  ///
  /// Copied from [requestEvents].
  RequestEventsProvider(
    String requestId,
  ) : this._internal(
          (ref) => requestEvents(
            ref as RequestEventsRef,
            requestId,
          ),
          from: requestEventsProvider,
          name: r'requestEventsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$requestEventsHash,
          dependencies: RequestEventsFamily._dependencies,
          allTransitiveDependencies:
              RequestEventsFamily._allTransitiveDependencies,
          requestId: requestId,
        );

  RequestEventsProvider._internal(
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
    FutureOr<List<RequestEvent>> Function(RequestEventsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: RequestEventsProvider._internal(
        (ref) => create(ref as RequestEventsRef),
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
  AutoDisposeFutureProviderElement<List<RequestEvent>> createElement() {
    return _RequestEventsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RequestEventsProvider && other.requestId == requestId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, requestId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin RequestEventsRef on AutoDisposeFutureProviderRef<List<RequestEvent>> {
  /// The parameter `requestId` of this provider.
  String get requestId;
}

class _RequestEventsProviderElement
    extends AutoDisposeFutureProviderElement<List<RequestEvent>>
    with RequestEventsRef {
  _RequestEventsProviderElement(super.provider);

  @override
  String get requestId => (origin as RequestEventsProvider).requestId;
}

String _$todayRequestsHash() => r'11491e42ca79fe62975d55fe4149a7e976b0e761';

/// Today's requests for a teacher: active + completed today, pending first.
///
/// Copied from [todayRequests].
@ProviderFor(todayRequests)
const todayRequestsProvider = TodayRequestsFamily();

/// Today's requests for a teacher: active + completed today, pending first.
///
/// Copied from [todayRequests].
class TodayRequestsFamily
    extends Family<AsyncValue<List<UnifiedLessonRequest>>> {
  /// Today's requests for a teacher: active + completed today, pending first.
  ///
  /// Copied from [todayRequests].
  const TodayRequestsFamily();

  /// Today's requests for a teacher: active + completed today, pending first.
  ///
  /// Copied from [todayRequests].
  TodayRequestsProvider call(
    String teacherId,
  ) {
    return TodayRequestsProvider(
      teacherId,
    );
  }

  @override
  TodayRequestsProvider getProviderOverride(
    covariant TodayRequestsProvider provider,
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
  String? get name => r'todayRequestsProvider';
}

/// Today's requests for a teacher: active + completed today, pending first.
///
/// Copied from [todayRequests].
class TodayRequestsProvider
    extends AutoDisposeFutureProvider<List<UnifiedLessonRequest>> {
  /// Today's requests for a teacher: active + completed today, pending first.
  ///
  /// Copied from [todayRequests].
  TodayRequestsProvider(
    String teacherId,
  ) : this._internal(
          (ref) => todayRequests(
            ref as TodayRequestsRef,
            teacherId,
          ),
          from: todayRequestsProvider,
          name: r'todayRequestsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$todayRequestsHash,
          dependencies: TodayRequestsFamily._dependencies,
          allTransitiveDependencies:
              TodayRequestsFamily._allTransitiveDependencies,
          teacherId: teacherId,
        );

  TodayRequestsProvider._internal(
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
    FutureOr<List<UnifiedLessonRequest>> Function(TodayRequestsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TodayRequestsProvider._internal(
        (ref) => create(ref as TodayRequestsRef),
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
  AutoDisposeFutureProviderElement<List<UnifiedLessonRequest>> createElement() {
    return _TodayRequestsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TodayRequestsProvider && other.teacherId == teacherId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, teacherId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin TodayRequestsRef
    on AutoDisposeFutureProviderRef<List<UnifiedLessonRequest>> {
  /// The parameter `teacherId` of this provider.
  String get teacherId;
}

class _TodayRequestsProviderElement
    extends AutoDisposeFutureProviderElement<List<UnifiedLessonRequest>>
    with TodayRequestsRef {
  _TodayRequestsProviderElement(super.provider);

  @override
  String get teacherId => (origin as TodayRequestsProvider).teacherId;
}

String _$studentTodayRequestsHash() =>
    r'efca6e72c7a0a53cc3edb789a312412ca1edd650';

/// Today's requests for a student: active + completed today, pending first.
///
/// Copied from [studentTodayRequests].
@ProviderFor(studentTodayRequests)
const studentTodayRequestsProvider = StudentTodayRequestsFamily();

/// Today's requests for a student: active + completed today, pending first.
///
/// Copied from [studentTodayRequests].
class StudentTodayRequestsFamily
    extends Family<AsyncValue<List<UnifiedLessonRequest>>> {
  /// Today's requests for a student: active + completed today, pending first.
  ///
  /// Copied from [studentTodayRequests].
  const StudentTodayRequestsFamily();

  /// Today's requests for a student: active + completed today, pending first.
  ///
  /// Copied from [studentTodayRequests].
  StudentTodayRequestsProvider call(
    String studentId,
  ) {
    return StudentTodayRequestsProvider(
      studentId,
    );
  }

  @override
  StudentTodayRequestsProvider getProviderOverride(
    covariant StudentTodayRequestsProvider provider,
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
  String? get name => r'studentTodayRequestsProvider';
}

/// Today's requests for a student: active + completed today, pending first.
///
/// Copied from [studentTodayRequests].
class StudentTodayRequestsProvider
    extends AutoDisposeFutureProvider<List<UnifiedLessonRequest>> {
  /// Today's requests for a student: active + completed today, pending first.
  ///
  /// Copied from [studentTodayRequests].
  StudentTodayRequestsProvider(
    String studentId,
  ) : this._internal(
          (ref) => studentTodayRequests(
            ref as StudentTodayRequestsRef,
            studentId,
          ),
          from: studentTodayRequestsProvider,
          name: r'studentTodayRequestsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$studentTodayRequestsHash,
          dependencies: StudentTodayRequestsFamily._dependencies,
          allTransitiveDependencies:
              StudentTodayRequestsFamily._allTransitiveDependencies,
          studentId: studentId,
        );

  StudentTodayRequestsProvider._internal(
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
    FutureOr<List<UnifiedLessonRequest>> Function(
            StudentTodayRequestsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: StudentTodayRequestsProvider._internal(
        (ref) => create(ref as StudentTodayRequestsRef),
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
  AutoDisposeFutureProviderElement<List<UnifiedLessonRequest>> createElement() {
    return _StudentTodayRequestsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StudentTodayRequestsProvider &&
        other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin StudentTodayRequestsRef
    on AutoDisposeFutureProviderRef<List<UnifiedLessonRequest>> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _StudentTodayRequestsProviderElement
    extends AutoDisposeFutureProviderElement<List<UnifiedLessonRequest>>
    with StudentTodayRequestsRef {
  _StudentTodayRequestsProviderElement(super.provider);

  @override
  String get studentId => (origin as StudentTodayRequestsProvider).studentId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
