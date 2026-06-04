// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'practice_loop_stats_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$practiceLoopStatsRepositoryHash() =>
    r'119e3d1d826c0f124f845d6b6feb81be76689ee2';

/// Repository provider — switches Mock ↔ Remote (#512).
///
/// Copied from [practiceLoopStatsRepository].
@ProviderFor(practiceLoopStatsRepository)
final practiceLoopStatsRepositoryProvider =
    Provider<PracticeLoopStatsRepository>.internal(
  practiceLoopStatsRepository,
  name: r'practiceLoopStatsRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$practiceLoopStatsRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef PracticeLoopStatsRepositoryRef
    = ProviderRef<PracticeLoopStatsRepository>;
String _$loopStatsSyncServiceHash() =>
    r'f83a9fcf80b551774cae86fc421fca90e6df7da4';

/// Offline-aware sync queue service (#512).
///
/// Copied from [loopStatsSyncService].
@ProviderFor(loopStatsSyncService)
final loopStatsSyncServiceProvider = Provider<LoopStatsSyncService>.internal(
  loopStatsSyncService,
  name: r'loopStatsSyncServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$loopStatsSyncServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef LoopStatsSyncServiceRef = ProviderRef<LoopStatsSyncService>;
String _$practiceLoopStatsForStudentHash() =>
    r'4b3faba214004c7ed821d4bb0cae8ca782c6dae9';

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

/// Teacher: per-student rows scoped by [window].
///
/// Copied from [practiceLoopStatsForStudent].
@ProviderFor(practiceLoopStatsForStudent)
const practiceLoopStatsForStudentProvider = PracticeLoopStatsForStudentFamily();

/// Teacher: per-student rows scoped by [window].
///
/// Copied from [practiceLoopStatsForStudent].
class PracticeLoopStatsForStudentFamily extends Family<
    AsyncValue<({int totalRepeats, List<PracticeLoopStats> rows})>> {
  /// Teacher: per-student rows scoped by [window].
  ///
  /// Copied from [practiceLoopStatsForStudent].
  const PracticeLoopStatsForStudentFamily();

  /// Teacher: per-student rows scoped by [window].
  ///
  /// Copied from [practiceLoopStatsForStudent].
  PracticeLoopStatsForStudentProvider call({
    required String studentId,
    required PracticeLoopStatsWindow window,
  }) {
    return PracticeLoopStatsForStudentProvider(
      studentId: studentId,
      window: window,
    );
  }

  @override
  PracticeLoopStatsForStudentProvider getProviderOverride(
    covariant PracticeLoopStatsForStudentProvider provider,
  ) {
    return call(
      studentId: provider.studentId,
      window: provider.window,
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
  String? get name => r'practiceLoopStatsForStudentProvider';
}

/// Teacher: per-student rows scoped by [window].
///
/// Copied from [practiceLoopStatsForStudent].
class PracticeLoopStatsForStudentProvider extends AutoDisposeFutureProvider<
    ({int totalRepeats, List<PracticeLoopStats> rows})> {
  /// Teacher: per-student rows scoped by [window].
  ///
  /// Copied from [practiceLoopStatsForStudent].
  PracticeLoopStatsForStudentProvider({
    required String studentId,
    required PracticeLoopStatsWindow window,
  }) : this._internal(
          (ref) => practiceLoopStatsForStudent(
            ref as PracticeLoopStatsForStudentRef,
            studentId: studentId,
            window: window,
          ),
          from: practiceLoopStatsForStudentProvider,
          name: r'practiceLoopStatsForStudentProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$practiceLoopStatsForStudentHash,
          dependencies: PracticeLoopStatsForStudentFamily._dependencies,
          allTransitiveDependencies:
              PracticeLoopStatsForStudentFamily._allTransitiveDependencies,
          studentId: studentId,
          window: window,
        );

  PracticeLoopStatsForStudentProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.studentId,
    required this.window,
  }) : super.internal();

  final String studentId;
  final PracticeLoopStatsWindow window;

  @override
  Override overrideWith(
    FutureOr<({int totalRepeats, List<PracticeLoopStats> rows})> Function(
            PracticeLoopStatsForStudentRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PracticeLoopStatsForStudentProvider._internal(
        (ref) => create(ref as PracticeLoopStatsForStudentRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        studentId: studentId,
        window: window,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<
      ({int totalRepeats, List<PracticeLoopStats> rows})> createElement() {
    return _PracticeLoopStatsForStudentProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PracticeLoopStatsForStudentProvider &&
        other.studentId == studentId &&
        other.window == window;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);
    hash = _SystemHash.combine(hash, window.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin PracticeLoopStatsForStudentRef on AutoDisposeFutureProviderRef<
    ({int totalRepeats, List<PracticeLoopStats> rows})> {
  /// The parameter `studentId` of this provider.
  String get studentId;

  /// The parameter `window` of this provider.
  PracticeLoopStatsWindow get window;
}

class _PracticeLoopStatsForStudentProviderElement
    extends AutoDisposeFutureProviderElement<
        ({int totalRepeats, List<PracticeLoopStats> rows})>
    with PracticeLoopStatsForStudentRef {
  _PracticeLoopStatsForStudentProviderElement(super.provider);

  @override
  String get studentId =>
      (origin as PracticeLoopStatsForStudentProvider).studentId;
  @override
  PracticeLoopStatsWindow get window =>
      (origin as PracticeLoopStatsForStudentProvider).window;
}

String _$practiceLoopStatsSummaryHash() =>
    r'c09bebcb56473eaee5a361eddec81d3701b17b0d';

/// Teacher: dashboard roll-up across all linked students.
///
/// Copied from [practiceLoopStatsSummary].
@ProviderFor(practiceLoopStatsSummary)
const practiceLoopStatsSummaryProvider = PracticeLoopStatsSummaryFamily();

/// Teacher: dashboard roll-up across all linked students.
///
/// Copied from [practiceLoopStatsSummary].
class PracticeLoopStatsSummaryFamily
    extends Family<AsyncValue<List<StudentRepeatStats>>> {
  /// Teacher: dashboard roll-up across all linked students.
  ///
  /// Copied from [practiceLoopStatsSummary].
  const PracticeLoopStatsSummaryFamily();

  /// Teacher: dashboard roll-up across all linked students.
  ///
  /// Copied from [practiceLoopStatsSummary].
  PracticeLoopStatsSummaryProvider call({
    required PracticeLoopStatsWindow window,
  }) {
    return PracticeLoopStatsSummaryProvider(
      window: window,
    );
  }

  @override
  PracticeLoopStatsSummaryProvider getProviderOverride(
    covariant PracticeLoopStatsSummaryProvider provider,
  ) {
    return call(
      window: provider.window,
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
  String? get name => r'practiceLoopStatsSummaryProvider';
}

/// Teacher: dashboard roll-up across all linked students.
///
/// Copied from [practiceLoopStatsSummary].
class PracticeLoopStatsSummaryProvider
    extends AutoDisposeFutureProvider<List<StudentRepeatStats>> {
  /// Teacher: dashboard roll-up across all linked students.
  ///
  /// Copied from [practiceLoopStatsSummary].
  PracticeLoopStatsSummaryProvider({
    required PracticeLoopStatsWindow window,
  }) : this._internal(
          (ref) => practiceLoopStatsSummary(
            ref as PracticeLoopStatsSummaryRef,
            window: window,
          ),
          from: practiceLoopStatsSummaryProvider,
          name: r'practiceLoopStatsSummaryProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$practiceLoopStatsSummaryHash,
          dependencies: PracticeLoopStatsSummaryFamily._dependencies,
          allTransitiveDependencies:
              PracticeLoopStatsSummaryFamily._allTransitiveDependencies,
          window: window,
        );

  PracticeLoopStatsSummaryProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.window,
  }) : super.internal();

  final PracticeLoopStatsWindow window;

  @override
  Override overrideWith(
    FutureOr<List<StudentRepeatStats>> Function(
            PracticeLoopStatsSummaryRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PracticeLoopStatsSummaryProvider._internal(
        (ref) => create(ref as PracticeLoopStatsSummaryRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        window: window,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<StudentRepeatStats>> createElement() {
    return _PracticeLoopStatsSummaryProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PracticeLoopStatsSummaryProvider && other.window == window;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, window.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin PracticeLoopStatsSummaryRef
    on AutoDisposeFutureProviderRef<List<StudentRepeatStats>> {
  /// The parameter `window` of this provider.
  PracticeLoopStatsWindow get window;
}

class _PracticeLoopStatsSummaryProviderElement
    extends AutoDisposeFutureProviderElement<List<StudentRepeatStats>>
    with PracticeLoopStatsSummaryRef {
  _PracticeLoopStatsSummaryProviderElement(super.provider);

  @override
  PracticeLoopStatsWindow get window =>
      (origin as PracticeLoopStatsSummaryProvider).window;
}

String _$loopStatsSyncActionsHash() =>
    r'13c5f10399ef511c2fa58089f2e79c08d065b495';

/// Student-side: thin actions API for the loop screen / lifecycle hooks.
///
/// Used by [PracticeLoopOverrideNotifier] at session end + by the queue
/// flush trigger when connectivity returns.
///
/// Copied from [loopStatsSyncActions].
@ProviderFor(loopStatsSyncActions)
final loopStatsSyncActionsProvider =
    AutoDisposeProvider<LoopStatsSyncActions>.internal(
  loopStatsSyncActions,
  name: r'loopStatsSyncActionsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$loopStatsSyncActionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef LoopStatsSyncActionsRef = AutoDisposeProviderRef<LoopStatsSyncActions>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
