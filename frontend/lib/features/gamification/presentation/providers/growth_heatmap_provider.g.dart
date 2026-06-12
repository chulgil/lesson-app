// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'growth_heatmap_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$growthHeatmapRepositoryHash() =>
    r'1fcaafc095001bb4b8bcaa4c0805d9014833dbf3';

/// P1: Mock 만 사용. P2 에서 BE 구현체 도입 시 환경 분기 추가 (O1 결정).
///
/// Copied from [growthHeatmapRepository].
@ProviderFor(growthHeatmapRepository)
final growthHeatmapRepositoryProvider =
    Provider<GrowthHeatmapRepository>.internal(
  growthHeatmapRepository,
  name: r'growthHeatmapRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$growthHeatmapRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef GrowthHeatmapRepositoryRef = ProviderRef<GrowthHeatmapRepository>;
String _$growthHeatmapHash() => r'f3158a2b05b56caefc1dc36fd2bb48d7446b2e35';

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

/// See also [growthHeatmap].
@ProviderFor(growthHeatmap)
const growthHeatmapProvider = GrowthHeatmapFamily();

/// See also [growthHeatmap].
class GrowthHeatmapFamily extends Family<AsyncValue<GrowthHeatmap>> {
  /// See also [growthHeatmap].
  const GrowthHeatmapFamily();

  /// See also [growthHeatmap].
  GrowthHeatmapProvider call(
    String studentId, {
    int yearsBack = 1,
  }) {
    return GrowthHeatmapProvider(
      studentId,
      yearsBack: yearsBack,
    );
  }

  @override
  GrowthHeatmapProvider getProviderOverride(
    covariant GrowthHeatmapProvider provider,
  ) {
    return call(
      provider.studentId,
      yearsBack: provider.yearsBack,
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
  String? get name => r'growthHeatmapProvider';
}

/// See also [growthHeatmap].
class GrowthHeatmapProvider extends AutoDisposeFutureProvider<GrowthHeatmap> {
  /// See also [growthHeatmap].
  GrowthHeatmapProvider(
    String studentId, {
    int yearsBack = 1,
  }) : this._internal(
          (ref) => growthHeatmap(
            ref as GrowthHeatmapRef,
            studentId,
            yearsBack: yearsBack,
          ),
          from: growthHeatmapProvider,
          name: r'growthHeatmapProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$growthHeatmapHash,
          dependencies: GrowthHeatmapFamily._dependencies,
          allTransitiveDependencies:
              GrowthHeatmapFamily._allTransitiveDependencies,
          studentId: studentId,
          yearsBack: yearsBack,
        );

  GrowthHeatmapProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.studentId,
    required this.yearsBack,
  }) : super.internal();

  final String studentId;
  final int yearsBack;

  @override
  Override overrideWith(
    FutureOr<GrowthHeatmap> Function(GrowthHeatmapRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: GrowthHeatmapProvider._internal(
        (ref) => create(ref as GrowthHeatmapRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        studentId: studentId,
        yearsBack: yearsBack,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<GrowthHeatmap> createElement() {
    return _GrowthHeatmapProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GrowthHeatmapProvider &&
        other.studentId == studentId &&
        other.yearsBack == yearsBack;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);
    hash = _SystemHash.combine(hash, yearsBack.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin GrowthHeatmapRef on AutoDisposeFutureProviderRef<GrowthHeatmap> {
  /// The parameter `studentId` of this provider.
  String get studentId;

  /// The parameter `yearsBack` of this provider.
  int get yearsBack;
}

class _GrowthHeatmapProviderElement
    extends AutoDisposeFutureProviderElement<GrowthHeatmap>
    with GrowthHeatmapRef {
  _GrowthHeatmapProviderElement(super.provider);

  @override
  String get studentId => (origin as GrowthHeatmapProvider).studentId;
  @override
  int get yearsBack => (origin as GrowthHeatmapProvider).yearsBack;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
