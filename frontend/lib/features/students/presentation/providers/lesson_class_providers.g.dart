// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lesson_class_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$lessonClassRepositoryHash() =>
    r'95606cb8068ef29b8b7836cf8745da759e402ff8';

/// Repository provider for LessonClass.
///
/// Copied from [lessonClassRepository].
@ProviderFor(lessonClassRepository)
final lessonClassRepositoryProvider =
    AutoDisposeProvider<LessonClassRepository>.internal(
  lessonClassRepository,
  name: r'lessonClassRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$lessonClassRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LessonClassRepositoryRef
    = AutoDisposeProviderRef<LessonClassRepository>;
String _$teacherLessonClassesHash() =>
    r'4c766108a151826da95eca968d1d2e37974d05c5';

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

/// Get all classes for the current teacher.
///
/// Copied from [teacherLessonClasses].
@ProviderFor(teacherLessonClasses)
const teacherLessonClassesProvider = TeacherLessonClassesFamily();

/// Get all classes for the current teacher.
///
/// Copied from [teacherLessonClasses].
class TeacherLessonClassesFamily extends Family<AsyncValue<List<LessonClass>>> {
  /// Get all classes for the current teacher.
  ///
  /// Copied from [teacherLessonClasses].
  const TeacherLessonClassesFamily();

  /// Get all classes for the current teacher.
  ///
  /// Copied from [teacherLessonClasses].
  TeacherLessonClassesProvider call(
    String teacherId,
  ) {
    return TeacherLessonClassesProvider(
      teacherId,
    );
  }

  @override
  TeacherLessonClassesProvider getProviderOverride(
    covariant TeacherLessonClassesProvider provider,
  ) {
    return call(
      provider.teacherId,
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
  String? get name => r'teacherLessonClassesProvider';
}

/// Get all classes for the current teacher.
///
/// Copied from [teacherLessonClasses].
class TeacherLessonClassesProvider
    extends AutoDisposeFutureProvider<List<LessonClass>> {
  /// Get all classes for the current teacher.
  ///
  /// Copied from [teacherLessonClasses].
  TeacherLessonClassesProvider(
    String teacherId,
  ) : this._internal(
          (ref) => teacherLessonClasses(
            ref as TeacherLessonClassesRef,
            teacherId,
          ),
          from: teacherLessonClassesProvider,
          name: r'teacherLessonClassesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$teacherLessonClassesHash,
          dependencies: TeacherLessonClassesFamily._dependencies,
          allTransitiveDependencies:
              TeacherLessonClassesFamily._allTransitiveDependencies,
          teacherId: teacherId,
        );

  TeacherLessonClassesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.teacherId,
  }) : super.internal();

  final String teacherId;

  @override
  Override overrideWith(
    FutureOr<List<LessonClass>> Function(TeacherLessonClassesRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TeacherLessonClassesProvider._internal(
        (ref) => create(ref as TeacherLessonClassesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        teacherId: teacherId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<LessonClass>> createElement() {
    return _TeacherLessonClassesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TeacherLessonClassesProvider &&
        other.teacherId == teacherId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, teacherId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin TeacherLessonClassesRef
    on AutoDisposeFutureProviderRef<List<LessonClass>> {
  /// The parameter `teacherId` of this provider.
  String get teacherId;
}

class _TeacherLessonClassesProviderElement
    extends AutoDisposeFutureProviderElement<List<LessonClass>>
    with TeacherLessonClassesRef {
  _TeacherLessonClassesProviderElement(super.provider);

  @override
  String get teacherId => (origin as TeacherLessonClassesProvider).teacherId;
}

String _$lessonClassHash() => r'f27f10f74f12ca1a4a1e557294c4771e72e92e36';

/// Get a single class by ID.
///
/// Copied from [lessonClass].
@ProviderFor(lessonClass)
const lessonClassProvider = LessonClassFamily();

/// Get a single class by ID.
///
/// Copied from [lessonClass].
class LessonClassFamily extends Family<AsyncValue<LessonClass?>> {
  /// Get a single class by ID.
  ///
  /// Copied from [lessonClass].
  const LessonClassFamily();

  /// Get a single class by ID.
  ///
  /// Copied from [lessonClass].
  LessonClassProvider call(
    String classId,
  ) {
    return LessonClassProvider(
      classId,
    );
  }

  @override
  LessonClassProvider getProviderOverride(
    covariant LessonClassProvider provider,
  ) {
    return call(
      provider.classId,
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
  String? get name => r'lessonClassProvider';
}

/// Get a single class by ID.
///
/// Copied from [lessonClass].
class LessonClassProvider extends AutoDisposeFutureProvider<LessonClass?> {
  /// Get a single class by ID.
  ///
  /// Copied from [lessonClass].
  LessonClassProvider(
    String classId,
  ) : this._internal(
          (ref) => lessonClass(
            ref as LessonClassRef,
            classId,
          ),
          from: lessonClassProvider,
          name: r'lessonClassProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$lessonClassHash,
          dependencies: LessonClassFamily._dependencies,
          allTransitiveDependencies:
              LessonClassFamily._allTransitiveDependencies,
          classId: classId,
        );

  LessonClassProvider._internal(
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
    FutureOr<LessonClass?> Function(LessonClassRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: LessonClassProvider._internal(
        (ref) => create(ref as LessonClassRef),
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
  AutoDisposeFutureProviderElement<LessonClass?> createElement() {
    return _LessonClassProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is LessonClassProvider && other.classId == classId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, classId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin LessonClassRef on AutoDisposeFutureProviderRef<LessonClass?> {
  /// The parameter `classId` of this provider.
  String get classId;
}

class _LessonClassProviderElement
    extends AutoDisposeFutureProviderElement<LessonClass?> with LessonClassRef {
  _LessonClassProviderElement(super.provider);

  @override
  String get classId => (origin as LessonClassProvider).classId;
}

String _$lessonClassNotifierHash() =>
    r'60dacf18f4107272022dbc24e031fa1a7bd6885a';

abstract class _$LessonClassNotifier
    extends BuildlessAutoDisposeAsyncNotifier<List<LessonClass>> {
  late final String teacherId;

  FutureOr<List<LessonClass>> build(
    String teacherId,
  );
}

/// Notifier for managing LessonClass CRUD operations.
///
/// Copied from [LessonClassNotifier].
@ProviderFor(LessonClassNotifier)
const lessonClassNotifierProvider = LessonClassNotifierFamily();

/// Notifier for managing LessonClass CRUD operations.
///
/// Copied from [LessonClassNotifier].
class LessonClassNotifierFamily extends Family<AsyncValue<List<LessonClass>>> {
  /// Notifier for managing LessonClass CRUD operations.
  ///
  /// Copied from [LessonClassNotifier].
  const LessonClassNotifierFamily();

  /// Notifier for managing LessonClass CRUD operations.
  ///
  /// Copied from [LessonClassNotifier].
  LessonClassNotifierProvider call(
    String teacherId,
  ) {
    return LessonClassNotifierProvider(
      teacherId,
    );
  }

  @override
  LessonClassNotifierProvider getProviderOverride(
    covariant LessonClassNotifierProvider provider,
  ) {
    return call(
      provider.teacherId,
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
  String? get name => r'lessonClassNotifierProvider';
}

/// Notifier for managing LessonClass CRUD operations.
///
/// Copied from [LessonClassNotifier].
class LessonClassNotifierProvider extends AutoDisposeAsyncNotifierProviderImpl<
    LessonClassNotifier, List<LessonClass>> {
  /// Notifier for managing LessonClass CRUD operations.
  ///
  /// Copied from [LessonClassNotifier].
  LessonClassNotifierProvider(
    String teacherId,
  ) : this._internal(
          () => LessonClassNotifier()..teacherId = teacherId,
          from: lessonClassNotifierProvider,
          name: r'lessonClassNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$lessonClassNotifierHash,
          dependencies: LessonClassNotifierFamily._dependencies,
          allTransitiveDependencies:
              LessonClassNotifierFamily._allTransitiveDependencies,
          teacherId: teacherId,
        );

  LessonClassNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.teacherId,
  }) : super.internal();

  final String teacherId;

  @override
  FutureOr<List<LessonClass>> runNotifierBuild(
    covariant LessonClassNotifier notifier,
  ) {
    return notifier.build(
      teacherId,
    );
  }

  @override
  Override overrideWith(LessonClassNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: LessonClassNotifierProvider._internal(
        () => create()..teacherId = teacherId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        teacherId: teacherId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<LessonClassNotifier,
      List<LessonClass>> createElement() {
    return _LessonClassNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is LessonClassNotifierProvider && other.teacherId == teacherId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, teacherId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin LessonClassNotifierRef
    on AutoDisposeAsyncNotifierProviderRef<List<LessonClass>> {
  /// The parameter `teacherId` of this provider.
  String get teacherId;
}

class _LessonClassNotifierProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<LessonClassNotifier,
        List<LessonClass>> with LessonClassNotifierRef {
  _LessonClassNotifierProviderElement(super.provider);

  @override
  String get teacherId => (origin as LessonClassNotifierProvider).teacherId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
