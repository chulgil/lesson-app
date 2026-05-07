// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'practice_crud_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$practiceLogsHash() => r'3cd94921ceb2385d489aca3047e1de22921e5376';

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

/// Practice logs by student
///
/// Copied from [practiceLogs].
@ProviderFor(practiceLogs)
const practiceLogsProvider = PracticeLogsFamily();

/// Practice logs by student
///
/// Copied from [practiceLogs].
class PracticeLogsFamily extends Family<AsyncValue<List<PracticeLog>>> {
  /// Practice logs by student
  ///
  /// Copied from [practiceLogs].
  const PracticeLogsFamily();

  /// Practice logs by student
  ///
  /// Copied from [practiceLogs].
  PracticeLogsProvider call(
    String studentId,
  ) {
    return PracticeLogsProvider(
      studentId,
    );
  }

  @override
  PracticeLogsProvider getProviderOverride(
    covariant PracticeLogsProvider provider,
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
  String? get name => r'practiceLogsProvider';
}

/// Practice logs by student
///
/// Copied from [practiceLogs].
class PracticeLogsProvider extends FutureProvider<List<PracticeLog>> {
  /// Practice logs by student
  ///
  /// Copied from [practiceLogs].
  PracticeLogsProvider(
    String studentId,
  ) : this._internal(
          (ref) => practiceLogs(
            ref as PracticeLogsRef,
            studentId,
          ),
          from: practiceLogsProvider,
          name: r'practiceLogsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$practiceLogsHash,
          dependencies: PracticeLogsFamily._dependencies,
          allTransitiveDependencies:
              PracticeLogsFamily._allTransitiveDependencies,
          studentId: studentId,
        );

