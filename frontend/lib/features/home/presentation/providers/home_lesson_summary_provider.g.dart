// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_lesson_summary_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$homeStudentsHash() => r'b1a5be9775402c6aca3d43cde33a88e2c903ae95';

/// See also [homeStudents].
@ProviderFor(homeStudents)
final homeStudentsProvider = FutureProvider<List<Student>>.internal(
  homeStudents,
  name: r'homeStudentsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$homeStudentsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef HomeStudentsRef = FutureProviderRef<List<Student>>;
String _$homeLessonsHash() => r'0bd94c849fab7a1b3efe12c71ba3e8adc3aacbf4';

/// See also [_homeLessons].
@ProviderFor(_homeLessons)
final _homeLessonsProvider = FutureProvider<List<Lesson>>.internal(
  _homeLessons,
  name: r'_homeLessonsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$homeLessonsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _HomeLessonsRef = FutureProviderRef<List<Lesson>>;
String _$homeHasLessonsHash() => r'fc52bc8030dda6c7c91f43b7316551687627866a';

/// See also [homeHasLessons].
@ProviderFor(homeHasLessons)
final homeHasLessonsProvider = Provider<bool>.internal(
  homeHasLessons,
  name: r'homeHasLessonsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$homeHasLessonsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef HomeHasLessonsRef = ProviderRef<bool>;
String _$homeHasCompletedLessonHash() =>
    r'f44f75831abf9d670e8cdbc6a564c8a19c1acad4';

/// See also [homeHasCompletedLesson].
@ProviderFor(homeHasCompletedLesson)
final homeHasCompletedLessonProvider = Provider<bool>.internal(
  homeHasCompletedLesson,
  name: r'homeHasCompletedLessonProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$homeHasCompletedLessonHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef HomeHasCompletedLessonRef = ProviderRef<bool>;
String _$homeFirstLessonIdHash() => r'7eb7a8abedae32878060365475385c68a78da63e';

/// See also [homeFirstLessonId].
@ProviderFor(homeFirstLessonId)
final homeFirstLessonIdProvider = Provider<String?>.internal(
  homeFirstLessonId,
  name: r'homeFirstLessonIdProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$homeFirstLessonIdHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef HomeFirstLessonIdRef = ProviderRef<String?>;
String _$homeActiveStudentMembershipsHash() =>
    r'd124109a4ae3d3f0b36d35e44a114ced9dcfc95f';

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

/// See also [homeActiveStudentMemberships].
@ProviderFor(homeActiveStudentMemberships)
const homeActiveStudentMembershipsProvider =
    HomeActiveStudentMembershipsFamily();

/// See also [homeActiveStudentMemberships].
class HomeActiveStudentMembershipsFamily
    extends Family<AsyncValue<List<ClassMembership>>> {
  /// See also [homeActiveStudentMemberships].
  const HomeActiveStudentMembershipsFamily();

  /// See also [homeActiveStudentMemberships].
  HomeActiveStudentMembershipsProvider call(String studentId) {
    return HomeActiveStudentMembershipsProvider(studentId);
  }

  @override
  HomeActiveStudentMembershipsProvider getProviderOverride(
    covariant HomeActiveStudentMembershipsProvider provider,
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
  String? get name => r'homeActiveStudentMembershipsProvider';
}

/// See also [homeActiveStudentMemberships].
class HomeActiveStudentMembershipsProvider
    extends FutureProvider<List<ClassMembership>> {
  /// See also [homeActiveStudentMemberships].
  HomeActiveStudentMembershipsProvider(String studentId)
    : this._internal(
        (ref) => homeActiveStudentMemberships(
          ref as HomeActiveStudentMembershipsRef,
          studentId,
        ),
        from: homeActiveStudentMembershipsProvider,
        name: r'homeActiveStudentMembershipsProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$homeActiveStudentMembershipsHash,
        dependencies: HomeActiveStudentMembershipsFamily._dependencies,
        allTransitiveDependencies:
            HomeActiveStudentMembershipsFamily._allTransitiveDependencies,
        studentId: studentId,
      );

  HomeActiveStudentMembershipsProvider._internal(
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
    FutureOr<List<ClassMembership>> Function(
      HomeActiveStudentMembershipsRef provider,
    )
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: HomeActiveStudentMembershipsProvider._internal(
        (ref) => create(ref as HomeActiveStudentMembershipsRef),
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
  FutureProviderElement<List<ClassMembership>> createElement() {
    return _HomeActiveStudentMembershipsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is HomeActiveStudentMembershipsProvider &&
        other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin HomeActiveStudentMembershipsRef
    on FutureProviderRef<List<ClassMembership>> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _HomeActiveStudentMembershipsProviderElement
    extends FutureProviderElement<List<ClassMembership>>
    with HomeActiveStudentMembershipsRef {
  _HomeActiveStudentMembershipsProviderElement(super.provider);

  @override
  String get studentId =>
      (origin as HomeActiveStudentMembershipsProvider).studentId;
}

String _$homeActiveStudentSubscriptionsHash() =>
    r'56997d33fe433e8142760b11eae8124539627f9b';

/// See also [homeActiveStudentSubscriptions].
@ProviderFor(homeActiveStudentSubscriptions)
const homeActiveStudentSubscriptionsProvider =
    HomeActiveStudentSubscriptionsFamily();

/// See also [homeActiveStudentSubscriptions].
class HomeActiveStudentSubscriptionsFamily
    extends Family<AsyncValue<List<Subscription>>> {
  /// See also [homeActiveStudentSubscriptions].
  const HomeActiveStudentSubscriptionsFamily();

  /// See also [homeActiveStudentSubscriptions].
  HomeActiveStudentSubscriptionsProvider call(String studentId) {
    return HomeActiveStudentSubscriptionsProvider(studentId);
  }

  @override
  HomeActiveStudentSubscriptionsProvider getProviderOverride(
    covariant HomeActiveStudentSubscriptionsProvider provider,
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
  String? get name => r'homeActiveStudentSubscriptionsProvider';
}

/// See also [homeActiveStudentSubscriptions].
class HomeActiveStudentSubscriptionsProvider
    extends FutureProvider<List<Subscription>> {
  /// See also [homeActiveStudentSubscriptions].
  HomeActiveStudentSubscriptionsProvider(String studentId)
    : this._internal(
        (ref) => homeActiveStudentSubscriptions(
          ref as HomeActiveStudentSubscriptionsRef,
          studentId,
        ),
        from: homeActiveStudentSubscriptionsProvider,
        name: r'homeActiveStudentSubscriptionsProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$homeActiveStudentSubscriptionsHash,
        dependencies: HomeActiveStudentSubscriptionsFamily._dependencies,
        allTransitiveDependencies:
            HomeActiveStudentSubscriptionsFamily._allTransitiveDependencies,
        studentId: studentId,
      );

  HomeActiveStudentSubscriptionsProvider._internal(
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
    FutureOr<List<Subscription>> Function(
      HomeActiveStudentSubscriptionsRef provider,
    )
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: HomeActiveStudentSubscriptionsProvider._internal(
        (ref) => create(ref as HomeActiveStudentSubscriptionsRef),
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
  FutureProviderElement<List<Subscription>> createElement() {
    return _HomeActiveStudentSubscriptionsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is HomeActiveStudentSubscriptionsProvider &&
        other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin HomeActiveStudentSubscriptionsRef
    on FutureProviderRef<List<Subscription>> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _HomeActiveStudentSubscriptionsProviderElement
    extends FutureProviderElement<List<Subscription>>
    with HomeActiveStudentSubscriptionsRef {
  _HomeActiveStudentSubscriptionsProviderElement(super.provider);

  @override
  String get studentId =>
      (origin as HomeActiveStudentSubscriptionsProvider).studentId;
}

String _$homeLessonClassContextHash() =>
    r'fbc21f5aa37771b0d2ac2c183ab4d3ecbd164b43';

/// See also [homeLessonClassContext].
@ProviderFor(homeLessonClassContext)
const homeLessonClassContextProvider = HomeLessonClassContextFamily();

/// See also [homeLessonClassContext].
class HomeLessonClassContextFamily
    extends Family<AsyncValue<HomeLessonClassContext?>> {
  /// See also [homeLessonClassContext].
  const HomeLessonClassContextFamily();

  /// See also [homeLessonClassContext].
  HomeLessonClassContextProvider call(String classId) {
    return HomeLessonClassContextProvider(classId);
  }

  @override
  HomeLessonClassContextProvider getProviderOverride(
    covariant HomeLessonClassContextProvider provider,
  ) {
    return call(provider.classId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'homeLessonClassContextProvider';
}

/// See also [homeLessonClassContext].
class HomeLessonClassContextProvider
    extends FutureProvider<HomeLessonClassContext?> {
  /// See also [homeLessonClassContext].
  HomeLessonClassContextProvider(String classId)
    : this._internal(
        (ref) =>
            homeLessonClassContext(ref as HomeLessonClassContextRef, classId),
        from: homeLessonClassContextProvider,
        name: r'homeLessonClassContextProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$homeLessonClassContextHash,
        dependencies: HomeLessonClassContextFamily._dependencies,
        allTransitiveDependencies:
            HomeLessonClassContextFamily._allTransitiveDependencies,
        classId: classId,
      );

  HomeLessonClassContextProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.classId,
  }) : super.internal();

  final String classId;

  @override
  Override overrideWith(
    FutureOr<HomeLessonClassContext?> Function(
      HomeLessonClassContextRef provider,
    )
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: HomeLessonClassContextProvider._internal(
        (ref) => create(ref as HomeLessonClassContextRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        classId: classId,
      ),
    );
  }

  @override
  FutureProviderElement<HomeLessonClassContext?> createElement() {
    return _HomeLessonClassContextProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is HomeLessonClassContextProvider && other.classId == classId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, classId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin HomeLessonClassContextRef on FutureProviderRef<HomeLessonClassContext?> {
  /// The parameter `classId` of this provider.
  String get classId;
}

class _HomeLessonClassContextProviderElement
    extends FutureProviderElement<HomeLessonClassContext?>
    with HomeLessonClassContextRef {
  _HomeLessonClassContextProviderElement(super.provider);

  @override
  String get classId => (origin as HomeLessonClassContextProvider).classId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
