// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_home_booking_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$studentHomeNextLessonHash() =>
    r'1b8ba617e0e0600b6a718da5fc4b78f359bd2dd8';

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

/// See also [studentHomeNextLesson].
@ProviderFor(studentHomeNextLesson)
const studentHomeNextLessonProvider = StudentHomeNextLessonFamily();

/// See also [studentHomeNextLesson].
class StudentHomeNextLessonFamily extends Family<AsyncValue<LessonBooking?>> {
  /// See also [studentHomeNextLesson].
  const StudentHomeNextLessonFamily();

  /// See also [studentHomeNextLesson].
  StudentHomeNextLessonProvider call(String studentId) {
    return StudentHomeNextLessonProvider(studentId);
  }

  @override
  StudentHomeNextLessonProvider getProviderOverride(
    covariant StudentHomeNextLessonProvider provider,
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
  String? get name => r'studentHomeNextLessonProvider';
}

/// See also [studentHomeNextLesson].
class StudentHomeNextLessonProvider
    extends AutoDisposeFutureProvider<LessonBooking?> {
  /// See also [studentHomeNextLesson].
  StudentHomeNextLessonProvider(String studentId)
    : this._internal(
        (ref) =>
            studentHomeNextLesson(ref as StudentHomeNextLessonRef, studentId),
        from: studentHomeNextLessonProvider,
        name: r'studentHomeNextLessonProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$studentHomeNextLessonHash,
        dependencies: StudentHomeNextLessonFamily._dependencies,
        allTransitiveDependencies:
            StudentHomeNextLessonFamily._allTransitiveDependencies,
        studentId: studentId,
      );

  StudentHomeNextLessonProvider._internal(
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
    FutureOr<LessonBooking?> Function(StudentHomeNextLessonRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: StudentHomeNextLessonProvider._internal(
        (ref) => create(ref as StudentHomeNextLessonRef),
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
  AutoDisposeFutureProviderElement<LessonBooking?> createElement() {
    return _StudentHomeNextLessonProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StudentHomeNextLessonProvider &&
        other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin StudentHomeNextLessonRef on AutoDisposeFutureProviderRef<LessonBooking?> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _StudentHomeNextLessonProviderElement
    extends AutoDisposeFutureProviderElement<LessonBooking?>
    with StudentHomeNextLessonRef {
  _StudentHomeNextLessonProviderElement(super.provider);

  @override
  String get studentId => (origin as StudentHomeNextLessonProvider).studentId;
}

String _$studentHomeTrialBookingsHash() =>
    r'abc1e7b26e53d121edfe43ad80c9273a6f3345ec';

/// See also [studentHomeTrialBookings].
@ProviderFor(studentHomeTrialBookings)
const studentHomeTrialBookingsProvider = StudentHomeTrialBookingsFamily();

/// See also [studentHomeTrialBookings].
class StudentHomeTrialBookingsFamily
    extends Family<AsyncValue<List<LessonBooking>>> {
  /// See also [studentHomeTrialBookings].
  const StudentHomeTrialBookingsFamily();

  /// See also [studentHomeTrialBookings].
  StudentHomeTrialBookingsProvider call(String studentId) {
    return StudentHomeTrialBookingsProvider(studentId);
  }

  @override
  StudentHomeTrialBookingsProvider getProviderOverride(
    covariant StudentHomeTrialBookingsProvider provider,
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
  String? get name => r'studentHomeTrialBookingsProvider';
}

/// See also [studentHomeTrialBookings].
class StudentHomeTrialBookingsProvider
    extends AutoDisposeFutureProvider<List<LessonBooking>> {
  /// See also [studentHomeTrialBookings].
  StudentHomeTrialBookingsProvider(String studentId)
    : this._internal(
        (ref) => studentHomeTrialBookings(
          ref as StudentHomeTrialBookingsRef,
          studentId,
        ),
        from: studentHomeTrialBookingsProvider,
        name: r'studentHomeTrialBookingsProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$studentHomeTrialBookingsHash,
        dependencies: StudentHomeTrialBookingsFamily._dependencies,
        allTransitiveDependencies:
            StudentHomeTrialBookingsFamily._allTransitiveDependencies,
        studentId: studentId,
      );

  StudentHomeTrialBookingsProvider._internal(
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
    FutureOr<List<LessonBooking>> Function(StudentHomeTrialBookingsRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: StudentHomeTrialBookingsProvider._internal(
        (ref) => create(ref as StudentHomeTrialBookingsRef),
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
  AutoDisposeFutureProviderElement<List<LessonBooking>> createElement() {
    return _StudentHomeTrialBookingsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StudentHomeTrialBookingsProvider &&
        other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin StudentHomeTrialBookingsRef
    on AutoDisposeFutureProviderRef<List<LessonBooking>> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _StudentHomeTrialBookingsProviderElement
    extends AutoDisposeFutureProviderElement<List<LessonBooking>>
    with StudentHomeTrialBookingsRef {
  _StudentHomeTrialBookingsProviderElement(super.provider);

  @override
  String get studentId =>
      (origin as StudentHomeTrialBookingsProvider).studentId;
}

String _$studentHomeHasAnyBookingHash() =>
    r'3f7b77dda381a4545a0f6c17104a9eee407bb662';

/// See also [studentHomeHasAnyBooking].
@ProviderFor(studentHomeHasAnyBooking)
const studentHomeHasAnyBookingProvider = StudentHomeHasAnyBookingFamily();

/// See also [studentHomeHasAnyBooking].
class StudentHomeHasAnyBookingFamily extends Family<AsyncValue<bool>> {
  /// See also [studentHomeHasAnyBooking].
  const StudentHomeHasAnyBookingFamily();

  /// See also [studentHomeHasAnyBooking].
  StudentHomeHasAnyBookingProvider call(String studentId) {
    return StudentHomeHasAnyBookingProvider(studentId);
  }

  @override
  StudentHomeHasAnyBookingProvider getProviderOverride(
    covariant StudentHomeHasAnyBookingProvider provider,
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
  String? get name => r'studentHomeHasAnyBookingProvider';
}

/// See also [studentHomeHasAnyBooking].
class StudentHomeHasAnyBookingProvider extends AutoDisposeFutureProvider<bool> {
  /// See also [studentHomeHasAnyBooking].
  StudentHomeHasAnyBookingProvider(String studentId)
    : this._internal(
        (ref) => studentHomeHasAnyBooking(
          ref as StudentHomeHasAnyBookingRef,
          studentId,
        ),
        from: studentHomeHasAnyBookingProvider,
        name: r'studentHomeHasAnyBookingProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$studentHomeHasAnyBookingHash,
        dependencies: StudentHomeHasAnyBookingFamily._dependencies,
        allTransitiveDependencies:
            StudentHomeHasAnyBookingFamily._allTransitiveDependencies,
        studentId: studentId,
      );

  StudentHomeHasAnyBookingProvider._internal(
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
    FutureOr<bool> Function(StudentHomeHasAnyBookingRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: StudentHomeHasAnyBookingProvider._internal(
        (ref) => create(ref as StudentHomeHasAnyBookingRef),
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
  AutoDisposeFutureProviderElement<bool> createElement() {
    return _StudentHomeHasAnyBookingProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StudentHomeHasAnyBookingProvider &&
        other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin StudentHomeHasAnyBookingRef on AutoDisposeFutureProviderRef<bool> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _StudentHomeHasAnyBookingProviderElement
    extends AutoDisposeFutureProviderElement<bool>
    with StudentHomeHasAnyBookingRef {
  _StudentHomeHasAnyBookingProviderElement(super.provider);

  @override
  String get studentId =>
      (origin as StudentHomeHasAnyBookingProvider).studentId;
}

String _$studentHomeLessonsScheduleHash() =>
    r'cd13cf9a96d11172c6a29ab35ec1ec8d4a4bf21f';

/// See also [studentHomeLessonsSchedule].
@ProviderFor(studentHomeLessonsSchedule)
const studentHomeLessonsScheduleProvider = StudentHomeLessonsScheduleFamily();

/// See also [studentHomeLessonsSchedule].
class StudentHomeLessonsScheduleFamily
    extends Family<AsyncValue<StudentHomeLessonsSchedule>> {
  /// See also [studentHomeLessonsSchedule].
  const StudentHomeLessonsScheduleFamily();

  /// See also [studentHomeLessonsSchedule].
  StudentHomeLessonsScheduleProvider call(String studentId) {
    return StudentHomeLessonsScheduleProvider(studentId);
  }

  @override
  StudentHomeLessonsScheduleProvider getProviderOverride(
    covariant StudentHomeLessonsScheduleProvider provider,
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
  String? get name => r'studentHomeLessonsScheduleProvider';
}

/// See also [studentHomeLessonsSchedule].
class StudentHomeLessonsScheduleProvider
    extends AutoDisposeFutureProvider<StudentHomeLessonsSchedule> {
  /// See also [studentHomeLessonsSchedule].
  StudentHomeLessonsScheduleProvider(String studentId)
    : this._internal(
        (ref) => studentHomeLessonsSchedule(
          ref as StudentHomeLessonsScheduleRef,
          studentId,
        ),
        from: studentHomeLessonsScheduleProvider,
        name: r'studentHomeLessonsScheduleProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$studentHomeLessonsScheduleHash,
        dependencies: StudentHomeLessonsScheduleFamily._dependencies,
        allTransitiveDependencies:
            StudentHomeLessonsScheduleFamily._allTransitiveDependencies,
        studentId: studentId,
      );

  StudentHomeLessonsScheduleProvider._internal(
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
    FutureOr<StudentHomeLessonsSchedule> Function(
      StudentHomeLessonsScheduleRef provider,
    )
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: StudentHomeLessonsScheduleProvider._internal(
        (ref) => create(ref as StudentHomeLessonsScheduleRef),
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
  AutoDisposeFutureProviderElement<StudentHomeLessonsSchedule> createElement() {
    return _StudentHomeLessonsScheduleProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StudentHomeLessonsScheduleProvider &&
        other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin StudentHomeLessonsScheduleRef
    on AutoDisposeFutureProviderRef<StudentHomeLessonsSchedule> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _StudentHomeLessonsScheduleProviderElement
    extends AutoDisposeFutureProviderElement<StudentHomeLessonsSchedule>
    with StudentHomeLessonsScheduleRef {
  _StudentHomeLessonsScheduleProviderElement(super.provider);

  @override
  String get studentId =>
      (origin as StudentHomeLessonsScheduleProvider).studentId;
}

String _$studentHomeBookingActionsHash() =>
    r'f02d4f8f01efe637258e33e77c12bf4899a5f6cf';

/// See also [studentHomeBookingActions].
@ProviderFor(studentHomeBookingActions)
final studentHomeBookingActionsProvider =
    AutoDisposeProvider<StudentHomeBookingActions>.internal(
      studentHomeBookingActions,
      name: r'studentHomeBookingActionsProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$studentHomeBookingActionsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef StudentHomeBookingActionsRef =
    AutoDisposeProviderRef<StudentHomeBookingActions>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
