// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'leaderboard_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$weeklyClassRankingHash() =>
    r'f4d26324178e5e73e1ef08f08ec1be5ccaa2d657';

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

/// Provides weekly class ranking with mock data.
///
/// Copied from [weeklyClassRanking].
@ProviderFor(weeklyClassRanking)
const weeklyClassRankingProvider = WeeklyClassRankingFamily();

/// Provides weekly class ranking with mock data.
///
/// Copied from [weeklyClassRanking].
class WeeklyClassRankingFamily extends Family<AsyncValue<WeeklyRanking>> {
  /// Provides weekly class ranking with mock data.
  ///
  /// Copied from [weeklyClassRanking].
  const WeeklyClassRankingFamily();

  /// Provides weekly class ranking with mock data.
  ///
  /// Copied from [weeklyClassRanking].
  WeeklyClassRankingProvider call(
    String classId,
  ) {
    return WeeklyClassRankingProvider(
      classId,
    );
  }

  @override
  WeeklyClassRankingProvider getProviderOverride(
    covariant WeeklyClassRankingProvider provider,
  ) {
    return call(
      provider.classId,
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
  String? get name => r'weeklyClassRankingProvider';
}

/// Provides weekly class ranking with mock data.
///
/// Copied from [weeklyClassRanking].
class WeeklyClassRankingProvider
    extends AutoDisposeFutureProvider<WeeklyRanking> {
  /// Provides weekly class ranking with mock data.
  ///
  /// Copied from [weeklyClassRanking].
  WeeklyClassRankingProvider(
    String classId,
  ) : this._internal(
          (ref) => weeklyClassRanking(
            ref as WeeklyClassRankingRef,
            classId,
          ),
          from: weeklyClassRankingProvider,
          name: r'weeklyClassRankingProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$weeklyClassRankingHash,
          dependencies: WeeklyClassRankingFamily._dependencies,
          allTransitiveDependencies:
              WeeklyClassRankingFamily._allTransitiveDependencies,
          classId: classId,
        );

  WeeklyClassRankingProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.classId,
  }) : super.internal();

  final String classId;

  @override
  Override overrideWith(
    FutureOr<WeeklyRanking> Function(WeeklyClassRankingRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: WeeklyClassRankingProvider._internal(
        (ref) => create(ref as WeeklyClassRankingRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        classId: classId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<WeeklyRanking> createElement() {
    return _WeeklyClassRankingProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is WeeklyClassRankingProvider && other.classId == classId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, classId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin WeeklyClassRankingRef on AutoDisposeFutureProviderRef<WeeklyRanking> {
  /// The parameter `classId` of this provider.
  String get classId;
}

class _WeeklyClassRankingProviderElement
    extends AutoDisposeFutureProviderElement<WeeklyRanking>
    with WeeklyClassRankingRef {
  _WeeklyClassRankingProviderElement(super.provider);

  @override
  String get classId => (origin as WeeklyClassRankingProvider).classId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
