// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'today_practice_minutes_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$todayPracticeMinutesHash() =>
    r'1c4247a99b6909372613e7ef94461f60bd89ab63';

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

/// 오늘 연습 분 — [GrowthHeatmap]과 완전히 동일한 소스에서 파생.
///
/// 새 트래킹 파이프라인을 만들지 않는다: [PracticeRecordingService]
/// (features/practice)가 채우는 heatmap 의 오늘 cell 을 그대로 읽어, 목표
/// 진행바와 성장 히트맵 셀이 항상 같은 숫자를 표시하도록 보장한다.
///
/// Copied from [todayPracticeMinutes].
@ProviderFor(todayPracticeMinutes)
const todayPracticeMinutesProvider = TodayPracticeMinutesFamily();

/// 오늘 연습 분 — [GrowthHeatmap]과 완전히 동일한 소스에서 파생.
///
/// 새 트래킹 파이프라인을 만들지 않는다: [PracticeRecordingService]
/// (features/practice)가 채우는 heatmap 의 오늘 cell 을 그대로 읽어, 목표
/// 진행바와 성장 히트맵 셀이 항상 같은 숫자를 표시하도록 보장한다.
///
/// Copied from [todayPracticeMinutes].
class TodayPracticeMinutesFamily extends Family<AsyncValue<int>> {
  /// 오늘 연습 분 — [GrowthHeatmap]과 완전히 동일한 소스에서 파생.
  ///
  /// 새 트래킹 파이프라인을 만들지 않는다: [PracticeRecordingService]
  /// (features/practice)가 채우는 heatmap 의 오늘 cell 을 그대로 읽어, 목표
  /// 진행바와 성장 히트맵 셀이 항상 같은 숫자를 표시하도록 보장한다.
  ///
  /// Copied from [todayPracticeMinutes].
  const TodayPracticeMinutesFamily();

  /// 오늘 연습 분 — [GrowthHeatmap]과 완전히 동일한 소스에서 파생.
  ///
  /// 새 트래킹 파이프라인을 만들지 않는다: [PracticeRecordingService]
  /// (features/practice)가 채우는 heatmap 의 오늘 cell 을 그대로 읽어, 목표
  /// 진행바와 성장 히트맵 셀이 항상 같은 숫자를 표시하도록 보장한다.
  ///
  /// Copied from [todayPracticeMinutes].
  TodayPracticeMinutesProvider call(
    String studentId,
  ) {
    return TodayPracticeMinutesProvider(
      studentId,
    );
  }

  @override
  TodayPracticeMinutesProvider getProviderOverride(
    covariant TodayPracticeMinutesProvider provider,
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
  String? get name => r'todayPracticeMinutesProvider';
}

/// 오늘 연습 분 — [GrowthHeatmap]과 완전히 동일한 소스에서 파생.
///
/// 새 트래킹 파이프라인을 만들지 않는다: [PracticeRecordingService]
/// (features/practice)가 채우는 heatmap 의 오늘 cell 을 그대로 읽어, 목표
/// 진행바와 성장 히트맵 셀이 항상 같은 숫자를 표시하도록 보장한다.
///
/// Copied from [todayPracticeMinutes].
class TodayPracticeMinutesProvider extends AutoDisposeFutureProvider<int> {
  /// 오늘 연습 분 — [GrowthHeatmap]과 완전히 동일한 소스에서 파생.
  ///
  /// 새 트래킹 파이프라인을 만들지 않는다: [PracticeRecordingService]
  /// (features/practice)가 채우는 heatmap 의 오늘 cell 을 그대로 읽어, 목표
  /// 진행바와 성장 히트맵 셀이 항상 같은 숫자를 표시하도록 보장한다.
  ///
  /// Copied from [todayPracticeMinutes].
  TodayPracticeMinutesProvider(
    String studentId,
  ) : this._internal(
          (ref) => todayPracticeMinutes(
            ref as TodayPracticeMinutesRef,
            studentId,
          ),
          from: todayPracticeMinutesProvider,
          name: r'todayPracticeMinutesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$todayPracticeMinutesHash,
          dependencies: TodayPracticeMinutesFamily._dependencies,
          allTransitiveDependencies:
              TodayPracticeMinutesFamily._allTransitiveDependencies,
          studentId: studentId,
        );

  TodayPracticeMinutesProvider._internal(
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
    FutureOr<int> Function(TodayPracticeMinutesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TodayPracticeMinutesProvider._internal(
        (ref) => create(ref as TodayPracticeMinutesRef),
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
    return _TodayPracticeMinutesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TodayPracticeMinutesProvider &&
        other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin TodayPracticeMinutesRef on AutoDisposeFutureProviderRef<int> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _TodayPracticeMinutesProviderElement
    extends AutoDisposeFutureProviderElement<int> with TodayPracticeMinutesRef {
  _TodayPracticeMinutesProviderElement(super.provider);

  @override
  String get studentId => (origin as TodayPracticeMinutesProvider).studentId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
