// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'teacher_availability_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$teacherAvailabilityRepositoryHash() =>
    r'dfd89892e3e9f9b923662c4e9a512298826fd46c';

/// See also [teacherAvailabilityRepository].
@ProviderFor(teacherAvailabilityRepository)
final teacherAvailabilityRepositoryProvider =
    Provider<TeacherAvailabilityRepository>.internal(
  teacherAvailabilityRepository,
  name: r'teacherAvailabilityRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$teacherAvailabilityRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef TeacherAvailabilityRepositoryRef
    = ProviderRef<TeacherAvailabilityRepository>;
String _$teacherAvailabilityHash() =>
    r'c8a488ca035b8e9370023cd62fd2868e23592120';

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

/// See also [teacherAvailability].
@ProviderFor(teacherAvailability)
const teacherAvailabilityProvider = TeacherAvailabilityFamily();

/// See also [teacherAvailability].
class TeacherAvailabilityFamily
    extends Family<AsyncValue<TeacherAvailability?>> {
  /// See also [teacherAvailability].
  const TeacherAvailabilityFamily();

  /// See also [teacherAvailability].
  TeacherAvailabilityProvider call(
    String teacherId,
  ) {
    return TeacherAvailabilityProvider(
      teacherId,
    );
  }

  @override
  TeacherAvailabilityProvider getProviderOverride(
    covariant TeacherAvailabilityProvider provider,
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
  String? get name => r'teacherAvailabilityProvider';
}

/// See also [teacherAvailability].
class TeacherAvailabilityProvider
    extends AutoDisposeFutureProvider<TeacherAvailability?> {
  /// See also [teacherAvailability].
  TeacherAvailabilityProvider(
    String teacherId,
  ) : this._internal(
          (ref) => teacherAvailability(
            ref as TeacherAvailabilityRef,
            teacherId,
          ),
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
    FutureOr<TeacherAvailability?> Function(TeacherAvailabilityRef provider)
        create,
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
  AutoDisposeFutureProviderElement<TeacherAvailability?> createElement() {
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

mixin TeacherAvailabilityRef
    on AutoDisposeFutureProviderRef<TeacherAvailability?> {
  /// The parameter `teacherId` of this provider.
  String get teacherId;
}

class _TeacherAvailabilityProviderElement
    extends AutoDisposeFutureProviderElement<TeacherAvailability?>
    with TeacherAvailabilityRef {
  _TeacherAvailabilityProviderElement(super.provider);

  @override
  String get teacherId => (origin as TeacherAvailabilityProvider).teacherId;
}

String _$affectedBookingsForWeeklyScheduleHash() =>
    r'976d2b1e1235150d1d609640a72a6a74fadfbb58';

/// See also [affectedBookingsForWeeklySchedule].
@ProviderFor(affectedBookingsForWeeklySchedule)
const affectedBookingsForWeeklyScheduleProvider =
    AffectedBookingsForWeeklyScheduleFamily();

/// See also [affectedBookingsForWeeklySchedule].
class AffectedBookingsForWeeklyScheduleFamily extends Family<AsyncValue<int>> {
  /// See also [affectedBookingsForWeeklySchedule].
  const AffectedBookingsForWeeklyScheduleFamily();

  /// See also [affectedBookingsForWeeklySchedule].
  AffectedBookingsForWeeklyScheduleProvider call({
    required String teacherId,
    required int weeklyDayOfWeek,
    required String weeklyStartTime,
    required String weeklyEndTime,
  }) {
    return AffectedBookingsForWeeklyScheduleProvider(
      teacherId: teacherId,
      weeklyDayOfWeek: weeklyDayOfWeek,
      weeklyStartTime: weeklyStartTime,
      weeklyEndTime: weeklyEndTime,
    );
  }

  @override
  AffectedBookingsForWeeklyScheduleProvider getProviderOverride(
    covariant AffectedBookingsForWeeklyScheduleProvider provider,
  ) {
    return call(
      teacherId: provider.teacherId,
      weeklyDayOfWeek: provider.weeklyDayOfWeek,
      weeklyStartTime: provider.weeklyStartTime,
      weeklyEndTime: provider.weeklyEndTime,
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
  String? get name => r'affectedBookingsForWeeklyScheduleProvider';
}

/// See also [affectedBookingsForWeeklySchedule].
class AffectedBookingsForWeeklyScheduleProvider
    extends AutoDisposeFutureProvider<int> {
  /// See also [affectedBookingsForWeeklySchedule].
  AffectedBookingsForWeeklyScheduleProvider({
    required String teacherId,
    required int weeklyDayOfWeek,
    required String weeklyStartTime,
    required String weeklyEndTime,
  }) : this._internal(
          (ref) => affectedBookingsForWeeklySchedule(
            ref as AffectedBookingsForWeeklyScheduleRef,
            teacherId: teacherId,
            weeklyDayOfWeek: weeklyDayOfWeek,
            weeklyStartTime: weeklyStartTime,
            weeklyEndTime: weeklyEndTime,
          ),
          from: affectedBookingsForWeeklyScheduleProvider,
          name: r'affectedBookingsForWeeklyScheduleProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$affectedBookingsForWeeklyScheduleHash,
          dependencies: AffectedBookingsForWeeklyScheduleFamily._dependencies,
          allTransitiveDependencies: AffectedBookingsForWeeklyScheduleFamily
              ._allTransitiveDependencies,
          teacherId: teacherId,
          weeklyDayOfWeek: weeklyDayOfWeek,
          weeklyStartTime: weeklyStartTime,
          weeklyEndTime: weeklyEndTime,
        );

  AffectedBookingsForWeeklyScheduleProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.teacherId,
    required this.weeklyDayOfWeek,
    required this.weeklyStartTime,
    required this.weeklyEndTime,
  }) : super.internal();

  final String teacherId;
  final int weeklyDayOfWeek;
  final String weeklyStartTime;
  final String weeklyEndTime;

  @override
  Override overrideWith(
    FutureOr<int> Function(AffectedBookingsForWeeklyScheduleRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: AffectedBookingsForWeeklyScheduleProvider._internal(
        (ref) => create(ref as AffectedBookingsForWeeklyScheduleRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        teacherId: teacherId,
        weeklyDayOfWeek: weeklyDayOfWeek,
        weeklyStartTime: weeklyStartTime,
        weeklyEndTime: weeklyEndTime,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<int> createElement() {
    return _AffectedBookingsForWeeklyScheduleProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AffectedBookingsForWeeklyScheduleProvider &&
        other.teacherId == teacherId &&
        other.weeklyDayOfWeek == weeklyDayOfWeek &&
        other.weeklyStartTime == weeklyStartTime &&
        other.weeklyEndTime == weeklyEndTime;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, teacherId.hashCode);
    hash = _SystemHash.combine(hash, weeklyDayOfWeek.hashCode);
    hash = _SystemHash.combine(hash, weeklyStartTime.hashCode);
    hash = _SystemHash.combine(hash, weeklyEndTime.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin AffectedBookingsForWeeklyScheduleRef
    on AutoDisposeFutureProviderRef<int> {
  /// The parameter `teacherId` of this provider.
  String get teacherId;

  /// The parameter `weeklyDayOfWeek` of this provider.
  int get weeklyDayOfWeek;

  /// The parameter `weeklyStartTime` of this provider.
  String get weeklyStartTime;

  /// The parameter `weeklyEndTime` of this provider.
  String get weeklyEndTime;
}

class _AffectedBookingsForWeeklyScheduleProviderElement
    extends AutoDisposeFutureProviderElement<int>
    with AffectedBookingsForWeeklyScheduleRef {
  _AffectedBookingsForWeeklyScheduleProviderElement(super.provider);

  @override
  String get teacherId =>
      (origin as AffectedBookingsForWeeklyScheduleProvider).teacherId;
  @override
  int get weeklyDayOfWeek =>
      (origin as AffectedBookingsForWeeklyScheduleProvider).weeklyDayOfWeek;
  @override
  String get weeklyStartTime =>
      (origin as AffectedBookingsForWeeklyScheduleProvider).weeklyStartTime;
  @override
  String get weeklyEndTime =>
      (origin as AffectedBookingsForWeeklyScheduleProvider).weeklyEndTime;
}

String _$availableSlotsForDateHash() =>
    r'2a8b5a78926f3f87370ed8f2a5adddf6ed8bb2a1';

/// See also [availableSlotsForDate].
@ProviderFor(availableSlotsForDate)
const availableSlotsForDateProvider = AvailableSlotsForDateFamily();

/// See also [availableSlotsForDate].
class AvailableSlotsForDateFamily
    extends Family<AsyncValue<List<AvailabilitySlot>>> {
  /// See also [availableSlotsForDate].
  const AvailableSlotsForDateFamily();

  /// See also [availableSlotsForDate].
  AvailableSlotsForDateProvider call({
    required String teacherId,
    required DateTime date,
    String? currentStudentId,
  }) {
    return AvailableSlotsForDateProvider(
      teacherId: teacherId,
      date: date,
      currentStudentId: currentStudentId,
    );
  }

  @override
  AvailableSlotsForDateProvider getProviderOverride(
    covariant AvailableSlotsForDateProvider provider,
  ) {
    return call(
      teacherId: provider.teacherId,
      date: provider.date,
      currentStudentId: provider.currentStudentId,
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
  String? get name => r'availableSlotsForDateProvider';
}

/// See also [availableSlotsForDate].
class AvailableSlotsForDateProvider
    extends AutoDisposeFutureProvider<List<AvailabilitySlot>> {
  /// See also [availableSlotsForDate].
  AvailableSlotsForDateProvider({
    required String teacherId,
    required DateTime date,
    String? currentStudentId,
  }) : this._internal(
          (ref) => availableSlotsForDate(
            ref as AvailableSlotsForDateRef,
            teacherId: teacherId,
            date: date,
            currentStudentId: currentStudentId,
          ),
          from: availableSlotsForDateProvider,
          name: r'availableSlotsForDateProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$availableSlotsForDateHash,
          dependencies: AvailableSlotsForDateFamily._dependencies,
          allTransitiveDependencies:
              AvailableSlotsForDateFamily._allTransitiveDependencies,
          teacherId: teacherId,
          date: date,
          currentStudentId: currentStudentId,
        );

  AvailableSlotsForDateProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.teacherId,
    required this.date,
    required this.currentStudentId,
  }) : super.internal();

  final String teacherId;
  final DateTime date;
  final String? currentStudentId;

  @override
  Override overrideWith(
    FutureOr<List<AvailabilitySlot>> Function(AvailableSlotsForDateRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: AvailableSlotsForDateProvider._internal(
        (ref) => create(ref as AvailableSlotsForDateRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        teacherId: teacherId,
        date: date,
        currentStudentId: currentStudentId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<AvailabilitySlot>> createElement() {
    return _AvailableSlotsForDateProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AvailableSlotsForDateProvider &&
        other.teacherId == teacherId &&
        other.date == date &&
        other.currentStudentId == currentStudentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, teacherId.hashCode);
    hash = _SystemHash.combine(hash, date.hashCode);
    hash = _SystemHash.combine(hash, currentStudentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin AvailableSlotsForDateRef
    on AutoDisposeFutureProviderRef<List<AvailabilitySlot>> {
  /// The parameter `teacherId` of this provider.
  String get teacherId;

  /// The parameter `date` of this provider.
  DateTime get date;

  /// The parameter `currentStudentId` of this provider.
  String? get currentStudentId;
}

class _AvailableSlotsForDateProviderElement
    extends AutoDisposeFutureProviderElement<List<AvailabilitySlot>>
    with AvailableSlotsForDateRef {
  _AvailableSlotsForDateProviderElement(super.provider);

  @override
  String get teacherId => (origin as AvailableSlotsForDateProvider).teacherId;
  @override
  DateTime get date => (origin as AvailableSlotsForDateProvider).date;
  @override
  String? get currentStudentId =>
      (origin as AvailableSlotsForDateProvider).currentStudentId;
}

String _$availableSlotsForDateRangeHash() =>
    r'6d57c6dcf069ee97f24623ec208ceb64032c96cd';

/// See also [availableSlotsForDateRange].
@ProviderFor(availableSlotsForDateRange)
const availableSlotsForDateRangeProvider = AvailableSlotsForDateRangeFamily();

/// See also [availableSlotsForDateRange].
class AvailableSlotsForDateRangeFamily
    extends Family<AsyncValue<List<AvailabilitySlot>>> {
  /// See also [availableSlotsForDateRange].
  const AvailableSlotsForDateRangeFamily();

  /// See also [availableSlotsForDateRange].
  AvailableSlotsForDateRangeProvider call({
    required String teacherId,
    required DateTime startDate,
    required DateTime endDate,
    String? currentStudentId,
  }) {
    return AvailableSlotsForDateRangeProvider(
      teacherId: teacherId,
      startDate: startDate,
      endDate: endDate,
      currentStudentId: currentStudentId,
    );
  }

  @override
  AvailableSlotsForDateRangeProvider getProviderOverride(
    covariant AvailableSlotsForDateRangeProvider provider,
  ) {
    return call(
      teacherId: provider.teacherId,
      startDate: provider.startDate,
      endDate: provider.endDate,
      currentStudentId: provider.currentStudentId,
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
  String? get name => r'availableSlotsForDateRangeProvider';
}

/// See also [availableSlotsForDateRange].
class AvailableSlotsForDateRangeProvider
    extends AutoDisposeFutureProvider<List<AvailabilitySlot>> {
  /// See also [availableSlotsForDateRange].
  AvailableSlotsForDateRangeProvider({
    required String teacherId,
    required DateTime startDate,
    required DateTime endDate,
    String? currentStudentId,
  }) : this._internal(
          (ref) => availableSlotsForDateRange(
            ref as AvailableSlotsForDateRangeRef,
            teacherId: teacherId,
            startDate: startDate,
            endDate: endDate,
            currentStudentId: currentStudentId,
          ),
          from: availableSlotsForDateRangeProvider,
          name: r'availableSlotsForDateRangeProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$availableSlotsForDateRangeHash,
          dependencies: AvailableSlotsForDateRangeFamily._dependencies,
          allTransitiveDependencies:
              AvailableSlotsForDateRangeFamily._allTransitiveDependencies,
          teacherId: teacherId,
          startDate: startDate,
          endDate: endDate,
          currentStudentId: currentStudentId,
        );

  AvailableSlotsForDateRangeProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.teacherId,
    required this.startDate,
    required this.endDate,
    required this.currentStudentId,
  }) : super.internal();

  final String teacherId;
  final DateTime startDate;
  final DateTime endDate;
  final String? currentStudentId;

  @override
  Override overrideWith(
    FutureOr<List<AvailabilitySlot>> Function(
            AvailableSlotsForDateRangeRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: AvailableSlotsForDateRangeProvider._internal(
        (ref) => create(ref as AvailableSlotsForDateRangeRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        teacherId: teacherId,
        startDate: startDate,
        endDate: endDate,
        currentStudentId: currentStudentId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<AvailabilitySlot>> createElement() {
    return _AvailableSlotsForDateRangeProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AvailableSlotsForDateRangeProvider &&
        other.teacherId == teacherId &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.currentStudentId == currentStudentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, teacherId.hashCode);
    hash = _SystemHash.combine(hash, startDate.hashCode);
    hash = _SystemHash.combine(hash, endDate.hashCode);
    hash = _SystemHash.combine(hash, currentStudentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin AvailableSlotsForDateRangeRef
    on AutoDisposeFutureProviderRef<List<AvailabilitySlot>> {
  /// The parameter `teacherId` of this provider.
  String get teacherId;

  /// The parameter `startDate` of this provider.
  DateTime get startDate;

  /// The parameter `endDate` of this provider.
  DateTime get endDate;

  /// The parameter `currentStudentId` of this provider.
  String? get currentStudentId;
}

class _AvailableSlotsForDateRangeProviderElement
    extends AutoDisposeFutureProviderElement<List<AvailabilitySlot>>
    with AvailableSlotsForDateRangeRef {
  _AvailableSlotsForDateRangeProviderElement(super.provider);

  @override
  String get teacherId =>
      (origin as AvailableSlotsForDateRangeProvider).teacherId;
  @override
  DateTime get startDate =>
      (origin as AvailableSlotsForDateRangeProvider).startDate;
  @override
  DateTime get endDate =>
      (origin as AvailableSlotsForDateRangeProvider).endDate;
  @override
  String? get currentStudentId =>
      (origin as AvailableSlotsForDateRangeProvider).currentStudentId;
}

String _$nextAvailableDatesHash() =>
    r'6115830e51fc561f3514e614529719d998b3527b';

/// See also [nextAvailableDates].
@ProviderFor(nextAvailableDates)
const nextAvailableDatesProvider = NextAvailableDatesFamily();

/// See also [nextAvailableDates].
class NextAvailableDatesFamily extends Family<AsyncValue<List<DateTime>>> {
  /// See also [nextAvailableDates].
  const NextAvailableDatesFamily();

  /// See also [nextAvailableDates].
  NextAvailableDatesProvider call({
    required String teacherId,
    required DateTime fromDate,
    int limit = 3,
  }) {
    return NextAvailableDatesProvider(
      teacherId: teacherId,
      fromDate: fromDate,
      limit: limit,
    );
  }

  @override
  NextAvailableDatesProvider getProviderOverride(
    covariant NextAvailableDatesProvider provider,
  ) {
    return call(
      teacherId: provider.teacherId,
      fromDate: provider.fromDate,
      limit: provider.limit,
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
  String? get name => r'nextAvailableDatesProvider';
}

/// See also [nextAvailableDates].
class NextAvailableDatesProvider
    extends AutoDisposeFutureProvider<List<DateTime>> {
  /// See also [nextAvailableDates].
  NextAvailableDatesProvider({
    required String teacherId,
    required DateTime fromDate,
    int limit = 3,
  }) : this._internal(
          (ref) => nextAvailableDates(
            ref as NextAvailableDatesRef,
            teacherId: teacherId,
            fromDate: fromDate,
            limit: limit,
          ),
          from: nextAvailableDatesProvider,
          name: r'nextAvailableDatesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$nextAvailableDatesHash,
          dependencies: NextAvailableDatesFamily._dependencies,
          allTransitiveDependencies:
              NextAvailableDatesFamily._allTransitiveDependencies,
          teacherId: teacherId,
          fromDate: fromDate,
          limit: limit,
        );

  NextAvailableDatesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.teacherId,
    required this.fromDate,
    required this.limit,
  }) : super.internal();

  final String teacherId;
  final DateTime fromDate;
  final int limit;

  @override
  Override overrideWith(
    FutureOr<List<DateTime>> Function(NextAvailableDatesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: NextAvailableDatesProvider._internal(
        (ref) => create(ref as NextAvailableDatesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        teacherId: teacherId,
        fromDate: fromDate,
        limit: limit,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<DateTime>> createElement() {
    return _NextAvailableDatesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is NextAvailableDatesProvider &&
        other.teacherId == teacherId &&
        other.fromDate == fromDate &&
        other.limit == limit;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, teacherId.hashCode);
    hash = _SystemHash.combine(hash, fromDate.hashCode);
    hash = _SystemHash.combine(hash, limit.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin NextAvailableDatesRef on AutoDisposeFutureProviderRef<List<DateTime>> {
  /// The parameter `teacherId` of this provider.
  String get teacherId;

  /// The parameter `fromDate` of this provider.
  DateTime get fromDate;

  /// The parameter `limit` of this provider.
  int get limit;
}

class _NextAvailableDatesProviderElement
    extends AutoDisposeFutureProviderElement<List<DateTime>>
    with NextAvailableDatesRef {
  _NextAvailableDatesProviderElement(super.provider);

  @override
  String get teacherId => (origin as NextAvailableDatesProvider).teacherId;
  @override
  DateTime get fromDate => (origin as NextAvailableDatesProvider).fromDate;
  @override
  int get limit => (origin as NextAvailableDatesProvider).limit;
}

String _$lessonTimePatternsHash() =>
    r'c14c6178be8c0a0a11497167a1a39b0802f82960';

/// Analyze student's lesson history to find recurring patterns
///
/// Copied from [lessonTimePatterns].
@ProviderFor(lessonTimePatterns)
const lessonTimePatternsProvider = LessonTimePatternsFamily();

/// Analyze student's lesson history to find recurring patterns
///
/// Copied from [lessonTimePatterns].
class LessonTimePatternsFamily
    extends Family<AsyncValue<List<LessonTimePattern>>> {
  /// Analyze student's lesson history to find recurring patterns
  ///
  /// Copied from [lessonTimePatterns].
  const LessonTimePatternsFamily();

  /// Analyze student's lesson history to find recurring patterns
  ///
  /// Copied from [lessonTimePatterns].
  LessonTimePatternsProvider call({
    required String studentId,
    required String teacherId,
    int analysisWindowDays =
        SlotRecommendationService.defaultAnalysisWindowDays,
  }) {
    return LessonTimePatternsProvider(
      studentId: studentId,
      teacherId: teacherId,
      analysisWindowDays: analysisWindowDays,
    );
  }

  @override
  LessonTimePatternsProvider getProviderOverride(
    covariant LessonTimePatternsProvider provider,
  ) {
    return call(
      studentId: provider.studentId,
      teacherId: provider.teacherId,
      analysisWindowDays: provider.analysisWindowDays,
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
  String? get name => r'lessonTimePatternsProvider';
}

/// Analyze student's lesson history to find recurring patterns
///
/// Copied from [lessonTimePatterns].
class LessonTimePatternsProvider
    extends AutoDisposeFutureProvider<List<LessonTimePattern>> {
  /// Analyze student's lesson history to find recurring patterns
  ///
  /// Copied from [lessonTimePatterns].
  LessonTimePatternsProvider({
    required String studentId,
    required String teacherId,
    int analysisWindowDays =
        SlotRecommendationService.defaultAnalysisWindowDays,
  }) : this._internal(
          (ref) => lessonTimePatterns(
            ref as LessonTimePatternsRef,
            studentId: studentId,
            teacherId: teacherId,
            analysisWindowDays: analysisWindowDays,
          ),
          from: lessonTimePatternsProvider,
          name: r'lessonTimePatternsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$lessonTimePatternsHash,
          dependencies: LessonTimePatternsFamily._dependencies,
          allTransitiveDependencies:
              LessonTimePatternsFamily._allTransitiveDependencies,
          studentId: studentId,
          teacherId: teacherId,
          analysisWindowDays: analysisWindowDays,
        );

  LessonTimePatternsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.studentId,
    required this.teacherId,
    required this.analysisWindowDays,
  }) : super.internal();

  final String studentId;
  final String teacherId;
  final int analysisWindowDays;

  @override
  Override overrideWith(
    FutureOr<List<LessonTimePattern>> Function(LessonTimePatternsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: LessonTimePatternsProvider._internal(
        (ref) => create(ref as LessonTimePatternsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        studentId: studentId,
        teacherId: teacherId,
        analysisWindowDays: analysisWindowDays,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<LessonTimePattern>> createElement() {
    return _LessonTimePatternsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is LessonTimePatternsProvider &&
        other.studentId == studentId &&
        other.teacherId == teacherId &&
        other.analysisWindowDays == analysisWindowDays;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);
    hash = _SystemHash.combine(hash, teacherId.hashCode);
    hash = _SystemHash.combine(hash, analysisWindowDays.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin LessonTimePatternsRef
    on AutoDisposeFutureProviderRef<List<LessonTimePattern>> {
  /// The parameter `studentId` of this provider.
  String get studentId;

  /// The parameter `teacherId` of this provider.
  String get teacherId;

  /// The parameter `analysisWindowDays` of this provider.
  int get analysisWindowDays;
}

class _LessonTimePatternsProviderElement
    extends AutoDisposeFutureProviderElement<List<LessonTimePattern>>
    with LessonTimePatternsRef {
  _LessonTimePatternsProviderElement(super.provider);

  @override
  String get studentId => (origin as LessonTimePatternsProvider).studentId;
  @override
  String get teacherId => (origin as LessonTimePatternsProvider).teacherId;
  @override
  int get analysisWindowDays =>
      (origin as LessonTimePatternsProvider).analysisWindowDays;
}

String _$recommendedSlotsHash() => r'51fdba6a699b45d38492e0a64a773518e83a58b7';

/// Get recommended slots based on lesson history patterns
///
/// Copied from [recommendedSlots].
@ProviderFor(recommendedSlots)
const recommendedSlotsProvider = RecommendedSlotsFamily();

/// Get recommended slots based on lesson history patterns
///
/// Copied from [recommendedSlots].
class RecommendedSlotsFamily
    extends Family<AsyncValue<List<AvailabilitySlot>>> {
  /// Get recommended slots based on lesson history patterns
  ///
  /// Copied from [recommendedSlots].
  const RecommendedSlotsFamily();

  /// Get recommended slots based on lesson history patterns
  ///
  /// Copied from [recommendedSlots].
  RecommendedSlotsProvider call({
    required String teacherId,
    required String studentId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return RecommendedSlotsProvider(
      teacherId: teacherId,
      studentId: studentId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  RecommendedSlotsProvider getProviderOverride(
    covariant RecommendedSlotsProvider provider,
  ) {
    return call(
      teacherId: provider.teacherId,
      studentId: provider.studentId,
      startDate: provider.startDate,
      endDate: provider.endDate,
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
  String? get name => r'recommendedSlotsProvider';
}

/// Get recommended slots based on lesson history patterns
///
/// Copied from [recommendedSlots].
class RecommendedSlotsProvider
    extends AutoDisposeFutureProvider<List<AvailabilitySlot>> {
  /// Get recommended slots based on lesson history patterns
  ///
  /// Copied from [recommendedSlots].
  RecommendedSlotsProvider({
    required String teacherId,
    required String studentId,
    required DateTime startDate,
    required DateTime endDate,
  }) : this._internal(
          (ref) => recommendedSlots(
            ref as RecommendedSlotsRef,
            teacherId: teacherId,
            studentId: studentId,
            startDate: startDate,
            endDate: endDate,
          ),
          from: recommendedSlotsProvider,
          name: r'recommendedSlotsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$recommendedSlotsHash,
          dependencies: RecommendedSlotsFamily._dependencies,
          allTransitiveDependencies:
              RecommendedSlotsFamily._allTransitiveDependencies,
          teacherId: teacherId,
          studentId: studentId,
          startDate: startDate,
          endDate: endDate,
        );

  RecommendedSlotsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.teacherId,
    required this.studentId,
    required this.startDate,
    required this.endDate,
  }) : super.internal();

  final String teacherId;
  final String studentId;
  final DateTime startDate;
  final DateTime endDate;

  @override
  Override overrideWith(
    FutureOr<List<AvailabilitySlot>> Function(RecommendedSlotsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: RecommendedSlotsProvider._internal(
        (ref) => create(ref as RecommendedSlotsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        teacherId: teacherId,
        studentId: studentId,
        startDate: startDate,
        endDate: endDate,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<AvailabilitySlot>> createElement() {
    return _RecommendedSlotsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RecommendedSlotsProvider &&
        other.teacherId == teacherId &&
        other.studentId == studentId &&
        other.startDate == startDate &&
        other.endDate == endDate;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, teacherId.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);
    hash = _SystemHash.combine(hash, startDate.hashCode);
    hash = _SystemHash.combine(hash, endDate.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin RecommendedSlotsRef
    on AutoDisposeFutureProviderRef<List<AvailabilitySlot>> {
  /// The parameter `teacherId` of this provider.
  String get teacherId;

  /// The parameter `studentId` of this provider.
  String get studentId;

  /// The parameter `startDate` of this provider.
  DateTime get startDate;

  /// The parameter `endDate` of this provider.
  DateTime get endDate;
}

class _RecommendedSlotsProviderElement
    extends AutoDisposeFutureProviderElement<List<AvailabilitySlot>>
    with RecommendedSlotsRef {
  _RecommendedSlotsProviderElement(super.provider);

  @override
  String get teacherId => (origin as RecommendedSlotsProvider).teacherId;
  @override
  String get studentId => (origin as RecommendedSlotsProvider).studentId;
  @override
  DateTime get startDate => (origin as RecommendedSlotsProvider).startDate;
  @override
  DateTime get endDate => (origin as RecommendedSlotsProvider).endDate;
}

String _$availableSlotsWithRecommendationsHash() =>
    r'286bc4a734b4d7ab82a9a7c5c4239ba36da9e45b';

/// Get available slots with recommendations marked
///
/// Copied from [availableSlotsWithRecommendations].
@ProviderFor(availableSlotsWithRecommendations)
const availableSlotsWithRecommendationsProvider =
    AvailableSlotsWithRecommendationsFamily();

/// Get available slots with recommendations marked
///
/// Copied from [availableSlotsWithRecommendations].
class AvailableSlotsWithRecommendationsFamily
    extends Family<AsyncValue<List<AvailabilitySlot>>> {
  /// Get available slots with recommendations marked
  ///
  /// Copied from [availableSlotsWithRecommendations].
  const AvailableSlotsWithRecommendationsFamily();

  /// Get available slots with recommendations marked
  ///
  /// Copied from [availableSlotsWithRecommendations].
  AvailableSlotsWithRecommendationsProvider call({
    required String teacherId,
    required DateTime date,
    required String studentId,
  }) {
    return AvailableSlotsWithRecommendationsProvider(
      teacherId: teacherId,
      date: date,
      studentId: studentId,
    );
  }

  @override
  AvailableSlotsWithRecommendationsProvider getProviderOverride(
    covariant AvailableSlotsWithRecommendationsProvider provider,
  ) {
    return call(
      teacherId: provider.teacherId,
      date: provider.date,
      studentId: provider.studentId,
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
  String? get name => r'availableSlotsWithRecommendationsProvider';
}

/// Get available slots with recommendations marked
///
/// Copied from [availableSlotsWithRecommendations].
class AvailableSlotsWithRecommendationsProvider
    extends AutoDisposeFutureProvider<List<AvailabilitySlot>> {
  /// Get available slots with recommendations marked
  ///
  /// Copied from [availableSlotsWithRecommendations].
  AvailableSlotsWithRecommendationsProvider({
    required String teacherId,
    required DateTime date,
    required String studentId,
  }) : this._internal(
          (ref) => availableSlotsWithRecommendations(
            ref as AvailableSlotsWithRecommendationsRef,
            teacherId: teacherId,
            date: date,
            studentId: studentId,
          ),
          from: availableSlotsWithRecommendationsProvider,
          name: r'availableSlotsWithRecommendationsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$availableSlotsWithRecommendationsHash,
          dependencies: AvailableSlotsWithRecommendationsFamily._dependencies,
          allTransitiveDependencies: AvailableSlotsWithRecommendationsFamily
              ._allTransitiveDependencies,
          teacherId: teacherId,
          date: date,
          studentId: studentId,
        );

  AvailableSlotsWithRecommendationsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.teacherId,
    required this.date,
    required this.studentId,
  }) : super.internal();

  final String teacherId;
  final DateTime date;
  final String studentId;

  @override
  Override overrideWith(
    FutureOr<List<AvailabilitySlot>> Function(
            AvailableSlotsWithRecommendationsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: AvailableSlotsWithRecommendationsProvider._internal(
        (ref) => create(ref as AvailableSlotsWithRecommendationsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        teacherId: teacherId,
        date: date,
        studentId: studentId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<AvailabilitySlot>> createElement() {
    return _AvailableSlotsWithRecommendationsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AvailableSlotsWithRecommendationsProvider &&
        other.teacherId == teacherId &&
        other.date == date &&
        other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, teacherId.hashCode);
    hash = _SystemHash.combine(hash, date.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin AvailableSlotsWithRecommendationsRef
    on AutoDisposeFutureProviderRef<List<AvailabilitySlot>> {
  /// The parameter `teacherId` of this provider.
  String get teacherId;

  /// The parameter `date` of this provider.
  DateTime get date;

  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _AvailableSlotsWithRecommendationsProviderElement
    extends AutoDisposeFutureProviderElement<List<AvailabilitySlot>>
    with AvailableSlotsWithRecommendationsRef {
  _AvailableSlotsWithRecommendationsProviderElement(super.provider);

  @override
  String get teacherId =>
      (origin as AvailableSlotsWithRecommendationsProvider).teacherId;
  @override
  DateTime get date =>
      (origin as AvailableSlotsWithRecommendationsProvider).date;
  @override
  String get studentId =>
      (origin as AvailableSlotsWithRecommendationsProvider).studentId;
}

String _$bookingTeacherInfoHash() =>
    r'69e90a5a4e090db3dd5a6e9c6ca4ef6ca0fd935f';

/// See also [bookingTeacherInfo].
@ProviderFor(bookingTeacherInfo)
const bookingTeacherInfoProvider = BookingTeacherInfoFamily();

/// See also [bookingTeacherInfo].
class BookingTeacherInfoFamily extends Family<AsyncValue<Teacher?>> {
  /// See also [bookingTeacherInfo].
  const BookingTeacherInfoFamily();

  /// See also [bookingTeacherInfo].
  BookingTeacherInfoProvider call({
    required String teacherId,
  }) {
    return BookingTeacherInfoProvider(
      teacherId: teacherId,
    );
  }

  @override
  BookingTeacherInfoProvider getProviderOverride(
    covariant BookingTeacherInfoProvider provider,
  ) {
    return call(
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
  String? get name => r'bookingTeacherInfoProvider';
}

/// See also [bookingTeacherInfo].
class BookingTeacherInfoProvider extends AutoDisposeFutureProvider<Teacher?> {
  /// See also [bookingTeacherInfo].
  BookingTeacherInfoProvider({
    required String teacherId,
  }) : this._internal(
          (ref) => bookingTeacherInfo(
            ref as BookingTeacherInfoRef,
            teacherId: teacherId,
          ),
          from: bookingTeacherInfoProvider,
          name: r'bookingTeacherInfoProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$bookingTeacherInfoHash,
          dependencies: BookingTeacherInfoFamily._dependencies,
          allTransitiveDependencies:
              BookingTeacherInfoFamily._allTransitiveDependencies,
          teacherId: teacherId,
        );

  BookingTeacherInfoProvider._internal(
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
    FutureOr<Teacher?> Function(BookingTeacherInfoRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: BookingTeacherInfoProvider._internal(
        (ref) => create(ref as BookingTeacherInfoRef),
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
  AutoDisposeFutureProviderElement<Teacher?> createElement() {
    return _BookingTeacherInfoProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BookingTeacherInfoProvider && other.teacherId == teacherId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, teacherId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin BookingTeacherInfoRef on AutoDisposeFutureProviderRef<Teacher?> {
  /// The parameter `teacherId` of this provider.
  String get teacherId;
}

class _BookingTeacherInfoProviderElement
    extends AutoDisposeFutureProviderElement<Teacher?>
    with BookingTeacherInfoRef {
  _BookingTeacherInfoProviderElement(super.provider);

  @override
  String get teacherId => (origin as BookingTeacherInfoProvider).teacherId;
}

String _$bookingSubscriptionHash() =>
    r'5d4f555ef22666572648d839e91c916459373935';

/// See also [bookingSubscription].
@ProviderFor(bookingSubscription)
const bookingSubscriptionProvider = BookingSubscriptionFamily();

/// See also [bookingSubscription].
class BookingSubscriptionFamily extends Family<AsyncValue<Subscription?>> {
  /// See also [bookingSubscription].
  const BookingSubscriptionFamily();

  /// See also [bookingSubscription].
  BookingSubscriptionProvider call({
    required String studentId,
    required String teacherId,
  }) {
    return BookingSubscriptionProvider(
      studentId: studentId,
      teacherId: teacherId,
    );
  }

  @override
  BookingSubscriptionProvider getProviderOverride(
    covariant BookingSubscriptionProvider provider,
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
  String? get name => r'bookingSubscriptionProvider';
}

/// See also [bookingSubscription].
class BookingSubscriptionProvider
    extends AutoDisposeFutureProvider<Subscription?> {
  /// See also [bookingSubscription].
  BookingSubscriptionProvider({
    required String studentId,
    required String teacherId,
  }) : this._internal(
          (ref) => bookingSubscription(
            ref as BookingSubscriptionRef,
            studentId: studentId,
            teacherId: teacherId,
          ),
          from: bookingSubscriptionProvider,
          name: r'bookingSubscriptionProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$bookingSubscriptionHash,
          dependencies: BookingSubscriptionFamily._dependencies,
          allTransitiveDependencies:
              BookingSubscriptionFamily._allTransitiveDependencies,
          studentId: studentId,
          teacherId: teacherId,
        );

  BookingSubscriptionProvider._internal(
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
    FutureOr<Subscription?> Function(BookingSubscriptionRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: BookingSubscriptionProvider._internal(
        (ref) => create(ref as BookingSubscriptionRef),
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
    return _BookingSubscriptionProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BookingSubscriptionProvider &&
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

mixin BookingSubscriptionRef on AutoDisposeFutureProviderRef<Subscription?> {
  /// The parameter `studentId` of this provider.
  String get studentId;

  /// The parameter `teacherId` of this provider.
  String get teacherId;
}

class _BookingSubscriptionProviderElement
    extends AutoDisposeFutureProviderElement<Subscription?>
    with BookingSubscriptionRef {
  _BookingSubscriptionProviderElement(super.provider);

  @override
  String get studentId => (origin as BookingSubscriptionProvider).studentId;
  @override
  String get teacherId => (origin as BookingSubscriptionProvider).teacherId;
}

String _$selectedSlotHash() => r'4ff826c12155b6b1508049bb0f35d51c1f7b3abd';

/// See also [SelectedSlot].
@ProviderFor(SelectedSlot)
final selectedSlotProvider =
    AutoDisposeNotifierProvider<SelectedSlot, AvailabilitySlot?>.internal(
  SelectedSlot.new,
  name: r'selectedSlotProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$selectedSlotHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SelectedSlot = AutoDisposeNotifier<AvailabilitySlot?>;
String _$selectedDateHash() => r'503d7c72b7c74086b4e6e3d4c2ce196ff83b942c';

/// See also [SelectedDate].
@ProviderFor(SelectedDate)
final selectedDateProvider =
    AutoDisposeNotifierProvider<SelectedDate, DateTime>.internal(
  SelectedDate.new,
  name: r'selectedDateProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$selectedDateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SelectedDate = AutoDisposeNotifier<DateTime>;
String _$slotBookingNotifierHash() =>
    r'e086e574292d2a020a5bb0878079182bb709b010';

/// See also [SlotBookingNotifier].
@ProviderFor(SlotBookingNotifier)
final slotBookingNotifierProvider = AutoDisposeNotifierProvider<
    SlotBookingNotifier, AsyncValue<AvailabilitySlot?>>.internal(
  SlotBookingNotifier.new,
  name: r'slotBookingNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$slotBookingNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SlotBookingNotifier
    = AutoDisposeNotifier<AsyncValue<AvailabilitySlot?>>;
String _$teacherAvailabilityNotifierHash() =>
    r'8956f53c167f5649dd774c8368d38df317925070';

abstract class _$TeacherAvailabilityNotifier
    extends BuildlessAutoDisposeNotifier<AsyncValue<TeacherAvailability?>> {
  late final String teacherId;

  AsyncValue<TeacherAvailability?> build(
    String teacherId,
  );
}

/// See also [TeacherAvailabilityNotifier].
@ProviderFor(TeacherAvailabilityNotifier)
const teacherAvailabilityNotifierProvider = TeacherAvailabilityNotifierFamily();

/// See also [TeacherAvailabilityNotifier].
class TeacherAvailabilityNotifierFamily
    extends Family<AsyncValue<TeacherAvailability?>> {
  /// See also [TeacherAvailabilityNotifier].
  const TeacherAvailabilityNotifierFamily();

  /// See also [TeacherAvailabilityNotifier].
  TeacherAvailabilityNotifierProvider call(
    String teacherId,
  ) {
    return TeacherAvailabilityNotifierProvider(
      teacherId,
    );
  }

  @override
  TeacherAvailabilityNotifierProvider getProviderOverride(
    covariant TeacherAvailabilityNotifierProvider provider,
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
  String? get name => r'teacherAvailabilityNotifierProvider';
}

/// See also [TeacherAvailabilityNotifier].
class TeacherAvailabilityNotifierProvider
    extends AutoDisposeNotifierProviderImpl<TeacherAvailabilityNotifier,
        AsyncValue<TeacherAvailability?>> {
  /// See also [TeacherAvailabilityNotifier].
  TeacherAvailabilityNotifierProvider(
    String teacherId,
  ) : this._internal(
          () => TeacherAvailabilityNotifier()..teacherId = teacherId,
          from: teacherAvailabilityNotifierProvider,
          name: r'teacherAvailabilityNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$teacherAvailabilityNotifierHash,
          dependencies: TeacherAvailabilityNotifierFamily._dependencies,
          allTransitiveDependencies:
              TeacherAvailabilityNotifierFamily._allTransitiveDependencies,
          teacherId: teacherId,
        );

  TeacherAvailabilityNotifierProvider._internal(
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
  AsyncValue<TeacherAvailability?> runNotifierBuild(
    covariant TeacherAvailabilityNotifier notifier,
  ) {
    return notifier.build(
      teacherId,
    );
  }

  @override
  Override overrideWith(TeacherAvailabilityNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: TeacherAvailabilityNotifierProvider._internal(
        () => create()..teacherId = teacherId,
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
  AutoDisposeNotifierProviderElement<TeacherAvailabilityNotifier,
      AsyncValue<TeacherAvailability?>> createElement() {
    return _TeacherAvailabilityNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TeacherAvailabilityNotifierProvider &&
        other.teacherId == teacherId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, teacherId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin TeacherAvailabilityNotifierRef
    on AutoDisposeNotifierProviderRef<AsyncValue<TeacherAvailability?>> {
  /// The parameter `teacherId` of this provider.
  String get teacherId;
}

class _TeacherAvailabilityNotifierProviderElement
    extends AutoDisposeNotifierProviderElement<TeacherAvailabilityNotifier,
        AsyncValue<TeacherAvailability?>> with TeacherAvailabilityNotifierRef {
  _TeacherAvailabilityNotifierProviderElement(super.provider);

  @override
  String get teacherId =>
      (origin as TeacherAvailabilityNotifierProvider).teacherId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
