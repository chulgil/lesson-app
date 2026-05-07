// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'practice_goal_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$practiceGoalRepositoryHash() =>
    r'f91134a799fa8a913abf5edf19949f7b6e61d498';

/// Practice goal repository provider - switches between Mock and Remote.
///
/// Copied from [practiceGoalRepository].
@ProviderFor(practiceGoalRepository)
final practiceGoalRepositoryProvider =
    Provider<PracticeGoalRepository>.internal(
  practiceGoalRepository,
  name: r'practiceGoalRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$practiceGoalRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef PracticeGoalRepositoryRef = ProviderRef<PracticeGoalRepository>;
String _$practiceGoalHash() => r'060fd0aefdf1dfebc6794cb69e9cfc9fb80a65be';

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

/// Student's current active goal
///
/// Copied from [practiceGoal].
@ProviderFor(practiceGoal)
const practiceGoalProvider = PracticeGoalFamily();

/// Student's current active goal
///
/// Copied from [practiceGoal].
class PracticeGoalFamily extends Family<AsyncValue<PracticeGoal?>> {
  /// Student's current active goal
  ///
  /// Copied from [practiceGoal].
  const PracticeGoalFamily();

  /// Student's current active goal
  ///
  /// Copied from [practiceGoal].
  PracticeGoalProvider call(
    String studentId,
  ) {
    return PracticeGoalProvider(
      studentId,
    );
  }

  @override
  PracticeGoalProvider getProviderOverride(
    covariant PracticeGoalProvider provider,
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
  String? get name => r'practiceGoalProvider';
}

/// Student's current active goal
///
/// Copied from [practiceGoal].
class PracticeGoalProvider extends FutureProvider<PracticeGoal?> {
  /// Student's current active goal
  ///
  /// Copied from [practiceGoal].
  PracticeGoalProvider(
    String studentId,
  ) : this._internal(
          (ref) => practiceGoal(
            ref as PracticeGoalRef,
            studentId,
          ),
          from: practiceGoalProvider,
          name: r'practiceGoalProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$practiceGoalHash,
          dependencies: PracticeGoalFamily._dependencies,
          allTransitiveDependencies:
              PracticeGoalFamily._allTransitiveDependencies,
          studentId: studentId,
        );

  PracticeGoalProvider._internal(
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
    FutureOr<PracticeGoal?> Function(PracticeGoalRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PracticeGoalProvider._internal(
        (ref) => create(ref as PracticeGoalRef),
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
  FutureProviderElement<PracticeGoal?> createElement() {
    return _PracticeGoalProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PracticeGoalProvider && other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin PracticeGoalRef on FutureProviderRef<PracticeGoal?> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _PracticeGoalProviderElement extends FutureProviderElement<PracticeGoal?>
    with PracticeGoalRef {
  _PracticeGoalProviderElement(super.provider);

  @override
  String get studentId => (origin as PracticeGoalProvider).studentId;
}

String _$todayProgressHash() => r'd4201f759e9eb697da327deab6b786d942a676d1';

/// Today's progress
///
/// Copied from [todayProgress].
@ProviderFor(todayProgress)
const todayProgressProvider = TodayProgressFamily();

/// Today's progress
///
/// Copied from [todayProgress].
class TodayProgressFamily extends Family<AsyncValue<DailyPracticeProgress>> {
  /// Today's progress
  ///
  /// Copied from [todayProgress].
  const TodayProgressFamily();

  /// Today's progress
  ///
  /// Copied from [todayProgress].
  TodayProgressProvider call(
    String studentId,
  ) {
    return TodayProgressProvider(
      studentId,
    );
  }

  @override
  TodayProgressProvider getProviderOverride(
    covariant TodayProgressProvider provider,
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
  String? get name => r'todayProgressProvider';
}

/// Today's progress
///
/// Copied from [todayProgress].
class TodayProgressProvider extends FutureProvider<DailyPracticeProgress> {
  /// Today's progress
  ///
  /// Copied from [todayProgress].
  TodayProgressProvider(
    String studentId,
  ) : this._internal(
          (ref) => todayProgress(
            ref as TodayProgressRef,
            studentId,
          ),
          from: todayProgressProvider,
          name: r'todayProgressProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$todayProgressHash,
          dependencies: TodayProgressFamily._dependencies,
          allTransitiveDependencies:
              TodayProgressFamily._allTransitiveDependencies,
          studentId: studentId,
        );

  TodayProgressProvider._internal(
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
    FutureOr<DailyPracticeProgress> Function(TodayProgressRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TodayProgressProvider._internal(
        (ref) => create(ref as TodayProgressRef),
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
  FutureProviderElement<DailyPracticeProgress> createElement() {
    return _TodayProgressProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TodayProgressProvider && other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin TodayProgressRef on FutureProviderRef<DailyPracticeProgress> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _TodayProgressProviderElement
    extends FutureProviderElement<DailyPracticeProgress> with TodayProgressRef {
  _TodayProgressProviderElement(super.provider);

  @override
  String get studentId => (origin as TodayProgressProvider).studentId;
}

String _$weeklyProgressHash() => r'341cab3d6ac6c84749e72a27080fb78d9e4d6b7e';

/// This week's progress
///
/// Copied from [weeklyProgress].
@ProviderFor(weeklyProgress)
const weeklyProgressProvider = WeeklyProgressFamily();

/// This week's progress
///
/// Copied from [weeklyProgress].
class WeeklyProgressFamily extends Family<AsyncValue<WeeklyPracticeProgress>> {
  /// This week's progress
  ///
  /// Copied from [weeklyProgress].
  const WeeklyProgressFamily();

  /// This week's progress
  ///
  /// Copied from [weeklyProgress].
  WeeklyProgressProvider call(
    String studentId,
  ) {
    return WeeklyProgressProvider(
      studentId,
    );
  }

  @override
  WeeklyProgressProvider getProviderOverride(
    covariant WeeklyProgressProvider provider,
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
  String? get name => r'weeklyProgressProvider';
}

/// This week's progress
///
/// Copied from [weeklyProgress].
class WeeklyProgressProvider extends FutureProvider<WeeklyPracticeProgress> {
  /// This week's progress
  ///
  /// Copied from [weeklyProgress].
  WeeklyProgressProvider(
    String studentId,
  ) : this._internal(
          (ref) => weeklyProgress(
            ref as WeeklyProgressRef,
            studentId,
          ),
          from: weeklyProgressProvider,
          name: r'weeklyProgressProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$weeklyProgressHash,
          dependencies: WeeklyProgressFamily._dependencies,
          allTransitiveDependencies:
              WeeklyProgressFamily._allTransitiveDependencies,
          studentId: studentId,
        );

  WeeklyProgressProvider._internal(
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
    FutureOr<WeeklyPracticeProgress> Function(WeeklyProgressRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: WeeklyProgressProvider._internal(
        (ref) => create(ref as WeeklyProgressRef),
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
  FutureProviderElement<WeeklyPracticeProgress> createElement() {
    return _WeeklyProgressProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is WeeklyProgressProvider && other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin WeeklyProgressRef on FutureProviderRef<WeeklyPracticeProgress> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _WeeklyProgressProviderElement
    extends FutureProviderElement<WeeklyPracticeProgress>
    with WeeklyProgressRef {
  _WeeklyProgressProviderElement(super.provider);

  @override
  String get studentId => (origin as WeeklyProgressProvider).studentId;
}

String _$goalStatusHash() => r'a41f55414a84e10d0d01a6914e65ca72782ae210';

/// Combined goal status provider for widgets
///
/// Copied from [goalStatus].
@ProviderFor(goalStatus)
const goalStatusProvider = GoalStatusFamily();

/// Combined goal status provider for widgets
///
/// Copied from [goalStatus].
class GoalStatusFamily extends Family<AsyncValue<GoalStatus>> {
  /// Combined goal status provider for widgets
  ///
  /// Copied from [goalStatus].
  const GoalStatusFamily();

  /// Combined goal status provider for widgets
  ///
  /// Copied from [goalStatus].
  GoalStatusProvider call(
    String studentId,
  ) {
    return GoalStatusProvider(
      studentId,
    );
  }

  @override
  GoalStatusProvider getProviderOverride(
    covariant GoalStatusProvider provider,
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
  String? get name => r'goalStatusProvider';
}

/// Combined goal status provider for widgets
///
/// Copied from [goalStatus].
class GoalStatusProvider extends FutureProvider<GoalStatus> {
  /// Combined goal status provider for widgets
  ///
  /// Copied from [goalStatus].
  GoalStatusProvider(
    String studentId,
  ) : this._internal(
          (ref) => goalStatus(
            ref as GoalStatusRef,
            studentId,
          ),
          from: goalStatusProvider,
          name: r'goalStatusProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$goalStatusHash,
          dependencies: GoalStatusFamily._dependencies,
          allTransitiveDependencies:
              GoalStatusFamily._allTransitiveDependencies,
          studentId: studentId,
        );

  GoalStatusProvider._internal(
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
    FutureOr<GoalStatus> Function(GoalStatusRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: GoalStatusProvider._internal(
        (ref) => create(ref as GoalStatusRef),
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
  FutureProviderElement<GoalStatus> createElement() {
    return _GoalStatusProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GoalStatusProvider && other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin GoalStatusRef on FutureProviderRef<GoalStatus> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _GoalStatusProviderElement extends FutureProviderElement<GoalStatus>
    with GoalStatusRef {
  _GoalStatusProviderElement(super.provider);

  @override
  String get studentId => (origin as GoalStatusProvider).studentId;
}

String _$practiceGoalCrudHash() => r'ed9a99443a5be8d0dcfe7acaba51c5722d8810ff';

/// Goal CRUD notifier
///
/// Copied from [PracticeGoalCrud].
@ProviderFor(PracticeGoalCrud)
final practiceGoalCrudProvider =
    AsyncNotifierProvider<PracticeGoalCrud, void>.internal(
  PracticeGoalCrud.new,
  name: r'practiceGoalCrudProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$practiceGoalCrudHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$PracticeGoalCrud = AsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
