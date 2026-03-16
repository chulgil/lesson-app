// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'practice_report_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$practiceReportRepositoryHash() =>
    r'f5c08af8e1b0b7404ef6760bbc3507b5dee136df';

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

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
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

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
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

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
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

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
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

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentMonthRef = AutoDisposeProviderRef<({int year, int month})>;
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
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
