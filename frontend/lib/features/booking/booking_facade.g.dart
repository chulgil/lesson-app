// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_facade.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$bookingByIdHash() => r'a35d63d2c93a8046e94e4e7198f34fdbbecc5336';

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

/// Single booking by ID.
///
/// Copied from [bookingById].
@ProviderFor(bookingById)
const bookingByIdProvider = BookingByIdFamily();

/// Single booking by ID.
///
/// Copied from [bookingById].
class BookingByIdFamily extends Family<AsyncValue<LessonBooking?>> {
  /// Single booking by ID.
  ///
  /// Copied from [bookingById].
  const BookingByIdFamily();

  /// Single booking by ID.
  ///
  /// Copied from [bookingById].
  BookingByIdProvider call(String id) {
    return BookingByIdProvider(id);
  }

  @override
  BookingByIdProvider getProviderOverride(
    covariant BookingByIdProvider provider,
  ) {
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
  String? get name => r'bookingByIdProvider';
}

/// Single booking by ID.
///
/// Copied from [bookingById].
class BookingByIdProvider extends AutoDisposeFutureProvider<LessonBooking?> {
  /// Single booking by ID.
  ///
  /// Copied from [bookingById].
  BookingByIdProvider(String id)
    : this._internal(
        (ref) => bookingById(ref as BookingByIdRef, id),
        from: bookingByIdProvider,
        name: r'bookingByIdProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$bookingByIdHash,
        dependencies: BookingByIdFamily._dependencies,
        allTransitiveDependencies: BookingByIdFamily._allTransitiveDependencies,
        id: id,
      );

