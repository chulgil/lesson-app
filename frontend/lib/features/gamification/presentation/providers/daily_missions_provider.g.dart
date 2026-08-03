// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_missions_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$todayMetronomeMinutesHash() =>
    r'bd6a80a51e1723018fd76c58c2ec85802b57484d';

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

/// 오늘 메트로놈 연습 분 — [todayPracticeMinutesProvider]와 동일 소스
/// ([growthHeatmapProvider]의 오늘 cell)에서 필드만 다르게 읽는다. 새
/// 트래킹 파이프라인 없음.
///
/// Copied from [todayMetronomeMinutes].
@ProviderFor(todayMetronomeMinutes)
const todayMetronomeMinutesProvider = TodayMetronomeMinutesFamily();

/// 오늘 메트로놈 연습 분 — [todayPracticeMinutesProvider]와 동일 소스
/// ([growthHeatmapProvider]의 오늘 cell)에서 필드만 다르게 읽는다. 새
/// 트래킹 파이프라인 없음.
///
/// Copied from [todayMetronomeMinutes].
class TodayMetronomeMinutesFamily extends Family<AsyncValue<int>> {
  /// 오늘 메트로놈 연습 분 — [todayPracticeMinutesProvider]와 동일 소스
  /// ([growthHeatmapProvider]의 오늘 cell)에서 필드만 다르게 읽는다. 새
  /// 트래킹 파이프라인 없음.
  ///
  /// Copied from [todayMetronomeMinutes].
  const TodayMetronomeMinutesFamily();

  /// 오늘 메트로놈 연습 분 — [todayPracticeMinutesProvider]와 동일 소스
  /// ([growthHeatmapProvider]의 오늘 cell)에서 필드만 다르게 읽는다. 새
  /// 트래킹 파이프라인 없음.
  ///
  /// Copied from [todayMetronomeMinutes].
  TodayMetronomeMinutesProvider call(
    String studentId,
  ) {
    return TodayMetronomeMinutesProvider(
      studentId,
    );
  }

  @override
  TodayMetronomeMinutesProvider getProviderOverride(
    covariant TodayMetronomeMinutesProvider provider,
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
  String? get name => r'todayMetronomeMinutesProvider';
}

/// 오늘 메트로놈 연습 분 — [todayPracticeMinutesProvider]와 동일 소스
/// ([growthHeatmapProvider]의 오늘 cell)에서 필드만 다르게 읽는다. 새
/// 트래킹 파이프라인 없음.
///
/// Copied from [todayMetronomeMinutes].
class TodayMetronomeMinutesProvider extends AutoDisposeFutureProvider<int> {
  /// 오늘 메트로놈 연습 분 — [todayPracticeMinutesProvider]와 동일 소스
  /// ([growthHeatmapProvider]의 오늘 cell)에서 필드만 다르게 읽는다. 새
  /// 트래킹 파이프라인 없음.
  ///
  /// Copied from [todayMetronomeMinutes].
  TodayMetronomeMinutesProvider(
    String studentId,
  ) : this._internal(
          (ref) => todayMetronomeMinutes(
            ref as TodayMetronomeMinutesRef,
            studentId,
          ),
          from: todayMetronomeMinutesProvider,
          name: r'todayMetronomeMinutesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$todayMetronomeMinutesHash,
          dependencies: TodayMetronomeMinutesFamily._dependencies,
          allTransitiveDependencies:
              TodayMetronomeMinutesFamily._allTransitiveDependencies,
          studentId: studentId,
        );

