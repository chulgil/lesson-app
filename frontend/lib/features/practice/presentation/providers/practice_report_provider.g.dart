// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'practice_report_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$practiceReportRepositoryHash() =>
    r'b69475cab52effedd3c2f461f2823fed1e8fcc60';

/// Practice stats repository provider - switches between Mock and Remote.
///
/// Copied from [practiceReportRepository].
@ProviderFor(practiceReportRepository)
final practiceReportRepositoryProvider =
    AutoDisposeProvider<PracticeStatsRepository>.internal(
  practiceReportRepository,
  name: r'practiceReportRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$practiceReportRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef PracticeReportRepositoryRef
    = AutoDisposeProviderRef<PracticeStatsRepository>;
String _$weeklyReportHash() => r'b6a9aa81cdb3c4930bdacb0a349c1b367dc988df';

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

/// Weekly report provider
///
/// Copied from [weeklyReport].
@ProviderFor(weeklyReport)
const weeklyReportProvider = WeeklyReportFamily();

/// Weekly report provider
///
/// Copied from [weeklyReport].
class WeeklyReportFamily extends Family<AsyncValue<PracticeStatsReport>> {
  /// Weekly report provider
  ///
  /// Copied from [weeklyReport].
  const WeeklyReportFamily();

  /// Weekly report provider
  ///
  /// Copied from [weeklyReport].
  WeeklyReportProvider call(
    ({String studentId, DateTime weekStart}) params,
  ) {
    return WeeklyReportProvider(
      params,
    );
  }

  @override
  WeeklyReportProvider getProviderOverride(
    covariant WeeklyReportProvider provider,
  ) {
    return call(
      provider.params,
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
  String? get name => r'weeklyReportProvider';
}

/// Weekly report provider
///
/// Copied from [weeklyReport].
class WeeklyReportProvider
    extends AutoDisposeFutureProvider<PracticeStatsReport> {
  /// Weekly report provider
  ///
  /// Copied from [weeklyReport].
  WeeklyReportProvider(
    ({String studentId, DateTime weekStart}) params,
  ) : this._internal(
          (ref) => weeklyReport(
            ref as WeeklyReportRef,
            params,
          ),
          from: weeklyReportProvider,
          name: r'weeklyReportProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$weeklyReportHash,
          dependencies: WeeklyReportFamily._dependencies,
          allTransitiveDependencies:
              WeeklyReportFamily._allTransitiveDependencies,
          params: params,
        );

  WeeklyReportProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.params,
  }) : super.internal();

  final ({String studentId, DateTime weekStart}) params;

  @override
  Override overrideWith(
    FutureOr<PracticeStatsReport> Function(WeeklyReportRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: WeeklyReportProvider._internal(
        (ref) => create(ref as WeeklyReportRef),
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
  AutoDisposeFutureProviderElement<PracticeStatsReport> createElement() {
    return _WeeklyReportProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is WeeklyReportProvider && other.params == params;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, params.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin WeeklyReportRef on AutoDisposeFutureProviderRef<PracticeStatsReport> {
  /// The parameter `params` of this provider.
  ({String studentId, DateTime weekStart}) get params;
}

class _WeeklyReportProviderElement
    extends AutoDisposeFutureProviderElement<PracticeStatsReport>
    with WeeklyReportRef {
  _WeeklyReportProviderElement(super.provider);

  @override
  ({String studentId, DateTime weekStart}) get params =>
      (origin as WeeklyReportProvider).params;
}

String _$monthlyReportHash() => r'87e7c162bac5f5e3856e04fcf9192956697bde73';

/// Monthly report provider
///
/// Copied from [monthlyReport].
@ProviderFor(monthlyReport)
const monthlyReportProvider = MonthlyReportFamily();

/// Monthly report provider
///
/// Copied from [monthlyReport].
class MonthlyReportFamily extends Family<AsyncValue<PracticeStatsReport>> {
  /// Monthly report provider
  ///
  /// Copied from [monthlyReport].
  const MonthlyReportFamily();

  /// Monthly report provider
  ///
  /// Copied from [monthlyReport].
  MonthlyReportProvider call(
    ({int month, String studentId, int year}) params,
  ) {
    return MonthlyReportProvider(
      params,
    );
  }

  @override
  MonthlyReportProvider getProviderOverride(
    covariant MonthlyReportProvider provider,
  ) {
    return call(
      provider.params,
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
  String? get name => r'monthlyReportProvider';
}

/// Monthly report provider
///
/// Copied from [monthlyReport].
class MonthlyReportProvider
    extends AutoDisposeFutureProvider<PracticeStatsReport> {
  /// Monthly report provider
  ///
  /// Copied from [monthlyReport].
  MonthlyReportProvider(
    ({int month, String studentId, int year}) params,
  ) : this._internal(
          (ref) => monthlyReport(
            ref as MonthlyReportRef,
            params,
          ),
          from: monthlyReportProvider,
          name: r'monthlyReportProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$monthlyReportHash,
          dependencies: MonthlyReportFamily._dependencies,
          allTransitiveDependencies:
              MonthlyReportFamily._allTransitiveDependencies,
          params: params,
        );

  MonthlyReportProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.params,
  }) : super.internal();

  final ({int month, String studentId, int year}) params;

  @override
  Override overrideWith(
    FutureOr<PracticeStatsReport> Function(MonthlyReportRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: MonthlyReportProvider._internal(
        (ref) => create(ref as MonthlyReportRef),
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
  AutoDisposeFutureProviderElement<PracticeStatsReport> createElement() {
    return _MonthlyReportProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MonthlyReportProvider && other.params == params;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, params.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin MonthlyReportRef on AutoDisposeFutureProviderRef<PracticeStatsReport> {
  /// The parameter `params` of this provider.
  ({int month, String studentId, int year}) get params;
}

class _MonthlyReportProviderElement
    extends AutoDisposeFutureProviderElement<PracticeStatsReport>
    with MonthlyReportRef {
  _MonthlyReportProviderElement(super.provider);

  @override
  ({int month, String studentId, int year}) get params =>
      (origin as MonthlyReportProvider).params;
}

String _$currentWeekStartHash() => r'9e488f860130f76858ff21477f22c698e3155932';

/// Current week start date provider
///
/// Copied from [currentWeekStart].
@ProviderFor(currentWeekStart)
final currentWeekStartProvider = AutoDisposeProvider<DateTime>.internal(
  currentWeekStart,
  name: r'currentWeekStartProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentWeekStartHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef CurrentWeekStartRef = AutoDisposeProviderRef<DateTime>;
String _$currentMonthHash() => r'bb55728ea5d1da50879494da35baed217f61fac3';

/// Current month provider
///
/// Copied from [currentMonth].
@ProviderFor(currentMonth)
final currentMonthProvider =
    AutoDisposeProvider<({int year, int month})>.internal(
  currentMonth,
  name: r'currentMonthProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$currentMonthHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef CurrentMonthRef = AutoDisposeProviderRef<({int year, int month})>;
String _$practiceReportCalculatorHash() =>
    r'0afb160d88ca577526389f6f214314dbd04529e5';

/// Calculator provider (pure, no I/O).
///
/// Copied from [practiceReportCalculator].
@ProviderFor(practiceReportCalculator)
final practiceReportCalculatorProvider =
    AutoDisposeProvider<PracticeReportCalculator>.internal(
  practiceReportCalculator,
  name: r'practiceReportCalculatorProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$practiceReportCalculatorHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef PracticeReportCalculatorRef
    = AutoDisposeProviderRef<PracticeReportCalculator>;
String _$practiceWeeklyReportHash() =>
    r'd0a685a234d9c00c03815b9310482ad691e48964';

/// Weekly practice report (new entity, §5.2).
///
/// Copied from [practiceWeeklyReport].
@ProviderFor(practiceWeeklyReport)
const practiceWeeklyReportProvider = PracticeWeeklyReportFamily();

/// Weekly practice report (new entity, §5.2).
///
/// Copied from [practiceWeeklyReport].
class PracticeWeeklyReportFamily extends Family<AsyncValue<WeeklyReport>> {
  /// Weekly practice report (new entity, §5.2).
  ///
  /// Copied from [practiceWeeklyReport].
  const PracticeWeeklyReportFamily();

  /// Weekly practice report (new entity, §5.2).
  ///
  /// Copied from [practiceWeeklyReport].
  PracticeWeeklyReportProvider call(
    ({String studentId, DateTime weekStart}) params,
  ) {
    return PracticeWeeklyReportProvider(
      params,
    );
  }

  @override
  PracticeWeeklyReportProvider getProviderOverride(
    covariant PracticeWeeklyReportProvider provider,
  ) {
    return call(
      provider.params,
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
  String? get name => r'practiceWeeklyReportProvider';
}

/// Weekly practice report (new entity, §5.2).
///
/// Copied from [practiceWeeklyReport].
class PracticeWeeklyReportProvider
    extends AutoDisposeFutureProvider<WeeklyReport> {
  /// Weekly practice report (new entity, §5.2).
  ///
  /// Copied from [practiceWeeklyReport].
  PracticeWeeklyReportProvider(
    ({String studentId, DateTime weekStart}) params,
  ) : this._internal(
          (ref) => practiceWeeklyReport(
            ref as PracticeWeeklyReportRef,
            params,
          ),
          from: practiceWeeklyReportProvider,
          name: r'practiceWeeklyReportProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$practiceWeeklyReportHash,
          dependencies: PracticeWeeklyReportFamily._dependencies,
          allTransitiveDependencies:
              PracticeWeeklyReportFamily._allTransitiveDependencies,
          params: params,
        );

  PracticeWeeklyReportProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.params,
  }) : super.internal();

  final ({String studentId, DateTime weekStart}) params;

  @override
  Override overrideWith(
    FutureOr<WeeklyReport> Function(PracticeWeeklyReportRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PracticeWeeklyReportProvider._internal(
        (ref) => create(ref as PracticeWeeklyReportRef),
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
  AutoDisposeFutureProviderElement<WeeklyReport> createElement() {
    return _PracticeWeeklyReportProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PracticeWeeklyReportProvider && other.params == params;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, params.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin PracticeWeeklyReportRef on AutoDisposeFutureProviderRef<WeeklyReport> {
  /// The parameter `params` of this provider.
  ({String studentId, DateTime weekStart}) get params;
}

class _PracticeWeeklyReportProviderElement
    extends AutoDisposeFutureProviderElement<WeeklyReport>
    with PracticeWeeklyReportRef {
  _PracticeWeeklyReportProviderElement(super.provider);

  @override
  ({String studentId, DateTime weekStart}) get params =>
      (origin as PracticeWeeklyReportProvider).params;
}

String _$practiceMonthlyReportHash() =>
    r'5e8e080155b2cce50cec1f3877eaf1024488e60f';

/// Monthly practice report (new entity, §5.2).
///
/// Copied from [practiceMonthlyReport].
@ProviderFor(practiceMonthlyReport)
const practiceMonthlyReportProvider = PracticeMonthlyReportFamily();

/// Monthly practice report (new entity, §5.2).
///
/// Copied from [practiceMonthlyReport].
class PracticeMonthlyReportFamily extends Family<AsyncValue<MonthlyReport>> {
  /// Monthly practice report (new entity, §5.2).
  ///
  /// Copied from [practiceMonthlyReport].
  const PracticeMonthlyReportFamily();

  /// Monthly practice report (new entity, §5.2).
  ///
  /// Copied from [practiceMonthlyReport].
  PracticeMonthlyReportProvider call(
    ({int month, String studentId, int year}) params,
  ) {
    return PracticeMonthlyReportProvider(
      params,
    );
  }

  @override
  PracticeMonthlyReportProvider getProviderOverride(
    covariant PracticeMonthlyReportProvider provider,
  ) {
    return call(
      provider.params,
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
  String? get name => r'practiceMonthlyReportProvider';
}

/// Monthly practice report (new entity, §5.2).
///
/// Copied from [practiceMonthlyReport].
class PracticeMonthlyReportProvider
    extends AutoDisposeFutureProvider<MonthlyReport> {
  /// Monthly practice report (new entity, §5.2).
  ///
  /// Copied from [practiceMonthlyReport].
  PracticeMonthlyReportProvider(
    ({int month, String studentId, int year}) params,
  ) : this._internal(
          (ref) => practiceMonthlyReport(
            ref as PracticeMonthlyReportRef,
            params,
          ),
          from: practiceMonthlyReportProvider,
          name: r'practiceMonthlyReportProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$practiceMonthlyReportHash,
          dependencies: PracticeMonthlyReportFamily._dependencies,
          allTransitiveDependencies:
              PracticeMonthlyReportFamily._allTransitiveDependencies,
          params: params,
        );

  PracticeMonthlyReportProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.params,
  }) : super.internal();

  final ({int month, String studentId, int year}) params;

  @override
  Override overrideWith(
    FutureOr<MonthlyReport> Function(PracticeMonthlyReportRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PracticeMonthlyReportProvider._internal(
        (ref) => create(ref as PracticeMonthlyReportRef),
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
  AutoDisposeFutureProviderElement<MonthlyReport> createElement() {
    return _PracticeMonthlyReportProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PracticeMonthlyReportProvider && other.params == params;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, params.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin PracticeMonthlyReportRef on AutoDisposeFutureProviderRef<MonthlyReport> {
  /// The parameter `params` of this provider.
  ({int month, String studentId, int year}) get params;
}

class _PracticeMonthlyReportProviderElement
    extends AutoDisposeFutureProviderElement<MonthlyReport>
    with PracticeMonthlyReportRef {
  _PracticeMonthlyReportProviderElement(super.provider);

  @override
  ({int month, String studentId, int year}) get params =>
      (origin as PracticeMonthlyReportProvider).params;
}

String _$reportDateHash() => r'e429f15d1e57e55516df00a4e2f2831a2cf58ae4';

/// Report date state notifier
///
/// Copied from [ReportDate].
@ProviderFor(ReportDate)
final reportDateProvider =
    AutoDisposeNotifierProvider<ReportDate, ReportDateState>.internal(
  ReportDate.new,
  name: r'reportDateProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$reportDateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ReportDate = AutoDisposeNotifier<ReportDateState>;
String _$practiceReportPeriodControllerHash() =>
    r'e47d626c80fc17b934442982ff330dcb2038de3a';

/// Currently selected report period (toggle state on the report screen).
///
/// Copied from [PracticeReportPeriodController].
@ProviderFor(PracticeReportPeriodController)
final practiceReportPeriodControllerProvider = AutoDisposeNotifierProvider<
    PracticeReportPeriodController, PracticeReportPeriod>.internal(
  PracticeReportPeriodController.new,
  name: r'practiceReportPeriodControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$practiceReportPeriodControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$PracticeReportPeriodController
    = AutoDisposeNotifier<PracticeReportPeriod>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
