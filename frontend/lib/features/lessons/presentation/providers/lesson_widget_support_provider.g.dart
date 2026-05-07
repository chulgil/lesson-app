// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lesson_widget_support_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$lessonWidgetPracticeItemsHash() =>
    r'ca022a76fee33e052c960a97cfb31c3d6f0e5ce9';

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

/// See also [lessonWidgetPracticeItems].
@ProviderFor(lessonWidgetPracticeItems)
const lessonWidgetPracticeItemsProvider = LessonWidgetPracticeItemsFamily();

/// See also [lessonWidgetPracticeItems].
class LessonWidgetPracticeItemsFamily
    extends Family<AsyncValue<List<PracticeItem>>> {
  /// See also [lessonWidgetPracticeItems].
  const LessonWidgetPracticeItemsFamily();

  /// See also [lessonWidgetPracticeItems].
  LessonWidgetPracticeItemsProvider call(
    String lessonId,
  ) {
    return LessonWidgetPracticeItemsProvider(
      lessonId,
    );
  }

  @override
  LessonWidgetPracticeItemsProvider getProviderOverride(
    covariant LessonWidgetPracticeItemsProvider provider,
  ) {
    return call(
      provider.lessonId,
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
  String? get name => r'lessonWidgetPracticeItemsProvider';
}

/// See also [lessonWidgetPracticeItems].
class LessonWidgetPracticeItemsProvider
    extends Provider<AsyncValue<List<PracticeItem>>> {
  /// See also [lessonWidgetPracticeItems].
  LessonWidgetPracticeItemsProvider(
    String lessonId,
  ) : this._internal(
          (ref) => lessonWidgetPracticeItems(
            ref as LessonWidgetPracticeItemsRef,
            lessonId,
          ),
          from: lessonWidgetPracticeItemsProvider,
          name: r'lessonWidgetPracticeItemsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$lessonWidgetPracticeItemsHash,
          dependencies: LessonWidgetPracticeItemsFamily._dependencies,
          allTransitiveDependencies:
              LessonWidgetPracticeItemsFamily._allTransitiveDependencies,
          lessonId: lessonId,
        );

  LessonWidgetPracticeItemsProvider._internal(
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
    AsyncValue<List<PracticeItem>> Function(
            LessonWidgetPracticeItemsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: LessonWidgetPracticeItemsProvider._internal(
        (ref) => create(ref as LessonWidgetPracticeItemsRef),
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
  ProviderElement<AsyncValue<List<PracticeItem>>> createElement() {
    return _LessonWidgetPracticeItemsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is LessonWidgetPracticeItemsProvider &&
        other.lessonId == lessonId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, lessonId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin LessonWidgetPracticeItemsRef
    on ProviderRef<AsyncValue<List<PracticeItem>>> {
  /// The parameter `lessonId` of this provider.
  String get lessonId;
}

class _LessonWidgetPracticeItemsProviderElement
    extends ProviderElement<AsyncValue<List<PracticeItem>>>
    with LessonWidgetPracticeItemsRef {
  _LessonWidgetPracticeItemsProviderElement(super.provider);

  @override
  String get lessonId => (origin as LessonWidgetPracticeItemsProvider).lessonId;
}

String _$lessonWidgetStudentRepertoiresHash() =>
    r'48b6910d8abe6932d2b0503837a89b439fbcbef2';

/// See also [lessonWidgetStudentRepertoires].
@ProviderFor(lessonWidgetStudentRepertoires)
const lessonWidgetStudentRepertoiresProvider =
    LessonWidgetStudentRepertoiresFamily();

/// See also [lessonWidgetStudentRepertoires].
class LessonWidgetStudentRepertoiresFamily
    extends Family<AsyncValue<List<PracticeRepertoire>>> {
  /// See also [lessonWidgetStudentRepertoires].
  const LessonWidgetStudentRepertoiresFamily();

  /// See also [lessonWidgetStudentRepertoires].
  LessonWidgetStudentRepertoiresProvider call(
    String studentId,
  ) {
    return LessonWidgetStudentRepertoiresProvider(
      studentId,
    );
  }

  @override
  LessonWidgetStudentRepertoiresProvider getProviderOverride(
    covariant LessonWidgetStudentRepertoiresProvider provider,
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
  String? get name => r'lessonWidgetStudentRepertoiresProvider';
}

/// See also [lessonWidgetStudentRepertoires].
class LessonWidgetStudentRepertoiresProvider
    extends Provider<AsyncValue<List<PracticeRepertoire>>> {
  /// See also [lessonWidgetStudentRepertoires].
  LessonWidgetStudentRepertoiresProvider(
    String studentId,
  ) : this._internal(
          (ref) => lessonWidgetStudentRepertoires(
            ref as LessonWidgetStudentRepertoiresRef,
            studentId,
          ),
          from: lessonWidgetStudentRepertoiresProvider,
          name: r'lessonWidgetStudentRepertoiresProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$lessonWidgetStudentRepertoiresHash,
          dependencies: LessonWidgetStudentRepertoiresFamily._dependencies,
          allTransitiveDependencies:
              LessonWidgetStudentRepertoiresFamily._allTransitiveDependencies,
          studentId: studentId,
        );

  LessonWidgetStudentRepertoiresProvider._internal(
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
    AsyncValue<List<PracticeRepertoire>> Function(
            LessonWidgetStudentRepertoiresRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: LessonWidgetStudentRepertoiresProvider._internal(
        (ref) => create(ref as LessonWidgetStudentRepertoiresRef),
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
  ProviderElement<AsyncValue<List<PracticeRepertoire>>> createElement() {
    return _LessonWidgetStudentRepertoiresProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is LessonWidgetStudentRepertoiresProvider &&
        other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin LessonWidgetStudentRepertoiresRef
    on ProviderRef<AsyncValue<List<PracticeRepertoire>>> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _LessonWidgetStudentRepertoiresProviderElement
    extends ProviderElement<AsyncValue<List<PracticeRepertoire>>>
    with LessonWidgetStudentRepertoiresRef {
  _LessonWidgetStudentRepertoiresProviderElement(super.provider);

  @override
  String get studentId =>
      (origin as LessonWidgetStudentRepertoiresProvider).studentId;
}

String _$lessonWidgetTeacherLocationsHash() =>
    r'5e720aacefe7f20c73171f99d0ce5481846f8e51';

/// See also [lessonWidgetTeacherLocations].
@ProviderFor(lessonWidgetTeacherLocations)
const lessonWidgetTeacherLocationsProvider =
    LessonWidgetTeacherLocationsFamily();

/// See also [lessonWidgetTeacherLocations].
class LessonWidgetTeacherLocationsFamily
    extends Family<AsyncValue<List<LessonLocation>>> {
  /// See also [lessonWidgetTeacherLocations].
  const LessonWidgetTeacherLocationsFamily();

  /// See also [lessonWidgetTeacherLocations].
  LessonWidgetTeacherLocationsProvider call(
    String teacherId,
  ) {
    return LessonWidgetTeacherLocationsProvider(
      teacherId,
    );
  }

  @override
  LessonWidgetTeacherLocationsProvider getProviderOverride(
    covariant LessonWidgetTeacherLocationsProvider provider,
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
  String? get name => r'lessonWidgetTeacherLocationsProvider';
}

/// See also [lessonWidgetTeacherLocations].
class LessonWidgetTeacherLocationsProvider
    extends Provider<AsyncValue<List<LessonLocation>>> {
  /// See also [lessonWidgetTeacherLocations].
  LessonWidgetTeacherLocationsProvider(
    String teacherId,
  ) : this._internal(
          (ref) => lessonWidgetTeacherLocations(
            ref as LessonWidgetTeacherLocationsRef,
            teacherId,
          ),
          from: lessonWidgetTeacherLocationsProvider,
          name: r'lessonWidgetTeacherLocationsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$lessonWidgetTeacherLocationsHash,
          dependencies: LessonWidgetTeacherLocationsFamily._dependencies,
          allTransitiveDependencies:
              LessonWidgetTeacherLocationsFamily._allTransitiveDependencies,
          teacherId: teacherId,
        );

  LessonWidgetTeacherLocationsProvider._internal(
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
    AsyncValue<List<LessonLocation>> Function(
            LessonWidgetTeacherLocationsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: LessonWidgetTeacherLocationsProvider._internal(
        (ref) => create(ref as LessonWidgetTeacherLocationsRef),
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
  ProviderElement<AsyncValue<List<LessonLocation>>> createElement() {
    return _LessonWidgetTeacherLocationsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is LessonWidgetTeacherLocationsProvider &&
        other.teacherId == teacherId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, teacherId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin LessonWidgetTeacherLocationsRef
    on ProviderRef<AsyncValue<List<LessonLocation>>> {
  /// The parameter `teacherId` of this provider.
  String get teacherId;
}

class _LessonWidgetTeacherLocationsProviderElement
    extends ProviderElement<AsyncValue<List<LessonLocation>>>
    with LessonWidgetTeacherLocationsRef {
  _LessonWidgetTeacherLocationsProviderElement(super.provider);

  @override
  String get teacherId =>
      (origin as LessonWidgetTeacherLocationsProvider).teacherId;
}

String _$lessonWidgetCurrentTeacherIdHash() =>
    r'6dede57e3d5c2275543f40c7ef065034e93434f4';

/// See also [lessonWidgetCurrentTeacherId].
@ProviderFor(lessonWidgetCurrentTeacherId)
final lessonWidgetCurrentTeacherIdProvider = Provider<String>.internal(
  lessonWidgetCurrentTeacherId,
  name: r'lessonWidgetCurrentTeacherIdProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$lessonWidgetCurrentTeacherIdHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef LessonWidgetCurrentTeacherIdRef = ProviderRef<String>;
String _$lessonWidgetRepertoireActionsHash() =>
    r'4cc3517383be153054f8d422f84f0ea78e6f5197';

/// See also [lessonWidgetRepertoireActions].
@ProviderFor(lessonWidgetRepertoireActions)
final lessonWidgetRepertoireActionsProvider =
    Provider<LessonWidgetRepertoireActions>.internal(
  lessonWidgetRepertoireActions,
  name: r'lessonWidgetRepertoireActionsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$lessonWidgetRepertoireActionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef LessonWidgetRepertoireActionsRef
    = ProviderRef<LessonWidgetRepertoireActions>;
String _$lessonWidgetPracticeItemActionsHash() =>
    r'04cdaf2896464608558ca3d60dd82553842c54ce';

/// See also [lessonWidgetPracticeItemActions].
@ProviderFor(lessonWidgetPracticeItemActions)
const lessonWidgetPracticeItemActionsProvider =
    LessonWidgetPracticeItemActionsFamily();

/// See also [lessonWidgetPracticeItemActions].
class LessonWidgetPracticeItemActionsFamily
    extends Family<LessonWidgetPracticeItemActions> {
  /// See also [lessonWidgetPracticeItemActions].
  const LessonWidgetPracticeItemActionsFamily();

  /// See also [lessonWidgetPracticeItemActions].
  LessonWidgetPracticeItemActionsProvider call(
    String lessonId,
  ) {
    return LessonWidgetPracticeItemActionsProvider(
      lessonId,
    );
  }

  @override
  LessonWidgetPracticeItemActionsProvider getProviderOverride(
    covariant LessonWidgetPracticeItemActionsProvider provider,
  ) {
    return call(
      provider.lessonId,
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
  String? get name => r'lessonWidgetPracticeItemActionsProvider';
}

/// See also [lessonWidgetPracticeItemActions].
class LessonWidgetPracticeItemActionsProvider
    extends Provider<LessonWidgetPracticeItemActions> {
  /// See also [lessonWidgetPracticeItemActions].
  LessonWidgetPracticeItemActionsProvider(
    String lessonId,
  ) : this._internal(
          (ref) => lessonWidgetPracticeItemActions(
            ref as LessonWidgetPracticeItemActionsRef,
            lessonId,
          ),
          from: lessonWidgetPracticeItemActionsProvider,
          name: r'lessonWidgetPracticeItemActionsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$lessonWidgetPracticeItemActionsHash,
          dependencies: LessonWidgetPracticeItemActionsFamily._dependencies,
          allTransitiveDependencies:
              LessonWidgetPracticeItemActionsFamily._allTransitiveDependencies,
          lessonId: lessonId,
        );

  LessonWidgetPracticeItemActionsProvider._internal(
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
    LessonWidgetPracticeItemActions Function(
            LessonWidgetPracticeItemActionsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: LessonWidgetPracticeItemActionsProvider._internal(
        (ref) => create(ref as LessonWidgetPracticeItemActionsRef),
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
  ProviderElement<LessonWidgetPracticeItemActions> createElement() {
    return _LessonWidgetPracticeItemActionsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is LessonWidgetPracticeItemActionsProvider &&
        other.lessonId == lessonId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, lessonId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin LessonWidgetPracticeItemActionsRef
    on ProviderRef<LessonWidgetPracticeItemActions> {
  /// The parameter `lessonId` of this provider.
  String get lessonId;
}

class _LessonWidgetPracticeItemActionsProviderElement
    extends ProviderElement<LessonWidgetPracticeItemActions>
    with LessonWidgetPracticeItemActionsRef {
  _LessonWidgetPracticeItemActionsProviderElement(super.provider);

  @override
  String get lessonId =>
      (origin as LessonWidgetPracticeItemActionsProvider).lessonId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