  TodayMetronomeMinutesProvider._internal(
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
    FutureOr<int> Function(TodayMetronomeMinutesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TodayMetronomeMinutesProvider._internal(
        (ref) => create(ref as TodayMetronomeMinutesRef),
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
    return _TodayMetronomeMinutesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TodayMetronomeMinutesProvider &&
        other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin TodayMetronomeMinutesRef on AutoDisposeFutureProviderRef<int> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _TodayMetronomeMinutesProviderElement
    extends AutoDisposeFutureProviderElement<int>
    with TodayMetronomeMinutesRef {
  _TodayMetronomeMinutesProviderElement(super.provider);

  @override
  String get studentId => (origin as TodayMetronomeMinutesProvider).studentId;
}

String _$todayTunerMinutesHash() => r'ff7457714969c9c9c41a0a9ff365fe72a1385ec6';

/// 오늘 튜너 연습 분 — 위와 동일 소스.
///
/// Copied from [todayTunerMinutes].
@ProviderFor(todayTunerMinutes)
const todayTunerMinutesProvider = TodayTunerMinutesFamily();

/// 오늘 튜너 연습 분 — 위와 동일 소스.
///
/// Copied from [todayTunerMinutes].
class TodayTunerMinutesFamily extends Family<AsyncValue<int>> {
  /// 오늘 튜너 연습 분 — 위와 동일 소스.
  ///
  /// Copied from [todayTunerMinutes].
  const TodayTunerMinutesFamily();

  /// 오늘 튜너 연습 분 — 위와 동일 소스.
  ///
  /// Copied from [todayTunerMinutes].
  TodayTunerMinutesProvider call(
    String studentId,
  ) {
    return TodayTunerMinutesProvider(
      studentId,
    );
  }

  @override
  TodayTunerMinutesProvider getProviderOverride(
    covariant TodayTunerMinutesProvider provider,
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
  String? get name => r'todayTunerMinutesProvider';
}

/// 오늘 튜너 연습 분 — 위와 동일 소스.
///
/// Copied from [todayTunerMinutes].
class TodayTunerMinutesProvider extends AutoDisposeFutureProvider<int> {
  /// 오늘 튜너 연습 분 — 위와 동일 소스.
  ///
  /// Copied from [todayTunerMinutes].
  TodayTunerMinutesProvider(
    String studentId,
  ) : this._internal(
          (ref) => todayTunerMinutes(
            ref as TodayTunerMinutesRef,
            studentId,
          ),
          from: todayTunerMinutesProvider,
          name: r'todayTunerMinutesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$todayTunerMinutesHash,
          dependencies: TodayTunerMinutesFamily._dependencies,
          allTransitiveDependencies:
              TodayTunerMinutesFamily._allTransitiveDependencies,
          studentId: studentId,
        );

  TodayTunerMinutesProvider._internal(
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
    FutureOr<int> Function(TodayTunerMinutesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TodayTunerMinutesProvider._internal(
        (ref) => create(ref as TodayTunerMinutesRef),
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
    return _TodayTunerMinutesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TodayTunerMinutesProvider && other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin TodayTunerMinutesRef on AutoDisposeFutureProviderRef<int> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _TodayTunerMinutesProviderElement
    extends AutoDisposeFutureProviderElement<int> with TodayTunerMinutesRef {
  _TodayTunerMinutesProviderElement(super.provider);

  @override
  String get studentId => (origin as TodayTunerMinutesProvider).studentId;
}

String _$todayRecordingCountHash() =>
    r'16096d244cbc1f9ff23ed3544bea7d9234453c19';

/// 오늘 녹음 횟수 — 위와 동일 소스. 분이 아니라 횟수([DailyPractice.
/// recordingCount])이므로 target=1(1회 이상)로 소비한다.
///
/// Copied from [todayRecordingCount].
@ProviderFor(todayRecordingCount)
const todayRecordingCountProvider = TodayRecordingCountFamily();

/// 오늘 녹음 횟수 — 위와 동일 소스. 분이 아니라 횟수([DailyPractice.
/// recordingCount])이므로 target=1(1회 이상)로 소비한다.
///
/// Copied from [todayRecordingCount].
class TodayRecordingCountFamily extends Family<AsyncValue<int>> {
  /// 오늘 녹음 횟수 — 위와 동일 소스. 분이 아니라 횟수([DailyPractice.
  /// recordingCount])이므로 target=1(1회 이상)로 소비한다.
  ///
  /// Copied from [todayRecordingCount].
  const TodayRecordingCountFamily();

  /// 오늘 녹음 횟수 — 위와 동일 소스. 분이 아니라 횟수([DailyPractice.
  /// recordingCount])이므로 target=1(1회 이상)로 소비한다.
  ///
  /// Copied from [todayRecordingCount].
  TodayRecordingCountProvider call(
    String studentId,
  ) {
    return TodayRecordingCountProvider(
      studentId,
    );
  }

  @override
  TodayRecordingCountProvider getProviderOverride(
    covariant TodayRecordingCountProvider provider,
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
  String? get name => r'todayRecordingCountProvider';
}

/// 오늘 녹음 횟수 — 위와 동일 소스. 분이 아니라 횟수([DailyPractice.
/// recordingCount])이므로 target=1(1회 이상)로 소비한다.
///
/// Copied from [todayRecordingCount].
class TodayRecordingCountProvider extends AutoDisposeFutureProvider<int> {
  /// 오늘 녹음 횟수 — 위와 동일 소스. 분이 아니라 횟수([DailyPractice.
  /// recordingCount])이므로 target=1(1회 이상)로 소비한다.
  ///
  /// Copied from [todayRecordingCount].
  TodayRecordingCountProvider(
    String studentId,
  ) : this._internal(
          (ref) => todayRecordingCount(
            ref as TodayRecordingCountRef,
            studentId,
          ),
          from: todayRecordingCountProvider,
          name: r'todayRecordingCountProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$todayRecordingCountHash,
          dependencies: TodayRecordingCountFamily._dependencies,
          allTransitiveDependencies:
              TodayRecordingCountFamily._allTransitiveDependencies,
          studentId: studentId,
        );

  TodayRecordingCountProvider._internal(
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
    FutureOr<int> Function(TodayRecordingCountRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TodayRecordingCountProvider._internal(
        (ref) => create(ref as TodayRecordingCountRef),
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
    return _TodayRecordingCountProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TodayRecordingCountProvider && other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin TodayRecordingCountRef on AutoDisposeFutureProviderRef<int> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _TodayRecordingCountProviderElement
    extends AutoDisposeFutureProviderElement<int> with TodayRecordingCountRef {
  _TodayRecordingCountProviderElement(super.provider);

  @override
  String get studentId => (origin as TodayRecordingCountProvider).studentId;
}

String _$dailyMissionsHash() => r'7c3ab9c25b8abce34f25dce6e736bce08ca89e56';

/// 오늘의 미션 3종(고정1+로테이션2) — 로테이션 + 진행값 + 완료 원장을
/// 조합한 최종 표시 데이터.
///
/// [DailyGoalCard]/`daily_practice_goal_provider.dart` 와 동일하게 각 의존
/// provider 를 `.valueOrNull ?? 기본값` 으로 읽는다(watch 는 하되 future 를
/// await 하지 않음) — Hive 기반 provider(목표/원장)의 `.future` 를 그대로
/// await 하면 위젯 테스트의 synthetic time 안에서 실제 파일 I/O 가 끝내
/// resolve 되지 않아 화면이 영원히 loading 에 멈추는 문제가 있었다(회귀
/// 확인됨). sync 조합이면 첫 프레임은 기본값(0진행/기본목표)으로 그리고,
/// 각 provider 가 실제로 resolve 되는 순간 자동 재계산된다.
///
/// Copied from [dailyMissions].
@ProviderFor(dailyMissions)
const dailyMissionsProvider = DailyMissionsFamily();

/// 오늘의 미션 3종(고정1+로테이션2) — 로테이션 + 진행값 + 완료 원장을
/// 조합한 최종 표시 데이터.
///
/// [DailyGoalCard]/`daily_practice_goal_provider.dart` 와 동일하게 각 의존
/// provider 를 `.valueOrNull ?? 기본값` 으로 읽는다(watch 는 하되 future 를
/// await 하지 않음) — Hive 기반 provider(목표/원장)의 `.future` 를 그대로
/// await 하면 위젯 테스트의 synthetic time 안에서 실제 파일 I/O 가 끝내
/// resolve 되지 않아 화면이 영원히 loading 에 멈추는 문제가 있었다(회귀
/// 확인됨). sync 조합이면 첫 프레임은 기본값(0진행/기본목표)으로 그리고,
/// 각 provider 가 실제로 resolve 되는 순간 자동 재계산된다.
///
/// Copied from [dailyMissions].
class DailyMissionsFamily extends Family<List<DailyMission>> {
  /// 오늘의 미션 3종(고정1+로테이션2) — 로테이션 + 진행값 + 완료 원장을
  /// 조합한 최종 표시 데이터.
  ///
  /// [DailyGoalCard]/`daily_practice_goal_provider.dart` 와 동일하게 각 의존
  /// provider 를 `.valueOrNull ?? 기본값` 으로 읽는다(watch 는 하되 future 를
  /// await 하지 않음) — Hive 기반 provider(목표/원장)의 `.future` 를 그대로
  /// await 하면 위젯 테스트의 synthetic time 안에서 실제 파일 I/O 가 끝내
  /// resolve 되지 않아 화면이 영원히 loading 에 멈추는 문제가 있었다(회귀
  /// 확인됨). sync 조합이면 첫 프레임은 기본값(0진행/기본목표)으로 그리고,
  /// 각 provider 가 실제로 resolve 되는 순간 자동 재계산된다.
  ///
  /// Copied from [dailyMissions].
  const DailyMissionsFamily();

  /// 오늘의 미션 3종(고정1+로테이션2) — 로테이션 + 진행값 + 완료 원장을
  /// 조합한 최종 표시 데이터.
  ///
  /// [DailyGoalCard]/`daily_practice_goal_provider.dart` 와 동일하게 각 의존
  /// provider 를 `.valueOrNull ?? 기본값` 으로 읽는다(watch 는 하되 future 를
  /// await 하지 않음) — Hive 기반 provider(목표/원장)의 `.future` 를 그대로
  /// await 하면 위젯 테스트의 synthetic time 안에서 실제 파일 I/O 가 끝내
  /// resolve 되지 않아 화면이 영원히 loading 에 멈추는 문제가 있었다(회귀
  /// 확인됨). sync 조합이면 첫 프레임은 기본값(0진행/기본목표)으로 그리고,
  /// 각 provider 가 실제로 resolve 되는 순간 자동 재계산된다.
  ///
  /// Copied from [dailyMissions].
  DailyMissionsProvider call(
    String studentId,
  ) {
    return DailyMissionsProvider(
      studentId,
    );
  }

  @override
  DailyMissionsProvider getProviderOverride(
    covariant DailyMissionsProvider provider,
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
  String? get name => r'dailyMissionsProvider';
}

/// 오늘의 미션 3종(고정1+로테이션2) — 로테이션 + 진행값 + 완료 원장을
/// 조합한 최종 표시 데이터.
///
/// [DailyGoalCard]/`daily_practice_goal_provider.dart` 와 동일하게 각 의존
/// provider 를 `.valueOrNull ?? 기본값` 으로 읽는다(watch 는 하되 future 를
/// await 하지 않음) — Hive 기반 provider(목표/원장)의 `.future` 를 그대로
/// await 하면 위젯 테스트의 synthetic time 안에서 실제 파일 I/O 가 끝내
/// resolve 되지 않아 화면이 영원히 loading 에 멈추는 문제가 있었다(회귀
/// 확인됨). sync 조합이면 첫 프레임은 기본값(0진행/기본목표)으로 그리고,
/// 각 provider 가 실제로 resolve 되는 순간 자동 재계산된다.
///
/// Copied from [dailyMissions].
class DailyMissionsProvider extends AutoDisposeProvider<List<DailyMission>> {
  /// 오늘의 미션 3종(고정1+로테이션2) — 로테이션 + 진행값 + 완료 원장을
  /// 조합한 최종 표시 데이터.
  ///
  /// [DailyGoalCard]/`daily_practice_goal_provider.dart` 와 동일하게 각 의존
  /// provider 를 `.valueOrNull ?? 기본값` 으로 읽는다(watch 는 하되 future 를
  /// await 하지 않음) — Hive 기반 provider(목표/원장)의 `.future` 를 그대로
  /// await 하면 위젯 테스트의 synthetic time 안에서 실제 파일 I/O 가 끝내
  /// resolve 되지 않아 화면이 영원히 loading 에 멈추는 문제가 있었다(회귀
  /// 확인됨). sync 조합이면 첫 프레임은 기본값(0진행/기본목표)으로 그리고,
  /// 각 provider 가 실제로 resolve 되는 순간 자동 재계산된다.
  ///
  /// Copied from [dailyMissions].
  DailyMissionsProvider(
    String studentId,
  ) : this._internal(
          (ref) => dailyMissions(
            ref as DailyMissionsRef,
            studentId,
          ),
          from: dailyMissionsProvider,
          name: r'dailyMissionsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$dailyMissionsHash,
          dependencies: DailyMissionsFamily._dependencies,
          allTransitiveDependencies:
              DailyMissionsFamily._allTransitiveDependencies,
          studentId: studentId,
        );

  DailyMissionsProvider._internal(
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
    List<DailyMission> Function(DailyMissionsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: DailyMissionsProvider._internal(
        (ref) => create(ref as DailyMissionsRef),
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
  AutoDisposeProviderElement<List<DailyMission>> createElement() {
    return _DailyMissionsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DailyMissionsProvider && other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin DailyMissionsRef on AutoDisposeProviderRef<List<DailyMission>> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _DailyMissionsProviderElement
    extends AutoDisposeProviderElement<List<DailyMission>>
    with DailyMissionsRef {
  _DailyMissionsProviderElement(super.provider);

  @override
  String get studentId => (origin as DailyMissionsProvider).studentId;
}

String _$dailyMissionLedgerHash() =>
    r'd57a0ab59d627bbdcec4bb67ee17160a17636228';

abstract class _$DailyMissionLedger
    extends BuildlessAsyncNotifier<Set<DailyMissionKind>> {
  late final String studentId;
  late final DateTime dateKst;

  FutureOr<Set<DailyMissionKind>> build(
    String studentId,
    DateTime dateKst,
  );
}

/// 데일리 미션 완료 원장 — 로컬 Hive, 멱등 (doc 46 §4④).
///
/// 관측 신호(progress)가 흔들려도(예: [DailyPracticeGoal] 를 상향 조정)
/// 한 번 완료된 미션은 그날(KST) 안에서는 계속 완료 상태를 유지한다 —
/// derived-only 라면 15/15 로 채운 뒤 목표를 30분으로 올리면 이미 채운
/// 스탬프가 되돌아가는 회귀가 생긴다. [DailyGoalCard]/`daily_practice_goal_
/// provider.dart` 와 동일하게 lazy-open Hive box 패턴을 따른다.
///
/// box key = `student:<id>:missions:<dateKey>`, value = 완료된
/// [DailyMissionKind.name] CSV. 쓰기는 [DailyMissionsCard] 가 프레임 이후
/// (post-frame) 시점에 호출한다 — provider build 도중 자기 자신이 아닌
/// 다른 provider 를 동기적으로 mutate 하는 패턴을 피하기 위함.
///
/// Copied from [DailyMissionLedger].
@ProviderFor(DailyMissionLedger)
const dailyMissionLedgerProvider = DailyMissionLedgerFamily();

/// 데일리 미션 완료 원장 — 로컬 Hive, 멱등 (doc 46 §4④).
///
/// 관측 신호(progress)가 흔들려도(예: [DailyPracticeGoal] 를 상향 조정)
/// 한 번 완료된 미션은 그날(KST) 안에서는 계속 완료 상태를 유지한다 —
/// derived-only 라면 15/15 로 채운 뒤 목표를 30분으로 올리면 이미 채운
/// 스탬프가 되돌아가는 회귀가 생긴다. [DailyGoalCard]/`daily_practice_goal_
/// provider.dart` 와 동일하게 lazy-open Hive box 패턴을 따른다.
///
/// box key = `student:<id>:missions:<dateKey>`, value = 완료된
/// [DailyMissionKind.name] CSV. 쓰기는 [DailyMissionsCard] 가 프레임 이후
/// (post-frame) 시점에 호출한다 — provider build 도중 자기 자신이 아닌
/// 다른 provider 를 동기적으로 mutate 하는 패턴을 피하기 위함.
///
/// Copied from [DailyMissionLedger].
class DailyMissionLedgerFamily
    extends Family<AsyncValue<Set<DailyMissionKind>>> {
  /// 데일리 미션 완료 원장 — 로컬 Hive, 멱등 (doc 46 §4④).
  ///
  /// 관측 신호(progress)가 흔들려도(예: [DailyPracticeGoal] 를 상향 조정)
  /// 한 번 완료된 미션은 그날(KST) 안에서는 계속 완료 상태를 유지한다 —
  /// derived-only 라면 15/15 로 채운 뒤 목표를 30분으로 올리면 이미 채운
  /// 스탬프가 되돌아가는 회귀가 생긴다. [DailyGoalCard]/`daily_practice_goal_
  /// provider.dart` 와 동일하게 lazy-open Hive box 패턴을 따른다.
  ///
  /// box key = `student:<id>:missions:<dateKey>`, value = 완료된
  /// [DailyMissionKind.name] CSV. 쓰기는 [DailyMissionsCard] 가 프레임 이후
  /// (post-frame) 시점에 호출한다 — provider build 도중 자기 자신이 아닌
  /// 다른 provider 를 동기적으로 mutate 하는 패턴을 피하기 위함.
  ///
  /// Copied from [DailyMissionLedger].
  const DailyMissionLedgerFamily();

  /// 데일리 미션 완료 원장 — 로컬 Hive, 멱등 (doc 46 §4④).
  ///
  /// 관측 신호(progress)가 흔들려도(예: [DailyPracticeGoal] 를 상향 조정)
  /// 한 번 완료된 미션은 그날(KST) 안에서는 계속 완료 상태를 유지한다 —
  /// derived-only 라면 15/15 로 채운 뒤 목표를 30분으로 올리면 이미 채운
  /// 스탬프가 되돌아가는 회귀가 생긴다. [DailyGoalCard]/`daily_practice_goal_
  /// provider.dart` 와 동일하게 lazy-open Hive box 패턴을 따른다.
  ///
  /// box key = `student:<id>:missions:<dateKey>`, value = 완료된
  /// [DailyMissionKind.name] CSV. 쓰기는 [DailyMissionsCard] 가 프레임 이후
  /// (post-frame) 시점에 호출한다 — provider build 도중 자기 자신이 아닌
  /// 다른 provider 를 동기적으로 mutate 하는 패턴을 피하기 위함.
  ///
  /// Copied from [DailyMissionLedger].
  DailyMissionLedgerProvider call(
    String studentId,
    DateTime dateKst,
  ) {
    return DailyMissionLedgerProvider(
      studentId,
      dateKst,
    );
  }

  @override
  DailyMissionLedgerProvider getProviderOverride(
    covariant DailyMissionLedgerProvider provider,
  ) {
    return call(
      provider.studentId,
      provider.dateKst,
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
  String? get name => r'dailyMissionLedgerProvider';
}

/// 데일리 미션 완료 원장 — 로컬 Hive, 멱등 (doc 46 §4④).
///
/// 관측 신호(progress)가 흔들려도(예: [DailyPracticeGoal] 를 상향 조정)
/// 한 번 완료된 미션은 그날(KST) 안에서는 계속 완료 상태를 유지한다 —
/// derived-only 라면 15/15 로 채운 뒤 목표를 30분으로 올리면 이미 채운
/// 스탬프가 되돌아가는 회귀가 생긴다. [DailyGoalCard]/`daily_practice_goal_
/// provider.dart` 와 동일하게 lazy-open Hive box 패턴을 따른다.
///
/// box key = `student:<id>:missions:<dateKey>`, value = 완료된
/// [DailyMissionKind.name] CSV. 쓰기는 [DailyMissionsCard] 가 프레임 이후
/// (post-frame) 시점에 호출한다 — provider build 도중 자기 자신이 아닌
/// 다른 provider 를 동기적으로 mutate 하는 패턴을 피하기 위함.
///
/// Copied from [DailyMissionLedger].
class DailyMissionLedgerProvider extends AsyncNotifierProviderImpl<
    DailyMissionLedger, Set<DailyMissionKind>> {
  /// 데일리 미션 완료 원장 — 로컬 Hive, 멱등 (doc 46 §4④).
  ///
  /// 관측 신호(progress)가 흔들려도(예: [DailyPracticeGoal] 를 상향 조정)
  /// 한 번 완료된 미션은 그날(KST) 안에서는 계속 완료 상태를 유지한다 —
  /// derived-only 라면 15/15 로 채운 뒤 목표를 30분으로 올리면 이미 채운
  /// 스탬프가 되돌아가는 회귀가 생긴다. [DailyGoalCard]/`daily_practice_goal_
  /// provider.dart` 와 동일하게 lazy-open Hive box 패턴을 따른다.
  ///
  /// box key = `student:<id>:missions:<dateKey>`, value = 완료된
  /// [DailyMissionKind.name] CSV. 쓰기는 [DailyMissionsCard] 가 프레임 이후
  /// (post-frame) 시점에 호출한다 — provider build 도중 자기 자신이 아닌
  /// 다른 provider 를 동기적으로 mutate 하는 패턴을 피하기 위함.
  ///
  /// Copied from [DailyMissionLedger].
  DailyMissionLedgerProvider(
    String studentId,
    DateTime dateKst,
  ) : this._internal(
          () => DailyMissionLedger()
            ..studentId = studentId
            ..dateKst = dateKst,
          from: dailyMissionLedgerProvider,
          name: r'dailyMissionLedgerProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$dailyMissionLedgerHash,
          dependencies: DailyMissionLedgerFamily._dependencies,
          allTransitiveDependencies:
              DailyMissionLedgerFamily._allTransitiveDependencies,
          studentId: studentId,
          dateKst: dateKst,
        );

  DailyMissionLedgerProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.studentId,
    required this.dateKst,
  }) : super.internal();

  final String studentId;
  final DateTime dateKst;

  @override
  FutureOr<Set<DailyMissionKind>> runNotifierBuild(
    covariant DailyMissionLedger notifier,
  ) {
    return notifier.build(
      studentId,
      dateKst,
    );
  }

  @override
  Override overrideWith(DailyMissionLedger Function() create) {
    return ProviderOverride(
      origin: this,
      override: DailyMissionLedgerProvider._internal(
        () => create()
          ..studentId = studentId
          ..dateKst = dateKst,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        studentId: studentId,
        dateKst: dateKst,
      ),
    );
  }

  @override
  AsyncNotifierProviderElement<DailyMissionLedger, Set<DailyMissionKind>>
      createElement() {
    return _DailyMissionLedgerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DailyMissionLedgerProvider &&
        other.studentId == studentId &&
        other.dateKst == dateKst;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);
    hash = _SystemHash.combine(hash, dateKst.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin DailyMissionLedgerRef on AsyncNotifierProviderRef<Set<DailyMissionKind>> {
  /// The parameter `studentId` of this provider.
  String get studentId;

  /// The parameter `dateKst` of this provider.
  DateTime get dateKst;
}

class _DailyMissionLedgerProviderElement extends AsyncNotifierProviderElement<
    DailyMissionLedger, Set<DailyMissionKind>> with DailyMissionLedgerRef {
  _DailyMissionLedgerProviderElement(super.provider);

  @override
  String get studentId => (origin as DailyMissionLedgerProvider).studentId;
  @override
  DateTime get dateKst => (origin as DailyMissionLedgerProvider).dateKst;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
