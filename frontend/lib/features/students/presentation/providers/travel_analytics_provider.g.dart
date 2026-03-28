// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'travel_analytics_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$monthlyTravelAnalyticsHash() =>
    r'cece0df4582706070ccd6b1aaf89c5d8afed9f29';

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

/// Calculate monthly travel analytics from memberships.
///
/// Estimates based on: travel_time × lessons_per_week × 4 weeks.
///
/// Copied from [monthlyTravelAnalytics].
@ProviderFor(monthlyTravelAnalytics)
const monthlyTravelAnalyticsProvider = MonthlyTravelAnalyticsFamily();

/// Calculate monthly travel analytics from memberships.
///
/// Estimates based on: travel_time × lessons_per_week × 4 weeks.
///
/// Copied from [monthlyTravelAnalytics].
class MonthlyTravelAnalyticsFamily extends Family<AsyncValue<TravelAnalytics>> {
  /// Calculate monthly travel analytics from memberships.
  ///
  /// Estimates based on: travel_time × lessons_per_week × 4 weeks.
  ///
  /// Copied from [monthlyTravelAnalytics].
  const MonthlyTravelAnalyticsFamily();

  /// Calculate monthly travel analytics from memberships.
  ///
  /// Estimates based on: travel_time × lessons_per_week × 4 weeks.
  ///
  /// Copied from [monthlyTravelAnalytics].
  MonthlyTravelAnalyticsProvider call(
    String teacherId,
  ) {
    return MonthlyTravelAnalyticsProvider(
      teacherId,
    );
  }

  @override
  MonthlyTravelAnalyticsProvider getProviderOverride(
    covariant MonthlyTravelAnalyticsProvider provider,
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
  String? get name => r'monthlyTravelAnalyticsProvider';
}

/// Calculate monthly travel analytics from memberships.
///
/// Estimates based on: travel_time × lessons_per_week × 4 weeks.
///
/// Copied from [monthlyTravelAnalytics].
class MonthlyTravelAnalyticsProvider
    extends AutoDisposeFutureProvider<TravelAnalytics> {
  /// Calculate monthly travel analytics from memberships.
  ///
  /// Estimates based on: travel_time × lessons_per_week × 4 weeks.
  ///
  /// Copied from [monthlyTravelAnalytics].
  MonthlyTravelAnalyticsProvider(
    String teacherId,
  ) : this._internal(
          (ref) => monthlyTravelAnalytics(
            ref as MonthlyTravelAnalyticsRef,
            teacherId,
          ),
          from: monthlyTravelAnalyticsProvider,
          name: r'monthlyTravelAnalyticsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$monthlyTravelAnalyticsHash,
          dependencies: MonthlyTravelAnalyticsFamily._dependencies,
          allTransitiveDependencies:
              MonthlyTravelAnalyticsFamily._allTransitiveDependencies,
          teacherId: teacherId,
        );

  MonthlyTravelAnalyticsProvider._internal(
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
    FutureOr<TravelAnalytics> Function(MonthlyTravelAnalyticsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: MonthlyTravelAnalyticsProvider._internal(
        (ref) => create(ref as MonthlyTravelAnalyticsRef),
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
  AutoDisposeFutureProviderElement<TravelAnalytics> createElement() {
    return _MonthlyTravelAnalyticsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MonthlyTravelAnalyticsProvider &&
        other.teacherId == teacherId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, teacherId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin MonthlyTravelAnalyticsRef
    on AutoDisposeFutureProviderRef<TravelAnalytics> {
  /// The parameter `teacherId` of this provider.
  String get teacherId;
}

class _MonthlyTravelAnalyticsProviderElement
    extends AutoDisposeFutureProviderElement<TravelAnalytics>
    with MonthlyTravelAnalyticsRef {
  _MonthlyTravelAnalyticsProviderElement(super.provider);

  @override
  String get teacherId => (origin as MonthlyTravelAnalyticsProvider).teacherId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
