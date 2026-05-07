// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'practice_stats_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$monthlyPracticeStatsHash() =>
    r'0202bf3a4807eb9226b0e4140c710618b8340f74';

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

/// Practice stats for selected month
///
/// Copied from [monthlyPracticeStats].
@ProviderFor(monthlyPracticeStats)
const monthlyPracticeStatsProvider = MonthlyPracticeStatsFamily();

/// Practice stats for selected month
///
/// Copied from [monthlyPracticeStats].
class MonthlyPracticeStatsFamily extends Family<AsyncValue<PracticeStats>> {
  /// Practice stats for selected month
  ///
  /// Copied from [monthlyPracticeStats].
  const MonthlyPracticeStatsFamily();

  /// Practice stats for selected month
  ///
  /// Copied from [monthlyPracticeStats].
  MonthlyPracticeStatsProvider call(
    String studentId,
  ) {
    return MonthlyPracticeStatsProvider(
      studentId,
    );
  }

  @override
  MonthlyPracticeStatsProvider getProviderOverride(
    covariant MonthlyPracticeStatsProvider provider,
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
  String? get name => r'monthlyPracticeStatsProvider';
}

/// Practice stats for selected month
///
/// Copied from [monthlyPracticeStats].
class MonthlyPracticeStatsProvider extends FutureProvider<PracticeStats> {
  /// Practice stats for selected month
  ///
  /// Copied from [monthlyPracticeStats].
  MonthlyPracticeStatsProvider(
    String studentId,
  ) : this._internal(
          (ref) => monthlyPracticeStats(
            ref as MonthlyPracticeStatsRef,
            studentId,
          ),
          from: monthlyPracticeStatsProvider,
          name: r'monthlyPracticeStatsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$monthlyPracticeStatsHash,
          dependencies: MonthlyPracticeStatsFamily._dependencies,
          allTransitiveDependencies:
              MonthlyPracticeStatsFamily._allTransitiveDependencies,
          studentId: studentId,
        );

  MonthlyPracticeStatsProvider._internal(
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
    FutureOr<PracticeStats> Function(MonthlyPracticeStatsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: MonthlyPracticeStatsProvider._internal(
        (ref) => create(ref as MonthlyPracticeStatsRef),
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
  FutureProviderElement<PracticeStats> createElement() {
    return _MonthlyPracticeStatsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MonthlyPracticeStatsProvider &&
        other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin MonthlyPracticeStatsRef on FutureProviderRef<PracticeStats> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _MonthlyPracticeStatsProviderElement
    extends FutureProviderElement<PracticeStats> with MonthlyPracticeStatsRef {
  _MonthlyPracticeStatsProviderElement(super.provider);

  @override
  String get studentId => (origin as MonthlyPracticeStatsProvider).studentId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