  BookingByIdProvider._internal(
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
    FutureOr<LessonBooking?> Function(BookingByIdRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: BookingByIdProvider._internal(
        (ref) => create(ref as BookingByIdRef),
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
  AutoDisposeFutureProviderElement<LessonBooking?> createElement() {
    return _BookingByIdProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BookingByIdProvider && other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin BookingByIdRef on AutoDisposeFutureProviderRef<LessonBooking?> {
  /// The parameter `id` of this provider.
  String get id;
}

class _BookingByIdProviderElement
    extends AutoDisposeFutureProviderElement<LessonBooking?>
    with BookingByIdRef {
  _BookingByIdProviderElement(super.provider);

  @override
  String get id => (origin as BookingByIdProvider).id;
}

String _$studentBookingListHash() =>
    r'b5c37938ec600a0450236561cfeccee90c942d99';

/// All bookings for a student (student home, trial cards).
///
/// Copied from [studentBookingList].
@ProviderFor(studentBookingList)
const studentBookingListProvider = StudentBookingListFamily();

/// All bookings for a student (student home, trial cards).
///
/// Copied from [studentBookingList].
class StudentBookingListFamily extends Family<AsyncValue<List<LessonBooking>>> {
  /// All bookings for a student (student home, trial cards).
  ///
  /// Copied from [studentBookingList].
  const StudentBookingListFamily();

  /// All bookings for a student (student home, trial cards).
  ///
  /// Copied from [studentBookingList].
  StudentBookingListProvider call(String studentId) {
    return StudentBookingListProvider(studentId);
  }

  @override
  StudentBookingListProvider getProviderOverride(
    covariant StudentBookingListProvider provider,
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
  String? get name => r'studentBookingListProvider';
}

/// All bookings for a student (student home, trial cards).
///
/// Copied from [studentBookingList].
class StudentBookingListProvider
    extends AutoDisposeFutureProvider<List<LessonBooking>> {
  /// All bookings for a student (student home, trial cards).
  ///
  /// Copied from [studentBookingList].
  StudentBookingListProvider(String studentId)
    : this._internal(
        (ref) => studentBookingList(ref as StudentBookingListRef, studentId),
        from: studentBookingListProvider,
        name: r'studentBookingListProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$studentBookingListHash,
        dependencies: StudentBookingListFamily._dependencies,
        allTransitiveDependencies:
            StudentBookingListFamily._allTransitiveDependencies,
        studentId: studentId,
      );

  StudentBookingListProvider._internal(
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
    FutureOr<List<LessonBooking>> Function(StudentBookingListRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: StudentBookingListProvider._internal(
        (ref) => create(ref as StudentBookingListRef),
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
    return _StudentBookingListProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StudentBookingListProvider && other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin StudentBookingListRef
    on AutoDisposeFutureProviderRef<List<LessonBooking>> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _StudentBookingListProviderElement
    extends AutoDisposeFutureProviderElement<List<LessonBooking>>
    with StudentBookingListRef {
  _StudentBookingListProviderElement(super.provider);

  @override
  String get studentId => (origin as StudentBookingListProvider).studentId;
}

String _$teacherBookingListHash() =>
    r'7c7c23972a259f95f01653063eda1bdafcb8f896';

/// All bookings for a teacher (teacher schedule).
///
/// Copied from [teacherBookingList].
@ProviderFor(teacherBookingList)
const teacherBookingListProvider = TeacherBookingListFamily();

/// All bookings for a teacher (teacher schedule).
///
/// Copied from [teacherBookingList].
class TeacherBookingListFamily extends Family<AsyncValue<List<LessonBooking>>> {
  /// All bookings for a teacher (teacher schedule).
  ///
  /// Copied from [teacherBookingList].
  const TeacherBookingListFamily();

  /// All bookings for a teacher (teacher schedule).
  ///
  /// Copied from [teacherBookingList].
  TeacherBookingListProvider call(String teacherId) {
    return TeacherBookingListProvider(teacherId);
  }

  @override
  TeacherBookingListProvider getProviderOverride(
    covariant TeacherBookingListProvider provider,
  ) {
    return call(provider.teacherId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'teacherBookingListProvider';
}

/// All bookings for a teacher (teacher schedule).
///
/// Copied from [teacherBookingList].
class TeacherBookingListProvider
    extends AutoDisposeFutureProvider<List<LessonBooking>> {
  /// All bookings for a teacher (teacher schedule).
  ///
  /// Copied from [teacherBookingList].
  TeacherBookingListProvider(String teacherId)
    : this._internal(
        (ref) => teacherBookingList(ref as TeacherBookingListRef, teacherId),
        from: teacherBookingListProvider,
        name: r'teacherBookingListProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$teacherBookingListHash,
        dependencies: TeacherBookingListFamily._dependencies,
        allTransitiveDependencies:
            TeacherBookingListFamily._allTransitiveDependencies,
        teacherId: teacherId,
      );

  TeacherBookingListProvider._internal(
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
    FutureOr<List<LessonBooking>> Function(TeacherBookingListRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TeacherBookingListProvider._internal(
        (ref) => create(ref as TeacherBookingListRef),
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
  AutoDisposeFutureProviderElement<List<LessonBooking>> createElement() {
    return _TeacherBookingListProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TeacherBookingListProvider && other.teacherId == teacherId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, teacherId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin TeacherBookingListRef
    on AutoDisposeFutureProviderRef<List<LessonBooking>> {
  /// The parameter `teacherId` of this provider.
  String get teacherId;
}

class _TeacherBookingListProviderElement
    extends AutoDisposeFutureProviderElement<List<LessonBooking>>
    with TeacherBookingListRef {
  _TeacherBookingListProviderElement(super.provider);

  @override
  String get teacherId => (origin as TeacherBookingListProvider).teacherId;
}

String _$pendingBookingListHash() =>
    r'6183776ccc1e12a374a752cb488367f37fe97547';

/// Pending bookings awaiting teacher approval.
///
/// Copied from [pendingBookingList].
@ProviderFor(pendingBookingList)
const pendingBookingListProvider = PendingBookingListFamily();

/// Pending bookings awaiting teacher approval.
///
/// Copied from [pendingBookingList].
class PendingBookingListFamily extends Family<AsyncValue<List<LessonBooking>>> {
  /// Pending bookings awaiting teacher approval.
  ///
  /// Copied from [pendingBookingList].
  const PendingBookingListFamily();

  /// Pending bookings awaiting teacher approval.
  ///
  /// Copied from [pendingBookingList].
  PendingBookingListProvider call(String teacherId) {
    return PendingBookingListProvider(teacherId);
  }

  @override
  PendingBookingListProvider getProviderOverride(
    covariant PendingBookingListProvider provider,
  ) {
    return call(provider.teacherId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'pendingBookingListProvider';
}

/// Pending bookings awaiting teacher approval.
///
/// Copied from [pendingBookingList].
class PendingBookingListProvider
    extends AutoDisposeFutureProvider<List<LessonBooking>> {
  /// Pending bookings awaiting teacher approval.
  ///
  /// Copied from [pendingBookingList].
  PendingBookingListProvider(String teacherId)
    : this._internal(
        (ref) => pendingBookingList(ref as PendingBookingListRef, teacherId),
        from: pendingBookingListProvider,
        name: r'pendingBookingListProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$pendingBookingListHash,
        dependencies: PendingBookingListFamily._dependencies,
        allTransitiveDependencies:
            PendingBookingListFamily._allTransitiveDependencies,
        teacherId: teacherId,
      );

  PendingBookingListProvider._internal(
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
    FutureOr<List<LessonBooking>> Function(PendingBookingListRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PendingBookingListProvider._internal(
        (ref) => create(ref as PendingBookingListRef),
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
  AutoDisposeFutureProviderElement<List<LessonBooking>> createElement() {
    return _PendingBookingListProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PendingBookingListProvider && other.teacherId == teacherId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, teacherId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin PendingBookingListRef
    on AutoDisposeFutureProviderRef<List<LessonBooking>> {
  /// The parameter `teacherId` of this provider.
  String get teacherId;
}

class _PendingBookingListProviderElement
    extends AutoDisposeFutureProviderElement<List<LessonBooking>>
    with PendingBookingListRef {
  _PendingBookingListProviderElement(super.provider);

  @override
  String get teacherId => (origin as PendingBookingListProvider).teacherId;
}

String _$pendingCountHash() => r'd40b60887c65a8c94635adb06047e16515b8245a';

/// Badge count for pending bookings.
///
/// Copied from [pendingCount].
@ProviderFor(pendingCount)
const pendingCountProvider = PendingCountFamily();

/// Badge count for pending bookings.
///
/// Copied from [pendingCount].
class PendingCountFamily extends Family<AsyncValue<int>> {
  /// Badge count for pending bookings.
  ///
  /// Copied from [pendingCount].
  const PendingCountFamily();

  /// Badge count for pending bookings.
  ///
  /// Copied from [pendingCount].
  PendingCountProvider call(String teacherId) {
    return PendingCountProvider(teacherId);
  }

  @override
  PendingCountProvider getProviderOverride(
    covariant PendingCountProvider provider,
  ) {
    return call(provider.teacherId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'pendingCountProvider';
}

/// Badge count for pending bookings.
///
/// Copied from [pendingCount].
class PendingCountProvider extends AutoDisposeFutureProvider<int> {
  /// Badge count for pending bookings.
  ///
  /// Copied from [pendingCount].
  PendingCountProvider(String teacherId)
    : this._internal(
        (ref) => pendingCount(ref as PendingCountRef, teacherId),
        from: pendingCountProvider,
        name: r'pendingCountProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$pendingCountHash,
        dependencies: PendingCountFamily._dependencies,
        allTransitiveDependencies:
            PendingCountFamily._allTransitiveDependencies,
        teacherId: teacherId,
      );

  PendingCountProvider._internal(
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
    FutureOr<int> Function(PendingCountRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PendingCountProvider._internal(
        (ref) => create(ref as PendingCountRef),
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
    return _PendingCountProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PendingCountProvider && other.teacherId == teacherId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, teacherId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin PendingCountRef on AutoDisposeFutureProviderRef<int> {
  /// The parameter `teacherId` of this provider.
  String get teacherId;
}

class _PendingCountProviderElement extends AutoDisposeFutureProviderElement<int>
    with PendingCountRef {
  _PendingCountProviderElement(super.provider);

  @override
  String get teacherId => (origin as PendingCountProvider).teacherId;
}

String _$upcomingConfirmedHash() => r'942a5a86494f63b00cfcc99bd681fb23d4b09c0a';

/// Confirmed upcoming bookings.
///
/// Copied from [upcomingConfirmed].
@ProviderFor(upcomingConfirmed)
const upcomingConfirmedProvider = UpcomingConfirmedFamily();

/// Confirmed upcoming bookings.
///
/// Copied from [upcomingConfirmed].
class UpcomingConfirmedFamily extends Family<AsyncValue<List<LessonBooking>>> {
  /// Confirmed upcoming bookings.
  ///
  /// Copied from [upcomingConfirmed].
  const UpcomingConfirmedFamily();

  /// Confirmed upcoming bookings.
  ///
  /// Copied from [upcomingConfirmed].
  UpcomingConfirmedProvider call(String teacherId) {
    return UpcomingConfirmedProvider(teacherId);
  }

  @override
  UpcomingConfirmedProvider getProviderOverride(
    covariant UpcomingConfirmedProvider provider,
  ) {
    return call(provider.teacherId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'upcomingConfirmedProvider';
}

/// Confirmed upcoming bookings.
///
/// Copied from [upcomingConfirmed].
class UpcomingConfirmedProvider
    extends AutoDisposeFutureProvider<List<LessonBooking>> {
  /// Confirmed upcoming bookings.
  ///
  /// Copied from [upcomingConfirmed].
  UpcomingConfirmedProvider(String teacherId)
    : this._internal(
        (ref) => upcomingConfirmed(ref as UpcomingConfirmedRef, teacherId),
        from: upcomingConfirmedProvider,
        name: r'upcomingConfirmedProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$upcomingConfirmedHash,
        dependencies: UpcomingConfirmedFamily._dependencies,
        allTransitiveDependencies:
            UpcomingConfirmedFamily._allTransitiveDependencies,
        teacherId: teacherId,
      );

  UpcomingConfirmedProvider._internal(
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
    FutureOr<List<LessonBooking>> Function(UpcomingConfirmedRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UpcomingConfirmedProvider._internal(
        (ref) => create(ref as UpcomingConfirmedRef),
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
  AutoDisposeFutureProviderElement<List<LessonBooking>> createElement() {
    return _UpcomingConfirmedProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UpcomingConfirmedProvider && other.teacherId == teacherId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, teacherId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin UpcomingConfirmedRef
    on AutoDisposeFutureProviderRef<List<LessonBooking>> {
  /// The parameter `teacherId` of this provider.
  String get teacherId;
}

class _UpcomingConfirmedProviderElement
    extends AutoDisposeFutureProviderElement<List<LessonBooking>>
    with UpcomingConfirmedRef {
  _UpcomingConfirmedProviderElement(super.provider);

  @override
  String get teacherId => (origin as UpcomingConfirmedProvider).teacherId;
}

String _$teacherSlotsHash() => r'd9f9662c8f43df88082a122cb2a75b4c411a2ade';

/// Teacher's available time slots.
///
/// Copied from [teacherSlots].
@ProviderFor(teacherSlots)
const teacherSlotsProvider = TeacherSlotsFamily();

/// Teacher's available time slots.
///
/// Copied from [teacherSlots].
class TeacherSlotsFamily extends Family<AsyncValue<List<TimeSlot>>> {
  /// Teacher's available time slots.
  ///
  /// Copied from [teacherSlots].
  const TeacherSlotsFamily();

  /// Teacher's available time slots.
  ///
  /// Copied from [teacherSlots].
  TeacherSlotsProvider call(String teacherId) {
    return TeacherSlotsProvider(teacherId);
  }

  @override
  TeacherSlotsProvider getProviderOverride(
    covariant TeacherSlotsProvider provider,
  ) {
    return call(provider.teacherId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'teacherSlotsProvider';
}

/// Teacher's available time slots.
///
/// Copied from [teacherSlots].
class TeacherSlotsProvider extends AutoDisposeFutureProvider<List<TimeSlot>> {
  /// Teacher's available time slots.
  ///
  /// Copied from [teacherSlots].
  TeacherSlotsProvider(String teacherId)
    : this._internal(
        (ref) => teacherSlots(ref as TeacherSlotsRef, teacherId),
        from: teacherSlotsProvider,
        name: r'teacherSlotsProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$teacherSlotsHash,
        dependencies: TeacherSlotsFamily._dependencies,
        allTransitiveDependencies:
            TeacherSlotsFamily._allTransitiveDependencies,
        teacherId: teacherId,
      );

  TeacherSlotsProvider._internal(
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
    FutureOr<List<TimeSlot>> Function(TeacherSlotsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TeacherSlotsProvider._internal(
        (ref) => create(ref as TeacherSlotsRef),
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
  AutoDisposeFutureProviderElement<List<TimeSlot>> createElement() {
    return _TeacherSlotsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TeacherSlotsProvider && other.teacherId == teacherId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, teacherId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin TeacherSlotsRef on AutoDisposeFutureProviderRef<List<TimeSlot>> {
  /// The parameter `teacherId` of this provider.
  String get teacherId;
}

class _TeacherSlotsProviderElement
    extends AutoDisposeFutureProviderElement<List<TimeSlot>>
    with TeacherSlotsRef {
  _TeacherSlotsProviderElement(super.provider);

  @override
  String get teacherId => (origin as TeacherSlotsProvider).teacherId;
}

String _$bookingFacadeHash() => r'37f832ad07a0dec1a2e99ffb0329073c905cf708';

/// Unified mutation API for all booking operations.
///
/// Methods:
/// - [requestTrial] — student requests trial lesson
/// - [approveTrial] — teacher approves trial
/// - [requestRegular] — student requests regular lessons
/// - [registerRegular] — teacher directly registers regular
/// - [markUnavailable] — teacher declines with reason
/// - [cancel] — either party cancels
/// - [complete] — teacher marks lesson done
/// - [update] — generic update
/// - [delete] — hard delete
///
/// Copied from [BookingFacade].
@ProviderFor(BookingFacade)
final bookingFacadeProvider =
    AsyncNotifierProvider<BookingFacade, List<LessonBooking>>.internal(
      BookingFacade.new,
      name: r'bookingFacadeProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$bookingFacadeHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$BookingFacade = AsyncNotifier<List<LessonBooking>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
