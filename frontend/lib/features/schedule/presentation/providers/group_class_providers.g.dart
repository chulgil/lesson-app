// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_class_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$groupClassRepositoryHash() =>
    r'fb679d22ab27da8ecbdf67dffb68060cd9b97022';

/// See also [groupClassRepository].
@ProviderFor(groupClassRepository)
final groupClassRepositoryProvider = Provider<GroupClassRepository>.internal(
  groupClassRepository,
  name: r'groupClassRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$groupClassRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef GroupClassRepositoryRef = ProviderRef<GroupClassRepository>;
String _$teacherGroupClassesHash() =>
    r'44df153ee4e9ab289328f2d0d4ec2141047f628a';

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

/// Classes a teacher owns, newest first.
///
/// Deactivated classes are included so the owner still sees what they took
/// down; the backend hides them from everyone else.
///
/// Copied from [teacherGroupClasses].
@ProviderFor(teacherGroupClasses)
const teacherGroupClassesProvider = TeacherGroupClassesFamily();

/// Classes a teacher owns, newest first.
///
/// Deactivated classes are included so the owner still sees what they took
/// down; the backend hides them from everyone else.
///
/// Copied from [teacherGroupClasses].
class TeacherGroupClassesFamily extends Family<AsyncValue<List<GroupClass>>> {
  /// Classes a teacher owns, newest first.
  ///
  /// Deactivated classes are included so the owner still sees what they took
  /// down; the backend hides them from everyone else.
  ///
  /// Copied from [teacherGroupClasses].
  const TeacherGroupClassesFamily();

  /// Classes a teacher owns, newest first.
  ///
  /// Deactivated classes are included so the owner still sees what they took
  /// down; the backend hides them from everyone else.
  ///
  /// Copied from [teacherGroupClasses].
  TeacherGroupClassesProvider call(
    String teacherId,
  ) {
    return TeacherGroupClassesProvider(
      teacherId,
    );
  }

  @override
  TeacherGroupClassesProvider getProviderOverride(
    covariant TeacherGroupClassesProvider provider,
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
  String? get name => r'teacherGroupClassesProvider';
}

/// Classes a teacher owns, newest first.
///
/// Deactivated classes are included so the owner still sees what they took
/// down; the backend hides them from everyone else.
///
/// Copied from [teacherGroupClasses].
class TeacherGroupClassesProvider
    extends AutoDisposeFutureProvider<List<GroupClass>> {
  /// Classes a teacher owns, newest first.
  ///
  /// Deactivated classes are included so the owner still sees what they took
  /// down; the backend hides them from everyone else.
  ///
  /// Copied from [teacherGroupClasses].
  TeacherGroupClassesProvider(
    String teacherId,
  ) : this._internal(
          (ref) => teacherGroupClasses(
            ref as TeacherGroupClassesRef,
            teacherId,
          ),
          from: teacherGroupClassesProvider,
          name: r'teacherGroupClassesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$teacherGroupClassesHash,
          dependencies: TeacherGroupClassesFamily._dependencies,
          allTransitiveDependencies:
              TeacherGroupClassesFamily._allTransitiveDependencies,
          teacherId: teacherId,
        );

  TeacherGroupClassesProvider._internal(
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
    FutureOr<List<GroupClass>> Function(TeacherGroupClassesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TeacherGroupClassesProvider._internal(
        (ref) => create(ref as TeacherGroupClassesRef),
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
  AutoDisposeFutureProviderElement<List<GroupClass>> createElement() {
    return _TeacherGroupClassesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TeacherGroupClassesProvider && other.teacherId == teacherId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, teacherId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin TeacherGroupClassesRef on AutoDisposeFutureProviderRef<List<GroupClass>> {
  /// The parameter `teacherId` of this provider.
  String get teacherId;
}

class _TeacherGroupClassesProviderElement
    extends AutoDisposeFutureProviderElement<List<GroupClass>>
    with TeacherGroupClassesRef {
  _TeacherGroupClassesProviderElement(super.provider);

  @override
  String get teacherId => (origin as TeacherGroupClassesProvider).teacherId;
}

String _$groupClassByIdHash() => r'8a6905c5d6cbd7fac1e6eddbb7f1c224307303a1';

/// A single class — used by the edit form and by screens that only hold an ID.
///
/// Copied from [groupClassById].
@ProviderFor(groupClassById)
const groupClassByIdProvider = GroupClassByIdFamily();

/// A single class — used by the edit form and by screens that only hold an ID.
///
/// Copied from [groupClassById].
class GroupClassByIdFamily extends Family<AsyncValue<GroupClass?>> {
  /// A single class — used by the edit form and by screens that only hold an ID.
  ///
  /// Copied from [groupClassById].
  const GroupClassByIdFamily();

  /// A single class — used by the edit form and by screens that only hold an ID.
  ///
  /// Copied from [groupClassById].
  GroupClassByIdProvider call(
    String classId,
  ) {
    return GroupClassByIdProvider(
      classId,
    );
  }

  @override
  GroupClassByIdProvider getProviderOverride(
    covariant GroupClassByIdProvider provider,
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
  String? get name => r'groupClassByIdProvider';
}

/// A single class — used by the edit form and by screens that only hold an ID.
///
/// Copied from [groupClassById].
class GroupClassByIdProvider extends AutoDisposeFutureProvider<GroupClass?> {
  /// A single class — used by the edit form and by screens that only hold an ID.
  ///
  /// Copied from [groupClassById].
  GroupClassByIdProvider(
    String classId,
  ) : this._internal(
          (ref) => groupClassById(
            ref as GroupClassByIdRef,
            classId,
          ),
          from: groupClassByIdProvider,
          name: r'groupClassByIdProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$groupClassByIdHash,
          dependencies: GroupClassByIdFamily._dependencies,
          allTransitiveDependencies:
              GroupClassByIdFamily._allTransitiveDependencies,
          classId: classId,
        );

  GroupClassByIdProvider._internal(
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
    FutureOr<GroupClass?> Function(GroupClassByIdRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: GroupClassByIdProvider._internal(
        (ref) => create(ref as GroupClassByIdRef),
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
  AutoDisposeFutureProviderElement<GroupClass?> createElement() {
    return _GroupClassByIdProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GroupClassByIdProvider && other.classId == classId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, classId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin GroupClassByIdRef on AutoDisposeFutureProviderRef<GroupClass?> {
  /// The parameter `classId` of this provider.
  String get classId;
}

class _GroupClassByIdProviderElement
    extends AutoDisposeFutureProviderElement<GroupClass?>
    with GroupClassByIdRef {
  _GroupClassByIdProviderElement(super.provider);

  @override
  String get classId => (origin as GroupClassByIdProvider).classId;
}

String _$groupClassFormNotifierHash() =>
    r'55f8a156b472d779fd59d0d558cef8c2576ea3d6';

/// Write path for class definitions. Kept apart from the read providers above
/// so a successful write always invalidates them explicitly.
///
/// Copied from [GroupClassFormNotifier].
@ProviderFor(GroupClassFormNotifier)
final groupClassFormNotifierProvider = AutoDisposeNotifierProvider<
    GroupClassFormNotifier, AsyncValue<GroupClass?>>.internal(
  GroupClassFormNotifier.new,
  name: r'groupClassFormNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$groupClassFormNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$GroupClassFormNotifier = AutoDisposeNotifier<AsyncValue<GroupClass?>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
