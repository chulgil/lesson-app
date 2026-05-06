// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lesson_crud_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$lessonsHash() => r'5d23fead06909e70dec6b5b854926a6417031821';

/// All lessons provider
///
/// Copied from [lessons].
@ProviderFor(lessons)
final lessonsProvider = FutureProvider<List<Lesson>>.internal(
  lessons,
  name: r'lessonsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$lessonsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef LessonsRef = FutureProviderRef<List<Lesson>>;
String _$lessonHash() => r'cc8bfef39026d4157579dcd1bab3a9d7a833248d';

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

/// Single lesson provider
///
/// Copied from [lesson].
@ProviderFor(lesson)
const lessonProvider = LessonFamily();

/// Single lesson provider
///
/// Copied from [lesson].
class LessonFamily extends Family<AsyncValue<Lesson?>> {
  /// Single lesson provider
  ///
  /// Copied from [lesson].
  const LessonFamily();

  /// Single lesson provider
  ///
  /// Copied from [lesson].
  LessonProvider call(String id) {
    return LessonProvider(id);
  }

  @override
  LessonProvider getProviderOverride(covariant LessonProvider provider) {
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
  String? get name => r'lessonProvider';
}

/// Single lesson provider
///
/// Copied from [lesson].
class LessonProvider extends FutureProvider<Lesson?> {
  /// Single lesson provider
  ///
  /// Copied from [lesson].
  LessonProvider(String id)
    : this._internal(
        (ref) => lesson(ref as LessonRef, id),
        from: lessonProvider,
        name: r'lessonProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product') ? null : _$lessonHash,
        dependencies: LessonFamily._dependencies,
        allTransitiveDependencies: LessonFamily._allTransitiveDependencies,
        id: id,
      );

  LessonProvider._internal(
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
  Override overrideWith(FutureOr<Lesson?> Function(LessonRef provider) create) {
    return ProviderOverride(
      origin: this,
      override: LessonProvider._internal(
        (ref) => create(ref as LessonRef),
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
  FutureProviderElement<Lesson?> createElement() {
    return _LessonProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is LessonProvider && other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin LessonRef on FutureProviderRef<Lesson?> {
  /// The parameter `id` of this provider.
  String get id;
}

class _LessonProviderElement extends FutureProviderElement<Lesson?>
    with LessonRef {
  _LessonProviderElement(super.provider);

  @override
  String get id => (origin as LessonProvider).id;
}

String _$lessonsByStudentHash() => r'398ab8c1935fddd677a3d632cbebb4e88a6530ed';

/// Lessons by student provider
///
/// Copied from [lessonsByStudent].
@ProviderFor(lessonsByStudent)
const lessonsByStudentProvider = LessonsByStudentFamily();

/// Lessons by student provider
///
/// Copied from [lessonsByStudent].
class LessonsByStudentFamily extends Family<AsyncValue<List<Lesson>>> {
  /// Lessons by student provider
  ///
  /// Copied from [lessonsByStudent].
  const LessonsByStudentFamily();

  /// Lessons by student provider
  ///
  /// Copied from [lessonsByStudent].
  LessonsByStudentProvider call(String studentId) {
    return LessonsByStudentProvider(studentId);
  }

  @override
  LessonsByStudentProvider getProviderOverride(
    covariant LessonsByStudentProvider provider,
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
  String? get name => r'lessonsByStudentProvider';
}

/// Lessons by student provider
///
/// Copied from [lessonsByStudent].
class LessonsByStudentProvider extends FutureProvider<List<Lesson>> {
  /// Lessons by student provider
  ///
  /// Copied from [lessonsByStudent].
  LessonsByStudentProvider(String studentId)
    : this._internal(
        (ref) => lessonsByStudent(ref as LessonsByStudentRef, studentId),
        from: lessonsByStudentProvider,
        name: r'lessonsByStudentProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$lessonsByStudentHash,
        dependencies: LessonsByStudentFamily._dependencies,
        allTransitiveDependencies:
            LessonsByStudentFamily._allTransitiveDependencies,
        studentId: studentId,
      );

  LessonsByStudentProvider._internal(
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
    FutureOr<List<Lesson>> Function(LessonsByStudentRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: LessonsByStudentProvider._internal(
        (ref) => create(ref as LessonsByStudentRef),
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
  FutureProviderElement<List<Lesson>> createElement() {
    return _LessonsByStudentProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is LessonsByStudentProvider && other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin LessonsByStudentRef on FutureProviderRef<List<Lesson>> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _LessonsByStudentProviderElement
    extends FutureProviderElement<List<Lesson>>
    with LessonsByStudentRef {
  _LessonsByStudentProviderElement(super.provider);

  @override
  String get studentId => (origin as LessonsByStudentProvider).studentId;
}

String _$lessonsByDateHash() => r'1856e5edd68e69da11a9365bda1e9a1a77bcde9e';

/// Lessons by date provider
///
/// Copied from [lessonsByDate].
@ProviderFor(lessonsByDate)
const lessonsByDateProvider = LessonsByDateFamily();

/// Lessons by date provider
///
/// Copied from [lessonsByDate].
class LessonsByDateFamily extends Family<AsyncValue<List<Lesson>>> {
  /// Lessons by date provider
  ///
  /// Copied from [lessonsByDate].
  const LessonsByDateFamily();

  /// Lessons by date provider
  ///
  /// Copied from [lessonsByDate].
  LessonsByDateProvider call(DateTime date) {
    return LessonsByDateProvider(date);
  }

  @override
  LessonsByDateProvider getProviderOverride(
    covariant LessonsByDateProvider provider,
  ) {
    return call(provider.date);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'lessonsByDateProvider';
}

/// Lessons by date provider
///
/// Copied from [lessonsByDate].
class LessonsByDateProvider extends FutureProvider<List<Lesson>> {
  /// Lessons by date provider
  ///
  /// Copied from [lessonsByDate].
  LessonsByDateProvider(DateTime date)
    : this._internal(
        (ref) => lessonsByDate(ref as LessonsByDateRef, date),
        from: lessonsByDateProvider,
        name: r'lessonsByDateProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$lessonsByDateHash,
        dependencies: LessonsByDateFamily._dependencies,
        allTransitiveDependencies:
            LessonsByDateFamily._allTransitiveDependencies,
        date: date,
      );

  LessonsByDateProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.date,
  }) : super.internal();

  final DateTime date;

  @override
  Override overrideWith(
    FutureOr<List<Lesson>> Function(LessonsByDateRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: LessonsByDateProvider._internal(
        (ref) => create(ref as LessonsByDateRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        date: date,
      ),
    );
  }

  @override
  FutureProviderElement<List<Lesson>> createElement() {
    return _LessonsByDateProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is LessonsByDateProvider && other.date == date;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, date.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin LessonsByDateRef on FutureProviderRef<List<Lesson>> {
  /// The parameter `date` of this provider.
  DateTime get date;
}

class _LessonsByDateProviderElement extends FutureProviderElement<List<Lesson>>
    with LessonsByDateRef {
  _LessonsByDateProviderElement(super.provider);

  @override
  DateTime get date => (origin as LessonsByDateProvider).date;
}

String _$upcomingLessonsHash() => r'b7e6482f8dcab4d3eaa97b963eb0fc8d12dd3a65';

/// Upcoming lessons provider
///
/// Copied from [upcomingLessons].
@ProviderFor(upcomingLessons)
final upcomingLessonsProvider = FutureProvider<List<Lesson>>.internal(
  upcomingLessons,
  name: r'upcomingLessonsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$upcomingLessonsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef UpcomingLessonsRef = FutureProviderRef<List<Lesson>>;
String _$recentLessonsHash() => r'4506dbef275f6f7fd61645fd24b11626d6f42da7';

/// Recent lessons provider
///
/// Copied from [recentLessons].
@ProviderFor(recentLessons)
final recentLessonsProvider = FutureProvider<List<Lesson>>.internal(
  recentLessons,
  name: r'recentLessonsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$recentLessonsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef RecentLessonsRef = FutureProviderRef<List<Lesson>>;
String _$todayLessonsHash() => r'86857cff138e2a3310ba15ff411889b823372167';

/// Today's lessons provider
///
/// Copied from [todayLessons].
@ProviderFor(todayLessons)
final todayLessonsProvider = FutureProvider<List<Lesson>>.internal(
  todayLessons,
  name: r'todayLessonsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$todayLessonsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef TodayLessonsRef = FutureProviderRef<List<Lesson>>;
String _$lessonsNotifierHash() => r'703437b5751ff16e2a5441b83758a0c004a47051';

/// Lesson list notifier for CRUD operations
///
/// Copied from [LessonsNotifier].
@ProviderFor(LessonsNotifier)
final lessonsNotifierProvider =
    AsyncNotifierProvider<LessonsNotifier, List<Lesson>>.internal(
      LessonsNotifier.new,
      name: r'lessonsNotifierProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$lessonsNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$LessonsNotifier = AsyncNotifier<List<Lesson>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
