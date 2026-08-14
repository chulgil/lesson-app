// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weekly_practice_minutes_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$weeklyPracticeMinutesHash() =>
    r'44d968c7ab45187858ef13be8671144ba85922f9';

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

/// 이번 주(월요일 시작) 연습 분 총합 — [GrowthHeatmap]과 완전히 동일한
/// 소스에서 파생.
///
/// heatmap 의 day key 는 로컬 날짜를 UTC 자정으로 태깅한 값
/// ([GrowthHeatmap] 문서 참조)이므로, 로컬 기준 "이번 주 월요일"을 UTC
/// 자정으로 정규화한 뒤 [GrowthHeatmap.weekTotal]로 조회한다.
///
/// Copied from [weeklyPracticeMinutes].
@ProviderFor(weeklyPracticeMinutes)
const weeklyPracticeMinutesProvider = WeeklyPracticeMinutesFamily();

/// 이번 주(월요일 시작) 연습 분 총합 — [GrowthHeatmap]과 완전히 동일한
/// 소스에서 파생.
///
/// heatmap 의 day key 는 로컬 날짜를 UTC 자정으로 태깅한 값
/// ([GrowthHeatmap] 문서 참조)이므로, 로컬 기준 "이번 주 월요일"을 UTC
/// 자정으로 정규화한 뒤 [GrowthHeatmap.weekTotal]로 조회한다.
///
/// Copied from [weeklyPracticeMinutes].
class WeeklyPracticeMinutesFamily extends Family<AsyncValue<int>> {
  /// 이번 주(월요일 시작) 연습 분 총합 — [GrowthHeatmap]과 완전히 동일한
  /// 소스에서 파생.
  ///
  /// heatmap 의 day key 는 로컬 날짜를 UTC 자정으로 태깅한 값
  /// ([GrowthHeatmap] 문서 참조)이므로, 로컬 기준 "이번 주 월요일"을 UTC
  /// 자정으로 정규화한 뒤 [GrowthHeatmap.weekTotal]로 조회한다.
  ///
  /// Copied from [weeklyPracticeMinutes].
  const WeeklyPracticeMinutesFamily();

  /// 이번 주(월요일 시작) 연습 분 총합 — [GrowthHeatmap]과 완전히 동일한
  /// 소스에서 파생.
  ///
  /// heatmap 의 day key 는 로컬 날짜를 UTC 자정으로 태깅한 값
  /// ([GrowthHeatmap] 문서 참조)이므로, 로컬 기준 "이번 주 월요일"을 UTC
  /// 자정으로 정규화한 뒤 [GrowthHeatmap.weekTotal]로 조회한다.
  ///
  /// Copied from [weeklyPracticeMinutes].
  WeeklyPracticeMinutesProvider call(
    String studentId,
  ) {
    return WeeklyPracticeMinutesProvider(
      studentId,
    );
  }

  @override
  WeeklyPracticeMinutesProvider getProviderOverride(
    covariant WeeklyPracticeMinutesProvider provider,
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
  String? get name => r'weeklyPracticeMinutesProvider';
}

/// 이번 주(월요일 시작) 연습 분 총합 — [GrowthHeatmap]과 완전히 동일한
/// 소스에서 파생.
///
/// heatmap 의 day key 는 로컬 날짜를 UTC 자정으로 태깅한 값
/// ([GrowthHeatmap] 문서 참조)이므로, 로컬 기준 "이번 주 월요일"을 UTC
/// 자정으로 정규화한 뒤 [GrowthHeatmap.weekTotal]로 조회한다.
///
/// Copied from [weeklyPracticeMinutes].
class WeeklyPracticeMinutesProvider extends AutoDisposeFutureProvider<int> {
  /// 이번 주(월요일 시작) 연습 분 총합 — [GrowthHeatmap]과 완전히 동일한
  /// 소스에서 파생.
  ///
  /// heatmap 의 day key 는 로컬 날짜를 UTC 자정으로 태깅한 값
  /// ([GrowthHeatmap] 문서 참조)이므로, 로컬 기준 "이번 주 월요일"을 UTC
  /// 자정으로 정규화한 뒤 [GrowthHeatmap.weekTotal]로 조회한다.
  ///
  /// Copied from [weeklyPracticeMinutes].
  WeeklyPracticeMinutesProvider(
    String studentId,
  ) : this._internal(
          (ref) => weeklyPracticeMinutes(
            ref as WeeklyPracticeMinutesRef,
            studentId,
          ),
          from: weeklyPracticeMinutesProvider,
          name: r'weeklyPracticeMinutesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$weeklyPracticeMinutesHash,
          dependencies: WeeklyPracticeMinutesFamily._dependencies,
          allTransitiveDependencies:
              WeeklyPracticeMinutesFamily._allTransitiveDependencies,
          studentId: studentId,
        );

  WeeklyPracticeMinutesProvider._internal(
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
    FutureOr<int> Function(WeeklyPracticeMinutesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: WeeklyPracticeMinutesProvider._internal(
        (ref) => create(ref as WeeklyPracticeMinutesRef),
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
  AutoDisposeFutureProviderElement<int> createElement() {
    return _WeeklyPracticeMinutesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is WeeklyPracticeMinutesProvider &&
        other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin WeeklyPracticeMinutesRef on AutoDisposeFutureProviderRef<int> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _WeeklyPracticeMinutesProviderElement
    extends AutoDisposeFutureProviderElement<int>
    with WeeklyPracticeMinutesRef {
  _WeeklyPracticeMinutesProviderElement(super.provider);

  @override
  String get studentId => (origin as WeeklyPracticeMinutesProvider).studentId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
