// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analytics_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$analyticsRepositoryHash() =>
    r'08a1b70ddf893dfa7e49edfeed777d7861453938';

/// See also [analyticsRepository].
@ProviderFor(analyticsRepository)
final analyticsRepositoryProvider = Provider<AnalyticsRepository>.internal(
  analyticsRepository,
  name: r'analyticsRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$analyticsRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AnalyticsRepositoryRef = ProviderRef<AnalyticsRepository>;
String _$analyticsServiceHash() => r'9f797849c883b6bfe7b38a6b2f601504ea20de18';

/// See also [analyticsService].
@ProviderFor(analyticsService)
final analyticsServiceProvider = Provider<MockAnalyticsService>.internal(
  analyticsService,
  name: r'analyticsServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$analyticsServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AnalyticsServiceRef = ProviderRef<MockAnalyticsService>;
String _$teacherMonthlyStatsHash() =>
    r'e0d655e931993af2b721344fc4225eba95aa2459';

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

/// See also [teacherMonthlyStats].
@ProviderFor(teacherMonthlyStats)
const teacherMonthlyStatsProvider = TeacherMonthlyStatsFamily();

/// See also [teacherMonthlyStats].
class TeacherMonthlyStatsFamily
    extends Family<AsyncValue<TeacherMonthlyStats>> {
  /// See also [teacherMonthlyStats].
  const TeacherMonthlyStatsFamily();

  /// See also [teacherMonthlyStats].
  TeacherMonthlyStatsProvider call(
    DateTime month,
  ) {
    return TeacherMonthlyStatsProvider(
      month,
    );
  }

  @override
  TeacherMonthlyStatsProvider getProviderOverride(
    covariant TeacherMonthlyStatsProvider provider,
  ) {
    return call(
      provider.month,
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
  String? get name => r'teacherMonthlyStatsProvider';
}

/// See also [teacherMonthlyStats].
class TeacherMonthlyStatsProvider
    extends AutoDisposeFutureProvider<TeacherMonthlyStats> {
  /// See also [teacherMonthlyStats].
  TeacherMonthlyStatsProvider(
    DateTime month,
  ) : this._internal(
          (ref) => teacherMonthlyStats(
            ref as TeacherMonthlyStatsRef,
            month,
          ),
          from: teacherMonthlyStatsProvider,
          name: r'teacherMonthlyStatsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$teacherMonthlyStatsHash,
          dependencies: TeacherMonthlyStatsFamily._dependencies,
          allTransitiveDependencies:
              TeacherMonthlyStatsFamily._allTransitiveDependencies,
          month: month,
        );

  TeacherMonthlyStatsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.month,
  }) : super.internal();

  final DateTime month;

  @override
  Override overrideWith(
    FutureOr<TeacherMonthlyStats> Function(TeacherMonthlyStatsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TeacherMonthlyStatsProvider._internal(
        (ref) => create(ref as TeacherMonthlyStatsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        month: month,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<TeacherMonthlyStats> createElement() {
    return _TeacherMonthlyStatsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TeacherMonthlyStatsProvider && other.month == month;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, month.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin TeacherMonthlyStatsRef
    on AutoDisposeFutureProviderRef<TeacherMonthlyStats> {
  /// The parameter `month` of this provider.
  DateTime get month;
}

class _TeacherMonthlyStatsProviderElement
    extends AutoDisposeFutureProviderElement<TeacherMonthlyStats>
    with TeacherMonthlyStatsRef {
  _TeacherMonthlyStatsProviderElement(super.provider);

  @override
  DateTime get month => (origin as TeacherMonthlyStatsProvider).month;
}

String _$teacherMonthlySummaryHash() =>
    r'7747e67b1856fddfa05f6a3c38dabe94716d461e';

/// See also [teacherMonthlySummary].
@ProviderFor(teacherMonthlySummary)
const teacherMonthlySummaryProvider = TeacherMonthlySummaryFamily();

/// See also [teacherMonthlySummary].
class TeacherMonthlySummaryFamily
    extends Family<AsyncValue<TeacherMonthlySummary>> {
  /// See also [teacherMonthlySummary].
  const TeacherMonthlySummaryFamily();

  /// See also [teacherMonthlySummary].
  TeacherMonthlySummaryProvider call({
    required int year,
    required int month,
  }) {
    return TeacherMonthlySummaryProvider(
      year: year,
      month: month,
    );
  }

  @override
  TeacherMonthlySummaryProvider getProviderOverride(
    covariant TeacherMonthlySummaryProvider provider,
  ) {
    return call(
      year: provider.year,
      month: provider.month,
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
  String? get name => r'teacherMonthlySummaryProvider';
}

/// See also [teacherMonthlySummary].
class TeacherMonthlySummaryProvider
    extends AutoDisposeFutureProvider<TeacherMonthlySummary> {
  /// See also [teacherMonthlySummary].
  TeacherMonthlySummaryProvider({
    required int year,
    required int month,
  }) : this._internal(
          (ref) => teacherMonthlySummary(
            ref as TeacherMonthlySummaryRef,
            year: year,
            month: month,
          ),
          from: teacherMonthlySummaryProvider,
          name: r'teacherMonthlySummaryProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$teacherMonthlySummaryHash,
          dependencies: TeacherMonthlySummaryFamily._dependencies,
          allTransitiveDependencies:
              TeacherMonthlySummaryFamily._allTransitiveDependencies,
          year: year,
          month: month,
        );

  TeacherMonthlySummaryProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.year,
    required this.month,
  }) : super.internal();

  final int year;
  final int month;

  @override
  Override overrideWith(
    FutureOr<TeacherMonthlySummary> Function(TeacherMonthlySummaryRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TeacherMonthlySummaryProvider._internal(
        (ref) => create(ref as TeacherMonthlySummaryRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        year: year,
        month: month,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<TeacherMonthlySummary> createElement() {
    return _TeacherMonthlySummaryProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TeacherMonthlySummaryProvider &&
        other.year == year &&
        other.month == month;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, year.hashCode);
    hash = _SystemHash.combine(hash, month.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin TeacherMonthlySummaryRef
    on AutoDisposeFutureProviderRef<TeacherMonthlySummary> {
  /// The parameter `year` of this provider.
  int get year;

  /// The parameter `month` of this provider.
  int get month;
}

class _TeacherMonthlySummaryProviderElement
    extends AutoDisposeFutureProviderElement<TeacherMonthlySummary>
    with TeacherMonthlySummaryRef {
  _TeacherMonthlySummaryProviderElement(super.provider);

  @override
  int get year => (origin as TeacherMonthlySummaryProvider).year;
  @override
  int get month => (origin as TeacherMonthlySummaryProvider).month;
}

String _$studentProgressDataHash() =>
    r'd974d1001fcf7bc6f9f04c165cf82c18268326ae';

/// See also [studentProgressData].
@ProviderFor(studentProgressData)
const studentProgressDataProvider = StudentProgressDataFamily();

/// See also [studentProgressData].
class StudentProgressDataFamily
    extends Family<AsyncValue<StudentProgressData>> {
  /// See also [studentProgressData].
  const StudentProgressDataFamily();

  /// See also [studentProgressData].
  StudentProgressDataProvider call(
    String studentId,
    AnalyticsPeriod period,
  ) {
    return StudentProgressDataProvider(
      studentId,
      period,
    );
  }

  @override
  StudentProgressDataProvider getProviderOverride(
    covariant StudentProgressDataProvider provider,
  ) {
    return call(
      provider.studentId,
      provider.period,
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
  String? get name => r'studentProgressDataProvider';
}

/// See also [studentProgressData].
class StudentProgressDataProvider
    extends AutoDisposeFutureProvider<StudentProgressData> {
  /// See also [studentProgressData].
  StudentProgressDataProvider(
    String studentId,
    AnalyticsPeriod period,
  ) : this._internal(
          (ref) => studentProgressData(
            ref as StudentProgressDataRef,
            studentId,
            period,
          ),
          from: studentProgressDataProvider,
          name: r'studentProgressDataProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$studentProgressDataHash,
          dependencies: StudentProgressDataFamily._dependencies,
          allTransitiveDependencies:
              StudentProgressDataFamily._allTransitiveDependencies,
          studentId: studentId,
          period: period,
        );

  StudentProgressDataProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.studentId,
    required this.period,
  }) : super.internal();

  final String studentId;
  final AnalyticsPeriod period;

  @override
  Override overrideWith(
    FutureOr<StudentProgressData> Function(StudentProgressDataRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: StudentProgressDataProvider._internal(
        (ref) => create(ref as StudentProgressDataRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        studentId: studentId,
        period: period,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<StudentProgressData> createElement() {
    return _StudentProgressDataProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StudentProgressDataProvider &&
        other.studentId == studentId &&
        other.period == period;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);
    hash = _SystemHash.combine(hash, period.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin StudentProgressDataRef
    on AutoDisposeFutureProviderRef<StudentProgressData> {
  /// The parameter `studentId` of this provider.
  String get studentId;

  /// The parameter `period` of this provider.
  AnalyticsPeriod get period;
}

class _StudentProgressDataProviderElement
    extends AutoDisposeFutureProviderElement<StudentProgressData>
    with StudentProgressDataRef {
  _StudentProgressDataProviderElement(super.provider);

  @override
  String get studentId => (origin as StudentProgressDataProvider).studentId;
  @override
  AnalyticsPeriod get period => (origin as StudentProgressDataProvider).period;
}

String _$studentProgressHash() => r'bbe2835a4a7cf0d7ef3ed08422a3508b450e8f61';

/// See also [studentProgress].
@ProviderFor(studentProgress)
const studentProgressProvider = StudentProgressFamily();

/// See also [studentProgress].
class StudentProgressFamily extends Family<AsyncValue<StudentProgress>> {
  /// See also [studentProgress].
  const StudentProgressFamily();

  /// See also [studentProgress].
  StudentProgressProvider call({
    required String studentId,
    required int months,
  }) {
    return StudentProgressProvider(
      studentId: studentId,
      months: months,
    );
  }

  @override
  StudentProgressProvider getProviderOverride(
    covariant StudentProgressProvider provider,
  ) {
    return call(
      studentId: provider.studentId,
      months: provider.months,
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
  String? get name => r'studentProgressProvider';
}

/// See also [studentProgress].
class StudentProgressProvider
    extends AutoDisposeFutureProvider<StudentProgress> {
  /// See also [studentProgress].
  StudentProgressProvider({
    required String studentId,
    required int months,
  }) : this._internal(
          (ref) => studentProgress(
            ref as StudentProgressRef,
            studentId: studentId,
            months: months,
          ),
          from: studentProgressProvider,
          name: r'studentProgressProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$studentProgressHash,
          dependencies: StudentProgressFamily._dependencies,
          allTransitiveDependencies:
              StudentProgressFamily._allTransitiveDependencies,
          studentId: studentId,
          months: months,
        );

  StudentProgressProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.studentId,
    required this.months,
  }) : super.internal();

  final String studentId;
  final int months;

  @override
  Override overrideWith(
    FutureOr<StudentProgress> Function(StudentProgressRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: StudentProgressProvider._internal(
        (ref) => create(ref as StudentProgressRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        studentId: studentId,
        months: months,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<StudentProgress> createElement() {
    return _StudentProgressProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StudentProgressProvider &&
        other.studentId == studentId &&
        other.months == months;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);
    hash = _SystemHash.combine(hash, months.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin StudentProgressRef on AutoDisposeFutureProviderRef<StudentProgress> {
  /// The parameter `studentId` of this provider.
  String get studentId;

  /// The parameter `months` of this provider.
  int get months;
}

class _StudentProgressProviderElement
    extends AutoDisposeFutureProviderElement<StudentProgress>
    with StudentProgressRef {
  _StudentProgressProviderElement(super.provider);

  @override
  String get studentId => (origin as StudentProgressProvider).studentId;
  @override
  int get months => (origin as StudentProgressProvider).months;
}

String _$revenueAnalyticsDataHash() =>
    r'1ea261775f79c87e761d6e341304e0652245ceb5';

/// See also [revenueAnalyticsData].
@ProviderFor(revenueAnalyticsData)
const revenueAnalyticsDataProvider = RevenueAnalyticsDataFamily();

/// See also [revenueAnalyticsData].
class RevenueAnalyticsDataFamily
    extends Family<AsyncValue<RevenueAnalyticsData>> {
  /// See also [revenueAnalyticsData].
  const RevenueAnalyticsDataFamily();

  /// See also [revenueAnalyticsData].
  RevenueAnalyticsDataProvider call(
    int periodMonths,
  ) {
    return RevenueAnalyticsDataProvider(
      periodMonths,
    );
  }

  @override
  RevenueAnalyticsDataProvider getProviderOverride(
    covariant RevenueAnalyticsDataProvider provider,
  ) {
    return call(
      provider.periodMonths,
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
  String? get name => r'revenueAnalyticsDataProvider';
}

/// See also [revenueAnalyticsData].
class RevenueAnalyticsDataProvider
    extends AutoDisposeFutureProvider<RevenueAnalyticsData> {
  /// See also [revenueAnalyticsData].
  RevenueAnalyticsDataProvider(
    int periodMonths,
  ) : this._internal(
          (ref) => revenueAnalyticsData(
            ref as RevenueAnalyticsDataRef,
            periodMonths,
          ),
          from: revenueAnalyticsDataProvider,
          name: r'revenueAnalyticsDataProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$revenueAnalyticsDataHash,
          dependencies: RevenueAnalyticsDataFamily._dependencies,
          allTransitiveDependencies:
              RevenueAnalyticsDataFamily._allTransitiveDependencies,
          periodMonths: periodMonths,
        );

  RevenueAnalyticsDataProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.periodMonths,
  }) : super.internal();

  final int periodMonths;

  @override
  Override overrideWith(
    FutureOr<RevenueAnalyticsData> Function(RevenueAnalyticsDataRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: RevenueAnalyticsDataProvider._internal(
        (ref) => create(ref as RevenueAnalyticsDataRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        periodMonths: periodMonths,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<RevenueAnalyticsData> createElement() {
    return _RevenueAnalyticsDataProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RevenueAnalyticsDataProvider &&
        other.periodMonths == periodMonths;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, periodMonths.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin RevenueAnalyticsDataRef
    on AutoDisposeFutureProviderRef<RevenueAnalyticsData> {
  /// The parameter `periodMonths` of this provider.
  int get periodMonths;
}

class _RevenueAnalyticsDataProviderElement
    extends AutoDisposeFutureProviderElement<RevenueAnalyticsData>
    with RevenueAnalyticsDataRef {
  _RevenueAnalyticsDataProviderElement(super.provider);

  @override
  int get periodMonths => (origin as RevenueAnalyticsDataProvider).periodMonths;
}

String _$revenueAnalyticsHash() => r'2b33437163ed0b7e0e80a01d9f7422abd5e94591';

/// See also [revenueAnalytics].
@ProviderFor(revenueAnalytics)
const revenueAnalyticsProvider = RevenueAnalyticsFamily();

/// See also [revenueAnalytics].
class RevenueAnalyticsFamily extends Family<AsyncValue<RevenueAnalytics>> {
  /// See also [revenueAnalytics].
  const RevenueAnalyticsFamily();

  /// See also [revenueAnalytics].
  RevenueAnalyticsProvider call({
    required int months,
  }) {
    return RevenueAnalyticsProvider(
      months: months,
    );
  }

  @override
  RevenueAnalyticsProvider getProviderOverride(
    covariant RevenueAnalyticsProvider provider,
  ) {
    return call(
      months: provider.months,
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
  String? get name => r'revenueAnalyticsProvider';
}

/// See also [revenueAnalytics].
class RevenueAnalyticsProvider
    extends AutoDisposeFutureProvider<RevenueAnalytics> {
  /// See also [revenueAnalytics].
  RevenueAnalyticsProvider({
    required int months,
  }) : this._internal(
          (ref) => revenueAnalytics(
            ref as RevenueAnalyticsRef,
            months: months,
          ),
          from: revenueAnalyticsProvider,
          name: r'revenueAnalyticsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$revenueAnalyticsHash,
          dependencies: RevenueAnalyticsFamily._dependencies,
          allTransitiveDependencies:
              RevenueAnalyticsFamily._allTransitiveDependencies,
          months: months,
        );

  RevenueAnalyticsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.months,
  }) : super.internal();

  final int months;

  @override
  Override overrideWith(
    FutureOr<RevenueAnalytics> Function(RevenueAnalyticsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: RevenueAnalyticsProvider._internal(
        (ref) => create(ref as RevenueAnalyticsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        months: months,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<RevenueAnalytics> createElement() {
    return _RevenueAnalyticsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RevenueAnalyticsProvider && other.months == months;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, months.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin RevenueAnalyticsRef on AutoDisposeFutureProviderRef<RevenueAnalytics> {
  /// The parameter `months` of this provider.
  int get months;
}

class _RevenueAnalyticsProviderElement
    extends AutoDisposeFutureProviderElement<RevenueAnalytics>
    with RevenueAnalyticsRef {
  _RevenueAnalyticsProviderElement(super.provider);

  @override
  int get months => (origin as RevenueAnalyticsProvider).months;
}

String _$retentionAnalyticsHash() =>
    r'062862fe06e7b4170c3c74c065ea3c225a97c87a';

/// See also [retentionAnalytics].
@ProviderFor(retentionAnalytics)
final retentionAnalyticsProvider =
    AutoDisposeFutureProvider<RetentionAnalyticsData>.internal(
  retentionAnalytics,
  name: r'retentionAnalyticsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$retentionAnalyticsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef RetentionAnalyticsRef
    = AutoDisposeFutureProviderRef<RetentionAnalyticsData>;
String _$studentSummaryListHash() =>
    r'a3ab5038b5b58f659a5c82b436405a709c606a2e';

/// See also [studentSummaryList].
@ProviderFor(studentSummaryList)
const studentSummaryListProvider = StudentSummaryListFamily();

/// See also [studentSummaryList].
class StudentSummaryListFamily
    extends Family<AsyncValue<List<StudentSummaryItem>>> {
  /// See also [studentSummaryList].
  const StudentSummaryListFamily();

  /// See also [studentSummaryList].
  StudentSummaryListProvider call(
    DateTime month,
  ) {
    return StudentSummaryListProvider(
      month,
    );
  }

  @override
  StudentSummaryListProvider getProviderOverride(
    covariant StudentSummaryListProvider provider,
  ) {
    return call(
      provider.month,
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
  String? get name => r'studentSummaryListProvider';
}

/// See also [studentSummaryList].
class StudentSummaryListProvider
    extends AutoDisposeFutureProvider<List<StudentSummaryItem>> {
  /// See also [studentSummaryList].
  StudentSummaryListProvider(
    DateTime month,
  ) : this._internal(
          (ref) => studentSummaryList(
            ref as StudentSummaryListRef,
            month,
          ),
          from: studentSummaryListProvider,
          name: r'studentSummaryListProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$studentSummaryListHash,
          dependencies: StudentSummaryListFamily._dependencies,
          allTransitiveDependencies:
              StudentSummaryListFamily._allTransitiveDependencies,
          month: month,
        );

  StudentSummaryListProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.month,
  }) : super.internal();

  final DateTime month;

  @override
  Override overrideWith(
    FutureOr<List<StudentSummaryItem>> Function(StudentSummaryListRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: StudentSummaryListProvider._internal(
        (ref) => create(ref as StudentSummaryListRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        month: month,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<StudentSummaryItem>> createElement() {
    return _StudentSummaryListProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StudentSummaryListProvider && other.month == month;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, month.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin StudentSummaryListRef
    on AutoDisposeFutureProviderRef<List<StudentSummaryItem>> {
  /// The parameter `month` of this provider.
  DateTime get month;
}

class _StudentSummaryListProviderElement
    extends AutoDisposeFutureProviderElement<List<StudentSummaryItem>>
    with StudentSummaryListRef {
  _StudentSummaryListProviderElement(super.provider);

  @override
  DateTime get month => (origin as StudentSummaryListProvider).month;
}

String _$studentAnalyticsSummaryHash() =>
    r'5b0058b2abba8ac02cb513d8d528a5e183124bef';

/// See also [studentAnalyticsSummary].
@ProviderFor(studentAnalyticsSummary)
const studentAnalyticsSummaryProvider = StudentAnalyticsSummaryFamily();

/// See also [studentAnalyticsSummary].
class StudentAnalyticsSummaryFamily
    extends Family<AsyncValue<StudentAnalyticsSummary>> {
  /// See also [studentAnalyticsSummary].
  const StudentAnalyticsSummaryFamily();

  /// See also [studentAnalyticsSummary].
  StudentAnalyticsSummaryProvider call({
    required String studentId,
  }) {
    return StudentAnalyticsSummaryProvider(
      studentId: studentId,
    );
  }

  @override
  StudentAnalyticsSummaryProvider getProviderOverride(
    covariant StudentAnalyticsSummaryProvider provider,
  ) {
    return call(
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
  String? get name => r'studentAnalyticsSummaryProvider';
}

/// See also [studentAnalyticsSummary].
class StudentAnalyticsSummaryProvider
    extends AutoDisposeFutureProvider<StudentAnalyticsSummary> {
  /// See also [studentAnalyticsSummary].
  StudentAnalyticsSummaryProvider({
    required String studentId,
  }) : this._internal(
          (ref) => studentAnalyticsSummary(
            ref as StudentAnalyticsSummaryRef,
            studentId: studentId,
          ),
          from: studentAnalyticsSummaryProvider,
          name: r'studentAnalyticsSummaryProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$studentAnalyticsSummaryHash,
          dependencies: StudentAnalyticsSummaryFamily._dependencies,
          allTransitiveDependencies:
              StudentAnalyticsSummaryFamily._allTransitiveDependencies,
          studentId: studentId,
        );

  StudentAnalyticsSummaryProvider._internal(
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
    FutureOr<StudentAnalyticsSummary> Function(
            StudentAnalyticsSummaryRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: StudentAnalyticsSummaryProvider._internal(
        (ref) => create(ref as StudentAnalyticsSummaryRef),
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
  AutoDisposeFutureProviderElement<StudentAnalyticsSummary> createElement() {
    return _StudentAnalyticsSummaryProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StudentAnalyticsSummaryProvider &&
        other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin StudentAnalyticsSummaryRef
    on AutoDisposeFutureProviderRef<StudentAnalyticsSummary> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _StudentAnalyticsSummaryProviderElement
    extends AutoDisposeFutureProviderElement<StudentAnalyticsSummary>
    with StudentAnalyticsSummaryRef {
  _StudentAnalyticsSummaryProviderElement(super.provider);

  @override
  String get studentId => (origin as StudentAnalyticsSummaryProvider).studentId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
