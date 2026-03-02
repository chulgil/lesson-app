// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_class_booking_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$scheduleBookingsHash() => r'a5f707ddb0d514fcd71a44ac27e623c030b8c6de';

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

/// Get all bookings for a schedule
///
/// Copied from [scheduleBookings].
@ProviderFor(scheduleBookings)
const scheduleBookingsProvider = ScheduleBookingsFamily();

/// Get all bookings for a schedule
///
/// Copied from [scheduleBookings].
class ScheduleBookingsFamily
    extends Family<AsyncValue<List<GroupClassBooking>>> {
  /// Get all bookings for a schedule
  ///
  /// Copied from [scheduleBookings].
  const ScheduleBookingsFamily();

  /// Get all bookings for a schedule
  ///
  /// Copied from [scheduleBookings].
  ScheduleBookingsProvider call(
    String scheduleId,
  ) {
    return ScheduleBookingsProvider(
      scheduleId,
    );
  }

  @override
  ScheduleBookingsProvider getProviderOverride(
    covariant ScheduleBookingsProvider provider,
  ) {
    return call(
      provider.scheduleId,
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
  String? get name => r'scheduleBookingsProvider';
}

/// Get all bookings for a schedule
///
/// Copied from [scheduleBookings].
class ScheduleBookingsProvider
    extends AutoDisposeFutureProvider<List<GroupClassBooking>> {
  /// Get all bookings for a schedule
  ///
  /// Copied from [scheduleBookings].
  ScheduleBookingsProvider(
    String scheduleId,
  ) : this._internal(
          (ref) => scheduleBookings(
            ref as ScheduleBookingsRef,
            scheduleId,
          ),
          from: scheduleBookingsProvider,
          name: r'scheduleBookingsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$scheduleBookingsHash,
          dependencies: ScheduleBookingsFamily._dependencies,
          allTransitiveDependencies:
              ScheduleBookingsFamily._allTransitiveDependencies,
          scheduleId: scheduleId,
        );

  ScheduleBookingsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.scheduleId,
  }) : super.internal();

  final String scheduleId;

  @override
  Override overrideWith(
    FutureOr<List<GroupClassBooking>> Function(ScheduleBookingsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ScheduleBookingsProvider._internal(
        (ref) => create(ref as ScheduleBookingsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        scheduleId: scheduleId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<GroupClassBooking>> createElement() {
    return _ScheduleBookingsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ScheduleBookingsProvider && other.scheduleId == scheduleId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, scheduleId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ScheduleBookingsRef
    on AutoDisposeFutureProviderRef<List<GroupClassBooking>> {
  /// The parameter `scheduleId` of this provider.
  String get scheduleId;
}

class _ScheduleBookingsProviderElement
    extends AutoDisposeFutureProviderElement<List<GroupClassBooking>>
    with ScheduleBookingsRef {
  _ScheduleBookingsProviderElement(super.provider);

  @override
  String get scheduleId => (origin as ScheduleBookingsProvider).scheduleId;
}

String _$scheduleWaitlistHash() => r'bda75b833e766f296f2edc6a2731c01c136d97db';

/// Get waitlist for a schedule
///
/// Copied from [scheduleWaitlist].
@ProviderFor(scheduleWaitlist)
const scheduleWaitlistProvider = ScheduleWaitlistFamily();

/// Get waitlist for a schedule
///
/// Copied from [scheduleWaitlist].
class ScheduleWaitlistFamily
    extends Family<AsyncValue<List<GroupClassBooking>>> {
  /// Get waitlist for a schedule
  ///
  /// Copied from [scheduleWaitlist].
  const ScheduleWaitlistFamily();

  /// Get waitlist for a schedule
  ///
  /// Copied from [scheduleWaitlist].
  ScheduleWaitlistProvider call(
    String scheduleId,
  ) {
    return ScheduleWaitlistProvider(
      scheduleId,
    );
  }

  @override
  ScheduleWaitlistProvider getProviderOverride(
    covariant ScheduleWaitlistProvider provider,
  ) {
    return call(
      provider.scheduleId,
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
  String? get name => r'scheduleWaitlistProvider';
}

/// Get waitlist for a schedule
///
/// Copied from [scheduleWaitlist].
class ScheduleWaitlistProvider
    extends AutoDisposeFutureProvider<List<GroupClassBooking>> {
  /// Get waitlist for a schedule
  ///
  /// Copied from [scheduleWaitlist].
  ScheduleWaitlistProvider(
    String scheduleId,
  ) : this._internal(
          (ref) => scheduleWaitlist(
            ref as ScheduleWaitlistRef,
            scheduleId,
          ),
          from: scheduleWaitlistProvider,
          name: r'scheduleWaitlistProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$scheduleWaitlistHash,
          dependencies: ScheduleWaitlistFamily._dependencies,
          allTransitiveDependencies:
              ScheduleWaitlistFamily._allTransitiveDependencies,
          scheduleId: scheduleId,
        );

  ScheduleWaitlistProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.scheduleId,
  }) : super.internal();

  final String scheduleId;

  @override
  Override overrideWith(
    FutureOr<List<GroupClassBooking>> Function(ScheduleWaitlistRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ScheduleWaitlistProvider._internal(
        (ref) => create(ref as ScheduleWaitlistRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        scheduleId: scheduleId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<GroupClassBooking>> createElement() {
    return _ScheduleWaitlistProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ScheduleWaitlistProvider && other.scheduleId == scheduleId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, scheduleId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ScheduleWaitlistRef
    on AutoDisposeFutureProviderRef<List<GroupClassBooking>> {
  /// The parameter `scheduleId` of this provider.
  String get scheduleId;
}

class _ScheduleWaitlistProviderElement
    extends AutoDisposeFutureProviderElement<List<GroupClassBooking>>
    with ScheduleWaitlistRef {
  _ScheduleWaitlistProviderElement(super.provider);

  @override
  String get scheduleId => (origin as ScheduleWaitlistProvider).scheduleId;
}

String _$scheduleConfirmedCountHash() =>
    r'b0874755852a40c6892ca8d44b185a69ef225952';

/// Get confirmed count for a schedule
///
/// Copied from [scheduleConfirmedCount].
@ProviderFor(scheduleConfirmedCount)
const scheduleConfirmedCountProvider = ScheduleConfirmedCountFamily();

/// Get confirmed count for a schedule
///
/// Copied from [scheduleConfirmedCount].
class ScheduleConfirmedCountFamily extends Family<AsyncValue<int>> {
  /// Get confirmed count for a schedule
  ///
  /// Copied from [scheduleConfirmedCount].
  const ScheduleConfirmedCountFamily();

  /// Get confirmed count for a schedule
  ///
  /// Copied from [scheduleConfirmedCount].
  ScheduleConfirmedCountProvider call(
    String scheduleId,
  ) {
    return ScheduleConfirmedCountProvider(
      scheduleId,
    );
  }

  @override
  ScheduleConfirmedCountProvider getProviderOverride(
    covariant ScheduleConfirmedCountProvider provider,
  ) {
    return call(
      provider.scheduleId,
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
  String? get name => r'scheduleConfirmedCountProvider';
}

/// Get confirmed count for a schedule
///
/// Copied from [scheduleConfirmedCount].
class ScheduleConfirmedCountProvider extends AutoDisposeFutureProvider<int> {
  /// Get confirmed count for a schedule
  ///
  /// Copied from [scheduleConfirmedCount].
  ScheduleConfirmedCountProvider(
    String scheduleId,
  ) : this._internal(
          (ref) => scheduleConfirmedCount(
            ref as ScheduleConfirmedCountRef,
            scheduleId,
          ),
          from: scheduleConfirmedCountProvider,
          name: r'scheduleConfirmedCountProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$scheduleConfirmedCountHash,
          dependencies: ScheduleConfirmedCountFamily._dependencies,
          allTransitiveDependencies:
              ScheduleConfirmedCountFamily._allTransitiveDependencies,
          scheduleId: scheduleId,
        );

  ScheduleConfirmedCountProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.scheduleId,
  }) : super.internal();

  final String scheduleId;

  @override
  Override overrideWith(
    FutureOr<int> Function(ScheduleConfirmedCountRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ScheduleConfirmedCountProvider._internal(
        (ref) => create(ref as ScheduleConfirmedCountRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        scheduleId: scheduleId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<int> createElement() {
    return _ScheduleConfirmedCountProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ScheduleConfirmedCountProvider &&
        other.scheduleId == scheduleId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, scheduleId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ScheduleConfirmedCountRef on AutoDisposeFutureProviderRef<int> {
  /// The parameter `scheduleId` of this provider.
  String get scheduleId;
}

class _ScheduleConfirmedCountProviderElement
    extends AutoDisposeFutureProviderElement<int>
    with ScheduleConfirmedCountRef {
  _ScheduleConfirmedCountProviderElement(super.provider);

  @override
  String get scheduleId =>
      (origin as ScheduleConfirmedCountProvider).scheduleId;
}

String _$scheduleWaitlistCountHash() =>
    r'6b2c7903b5951b6ae04b16ec5c437b87edd077bf';

/// Get waitlist count for a schedule
///
/// Copied from [scheduleWaitlistCount].
@ProviderFor(scheduleWaitlistCount)
const scheduleWaitlistCountProvider = ScheduleWaitlistCountFamily();

/// Get waitlist count for a schedule
///
/// Copied from [scheduleWaitlistCount].
class ScheduleWaitlistCountFamily extends Family<AsyncValue<int>> {
  /// Get waitlist count for a schedule
  ///
  /// Copied from [scheduleWaitlistCount].
  const ScheduleWaitlistCountFamily();

  /// Get waitlist count for a schedule
  ///
  /// Copied from [scheduleWaitlistCount].
  ScheduleWaitlistCountProvider call(
    String scheduleId,
  ) {
    return ScheduleWaitlistCountProvider(
      scheduleId,
    );
  }

  @override
  ScheduleWaitlistCountProvider getProviderOverride(
    covariant ScheduleWaitlistCountProvider provider,
  ) {
    return call(
      provider.scheduleId,
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
  String? get name => r'scheduleWaitlistCountProvider';
}

/// Get waitlist count for a schedule
///
/// Copied from [scheduleWaitlistCount].
class ScheduleWaitlistCountProvider extends AutoDisposeFutureProvider<int> {
  /// Get waitlist count for a schedule
  ///
  /// Copied from [scheduleWaitlistCount].
  ScheduleWaitlistCountProvider(
    String scheduleId,
  ) : this._internal(
          (ref) => scheduleWaitlistCount(
            ref as ScheduleWaitlistCountRef,
            scheduleId,
          ),
          from: scheduleWaitlistCountProvider,
          name: r'scheduleWaitlistCountProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$scheduleWaitlistCountHash,
          dependencies: ScheduleWaitlistCountFamily._dependencies,
          allTransitiveDependencies:
              ScheduleWaitlistCountFamily._allTransitiveDependencies,
          scheduleId: scheduleId,
        );

  ScheduleWaitlistCountProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.scheduleId,
  }) : super.internal();

  final String scheduleId;

  @override
  Override overrideWith(
    FutureOr<int> Function(ScheduleWaitlistCountRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ScheduleWaitlistCountProvider._internal(
        (ref) => create(ref as ScheduleWaitlistCountRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        scheduleId: scheduleId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<int> createElement() {
    return _ScheduleWaitlistCountProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ScheduleWaitlistCountProvider &&
        other.scheduleId == scheduleId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, scheduleId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ScheduleWaitlistCountRef on AutoDisposeFutureProviderRef<int> {
  /// The parameter `scheduleId` of this provider.
  String get scheduleId;
}

class _ScheduleWaitlistCountProviderElement
    extends AutoDisposeFutureProviderElement<int>
    with ScheduleWaitlistCountRef {
  _ScheduleWaitlistCountProviderElement(super.provider);

  @override
  String get scheduleId => (origin as ScheduleWaitlistCountProvider).scheduleId;
}

String _$studentScheduleBookingHash() =>
    r'901eb545ac6e33e42982ff173edfdc2e8fefc50b';

/// Get booking for a specific student and schedule
///
/// Copied from [studentScheduleBooking].
@ProviderFor(studentScheduleBooking)
const studentScheduleBookingProvider = StudentScheduleBookingFamily();

/// Get booking for a specific student and schedule
///
/// Copied from [studentScheduleBooking].
class StudentScheduleBookingFamily
    extends Family<AsyncValue<GroupClassBooking?>> {
  /// Get booking for a specific student and schedule
  ///
  /// Copied from [studentScheduleBooking].
  const StudentScheduleBookingFamily();

  /// Get booking for a specific student and schedule
  ///
  /// Copied from [studentScheduleBooking].
  StudentScheduleBookingProvider call(
    String scheduleId,
    String studentId,
  ) {
    return StudentScheduleBookingProvider(
      scheduleId,
      studentId,
    );
  }

  @override
  StudentScheduleBookingProvider getProviderOverride(
    covariant StudentScheduleBookingProvider provider,
  ) {
    return call(
      provider.scheduleId,
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
  String? get name => r'studentScheduleBookingProvider';
}

/// Get booking for a specific student and schedule
///
/// Copied from [studentScheduleBooking].
class StudentScheduleBookingProvider
    extends AutoDisposeFutureProvider<GroupClassBooking?> {
  /// Get booking for a specific student and schedule
  ///
  /// Copied from [studentScheduleBooking].
  StudentScheduleBookingProvider(
    String scheduleId,
    String studentId,
  ) : this._internal(
          (ref) => studentScheduleBooking(
            ref as StudentScheduleBookingRef,
            scheduleId,
            studentId,
          ),
          from: studentScheduleBookingProvider,
          name: r'studentScheduleBookingProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$studentScheduleBookingHash,
          dependencies: StudentScheduleBookingFamily._dependencies,
          allTransitiveDependencies:
              StudentScheduleBookingFamily._allTransitiveDependencies,
          scheduleId: scheduleId,
          studentId: studentId,
        );

  StudentScheduleBookingProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.scheduleId,
    required this.studentId,
  }) : super.internal();

  final String scheduleId;
  final String studentId;

  @override
  Override overrideWith(
    FutureOr<GroupClassBooking?> Function(StudentScheduleBookingRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: StudentScheduleBookingProvider._internal(
        (ref) => create(ref as StudentScheduleBookingRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        scheduleId: scheduleId,
        studentId: studentId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<GroupClassBooking?> createElement() {
    return _StudentScheduleBookingProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StudentScheduleBookingProvider &&
        other.scheduleId == scheduleId &&
        other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, scheduleId.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin StudentScheduleBookingRef
    on AutoDisposeFutureProviderRef<GroupClassBooking?> {
  /// The parameter `scheduleId` of this provider.
  String get scheduleId;

  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _StudentScheduleBookingProviderElement
    extends AutoDisposeFutureProviderElement<GroupClassBooking?>
    with StudentScheduleBookingRef {
  _StudentScheduleBookingProviderElement(super.provider);

  @override
  String get scheduleId =>
      (origin as StudentScheduleBookingProvider).scheduleId;
  @override
  String get studentId => (origin as StudentScheduleBookingProvider).studentId;
}

String _$studentActiveBookingsHash() =>
    r'6d632d88b2dd78d4dc79913bf65dd4cdd868be1d';

/// Get all active bookings for a student
///
/// Copied from [studentActiveBookings].
@ProviderFor(studentActiveBookings)
const studentActiveBookingsProvider = StudentActiveBookingsFamily();

/// Get all active bookings for a student
///
/// Copied from [studentActiveBookings].
class StudentActiveBookingsFamily
    extends Family<AsyncValue<List<GroupClassBooking>>> {
  /// Get all active bookings for a student
  ///
  /// Copied from [studentActiveBookings].
  const StudentActiveBookingsFamily();

  /// Get all active bookings for a student
  ///
  /// Copied from [studentActiveBookings].
  StudentActiveBookingsProvider call(
    String studentId,
  ) {
    return StudentActiveBookingsProvider(
      studentId,
    );
  }

  @override
  StudentActiveBookingsProvider getProviderOverride(
    covariant StudentActiveBookingsProvider provider,
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
  String? get name => r'studentActiveBookingsProvider';
}

/// Get all active bookings for a student
///
/// Copied from [studentActiveBookings].
class StudentActiveBookingsProvider
    extends AutoDisposeFutureProvider<List<GroupClassBooking>> {
  /// Get all active bookings for a student
  ///
  /// Copied from [studentActiveBookings].
  StudentActiveBookingsProvider(
    String studentId,
  ) : this._internal(
          (ref) => studentActiveBookings(
            ref as StudentActiveBookingsRef,
            studentId,
          ),
          from: studentActiveBookingsProvider,
          name: r'studentActiveBookingsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$studentActiveBookingsHash,
          dependencies: StudentActiveBookingsFamily._dependencies,
          allTransitiveDependencies:
              StudentActiveBookingsFamily._allTransitiveDependencies,
          studentId: studentId,
        );

  StudentActiveBookingsProvider._internal(
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
    FutureOr<List<GroupClassBooking>> Function(
            StudentActiveBookingsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: StudentActiveBookingsProvider._internal(
        (ref) => create(ref as StudentActiveBookingsRef),
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
  AutoDisposeFutureProviderElement<List<GroupClassBooking>> createElement() {
    return _StudentActiveBookingsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StudentActiveBookingsProvider &&
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
mixin StudentActiveBookingsRef
    on AutoDisposeFutureProviderRef<List<GroupClassBooking>> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _StudentActiveBookingsProviderElement
    extends AutoDisposeFutureProviderElement<List<GroupClassBooking>>
    with StudentActiveBookingsRef {
  _StudentActiveBookingsProviderElement(super.provider);

  @override
  String get studentId => (origin as StudentActiveBookingsProvider).studentId;
}

String _$studentWaitlistPositionHash() =>
    r'df4fce6534dd534db29c101529f2303faafdc560';

/// Get waitlist position for a student
///
/// Copied from [studentWaitlistPosition].
@ProviderFor(studentWaitlistPosition)
const studentWaitlistPositionProvider = StudentWaitlistPositionFamily();

/// Get waitlist position for a student
///
/// Copied from [studentWaitlistPosition].
class StudentWaitlistPositionFamily extends Family<AsyncValue<int?>> {
  /// Get waitlist position for a student
  ///
  /// Copied from [studentWaitlistPosition].
  const StudentWaitlistPositionFamily();

  /// Get waitlist position for a student
  ///
  /// Copied from [studentWaitlistPosition].
  StudentWaitlistPositionProvider call(
    String scheduleId,
    String studentId,
  ) {
    return StudentWaitlistPositionProvider(
      scheduleId,
      studentId,
    );
  }

  @override
  StudentWaitlistPositionProvider getProviderOverride(
    covariant StudentWaitlistPositionProvider provider,
  ) {
    return call(
      provider.scheduleId,
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
  String? get name => r'studentWaitlistPositionProvider';
}

/// Get waitlist position for a student
///
/// Copied from [studentWaitlistPosition].
class StudentWaitlistPositionProvider extends AutoDisposeFutureProvider<int?> {
  /// Get waitlist position for a student
  ///
  /// Copied from [studentWaitlistPosition].
  StudentWaitlistPositionProvider(
    String scheduleId,
    String studentId,
  ) : this._internal(
          (ref) => studentWaitlistPosition(
            ref as StudentWaitlistPositionRef,
            scheduleId,
            studentId,
          ),
          from: studentWaitlistPositionProvider,
          name: r'studentWaitlistPositionProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$studentWaitlistPositionHash,
          dependencies: StudentWaitlistPositionFamily._dependencies,
          allTransitiveDependencies:
              StudentWaitlistPositionFamily._allTransitiveDependencies,
          scheduleId: scheduleId,
          studentId: studentId,
        );

  StudentWaitlistPositionProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.scheduleId,
    required this.studentId,
  }) : super.internal();

  final String scheduleId;
  final String studentId;

  @override
  Override overrideWith(
    FutureOr<int?> Function(StudentWaitlistPositionRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: StudentWaitlistPositionProvider._internal(
        (ref) => create(ref as StudentWaitlistPositionRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        scheduleId: scheduleId,
        studentId: studentId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<int?> createElement() {
    return _StudentWaitlistPositionProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StudentWaitlistPositionProvider &&
        other.scheduleId == scheduleId &&
        other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, scheduleId.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin StudentWaitlistPositionRef on AutoDisposeFutureProviderRef<int?> {
  /// The parameter `scheduleId` of this provider.
  String get scheduleId;

  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _StudentWaitlistPositionProviderElement
    extends AutoDisposeFutureProviderElement<int?>
    with StudentWaitlistPositionRef {
  _StudentWaitlistPositionProviderElement(super.provider);

  @override
  String get scheduleId =>
      (origin as StudentWaitlistPositionProvider).scheduleId;
  @override
  String get studentId => (origin as StudentWaitlistPositionProvider).studentId;
}

String _$groupClassBookingNotifierHash() =>
    r'8bf7721dd2dc0d3ede40afda8e9cc8b195df2fcc';

/// See also [GroupClassBookingNotifier].
@ProviderFor(GroupClassBookingNotifier)
final groupClassBookingNotifierProvider = AutoDisposeNotifierProvider<
    GroupClassBookingNotifier, AsyncValue<GroupClassBooking?>>.internal(
  GroupClassBookingNotifier.new,
  name: r'groupClassBookingNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$groupClassBookingNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$GroupClassBookingNotifier
    = AutoDisposeNotifier<AsyncValue<GroupClassBooking?>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
