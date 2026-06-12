// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'spotlight_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$spotlightPromptRepositoryHash() =>
    r'90b4fdfd3866d309f4a288d80ccb52e5a81c51d9';

/// P3: Mock 우선 (P1/P2 패턴 일관). Hive 운영 통합은 Job 7/Job 9 단계에서 분기.
///
/// Copied from [spotlightPromptRepository].
@ProviderFor(spotlightPromptRepository)
final spotlightPromptRepositoryProvider =
    Provider<SpotlightPromptRepository>.internal(
  spotlightPromptRepository,
  name: r'spotlightPromptRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$spotlightPromptRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef SpotlightPromptRepositoryRef = ProviderRef<SpotlightPromptRepository>;
String _$spotlightEligibilityServiceHash() =>
    r'cc6e809559e4779bc6da3612a9b48d959b79aa01';

/// See also [spotlightEligibilityService].
@ProviderFor(spotlightEligibilityService)
final spotlightEligibilityServiceProvider =
    Provider<SpotlightEligibilityService>.internal(
  spotlightEligibilityService,
  name: r'spotlightEligibilityServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$spotlightEligibilityServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef SpotlightEligibilityServiceRef
    = ProviderRef<SpotlightEligibilityService>;
String _$spotlightQueueServiceHash() =>
    r'55026cf4396aecaf06714252ae6e5d9f352afce2';

/// See also [spotlightQueueService].
@ProviderFor(spotlightQueueService)
final spotlightQueueServiceProvider = Provider<SpotlightQueueService>.internal(
  spotlightQueueService,
  name: r'spotlightQueueServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$spotlightQueueServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef SpotlightQueueServiceRef = ProviderRef<SpotlightQueueService>;
String _$spotlightDeclineLearningServiceHash() =>
    r'07f8c2413608b9b0aee676b6836f471a12d8d851';

/// See also [spotlightDeclineLearningService].
@ProviderFor(spotlightDeclineLearningService)
final spotlightDeclineLearningServiceProvider =
    Provider<SpotlightDeclineLearningService>.internal(
  spotlightDeclineLearningService,
  name: r'spotlightDeclineLearningServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$spotlightDeclineLearningServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef SpotlightDeclineLearningServiceRef
    = ProviderRef<SpotlightDeclineLearningService>;
String _$currentSpotlightForCelebrationHash() =>
    r'b47c1ff4297b919bb61af26b0561f3ccf9bf115c';

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

/// 축하 overlay 에 노출할 다음 prompt 평가.
///
/// 흐름:
/// 1. Queue.nextPromptableFor(studentId, now) — promptable 있는지 + 정렬된 후보
/// 2. lastShownAt 분포로 promptsShownToday / promptsShownThisWeek 도출
///    (월요일 시작, KST 기준)
/// 3. Eligibility.evaluate(ctx) — 6 조건 평가
/// 4. eligible → 후보 반환 / 아니면 null
///
/// Copied from [currentSpotlightForCelebration].
@ProviderFor(currentSpotlightForCelebration)
const currentSpotlightForCelebrationProvider =
    CurrentSpotlightForCelebrationFamily();

/// 축하 overlay 에 노출할 다음 prompt 평가.
///
/// 흐름:
/// 1. Queue.nextPromptableFor(studentId, now) — promptable 있는지 + 정렬된 후보
/// 2. lastShownAt 분포로 promptsShownToday / promptsShownThisWeek 도출
///    (월요일 시작, KST 기준)
/// 3. Eligibility.evaluate(ctx) — 6 조건 평가
/// 4. eligible → 후보 반환 / 아니면 null
///
/// Copied from [currentSpotlightForCelebration].
class CurrentSpotlightForCelebrationFamily
    extends Family<AsyncValue<SpotlightPrompt?>> {
  /// 축하 overlay 에 노출할 다음 prompt 평가.
  ///
  /// 흐름:
  /// 1. Queue.nextPromptableFor(studentId, now) — promptable 있는지 + 정렬된 후보
  /// 2. lastShownAt 분포로 promptsShownToday / promptsShownThisWeek 도출
  ///    (월요일 시작, KST 기준)
  /// 3. Eligibility.evaluate(ctx) — 6 조건 평가
  /// 4. eligible → 후보 반환 / 아니면 null
  ///
  /// Copied from [currentSpotlightForCelebration].
  const CurrentSpotlightForCelebrationFamily();

  /// 축하 overlay 에 노출할 다음 prompt 평가.
  ///
  /// 흐름:
  /// 1. Queue.nextPromptableFor(studentId, now) — promptable 있는지 + 정렬된 후보
  /// 2. lastShownAt 분포로 promptsShownToday / promptsShownThisWeek 도출
  ///    (월요일 시작, KST 기준)
  /// 3. Eligibility.evaluate(ctx) — 6 조건 평가
  /// 4. eligible → 후보 반환 / 아니면 null
  ///
  /// Copied from [currentSpotlightForCelebration].
  CurrentSpotlightForCelebrationProvider call(
    String studentId, {
    required Duration sessionDuration,
    required DateTime now,
    required bool studentIsUnder14,
    required bool studentHasParentConsent,
  }) {
    return CurrentSpotlightForCelebrationProvider(
      studentId,
      sessionDuration: sessionDuration,
      now: now,
      studentIsUnder14: studentIsUnder14,
      studentHasParentConsent: studentHasParentConsent,
    );
  }

  @override
  CurrentSpotlightForCelebrationProvider getProviderOverride(
    covariant CurrentSpotlightForCelebrationProvider provider,
  ) {
    return call(
      provider.studentId,
      sessionDuration: provider.sessionDuration,
      now: provider.now,
      studentIsUnder14: provider.studentIsUnder14,
      studentHasParentConsent: provider.studentHasParentConsent,
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
  String? get name => r'currentSpotlightForCelebrationProvider';
}

/// 축하 overlay 에 노출할 다음 prompt 평가.
///
/// 흐름:
/// 1. Queue.nextPromptableFor(studentId, now) — promptable 있는지 + 정렬된 후보
/// 2. lastShownAt 분포로 promptsShownToday / promptsShownThisWeek 도출
///    (월요일 시작, KST 기준)
/// 3. Eligibility.evaluate(ctx) — 6 조건 평가
/// 4. eligible → 후보 반환 / 아니면 null
///
/// Copied from [currentSpotlightForCelebration].
class CurrentSpotlightForCelebrationProvider
    extends AutoDisposeFutureProvider<SpotlightPrompt?> {
  /// 축하 overlay 에 노출할 다음 prompt 평가.
  ///
  /// 흐름:
  /// 1. Queue.nextPromptableFor(studentId, now) — promptable 있는지 + 정렬된 후보
  /// 2. lastShownAt 분포로 promptsShownToday / promptsShownThisWeek 도출
  ///    (월요일 시작, KST 기준)
  /// 3. Eligibility.evaluate(ctx) — 6 조건 평가
  /// 4. eligible → 후보 반환 / 아니면 null
  ///
  /// Copied from [currentSpotlightForCelebration].
  CurrentSpotlightForCelebrationProvider(
    String studentId, {
    required Duration sessionDuration,
    required DateTime now,
    required bool studentIsUnder14,
    required bool studentHasParentConsent,
  }) : this._internal(
          (ref) => currentSpotlightForCelebration(
            ref as CurrentSpotlightForCelebrationRef,
            studentId,
            sessionDuration: sessionDuration,
            now: now,
            studentIsUnder14: studentIsUnder14,
            studentHasParentConsent: studentHasParentConsent,
          ),
          from: currentSpotlightForCelebrationProvider,
          name: r'currentSpotlightForCelebrationProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$currentSpotlightForCelebrationHash,
          dependencies: CurrentSpotlightForCelebrationFamily._dependencies,
          allTransitiveDependencies:
              CurrentSpotlightForCelebrationFamily._allTransitiveDependencies,
          studentId: studentId,
          sessionDuration: sessionDuration,
          now: now,
          studentIsUnder14: studentIsUnder14,
          studentHasParentConsent: studentHasParentConsent,
        );

  CurrentSpotlightForCelebrationProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.studentId,
    required this.sessionDuration,
    required this.now,
    required this.studentIsUnder14,
    required this.studentHasParentConsent,
  }) : super.internal();

  final String studentId;
  final Duration sessionDuration;
  final DateTime now;
  final bool studentIsUnder14;
  final bool studentHasParentConsent;

  @override
  Override overrideWith(
    FutureOr<SpotlightPrompt?> Function(
            CurrentSpotlightForCelebrationRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CurrentSpotlightForCelebrationProvider._internal(
        (ref) => create(ref as CurrentSpotlightForCelebrationRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        studentId: studentId,
        sessionDuration: sessionDuration,
        now: now,
        studentIsUnder14: studentIsUnder14,
        studentHasParentConsent: studentHasParentConsent,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<SpotlightPrompt?> createElement() {
    return _CurrentSpotlightForCelebrationProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CurrentSpotlightForCelebrationProvider &&
        other.studentId == studentId &&
        other.sessionDuration == sessionDuration &&
        other.now == now &&
        other.studentIsUnder14 == studentIsUnder14 &&
        other.studentHasParentConsent == studentHasParentConsent;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);
    hash = _SystemHash.combine(hash, sessionDuration.hashCode);
    hash = _SystemHash.combine(hash, now.hashCode);
    hash = _SystemHash.combine(hash, studentIsUnder14.hashCode);
    hash = _SystemHash.combine(hash, studentHasParentConsent.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin CurrentSpotlightForCelebrationRef
    on AutoDisposeFutureProviderRef<SpotlightPrompt?> {
  /// The parameter `studentId` of this provider.
  String get studentId;

  /// The parameter `sessionDuration` of this provider.
  Duration get sessionDuration;

  /// The parameter `now` of this provider.
  DateTime get now;

  /// The parameter `studentIsUnder14` of this provider.
  bool get studentIsUnder14;

  /// The parameter `studentHasParentConsent` of this provider.
  bool get studentHasParentConsent;
}

class _CurrentSpotlightForCelebrationProviderElement
    extends AutoDisposeFutureProviderElement<SpotlightPrompt?>
    with CurrentSpotlightForCelebrationRef {
  _CurrentSpotlightForCelebrationProviderElement(super.provider);

  @override
  String get studentId =>
      (origin as CurrentSpotlightForCelebrationProvider).studentId;
  @override
  Duration get sessionDuration =>
      (origin as CurrentSpotlightForCelebrationProvider).sessionDuration;
  @override
  DateTime get now => (origin as CurrentSpotlightForCelebrationProvider).now;
  @override
  bool get studentIsUnder14 =>
      (origin as CurrentSpotlightForCelebrationProvider).studentIsUnder14;
  @override
  bool get studentHasParentConsent =>
      (origin as CurrentSpotlightForCelebrationProvider)
          .studentHasParentConsent;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
