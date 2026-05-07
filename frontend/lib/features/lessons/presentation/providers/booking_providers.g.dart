// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$allBookingsHash() => r'eadf3757fa279027a55bb41508adda2f977e126f';

/// All bookings provider
///
/// Copied from [allBookings].
@ProviderFor(allBookings)
final allBookingsProvider = FutureProvider<List<LessonBooking>>.internal(
  allBookings,
  name: r'allBookingsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$allBookingsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AllBookingsRef = FutureProviderRef<List<LessonBooking>>;
String _$bookingHash() => r'2e0f239717774b3d294b89b4ce84436d34264c68';

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

/// Single booking provider
///
/// Copied from [booking].
@ProviderFor(booking)
const bookingProvider = BookingFamily();

/// Single booking provider
///
/// Copied from [booking].
class BookingFamily extends Family<AsyncValue<LessonBooking?>> {
  /// Single booking provider
  ///
  /// Copied from [booking].
  const BookingFamily();

  /// Single booking provider
  ///
  /// Copied from [booking].
  BookingProvider call(String bookingId) {
    return BookingProvider(bookingId);
  }

  @override
  BookingProvider getProviderOverride(covariant BookingProvider provider) {
    return call(provider.bookingId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'bookingProvider';
}

/// Single booking provider
///
/// Copied from [booking].
class BookingProvider extends FutureProvider<LessonBooking?> {
  /// Single booking provider
  ///
  /// Copied from [booking].
  BookingProvider(String bookingId)
    : this._internal(
        (ref) => booking(ref as BookingRef, bookingId),
        from: bookingProvider,
        name: r'bookingProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$bookingHash,
        dependencies: BookingFamily._dependencies,
        allTransitiveDependencies: BookingFamily._allTransitiveDependencies,
        bookingId: bookingId,
      );

  BookingProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.bookingId,
  }) : super.internal();

  final String bookingId;

  @override
  Override overrideWith(
    FutureOr<LessonBooking?> Function(BookingRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: BookingProvider._internal(
        (ref) => create(ref as BookingRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        bookingId: bookingId,
      ),
    );
  }

  @override
  FutureProviderElement<LessonBooking?> createElement() {
    return _BookingProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BookingProvider && other.bookingId == bookingId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, bookingId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin BookingRef on FutureProviderRef<LessonBooking?> {
  /// The parameter `bookingId` of this provider.
  String get bookingId;
}

class _BookingProviderElement extends FutureProviderElement<LessonBooking?>
    with BookingRef {
  _BookingProviderElement(super.provider);

  @override
  String get bookingId => (origin as BookingProvider).bookingId;
}

String _$teacherBookingsHash() => r'47b65da9c096b5c964cf8c4f54986b03260ed828';

/// Bookings by teacher provider
///
/// Copied from [teacherBookings].
@ProviderFor(teacherBookings)
const teacherBookingsProvider = TeacherBookingsFamily();

/// Bookings by teacher provider
///
/// Copied from [teacherBookings].
class TeacherBookingsFamily extends Family<AsyncValue<List<LessonBooking>>> {
  /// Bookings by teacher provider
  ///
  /// Copied from [teacherBookings].
  const TeacherBookingsFamily();

  /// Bookings by teacher provider
  ///
  /// Copied from [teacherBookings].
  TeacherBookingsProvider call(String teacherId) {
    return TeacherBookingsProvider(teacherId);
  }

  @override
  TeacherBookingsProvider getProviderOverride(
    covariant TeacherBookingsProvider provider,
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
  String? get name => r'teacherBookingsProvider';
}

/// Bookings by teacher provider
///
/// Copied from [teacherBookings].
class TeacherBookingsProvider extends FutureProvider<List<LessonBooking>> {
  /// Bookings by teacher provider
  ///
  /// Copied from [teacherBookings].
  TeacherBookingsProvider(String teacherId)
    : this._internal(
        (ref) => teacherBookings(ref as TeacherBookingsRef, teacherId),
        from: teacherBookingsProvider,
        name: r'teacherBookingsProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$teacherBookingsHash,
        dependencies: TeacherBookingsFamily._dependencies,
        allTransitiveDependencies:
            TeacherBookingsFamily._allTransitiveDependencies,
        teacherId: teacherId,
      );

  TeacherBookingsProvider._internal(
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
    FutureOr<List<LessonBooking>> Function(TeacherBookingsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TeacherBookingsProvider._internal(
        (ref) => create(ref as TeacherBookingsRef),
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
  FutureProviderElement<List<LessonBooking>> createElement() {
    return _TeacherBookingsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TeacherBookingsProvider && other.teacherId == teacherId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, teacherId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin TeacherBookingsRef on FutureProviderRef<List<LessonBooking>> {
  /// The parameter `teacherId` of this provider.
  String get teacherId;
}

class _TeacherBookingsProviderElement
    extends FutureProviderElement<List<LessonBooking>>
    with TeacherBookingsRef {
  _TeacherBookingsProviderElement(super.provider);

  @override
  String get teacherId => (origin as TeacherBookingsProvider).teacherId;
}

String _$studentBookingsHash() => r'c0c12c9f0793e6722b54ab7d4609fde620703e9b';

/// Bookings by student provider
///
/// Copied from [studentBookings].
@ProviderFor(studentBookings)
const studentBookingsProvider = StudentBookingsFamily();

/// Bookings by student provider
///
/// Copied from [studentBookings].
class StudentBookingsFamily extends Family<AsyncValue<List<LessonBooking>>> {
  /// Bookings by student provider
  ///
  /// Copied from [studentBookings].
  const StudentBookingsFamily();

  /// Bookings by student provider
  ///
  /// Copied from [studentBookings].
  StudentBookingsProvider call(String studentId) {
    return StudentBookingsProvider(studentId);
  }

  @override
  StudentBookingsProvider getProviderOverride(
    covariant StudentBookingsProvider provider,
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
  String? get name => r'studentBookingsProvider';
}

/// Bookings by student provider
///
/// Copied from [studentBookings].
class StudentBookingsProvider extends FutureProvider<List<LessonBooking>> {
  /// Bookings by student provider
  ///
  /// Copied from [studentBookings].
  StudentBookingsProvider(String studentId)
    : this._internal(
        (ref) => studentBookings(ref as StudentBookingsRef, studentId),
        from: studentBookingsProvider,
        name: r'studentBookingsProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$studentBookingsHash,
        dependencies: StudentBookingsFamily._dependencies,
        allTransitiveDependencies:
            StudentBookingsFamily._allTransitiveDependencies,
        studentId: studentId,
      );

  StudentBookingsProvider._internal(
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
    FutureOr<List<LessonBooking>> Function(StudentBookingsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: StudentBookingsProvider._internal(
        (ref) => create(ref as StudentBookingsRef),
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
  FutureProviderElement<List<LessonBooking>> createElement() {
    return _StudentBookingsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StudentBookingsProvider && other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin StudentBookingsRef on FutureProviderRef<List<LessonBooking>> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _StudentBookingsProviderElement
    extends FutureProviderElement<List<LessonBooking>>
    with StudentBookingsRef {
  _StudentBookingsProviderElement(super.provider);

  @override
  String get studentId => (origin as StudentBookingsProvider).studentId;
}

String _$bookingsByStatusHash() => r'087810165c57cfb2ec188dc4141db90fd81cc17a';

/// Bookings by status provider
///
/// Copied from [bookingsByStatus].
@ProviderFor(bookingsByStatus)
const bookingsByStatusProvider = BookingsByStatusFamily();

/// Bookings by status provider
///
/// Copied from [bookingsByStatus].
class BookingsByStatusFamily extends Family<AsyncValue<List<LessonBooking>>> {
  /// Bookings by status provider
  ///
  /// Copied from [bookingsByStatus].
  const BookingsByStatusFamily();

  /// Bookings by status provider
  ///
  /// Copied from [bookingsByStatus].
  BookingsByStatusProvider call(BookingStatus status) {
    return BookingsByStatusProvider(status);
  }

  @override
  BookingsByStatusProvider getProviderOverride(
    covariant BookingsByStatusProvider provider,
  ) {
    return call(provider.status);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'bookingsByStatusProvider';
}

/// Bookings by status provider
///
/// Copied from [bookingsByStatus].
class BookingsByStatusProvider extends FutureProvider<List<LessonBooking>> {
  /// Bookings by status provider
  ///
  /// Copied from [bookingsByStatus].
  BookingsByStatusProvider(BookingStatus status)
    : this._internal(
        (ref) => bookingsByStatus(ref as BookingsByStatusRef, status),
        from: bookingsByStatusProvider,
        name: r'bookingsByStatusProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$bookingsByStatusHash,
        dependencies: BookingsByStatusFamily._dependencies,
        allTransitiveDependencies:
            BookingsByStatusFamily._allTransitiveDependencies,
        status: status,
      );

  BookingsByStatusProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.status,
  }) : super.internal();

  final BookingStatus status;

  @override
  Override overrideWith(
    FutureOr<List<LessonBooking>> Function(BookingsByStatusRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: BookingsByStatusProvider._internal(
        (ref) => create(ref as BookingsByStatusRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        status: status,
      ),
    );
  }

  @override
  FutureProviderElement<List<LessonBooking>> createElement() {
    return _BookingsByStatusProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BookingsByStatusProvider && other.status == status;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, status.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin BookingsByStatusRef on FutureProviderRef<List<LessonBooking>> {
  /// The parameter `status` of this provider.
  BookingStatus get status;
}

class _BookingsByStatusProviderElement
    extends FutureProviderElement<List<LessonBooking>>
    with BookingsByStatusRef {
  _BookingsByStatusProviderElement(super.provider);

  @override
  BookingStatus get status => (origin as BookingsByStatusProvider).status;
}

String _$pendingBookingsHash() => r'f16684abd84e7fb481264358190799267c116212';

/// Pending bookings for teacher provider
///
/// Copied from [pendingBookings].
@ProviderFor(pendingBookings)
const pendingBookingsProvider = PendingBookingsFamily();

/// Pending bookings for teacher provider
///
/// Copied from [pendingBookings].
class PendingBookingsFamily extends Family<AsyncValue<List<LessonBooking>>> {
  /// Pending bookings for teacher provider
  ///
  /// Copied from [pendingBookings].
  const PendingBookingsFamily();

  /// Pending bookings for teacher provider
  ///
  /// Copied from [pendingBookings].
  PendingBookingsProvider call(String teacherId) {
    return PendingBookingsProvider(teacherId);
  }

  @override
  PendingBookingsProvider getProviderOverride(
    covariant PendingBookingsProvider provider,
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
  String? get name => r'pendingBookingsProvider';
}

/// Pending bookings for teacher provider
///
/// Copied from [pendingBookings].
class PendingBookingsProvider extends FutureProvider<List<LessonBooking>> {
  /// Pending bookings for teacher provider
  ///
  /// Copied from [pendingBookings].
  PendingBookingsProvider(String teacherId)
    : this._internal(
        (ref) => pendingBookings(ref as PendingBookingsRef, teacherId),
        from: pendingBookingsProvider,
        name: r'pendingBookingsProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$pendingBookingsHash,
        dependencies: PendingBookingsFamily._dependencies,
        allTransitiveDependencies:
            PendingBookingsFamily._allTransitiveDependencies,
        teacherId: teacherId,
      );

  PendingBookingsProvider._internal(
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
    FutureOr<List<LessonBooking>> Function(PendingBookingsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PendingBookingsProvider._internal(
        (ref) => create(ref as PendingBookingsRef),
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
  FutureProviderElement<List<LessonBooking>> createElement() {
    return _PendingBookingsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PendingBookingsProvider && other.teacherId == teacherId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, teacherId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin PendingBookingsRef on FutureProviderRef<List<LessonBooking>> {
  /// The parameter `teacherId` of this provider.
  String get teacherId;
}

class _PendingBookingsProviderElement
    extends FutureProviderElement<List<LessonBooking>>
    with PendingBookingsRef {
  _PendingBookingsProviderElement(super.provider);

  @override
  String get teacherId => (origin as PendingBookingsProvider).teacherId;
}

String _$pendingBookingsCountHash() =>
    r'4f88f8192059f17e124ba96c6513fa13acf38940';

/// Pending bookings count provider (for badge)
///
/// Copied from [pendingBookingsCount].
@ProviderFor(pendingBookingsCount)
const pendingBookingsCountProvider = PendingBookingsCountFamily();

/// Pending bookings count provider (for badge)
///
/// Copied from [pendingBookingsCount].
class PendingBookingsCountFamily extends Family<AsyncValue<int>> {
  /// Pending bookings count provider (for badge)
  ///
  /// Copied from [pendingBookingsCount].
  const PendingBookingsCountFamily();

  /// Pending bookings count provider (for badge)
  ///
  /// Copied from [pendingBookingsCount].
  PendingBookingsCountProvider call(String teacherId) {
    return PendingBookingsCountProvider(teacherId);
  }

  @override
  PendingBookingsCountProvider getProviderOverride(
    covariant PendingBookingsCountProvider provider,
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
  String? get name => r'pendingBookingsCountProvider';
}

/// Pending bookings count provider (for badge)
///
/// Copied from [pendingBookingsCount].
class PendingBookingsCountProvider extends FutureProvider<int> {
  /// Pending bookings count provider (for badge)
  ///
  /// Copied from [pendingBookingsCount].
  PendingBookingsCountProvider(String teacherId)
    : this._internal(
        (ref) =>
            pendingBookingsCount(ref as PendingBookingsCountRef, teacherId),
        from: pendingBookingsCountProvider,
        name: r'pendingBookingsCountProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$pendingBookingsCountHash,
        dependencies: PendingBookingsCountFamily._dependencies,
        allTransitiveDependencies:
            PendingBookingsCountFamily._allTransitiveDependencies,
        teacherId: teacherId,
      );

  PendingBookingsCountProvider._internal(
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
    FutureOr<int> Function(PendingBookingsCountRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PendingBookingsCountProvider._internal(
        (ref) => create(ref as PendingBookingsCountRef),
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
  FutureProviderElement<int> createElement() {
    return _PendingBookingsCountProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PendingBookingsCountProvider &&
        other.teacherId == teacherId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, teacherId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin PendingBookingsCountRef on FutureProviderRef<int> {
  /// The parameter `teacherId` of this provider.
  String get teacherId;
}

class _PendingBookingsCountProviderElement extends FutureProviderElement<int>
    with PendingBookingsCountRef {
  _PendingBookingsCountProviderElement(super.provider);

  @override
  String get teacherId => (origin as PendingBookingsCountProvider).teacherId;
}

String _$upcomingBookingsHash() => r'76b3a551486f1068d0ed24a6bf0961f18aa4fdaa';

/// Upcoming bookings provider (confirmed, future dates)
///
/// Copied from [upcomingBookings].
@ProviderFor(upcomingBookings)
const upcomingBookingsProvider = UpcomingBookingsFamily();

/// Upcoming bookings provider (confirmed, future dates)
///
/// Copied from [upcomingBookings].
class UpcomingBookingsFamily extends Family<AsyncValue<List<LessonBooking>>> {
  /// Upcoming bookings provider (confirmed, future dates)
  ///
  /// Copied from [upcomingBookings].
  const UpcomingBookingsFamily();

  /// Upcoming bookings provider (confirmed, future dates)
  ///
  /// Copied from [upcomingBookings].
  UpcomingBookingsProvider call(String teacherId) {
    return UpcomingBookingsProvider(teacherId);
  }

  @override
  UpcomingBookingsProvider getProviderOverride(
    covariant UpcomingBookingsProvider provider,
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
  String? get name => r'upcomingBookingsProvider';
}

/// Upcoming bookings provider (confirmed, future dates)
///
/// Copied from [upcomingBookings].
class UpcomingBookingsProvider extends FutureProvider<List<LessonBooking>> {
  /// Upcoming bookings provider (confirmed, future dates)
  ///
  /// Copied from [upcomingBookings].
  UpcomingBookingsProvider(String teacherId)
    : this._internal(
        (ref) => upcomingBookings(ref as UpcomingBookingsRef, teacherId),
        from: upcomingBookingsProvider,
        name: r'upcomingBookingsProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$upcomingBookingsHash,
        dependencies: UpcomingBookingsFamily._dependencies,
        allTransitiveDependencies:
            UpcomingBookingsFamily._allTransitiveDependencies,
        teacherId: teacherId,
      );

  UpcomingBookingsProvider._internal(
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
    FutureOr<List<LessonBooking>> Function(UpcomingBookingsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UpcomingBookingsProvider._internal(
        (ref) => create(ref as UpcomingBookingsRef),
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
  FutureProviderElement<List<LessonBooking>> createElement() {
    return _UpcomingBookingsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UpcomingBookingsProvider && other.teacherId == teacherId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, teacherId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin UpcomingBookingsRef on FutureProviderRef<List<LessonBooking>> {
  /// The parameter `teacherId` of this provider.
  String get teacherId;
}

class _UpcomingBookingsProviderElement
    extends FutureProviderElement<List<LessonBooking>>
    with UpcomingBookingsRef {
  _UpcomingBookingsProviderElement(super.provider);

  @override
  String get teacherId => (origin as UpcomingBookingsProvider).teacherId;
}

String _$teacherAvailabilityHash() =>
    r'51999456d8d5e37b1b37d8351bb692765d91c4dc';

/// Teacher availability provider
///
/// Copied from [teacherAvailability].
@ProviderFor(teacherAvailability)
const teacherAvailabilityProvider = TeacherAvailabilityFamily();

/// Teacher availability provider
///
/// Copied from [teacherAvailability].
class TeacherAvailabilityFamily extends Family<AsyncValue<List<TimeSlot>>> {
  /// Teacher availability provider
  ///
  /// Copied from [teacherAvailability].
  const TeacherAvailabilityFamily();

  /// Teacher availability provider
  ///
  /// Copied from [teacherAvailability].
  TeacherAvailabilityProvider call(String teacherId) {
    return TeacherAvailabilityProvider(teacherId);
  }

  @override
  TeacherAvailabilityProvider getProviderOverride(
    covariant TeacherAvailabilityProvider provider,
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
  String? get name => r'teacherAvailabilityProvider';
}

/// Teacher availability provider
///
/// Copied from [teacherAvailability].
class TeacherAvailabilityProvider extends FutureProvider<List<TimeSlot>> {
  /// Teacher availability provider
  ///
  /// Copied from [teacherAvailability].
  TeacherAvailabilityProvider(String teacherId)
    : this._internal(
        (ref) => teacherAvailability(ref as TeacherAvailabilityRef, teacherId),
        from: teacherAvailabilityProvider,
        name: r'teacherAvailabilityProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$teacherAvailabilityHash,
        dependencies: TeacherAvailabilityFamily._dependencies,
        allTransitiveDependencies:
            TeacherAvailabilityFamily._allTransitiveDependencies,
        teacherId: teacherId,
      );

  TeacherAvailabilityProvider._internal(
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
    FutureOr<List<TimeSlot>> Function(TeacherAvailabilityRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TeacherAvailabilityProvider._internal(
        (ref) => create(ref as TeacherAvailabilityRef),
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
  FutureProviderElement<List<TimeSlot>> createElement() {
    return _TeacherAvailabilityProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TeacherAvailabilityProvider && other.teacherId == teacherId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, teacherId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin TeacherAvailabilityRef on FutureProviderRef<List<TimeSlot>> {
  /// The parameter `teacherId` of this provider.
  String get teacherId;
}

class _TeacherAvailabilityProviderElement
    extends FutureProviderElement<List<TimeSlot>>
    with TeacherAvailabilityRef {
  _TeacherAvailabilityProviderElement(super.provider);

  @override
  String get teacherId => (origin as TeacherAvailabilityProvider).teacherId;
}

String _$availableDatesHash() => r'80d2797320c99c79ab764aa134e3a842990cbb27';

/// Available dates provider
///
/// Copied from [availableDates].
@ProviderFor(availableDates)
const availableDatesProvider = AvailableDatesFamily();

/// Available dates provider
///
/// Copied from [availableDates].
class AvailableDatesFamily extends Family<AsyncValue<List<DateTime>>> {
  /// Available dates provider
  ///
  /// Copied from [availableDates].
  const AvailableDatesFamily();

  /// Available dates provider
  ///
  /// Copied from [availableDates].
  AvailableDatesProvider call(
    ({DateTime from, String teacherId, DateTime to}) params,
  ) {
    return AvailableDatesProvider(params);
  }

  @override
  AvailableDatesProvider getProviderOverride(
    covariant AvailableDatesProvider provider,
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
  String? get name => r'availableDatesProvider';
}

/// Available dates provider
///
/// Copied from [availableDates].
class AvailableDatesProvider extends FutureProvider<List<DateTime>> {
  /// Available dates provider
  ///
  /// Copied from [availableDates].
  AvailableDatesProvider(
    ({DateTime from, String teacherId, DateTime to}) params,
  ) : this._internal(
        (ref) => availableDates(ref as AvailableDatesRef, params),
        from: availableDatesProvider,
        name: r'availableDatesProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$availableDatesHash,
        dependencies: AvailableDatesFamily._dependencies,
        allTransitiveDependencies:
            AvailableDatesFamily._allTransitiveDependencies,
        params: params,
      );

  AvailableDatesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.params,
  }) : super.internal();

  final ({DateTime from, String teacherId, DateTime to}) params;

  @override
  Override overrideWith(
    FutureOr<List<DateTime>> Function(AvailableDatesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: AvailableDatesProvider._internal(
        (ref) => create(ref as AvailableDatesRef),
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
  FutureProviderElement<List<DateTime>> createElement() {
    return _AvailableDatesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AvailableDatesProvider && other.params == params;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, params.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin AvailableDatesRef on FutureProviderRef<List<DateTime>> {
  /// The parameter `params` of this provider.
  ({DateTime from, String teacherId, DateTime to}) get params;
}

class _AvailableDatesProviderElement
    extends FutureProviderElement<List<DateTime>>
    with AvailableDatesRef {
  _AvailableDatesProviderElement(super.provider);

  @override
  ({DateTime from, String teacherId, DateTime to}) get params =>
      (origin as AvailableDatesProvider).params;
}

String _$bookingAvailableTimeSlotsHash() =>
    r'5899e0cc0ea73a3309996c8c3909eea8cd4f9025';

/// Available time slots for booking (by date)
///
/// Copied from [bookingAvailableTimeSlots].
@ProviderFor(bookingAvailableTimeSlots)
const bookingAvailableTimeSlotsProvider = BookingAvailableTimeSlotsFamily();

/// Available time slots for booking (by date)
///
/// Copied from [bookingAvailableTimeSlots].
class BookingAvailableTimeSlotsFamily
    extends Family<AsyncValue<List<TimeSlot>>> {
  /// Available time slots for booking (by date)
  ///
  /// Copied from [bookingAvailableTimeSlots].
  const BookingAvailableTimeSlotsFamily();

  /// Available time slots for booking (by date)
  ///
  /// Copied from [bookingAvailableTimeSlots].
  BookingAvailableTimeSlotsProvider call(
    ({DateTime date, String teacherId}) params,
  ) {
    return BookingAvailableTimeSlotsProvider(params);
  }

  @override
  BookingAvailableTimeSlotsProvider getProviderOverride(
    covariant BookingAvailableTimeSlotsProvider provider,
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
  String? get name => r'bookingAvailableTimeSlotsProvider';
}

/// Available time slots for booking (by date)
///
/// Copied from [bookingAvailableTimeSlots].
class BookingAvailableTimeSlotsProvider extends FutureProvider<List<TimeSlot>> {
  /// Available time slots for booking (by date)
  ///
  /// Copied from [bookingAvailableTimeSlots].
  BookingAvailableTimeSlotsProvider(({DateTime date, String teacherId}) params)
    : this._internal(
        (ref) => bookingAvailableTimeSlots(
          ref as BookingAvailableTimeSlotsRef,
          params,
        ),
        from: bookingAvailableTimeSlotsProvider,
        name: r'bookingAvailableTimeSlotsProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$bookingAvailableTimeSlotsHash,
        dependencies: BookingAvailableTimeSlotsFamily._dependencies,
        allTransitiveDependencies:
            BookingAvailableTimeSlotsFamily._allTransitiveDependencies,
        params: params,
      );

  BookingAvailableTimeSlotsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.params,
  }) : super.internal();

  final ({DateTime date, String teacherId}) params;

  @override
  Override overrideWith(
    FutureOr<List<TimeSlot>> Function(BookingAvailableTimeSlotsRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: BookingAvailableTimeSlotsProvider._internal(
        (ref) => create(ref as BookingAvailableTimeSlotsRef),
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
  FutureProviderElement<List<TimeSlot>> createElement() {
    return _BookingAvailableTimeSlotsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BookingAvailableTimeSlotsProvider && other.params == params;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, params.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin BookingAvailableTimeSlotsRef on FutureProviderRef<List<TimeSlot>> {
  /// The parameter `params` of this provider.
  ({DateTime date, String teacherId}) get params;
}

class _BookingAvailableTimeSlotsProviderElement
    extends FutureProviderElement<List<TimeSlot>>
    with BookingAvailableTimeSlotsRef {
  _BookingAvailableTimeSlotsProviderElement(super.provider);

  @override
  ({DateTime date, String teacherId}) get params =>
      (origin as BookingAvailableTimeSlotsProvider).params;
}

String _$bookingsNotifierHash() => r'c6d160d4eff4cde69eaedd22520a3cc578c33c41';

/// Bookings notifier for CRUD operations
///
/// Copied from [BookingsNotifier].
@ProviderFor(BookingsNotifier)
final bookingsNotifierProvider =
    AsyncNotifierProvider<BookingsNotifier, List<LessonBooking>>.internal(
      BookingsNotifier.new,
      name: r'bookingsNotifierProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$bookingsNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$BookingsNotifier = AsyncNotifier<List<LessonBooking>>;
String _$selectedBookingDateHash() =>
    r'9fe743ea8c2683afdb9ec076aeff22aae2042406';

/// Selected date for booking
///
/// Copied from [SelectedBookingDate].
@ProviderFor(SelectedBookingDate)
final selectedBookingDateProvider =
    NotifierProvider<SelectedBookingDate, DateTime?>.internal(
      SelectedBookingDate.new,
      name: r'selectedBookingDateProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$selectedBookingDateHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SelectedBookingDate = Notifier<DateTime?>;
String _$selectedBookingTimeSlotHash() =>
    r'fb4a3c138fb8ec3806b863c3371578573288c9c0';

/// Selected time slot for booking
///
/// Copied from [SelectedBookingTimeSlot].
@ProviderFor(SelectedBookingTimeSlot)
final selectedBookingTimeSlotProvider =
    NotifierProvider<SelectedBookingTimeSlot, TimeSlot?>.internal(
      SelectedBookingTimeSlot.new,
      name: r'selectedBookingTimeSlotProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$selectedBookingTimeSlotHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SelectedBookingTimeSlot = Notifier<TimeSlot?>;
String _$selectedScheduleTypeHash() =>
    r'a031780d390422999ca737b33e3af9b035f478a1';

/// Selected schedule type for regular lesson
///
/// Copied from [SelectedScheduleType].
@ProviderFor(SelectedScheduleType)
final selectedScheduleTypeProvider =
    NotifierProvider<SelectedScheduleType, ScheduleType>.internal(
      SelectedScheduleType.new,
      name: r'selectedScheduleTypeProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$selectedScheduleTypeHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SelectedScheduleType = Notifier<ScheduleType>;
String _$trialLessonFormHash() => r'49d53a5a94f19aa7b32d251973c417a35f958e5a';

/// See also [TrialLessonForm].
@ProviderFor(TrialLessonForm)
final trialLessonFormProvider =
    NotifierProvider<TrialLessonForm, TrialLessonFormState>.internal(
      TrialLessonForm.new,
      name: r'trialLessonFormProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$trialLessonFormHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$TrialLessonForm = Notifier<TrialLessonFormState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
