// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'practice_item_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$practiceItemRepositoryHash() =>
    r'f83f3bf3c87c929cd1b383ffcda61ebea7ceebd4';

/// Repository provider
///
/// Copied from [practiceItemRepository].
@ProviderFor(practiceItemRepository)
final practiceItemRepositoryProvider =
    Provider<PracticeItemRepository>.internal(
      practiceItemRepository,
      name: r'practiceItemRepositoryProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$practiceItemRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef PracticeItemRepositoryRef = ProviderRef<PracticeItemRepository>;
String _$practiceItemsByLessonHash() =>
    r'e8e891f6b528e8149e58763f3e4e47bc9b1ab911';

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

/// Practice items by lesson ID
///
/// Copied from [practiceItemsByLesson].
@ProviderFor(practiceItemsByLesson)
const practiceItemsByLessonProvider = PracticeItemsByLessonFamily();

/// Practice items by lesson ID
///
/// Copied from [practiceItemsByLesson].
class PracticeItemsByLessonFamily
    extends Family<AsyncValue<List<PracticeItem>>> {
  /// Practice items by lesson ID
  ///
  /// Copied from [practiceItemsByLesson].
  const PracticeItemsByLessonFamily();

  /// Practice items by lesson ID
  ///
  /// Copied from [practiceItemsByLesson].
  PracticeItemsByLessonProvider call(String lessonId) {
    return PracticeItemsByLessonProvider(lessonId);
  }

  @override
  PracticeItemsByLessonProvider getProviderOverride(
    covariant PracticeItemsByLessonProvider provider,
  ) {
    return call(provider.lessonId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'practiceItemsByLessonProvider';
}

/// Practice items by lesson ID
///
/// Copied from [practiceItemsByLesson].
class PracticeItemsByLessonProvider extends FutureProvider<List<PracticeItem>> {
  /// Practice items by lesson ID
  ///
  /// Copied from [practiceItemsByLesson].
  PracticeItemsByLessonProvider(String lessonId)
    : this._internal(
        (ref) =>
            practiceItemsByLesson(ref as PracticeItemsByLessonRef, lessonId),
        from: practiceItemsByLessonProvider,
        name: r'practiceItemsByLessonProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$practiceItemsByLessonHash,
        dependencies: PracticeItemsByLessonFamily._dependencies,
        allTransitiveDependencies:
            PracticeItemsByLessonFamily._allTransitiveDependencies,
        lessonId: lessonId,
      );

  PracticeItemsByLessonProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.lessonId,
  }) : super.internal();

  final String lessonId;

  @override
  Override overrideWith(
    FutureOr<List<PracticeItem>> Function(PracticeItemsByLessonRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PracticeItemsByLessonProvider._internal(
        (ref) => create(ref as PracticeItemsByLessonRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        lessonId: lessonId,
      ),
    );
  }

  @override
  FutureProviderElement<List<PracticeItem>> createElement() {
    return _PracticeItemsByLessonProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PracticeItemsByLessonProvider && other.lessonId == lessonId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, lessonId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin PracticeItemsByLessonRef on FutureProviderRef<List<PracticeItem>> {
  /// The parameter `lessonId` of this provider.
  String get lessonId;
}

class _PracticeItemsByLessonProviderElement
    extends FutureProviderElement<List<PracticeItem>>
    with PracticeItemsByLessonRef {
  _PracticeItemsByLessonProviderElement(super.provider);

  @override
  String get lessonId => (origin as PracticeItemsByLessonProvider).lessonId;
}

String _$practiceItemsByStudentHash() =>
    r'b51c709528da3f16bd4a96b7ba2bebb69cd5f643';

/// Practice items by student ID
///
/// Copied from [practiceItemsByStudent].
@ProviderFor(practiceItemsByStudent)
const practiceItemsByStudentProvider = PracticeItemsByStudentFamily();

/// Practice items by student ID
///
/// Copied from [practiceItemsByStudent].
class PracticeItemsByStudentFamily
    extends Family<AsyncValue<List<PracticeItem>>> {
  /// Practice items by student ID
  ///
  /// Copied from [practiceItemsByStudent].
  const PracticeItemsByStudentFamily();

  /// Practice items by student ID
  ///
  /// Copied from [practiceItemsByStudent].
  PracticeItemsByStudentProvider call(String studentId) {
    return PracticeItemsByStudentProvider(studentId);
  }

  @override
  PracticeItemsByStudentProvider getProviderOverride(
    covariant PracticeItemsByStudentProvider provider,
  ) {
    return call(provider.studentId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'practiceItemsByStudentProvider';
}

/// Practice items by student ID
///
/// Copied from [practiceItemsByStudent].
class PracticeItemsByStudentProvider
    extends FutureProvider<List<PracticeItem>> {
  /// Practice items by student ID
  ///
  /// Copied from [practiceItemsByStudent].
  PracticeItemsByStudentProvider(String studentId)
    : this._internal(
        (ref) =>
            practiceItemsByStudent(ref as PracticeItemsByStudentRef, studentId),
        from: practiceItemsByStudentProvider,
        name: r'practiceItemsByStudentProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$practiceItemsByStudentHash,
        dependencies: PracticeItemsByStudentFamily._dependencies,
        allTransitiveDependencies:
            PracticeItemsByStudentFamily._allTransitiveDependencies,
        studentId: studentId,
      );

  PracticeItemsByStudentProvider._internal(
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
    FutureOr<List<PracticeItem>> Function(PracticeItemsByStudentRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PracticeItemsByStudentProvider._internal(
        (ref) => create(ref as PracticeItemsByStudentRef),
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
  FutureProviderElement<List<PracticeItem>> createElement() {
    return _PracticeItemsByStudentProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PracticeItemsByStudentProvider &&
        other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin PracticeItemsByStudentRef on FutureProviderRef<List<PracticeItem>> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _PracticeItemsByStudentProviderElement
    extends FutureProviderElement<List<PracticeItem>>
    with PracticeItemsByStudentRef {
  _PracticeItemsByStudentProviderElement(super.provider);

  @override
  String get studentId => (origin as PracticeItemsByStudentProvider).studentId;
}

String _$weeklyPracticeItemsHash() =>
    r'18f7c392522dbbf8643c08ed47226b48816ca2eb';

/// Weekly practice items for student (current week)
///
/// Copied from [weeklyPracticeItems].
@ProviderFor(weeklyPracticeItems)
const weeklyPracticeItemsProvider = WeeklyPracticeItemsFamily();

/// Weekly practice items for student (current week)
///
/// Copied from [weeklyPracticeItems].
class WeeklyPracticeItemsFamily extends Family<AsyncValue<List<PracticeItem>>> {
  /// Weekly practice items for student (current week)
  ///
  /// Copied from [weeklyPracticeItems].
  const WeeklyPracticeItemsFamily();

  /// Weekly practice items for student (current week)
  ///
  /// Copied from [weeklyPracticeItems].
  WeeklyPracticeItemsProvider call(String studentId) {
    return WeeklyPracticeItemsProvider(studentId);
  }

  @override
  WeeklyPracticeItemsProvider getProviderOverride(
    covariant WeeklyPracticeItemsProvider provider,
  ) {
    return call(provider.studentId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'weeklyPracticeItemsProvider';
}

/// Weekly practice items for student (current week)
///
/// Copied from [weeklyPracticeItems].
class WeeklyPracticeItemsProvider extends FutureProvider<List<PracticeItem>> {
  /// Weekly practice items for student (current week)
  ///
  /// Copied from [weeklyPracticeItems].
  WeeklyPracticeItemsProvider(String studentId)
    : this._internal(
        (ref) => weeklyPracticeItems(ref as WeeklyPracticeItemsRef, studentId),
        from: weeklyPracticeItemsProvider,
        name: r'weeklyPracticeItemsProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$weeklyPracticeItemsHash,
        dependencies: WeeklyPracticeItemsFamily._dependencies,
        allTransitiveDependencies:
            WeeklyPracticeItemsFamily._allTransitiveDependencies,
        studentId: studentId,
      );

  WeeklyPracticeItemsProvider._internal(
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
    FutureOr<List<PracticeItem>> Function(WeeklyPracticeItemsRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: WeeklyPracticeItemsProvider._internal(
        (ref) => create(ref as WeeklyPracticeItemsRef),
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
  FutureProviderElement<List<PracticeItem>> createElement() {
    return _WeeklyPracticeItemsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is WeeklyPracticeItemsProvider && other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin WeeklyPracticeItemsRef on FutureProviderRef<List<PracticeItem>> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _WeeklyPracticeItemsProviderElement
    extends FutureProviderElement<List<PracticeItem>>
    with WeeklyPracticeItemsRef {
  _WeeklyPracticeItemsProviderElement(super.provider);

  @override
  String get studentId => (origin as WeeklyPracticeItemsProvider).studentId;
}

String _$incompletePracticeItemsHash() =>
    r'86479e147dc4ea66d233e60a6381ab4901320589';

/// Incomplete practice items for student (for dashboard)
///
/// Copied from [incompletePracticeItems].
@ProviderFor(incompletePracticeItems)
const incompletePracticeItemsProvider = IncompletePracticeItemsFamily();

/// Incomplete practice items for student (for dashboard)
///
/// Copied from [incompletePracticeItems].
class IncompletePracticeItemsFamily
    extends Family<AsyncValue<List<PracticeItem>>> {
  /// Incomplete practice items for student (for dashboard)
  ///
  /// Copied from [incompletePracticeItems].
  const IncompletePracticeItemsFamily();

  /// Incomplete practice items for student (for dashboard)
  ///
  /// Copied from [incompletePracticeItems].
  IncompletePracticeItemsProvider call(String studentId) {
    return IncompletePracticeItemsProvider(studentId);
  }

  @override
  IncompletePracticeItemsProvider getProviderOverride(
    covariant IncompletePracticeItemsProvider provider,
  ) {
    return call(provider.studentId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'incompletePracticeItemsProvider';
}

/// Incomplete practice items for student (for dashboard)
///
/// Copied from [incompletePracticeItems].
class IncompletePracticeItemsProvider
    extends FutureProvider<List<PracticeItem>> {
  /// Incomplete practice items for student (for dashboard)
  ///
  /// Copied from [incompletePracticeItems].
  IncompletePracticeItemsProvider(String studentId)
    : this._internal(
        (ref) => incompletePracticeItems(
          ref as IncompletePracticeItemsRef,
          studentId,
        ),
        from: incompletePracticeItemsProvider,
        name: r'incompletePracticeItemsProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$incompletePracticeItemsHash,
        dependencies: IncompletePracticeItemsFamily._dependencies,
        allTransitiveDependencies:
            IncompletePracticeItemsFamily._allTransitiveDependencies,
        studentId: studentId,
      );

  IncompletePracticeItemsProvider._internal(
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
    FutureOr<List<PracticeItem>> Function(IncompletePracticeItemsRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: IncompletePracticeItemsProvider._internal(
        (ref) => create(ref as IncompletePracticeItemsRef),
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
  FutureProviderElement<List<PracticeItem>> createElement() {
    return _IncompletePracticeItemsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is IncompletePracticeItemsProvider &&
        other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin IncompletePracticeItemsRef on FutureProviderRef<List<PracticeItem>> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _IncompletePracticeItemsProviderElement
    extends FutureProviderElement<List<PracticeItem>>
    with IncompletePracticeItemsRef {
  _IncompletePracticeItemsProviderElement(super.provider);

  @override
  String get studentId => (origin as IncompletePracticeItemsProvider).studentId;
}

String _$awaitingFeedbackHash() => r'7727891a22045712ecbe521df39860466a075ce9';

/// Practice items awaiting teacher feedback
///
/// Copied from [awaitingFeedback].
@ProviderFor(awaitingFeedback)
final awaitingFeedbackProvider = FutureProvider<List<PracticeItem>>.internal(
  awaitingFeedback,
  name: r'awaitingFeedbackProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$awaitingFeedbackHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AwaitingFeedbackRef = FutureProviderRef<List<PracticeItem>>;
String _$practiceItemByIdHash() => r'058f84c25b55bb9b22ecf1b207ebce2c3e71b079';

/// Single practice item by ID
///
/// Copied from [practiceItemById].
@ProviderFor(practiceItemById)
const practiceItemByIdProvider = PracticeItemByIdFamily();

/// Single practice item by ID
///
/// Copied from [practiceItemById].
class PracticeItemByIdFamily extends Family<AsyncValue<PracticeItem?>> {
  /// Single practice item by ID
  ///
  /// Copied from [practiceItemById].
  const PracticeItemByIdFamily();

  /// Single practice item by ID
  ///
  /// Copied from [practiceItemById].
  PracticeItemByIdProvider call(String id) {
    return PracticeItemByIdProvider(id);
  }

  @override
  PracticeItemByIdProvider getProviderOverride(
    covariant PracticeItemByIdProvider provider,
  ) {
    return call(provider.id);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'practiceItemByIdProvider';
}

/// Single practice item by ID
///
/// Copied from [practiceItemById].
class PracticeItemByIdProvider extends FutureProvider<PracticeItem?> {
  /// Single practice item by ID
  ///
  /// Copied from [practiceItemById].
  PracticeItemByIdProvider(String id)
    : this._internal(
        (ref) => practiceItemById(ref as PracticeItemByIdRef, id),
        from: practiceItemByIdProvider,
        name: r'practiceItemByIdProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$practiceItemByIdHash,
        dependencies: PracticeItemByIdFamily._dependencies,
        allTransitiveDependencies:
            PracticeItemByIdFamily._allTransitiveDependencies,
        id: id,
      );

  PracticeItemByIdProvider._internal(
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
    FutureOr<PracticeItem?> Function(PracticeItemByIdRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PracticeItemByIdProvider._internal(
        (ref) => create(ref as PracticeItemByIdRef),
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
  FutureProviderElement<PracticeItem?> createElement() {
    return _PracticeItemByIdProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PracticeItemByIdProvider && other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin PracticeItemByIdRef on FutureProviderRef<PracticeItem?> {
  /// The parameter `id` of this provider.
  String get id;
}

class _PracticeItemByIdProviderElement
    extends FutureProviderElement<PracticeItem?>
    with PracticeItemByIdRef {
  _PracticeItemByIdProviderElement(super.provider);

  @override
  String get id => (origin as PracticeItemByIdProvider).id;
}

String _$currentStudentIdHash() => r'3fe269cf04c36a61a4869c2cd2f60b9fdee8ad34';

/// Current student ID provider (placeholder - should come from auth/navigation)
///
/// Copied from [CurrentStudentId].
@ProviderFor(CurrentStudentId)
final currentStudentIdProvider =
    NotifierProvider<CurrentStudentId, String?>.internal(
      CurrentStudentId.new,
      name: r'currentStudentIdProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$currentStudentIdHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$CurrentStudentId = Notifier<String?>;
String _$practiceItemsNotifierHash() =>
    r'2803415815fc325a7e58f87d90688a6c17a9e86e';

abstract class _$PracticeItemsNotifier
    extends BuildlessAsyncNotifier<List<PracticeItem>> {
  late final String lessonId;

  FutureOr<List<PracticeItem>> build(String lessonId);
}

/// Notifier for practice item CRUD operations (lesson-based)
///
/// Copied from [PracticeItemsNotifier].
@ProviderFor(PracticeItemsNotifier)
const practiceItemsNotifierProvider = PracticeItemsNotifierFamily();

/// Notifier for practice item CRUD operations (lesson-based)
///
/// Copied from [PracticeItemsNotifier].
class PracticeItemsNotifierFamily
    extends Family<AsyncValue<List<PracticeItem>>> {
  /// Notifier for practice item CRUD operations (lesson-based)
  ///
  /// Copied from [PracticeItemsNotifier].
  const PracticeItemsNotifierFamily();

  /// Notifier for practice item CRUD operations (lesson-based)
  ///
  /// Copied from [PracticeItemsNotifier].
  PracticeItemsNotifierProvider call(String lessonId) {
    return PracticeItemsNotifierProvider(lessonId);
  }

  @override
  PracticeItemsNotifierProvider getProviderOverride(
    covariant PracticeItemsNotifierProvider provider,
  ) {
    return call(provider.lessonId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'practiceItemsNotifierProvider';
}

/// Notifier for practice item CRUD operations (lesson-based)
///
/// Copied from [PracticeItemsNotifier].
class PracticeItemsNotifierProvider
    extends
        AsyncNotifierProviderImpl<PracticeItemsNotifier, List<PracticeItem>> {
  /// Notifier for practice item CRUD operations (lesson-based)
  ///
  /// Copied from [PracticeItemsNotifier].
  PracticeItemsNotifierProvider(String lessonId)
    : this._internal(
        () => PracticeItemsNotifier()..lessonId = lessonId,
        from: practiceItemsNotifierProvider,
        name: r'practiceItemsNotifierProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$practiceItemsNotifierHash,
        dependencies: PracticeItemsNotifierFamily._dependencies,
        allTransitiveDependencies:
            PracticeItemsNotifierFamily._allTransitiveDependencies,
        lessonId: lessonId,
      );

  PracticeItemsNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.lessonId,
  }) : super.internal();

  final String lessonId;

  @override
  FutureOr<List<PracticeItem>> runNotifierBuild(
    covariant PracticeItemsNotifier notifier,
  ) {
    return notifier.build(lessonId);
  }

  @override
  Override overrideWith(PracticeItemsNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: PracticeItemsNotifierProvider._internal(
        () => create()..lessonId = lessonId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        lessonId: lessonId,
      ),
    );
  }

  @override
  AsyncNotifierProviderElement<PracticeItemsNotifier, List<PracticeItem>>
  createElement() {
    return _PracticeItemsNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PracticeItemsNotifierProvider && other.lessonId == lessonId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, lessonId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin PracticeItemsNotifierRef on AsyncNotifierProviderRef<List<PracticeItem>> {
  /// The parameter `lessonId` of this provider.
  String get lessonId;
}

class _PracticeItemsNotifierProviderElement
    extends
        AsyncNotifierProviderElement<PracticeItemsNotifier, List<PracticeItem>>
    with PracticeItemsNotifierRef {
  _PracticeItemsNotifierProviderElement(super.provider);

  @override
  String get lessonId => (origin as PracticeItemsNotifierProvider).lessonId;
}

String _$studentPracticeNotifierHash() =>
    r'233fac96d40d911cdb583fad453e309267029141';

abstract class _$StudentPracticeNotifier
    extends BuildlessAsyncNotifier<List<PracticeItem>> {
  late final String studentId;

  FutureOr<List<PracticeItem>> build(String studentId);
}

/// Notifier for student's practice items (student-based operations)
///
/// Copied from [StudentPracticeNotifier].
@ProviderFor(StudentPracticeNotifier)
const studentPracticeNotifierProvider = StudentPracticeNotifierFamily();

/// Notifier for student's practice items (student-based operations)
///
/// Copied from [StudentPracticeNotifier].
class StudentPracticeNotifierFamily
    extends Family<AsyncValue<List<PracticeItem>>> {
  /// Notifier for student's practice items (student-based operations)
  ///
  /// Copied from [StudentPracticeNotifier].
  const StudentPracticeNotifierFamily();

  /// Notifier for student's practice items (student-based operations)
  ///
  /// Copied from [StudentPracticeNotifier].
  StudentPracticeNotifierProvider call(String studentId) {
    return StudentPracticeNotifierProvider(studentId);
  }

  @override
  StudentPracticeNotifierProvider getProviderOverride(
    covariant StudentPracticeNotifierProvider provider,
  ) {
    return call(provider.studentId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'studentPracticeNotifierProvider';
}

/// Notifier for student's practice items (student-based operations)
///
/// Copied from [StudentPracticeNotifier].
class StudentPracticeNotifierProvider
    extends
        AsyncNotifierProviderImpl<StudentPracticeNotifier, List<PracticeItem>> {
  /// Notifier for student's practice items (student-based operations)
  ///
  /// Copied from [StudentPracticeNotifier].
  StudentPracticeNotifierProvider(String studentId)
    : this._internal(
        () => StudentPracticeNotifier()..studentId = studentId,
        from: studentPracticeNotifierProvider,
        name: r'studentPracticeNotifierProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$studentPracticeNotifierHash,
        dependencies: StudentPracticeNotifierFamily._dependencies,
        allTransitiveDependencies:
            StudentPracticeNotifierFamily._allTransitiveDependencies,
        studentId: studentId,
      );

  StudentPracticeNotifierProvider._internal(
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
  FutureOr<List<PracticeItem>> runNotifierBuild(
    covariant StudentPracticeNotifier notifier,
  ) {
    return notifier.build(studentId);
  }

  @override
  Override overrideWith(StudentPracticeNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: StudentPracticeNotifierProvider._internal(
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
  AsyncNotifierProviderElement<StudentPracticeNotifier, List<PracticeItem>>
  createElement() {
    return _StudentPracticeNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StudentPracticeNotifierProvider &&
        other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin StudentPracticeNotifierRef
    on AsyncNotifierProviderRef<List<PracticeItem>> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _StudentPracticeNotifierProviderElement
    extends
        AsyncNotifierProviderElement<
          StudentPracticeNotifier,
          List<PracticeItem>
        >
    with StudentPracticeNotifierRef {
  _StudentPracticeNotifierProviderElement(super.provider);

  @override
  String get studentId => (origin as StudentPracticeNotifierProvider).studentId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
