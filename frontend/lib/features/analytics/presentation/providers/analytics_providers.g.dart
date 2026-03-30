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
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