  PracticeLogsProvider._internal(
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
    FutureOr<List<PracticeLog>> Function(PracticeLogsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PracticeLogsProvider._internal(
        (ref) => create(ref as PracticeLogsRef),
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
  FutureProviderElement<List<PracticeLog>> createElement() {
    return _PracticeLogsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PracticeLogsProvider && other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin PracticeLogsRef on FutureProviderRef<List<PracticeLog>> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _PracticeLogsProviderElement
    extends FutureProviderElement<List<PracticeLog>> with PracticeLogsRef {
  _PracticeLogsProviderElement(super.provider);

  @override
  String get studentId => (origin as PracticeLogsProvider).studentId;
}

String _$practiceLogHash() => r'c6a058a7cd36420d080c18602308c7c00f9da84c';

/// Single practice log
///
/// Copied from [practiceLog].
@ProviderFor(practiceLog)
const practiceLogProvider = PracticeLogFamily();

/// Single practice log
///
/// Copied from [practiceLog].
class PracticeLogFamily extends Family<AsyncValue<PracticeLog?>> {
  /// Single practice log
  ///
  /// Copied from [practiceLog].
  const PracticeLogFamily();

  /// Single practice log
  ///
  /// Copied from [practiceLog].
  PracticeLogProvider call(
    String id,
  ) {
    return PracticeLogProvider(
      id,
    );
  }

  @override
  PracticeLogProvider getProviderOverride(
    covariant PracticeLogProvider provider,
  ) {
    return call(
      provider.id,
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
  String? get name => r'practiceLogProvider';
}

/// Single practice log
///
/// Copied from [practiceLog].
class PracticeLogProvider extends FutureProvider<PracticeLog?> {
  /// Single practice log
  ///
  /// Copied from [practiceLog].
  PracticeLogProvider(
    String id,
  ) : this._internal(
          (ref) => practiceLog(
            ref as PracticeLogRef,
            id,
          ),
          from: practiceLogProvider,
          name: r'practiceLogProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$practiceLogHash,
          dependencies: PracticeLogFamily._dependencies,
          allTransitiveDependencies:
              PracticeLogFamily._allTransitiveDependencies,
          id: id,
        );

  PracticeLogProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.id,
  }) : super.internal();

  final String id;

  @override
  Override overrideWith(
    FutureOr<PracticeLog?> Function(PracticeLogRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PracticeLogProvider._internal(
        (ref) => create(ref as PracticeLogRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        id: id,
      ),
    );
  }

  @override
  FutureProviderElement<PracticeLog?> createElement() {
    return _PracticeLogProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PracticeLogProvider && other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin PracticeLogRef on FutureProviderRef<PracticeLog?> {
  /// The parameter `id` of this provider.
  String get id;
}

class _PracticeLogProviderElement extends FutureProviderElement<PracticeLog?>
    with PracticeLogRef {
  _PracticeLogProviderElement(super.provider);

  @override
  String get id => (origin as PracticeLogProvider).id;
}

String _$practiceLogByDateHash() => r'3f3be7bcd6d1386b978cfe417342f66ac3f60c2e';

/// Practice log for specific date
///
/// Copied from [practiceLogByDate].
@ProviderFor(practiceLogByDate)
const practiceLogByDateProvider = PracticeLogByDateFamily();

/// Practice log for specific date
///
/// Copied from [practiceLogByDate].
class PracticeLogByDateFamily extends Family<AsyncValue<PracticeLog?>> {
  /// Practice log for specific date
  ///
  /// Copied from [practiceLogByDate].
  const PracticeLogByDateFamily();

  /// Practice log for specific date
  ///
  /// Copied from [practiceLogByDate].
  PracticeLogByDateProvider call(
    ({DateTime date, String studentId}) params,
  ) {
    return PracticeLogByDateProvider(
      params,
    );
  }

  @override
  PracticeLogByDateProvider getProviderOverride(
    covariant PracticeLogByDateProvider provider,
  ) {
    return call(
      provider.params,
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
  String? get name => r'practiceLogByDateProvider';
}

/// Practice log for specific date
///
/// Copied from [practiceLogByDate].
class PracticeLogByDateProvider extends FutureProvider<PracticeLog?> {
  /// Practice log for specific date
  ///
  /// Copied from [practiceLogByDate].
  PracticeLogByDateProvider(
    ({DateTime date, String studentId}) params,
  ) : this._internal(
          (ref) => practiceLogByDate(
            ref as PracticeLogByDateRef,
            params,
          ),
          from: practiceLogByDateProvider,
          name: r'practiceLogByDateProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$practiceLogByDateHash,
          dependencies: PracticeLogByDateFamily._dependencies,
          allTransitiveDependencies:
              PracticeLogByDateFamily._allTransitiveDependencies,
          params: params,
        );

  PracticeLogByDateProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.params,
  }) : super.internal();

  final ({DateTime date, String studentId}) params;

  @override
  Override overrideWith(
    FutureOr<PracticeLog?> Function(PracticeLogByDateRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PracticeLogByDateProvider._internal(
        (ref) => create(ref as PracticeLogByDateRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        params: params,
      ),
    );
  }

  @override
  FutureProviderElement<PracticeLog?> createElement() {
    return _PracticeLogByDateProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PracticeLogByDateProvider && other.params == params;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, params.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin PracticeLogByDateRef on FutureProviderRef<PracticeLog?> {
  /// The parameter `params` of this provider.
  ({DateTime date, String studentId}) get params;
}

class _PracticeLogByDateProviderElement
    extends FutureProviderElement<PracticeLog?> with PracticeLogByDateRef {
  _PracticeLogByDateProviderElement(super.provider);

  @override
  ({DateTime date, String studentId}) get params =>
      (origin as PracticeLogByDateProvider).params;
}

String _$todayPracticeHash() => r'8a53e3afcf9dd11a676c39f70960f71a5be210bd';

/// Today's practice log for student
///
/// Copied from [todayPractice].
@ProviderFor(todayPractice)
const todayPracticeProvider = TodayPracticeFamily();

/// Today's practice log for student
///
/// Copied from [todayPractice].
class TodayPracticeFamily extends Family<AsyncValue<PracticeLog?>> {
  /// Today's practice log for student
  ///
  /// Copied from [todayPractice].
  const TodayPracticeFamily();

  /// Today's practice log for student
  ///
  /// Copied from [todayPractice].
  TodayPracticeProvider call(
    String studentId,
  ) {
    return TodayPracticeProvider(
      studentId,
    );
  }

  @override
  TodayPracticeProvider getProviderOverride(
    covariant TodayPracticeProvider provider,
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
  String? get name => r'todayPracticeProvider';
}

/// Today's practice log for student
///
/// Copied from [todayPractice].
class TodayPracticeProvider extends FutureProvider<PracticeLog?> {
  /// Today's practice log for student
  ///
  /// Copied from [todayPractice].
  TodayPracticeProvider(
    String studentId,
  ) : this._internal(
          (ref) => todayPractice(
            ref as TodayPracticeRef,
            studentId,
          ),
          from: todayPracticeProvider,
          name: r'todayPracticeProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$todayPracticeHash,
          dependencies: TodayPracticeFamily._dependencies,
          allTransitiveDependencies:
              TodayPracticeFamily._allTransitiveDependencies,
          studentId: studentId,
        );

  TodayPracticeProvider._internal(
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
    FutureOr<PracticeLog?> Function(TodayPracticeRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TodayPracticeProvider._internal(
        (ref) => create(ref as TodayPracticeRef),
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
  FutureProviderElement<PracticeLog?> createElement() {
    return _TodayPracticeProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TodayPracticeProvider && other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin TodayPracticeRef on FutureProviderRef<PracticeLog?> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _TodayPracticeProviderElement extends FutureProviderElement<PracticeLog?>
    with TodayPracticeRef {
  _TodayPracticeProviderElement(super.provider);

  @override
  String get studentId => (origin as TodayPracticeProvider).studentId;
}

String _$weeklyPracticeHash() => r'0843ef1f4d7cf4e165568b489b8d931358bd10d9';

/// Weekly practice for student (current week)
///
/// Copied from [weeklyPractice].
@ProviderFor(weeklyPractice)
const weeklyPracticeProvider = WeeklyPracticeFamily();

/// Weekly practice for student (current week)
///
/// Copied from [weeklyPractice].
class WeeklyPracticeFamily extends Family<AsyncValue<List<bool>>> {
  /// Weekly practice for student (current week)
  ///
  /// Copied from [weeklyPractice].
  const WeeklyPracticeFamily();

  /// Weekly practice for student (current week)
  ///
  /// Copied from [weeklyPractice].
  WeeklyPracticeProvider call(
    String studentId,
  ) {
    return WeeklyPracticeProvider(
      studentId,
    );
  }

  @override
  WeeklyPracticeProvider getProviderOverride(
    covariant WeeklyPracticeProvider provider,
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
  String? get name => r'weeklyPracticeProvider';
}

/// Weekly practice for student (current week)
///
/// Copied from [weeklyPractice].
class WeeklyPracticeProvider extends FutureProvider<List<bool>> {
  /// Weekly practice for student (current week)
  ///
  /// Copied from [weeklyPractice].
  WeeklyPracticeProvider(
    String studentId,
  ) : this._internal(
          (ref) => weeklyPractice(
            ref as WeeklyPracticeRef,
            studentId,
          ),
          from: weeklyPracticeProvider,
          name: r'weeklyPracticeProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$weeklyPracticeHash,
          dependencies: WeeklyPracticeFamily._dependencies,
          allTransitiveDependencies:
              WeeklyPracticeFamily._allTransitiveDependencies,
          studentId: studentId,
        );

  WeeklyPracticeProvider._internal(
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
    FutureOr<List<bool>> Function(WeeklyPracticeRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: WeeklyPracticeProvider._internal(
        (ref) => create(ref as WeeklyPracticeRef),
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
  FutureProviderElement<List<bool>> createElement() {
    return _WeeklyPracticeProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is WeeklyPracticeProvider && other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin WeeklyPracticeRef on FutureProviderRef<List<bool>> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _WeeklyPracticeProviderElement extends FutureProviderElement<List<bool>>
    with WeeklyPracticeRef {
  _WeeklyPracticeProviderElement(super.provider);

  @override
  String get studentId => (origin as WeeklyPracticeProvider).studentId;
}

String _$practiceNotifierHash() => r'ae64f53dbedb74bb252dfa0a3ab3aa0d2067146b';

abstract class _$PracticeNotifier
    extends BuildlessAsyncNotifier<List<PracticeLog>> {
  late final String studentId;

  FutureOr<List<PracticeLog>> build(
    String studentId,
  );
}

/// Practice notifier for CRUD operations
///
/// Copied from [PracticeNotifier].
@ProviderFor(PracticeNotifier)
const practiceNotifierProvider = PracticeNotifierFamily();

/// Practice notifier for CRUD operations
///
/// Copied from [PracticeNotifier].
class PracticeNotifierFamily extends Family<AsyncValue<List<PracticeLog>>> {
  /// Practice notifier for CRUD operations
  ///
  /// Copied from [PracticeNotifier].
  const PracticeNotifierFamily();

  /// Practice notifier for CRUD operations
  ///
  /// Copied from [PracticeNotifier].
  PracticeNotifierProvider call(
    String studentId,
  ) {
    return PracticeNotifierProvider(
      studentId,
    );
  }

  @override
  PracticeNotifierProvider getProviderOverride(
    covariant PracticeNotifierProvider provider,
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
  String? get name => r'practiceNotifierProvider';
}

/// Practice notifier for CRUD operations
///
/// Copied from [PracticeNotifier].
class PracticeNotifierProvider
    extends AsyncNotifierProviderImpl<PracticeNotifier, List<PracticeLog>> {
  /// Practice notifier for CRUD operations
  ///
  /// Copied from [PracticeNotifier].
  PracticeNotifierProvider(
    String studentId,
  ) : this._internal(
          () => PracticeNotifier()..studentId = studentId,
          from: practiceNotifierProvider,
          name: r'practiceNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$practiceNotifierHash,
          dependencies: PracticeNotifierFamily._dependencies,
          allTransitiveDependencies:
              PracticeNotifierFamily._allTransitiveDependencies,
          studentId: studentId,
        );

  PracticeNotifierProvider._internal(
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
  FutureOr<List<PracticeLog>> runNotifierBuild(
    covariant PracticeNotifier notifier,
  ) {
    return notifier.build(
      studentId,
    );
  }

  @override
  Override overrideWith(PracticeNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: PracticeNotifierProvider._internal(
        () => create()..studentId = studentId,
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
  AsyncNotifierProviderElement<PracticeNotifier, List<PracticeLog>>
      createElement() {
    return _PracticeNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PracticeNotifierProvider && other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin PracticeNotifierRef on AsyncNotifierProviderRef<List<PracticeLog>> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _PracticeNotifierProviderElement
    extends AsyncNotifierProviderElement<PracticeNotifier, List<PracticeLog>>
    with PracticeNotifierRef {
  _PracticeNotifierProviderElement(super.provider);

  @override
  String get studentId => (origin as PracticeNotifierProvider).studentId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
