// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lesson_policy_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$lessonPolicyRepositoryHash() =>
    r'3ed5761d1ff93d7d84827b297359d90bcf7af393';

/// Provider for the lesson policy repository.
///
/// Copied from [lessonPolicyRepository].
@ProviderFor(lessonPolicyRepository)
final lessonPolicyRepositoryProvider =
    Provider<LessonPolicyRepository>.internal(
  lessonPolicyRepository,
  name: r'lessonPolicyRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$lessonPolicyRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LessonPolicyRepositoryRef = ProviderRef<LessonPolicyRepository>;
String _$teacherPolicyHash() => r'bac34e07077fdd362c2459208b410b198fdc3310';

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

/// Provider for teacher's default policy.
///
/// Copied from [teacherPolicy].
@ProviderFor(teacherPolicy)
const teacherPolicyProvider = TeacherPolicyFamily();

/// Provider for teacher's default policy.
///
/// Copied from [teacherPolicy].
class TeacherPolicyFamily extends Family<AsyncValue<LessonPolicy?>> {
  /// Provider for teacher's default policy.
  ///
  /// Copied from [teacherPolicy].
  const TeacherPolicyFamily();

  /// Provider for teacher's default policy.
  ///
  /// Copied from [teacherPolicy].
  TeacherPolicyProvider call(
    String teacherId,
  ) {
    return TeacherPolicyProvider(
      teacherId,
    );
  }

  @override
  TeacherPolicyProvider getProviderOverride(
    covariant TeacherPolicyProvider provider,
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
  String? get name => r'teacherPolicyProvider';
}

/// Provider for teacher's default policy.
///
/// Copied from [teacherPolicy].
class TeacherPolicyProvider extends AutoDisposeFutureProvider<LessonPolicy?> {
  /// Provider for teacher's default policy.
  ///
  /// Copied from [teacherPolicy].
  TeacherPolicyProvider(
    String teacherId,
  ) : this._internal(
          (ref) => teacherPolicy(
            ref as TeacherPolicyRef,
            teacherId,
          ),
          from: teacherPolicyProvider,
          name: r'teacherPolicyProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$teacherPolicyHash,
          dependencies: TeacherPolicyFamily._dependencies,
          allTransitiveDependencies:
              TeacherPolicyFamily._allTransitiveDependencies,
          teacherId: teacherId,
        );

  TeacherPolicyProvider._internal(
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
    FutureOr<LessonPolicy?> Function(TeacherPolicyRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TeacherPolicyProvider._internal(
        (ref) => create(ref as TeacherPolicyRef),
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
  AutoDisposeFutureProviderElement<LessonPolicy?> createElement() {
    return _TeacherPolicyProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TeacherPolicyProvider && other.teacherId == teacherId;
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
mixin TeacherPolicyRef on AutoDisposeFutureProviderRef<LessonPolicy?> {
  /// The parameter `teacherId` of this provider.
  String get teacherId;
}

class _TeacherPolicyProviderElement
    extends AutoDisposeFutureProviderElement<LessonPolicy?>
    with TeacherPolicyRef {
  _TeacherPolicyProviderElement(super.provider);

  @override
  String get teacherId => (origin as TeacherPolicyProvider).teacherId;
}

String _$classPolicyHash() => r'0425b063385bde141edf73d25d75e1b67dbe5d02';

/// Provider for class-specific policy.
///
/// Copied from [classPolicy].
@ProviderFor(classPolicy)
const classPolicyProvider = ClassPolicyFamily();

/// Provider for class-specific policy.
///
/// Copied from [classPolicy].
class ClassPolicyFamily extends Family<AsyncValue<LessonPolicy?>> {
  /// Provider for class-specific policy.
  ///
  /// Copied from [classPolicy].
  const ClassPolicyFamily();

  /// Provider for class-specific policy.
  ///
  /// Copied from [classPolicy].
  ClassPolicyProvider call(
    String lessonClassId,
  ) {
    return ClassPolicyProvider(
      lessonClassId,
    );
  }

  @override
  ClassPolicyProvider getProviderOverride(
    covariant ClassPolicyProvider provider,
  ) {
    return call(
      provider.lessonClassId,
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
  String? get name => r'classPolicyProvider';
}

/// Provider for class-specific policy.
///
/// Copied from [classPolicy].
class ClassPolicyProvider extends AutoDisposeFutureProvider<LessonPolicy?> {
  /// Provider for class-specific policy.
  ///
  /// Copied from [classPolicy].
  ClassPolicyProvider(
    String lessonClassId,
  ) : this._internal(
          (ref) => classPolicy(
            ref as ClassPolicyRef,
            lessonClassId,
          ),
          from: classPolicyProvider,
          name: r'classPolicyProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$classPolicyHash,
          dependencies: ClassPolicyFamily._dependencies,
          allTransitiveDependencies:
              ClassPolicyFamily._allTransitiveDependencies,
          lessonClassId: lessonClassId,
        );

  ClassPolicyProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.lessonClassId,
  }) : super.internal();

  final String lessonClassId;

  @override
  Override overrideWith(
    FutureOr<LessonPolicy?> Function(ClassPolicyRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ClassPolicyProvider._internal(
        (ref) => create(ref as ClassPolicyRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        lessonClassId: lessonClassId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<LessonPolicy?> createElement() {
    return _ClassPolicyProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ClassPolicyProvider && other.lessonClassId == lessonClassId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, lessonClassId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ClassPolicyRef on AutoDisposeFutureProviderRef<LessonPolicy?> {
  /// The parameter `lessonClassId` of this provider.
  String get lessonClassId;
}

class _ClassPolicyProviderElement
    extends AutoDisposeFutureProviderElement<LessonPolicy?>
    with ClassPolicyRef {
  _ClassPolicyProviderElement(super.provider);

  @override
  String get lessonClassId => (origin as ClassPolicyProvider).lessonClassId;
}

String _$effectivePolicyHash() => r'75b86996d32bf31913daaf41552302c77e0ed9a5';

/// Provider for effective policy (class or teacher default).
///
/// Copied from [effectivePolicy].
@ProviderFor(effectivePolicy)
const effectivePolicyProvider = EffectivePolicyFamily();

/// Provider for effective policy (class or teacher default).
///
/// Copied from [effectivePolicy].
class EffectivePolicyFamily extends Family<AsyncValue<LessonPolicy?>> {
  /// Provider for effective policy (class or teacher default).
  ///
  /// Copied from [effectivePolicy].
  const EffectivePolicyFamily();

  /// Provider for effective policy (class or teacher default).
  ///
  /// Copied from [effectivePolicy].
  EffectivePolicyProvider call({
    required String teacherId,
    String? lessonClassId,
  }) {
    return EffectivePolicyProvider(
      teacherId: teacherId,
      lessonClassId: lessonClassId,
    );
  }

  @override
  EffectivePolicyProvider getProviderOverride(
    covariant EffectivePolicyProvider provider,
  ) {
    return call(
      teacherId: provider.teacherId,
      lessonClassId: provider.lessonClassId,
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
  String? get name => r'effectivePolicyProvider';
}

/// Provider for effective policy (class or teacher default).
///
/// Copied from [effectivePolicy].
class EffectivePolicyProvider extends AutoDisposeFutureProvider<LessonPolicy?> {
  /// Provider for effective policy (class or teacher default).
  ///
  /// Copied from [effectivePolicy].
  EffectivePolicyProvider({
    required String teacherId,
    String? lessonClassId,
  }) : this._internal(
          (ref) => effectivePolicy(
            ref as EffectivePolicyRef,
            teacherId: teacherId,
            lessonClassId: lessonClassId,
          ),
          from: effectivePolicyProvider,
          name: r'effectivePolicyProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$effectivePolicyHash,
          dependencies: EffectivePolicyFamily._dependencies,
          allTransitiveDependencies:
              EffectivePolicyFamily._allTransitiveDependencies,
          teacherId: teacherId,
          lessonClassId: lessonClassId,
        );

  EffectivePolicyProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.teacherId,
    required this.lessonClassId,
  }) : super.internal();

  final String teacherId;
  final String? lessonClassId;

  @override
  Override overrideWith(
    FutureOr<LessonPolicy?> Function(EffectivePolicyRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: EffectivePolicyProvider._internal(
        (ref) => create(ref as EffectivePolicyRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        teacherId: teacherId,
        lessonClassId: lessonClassId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<LessonPolicy?> createElement() {
    return _EffectivePolicyProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is EffectivePolicyProvider &&
        other.teacherId == teacherId &&
        other.lessonClassId == lessonClassId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, teacherId.hashCode);
    hash = _SystemHash.combine(hash, lessonClassId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin EffectivePolicyRef on AutoDisposeFutureProviderRef<LessonPolicy?> {
  /// The parameter `teacherId` of this provider.
  String get teacherId;

  /// The parameter `lessonClassId` of this provider.
  String? get lessonClassId;
}

class _EffectivePolicyProviderElement
    extends AutoDisposeFutureProviderElement<LessonPolicy?>
    with EffectivePolicyRef {
  _EffectivePolicyProviderElement(super.provider);

  @override
  String get teacherId => (origin as EffectivePolicyProvider).teacherId;
  @override
  String? get lessonClassId =>
      (origin as EffectivePolicyProvider).lessonClassId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
