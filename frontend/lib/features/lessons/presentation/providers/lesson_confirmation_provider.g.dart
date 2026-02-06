// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lesson_confirmation_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$lessonNeedsConfirmationHash() =>
    r'735e322573b2ce776e8823e647eeea483c4abfd5';

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

/// Check if lesson needs confirmation (past scheduled lesson without notes)
///
/// Copied from [lessonNeedsConfirmation].
@ProviderFor(lessonNeedsConfirmation)
const lessonNeedsConfirmationProvider = LessonNeedsConfirmationFamily();

/// Check if lesson needs confirmation (past scheduled lesson without notes)
///
/// Copied from [lessonNeedsConfirmation].
class LessonNeedsConfirmationFamily extends Family<AsyncValue<bool>> {
  /// Check if lesson needs confirmation (past scheduled lesson without notes)
  ///
  /// Copied from [lessonNeedsConfirmation].
  const LessonNeedsConfirmationFamily();

  /// Check if lesson needs confirmation (past scheduled lesson without notes)
  ///
  /// Copied from [lessonNeedsConfirmation].
  LessonNeedsConfirmationProvider call(
    String lessonId,
  ) {
    return LessonNeedsConfirmationProvider(
      lessonId,
    );
  }

  @override
  LessonNeedsConfirmationProvider getProviderOverride(
    covariant LessonNeedsConfirmationProvider provider,
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
  String? get name => r'lessonNeedsConfirmationProvider';
}

/// Check if lesson needs confirmation (past scheduled lesson without notes)
///
/// Copied from [lessonNeedsConfirmation].
class LessonNeedsConfirmationProvider extends AutoDisposeFutureProvider<bool> {
  /// Check if lesson needs confirmation (past scheduled lesson without notes)
  ///
  /// Copied from [lessonNeedsConfirmation].
  LessonNeedsConfirmationProvider(
    String lessonId,
  ) : this._internal(
          (ref) => lessonNeedsConfirmation(
            ref as LessonNeedsConfirmationRef,
            lessonId,
          ),
          from: lessonNeedsConfirmationProvider,
          name: r'lessonNeedsConfirmationProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$lessonNeedsConfirmationHash,
          dependencies: LessonNeedsConfirmationFamily._dependencies,
          allTransitiveDependencies:
              LessonNeedsConfirmationFamily._allTransitiveDependencies,
          lessonId: lessonId,
        );

  LessonNeedsConfirmationProvider._internal(
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
    FutureOr<bool> Function(LessonNeedsConfirmationRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: LessonNeedsConfirmationProvider._internal(
        (ref) => create(ref as LessonNeedsConfirmationRef),
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
  AutoDisposeFutureProviderElement<bool> createElement() {
    return _LessonNeedsConfirmationProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is LessonNeedsConfirmationProvider &&
        other.lessonId == lessonId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, lessonId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin LessonNeedsConfirmationRef on AutoDisposeFutureProviderRef<bool> {
  /// The parameter `lessonId` of this provider.
  String get lessonId;
}

class _LessonNeedsConfirmationProviderElement
    extends AutoDisposeFutureProviderElement<bool>
    with LessonNeedsConfirmationRef {
  _LessonNeedsConfirmationProviderElement(super.provider);

  @override
  String get lessonId => (origin as LessonNeedsConfirmationProvider).lessonId;
}

String _$lessonsNeedingConfirmationHash() =>
    r'2405bf96b1bfedba3fbfdec4ee7100436376f8a5';

/// Get lessons that need confirmation (past scheduled lessons)
///
/// Copied from [lessonsNeedingConfirmation].
@ProviderFor(lessonsNeedingConfirmation)
final lessonsNeedingConfirmationProvider =
    AutoDisposeFutureProvider<List<Lesson>>.internal(
  lessonsNeedingConfirmation,
  name: r'lessonsNeedingConfirmationProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$lessonsNeedingConfirmationHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LessonsNeedingConfirmationRef
    = AutoDisposeFutureProviderRef<List<Lesson>>;
String _$canCancelWithoutDeductionHash() =>
    r'7cb597b75858f0977ff6fd9e06e880a4a2199443';

/// 24-hour cancellation policy check
///
/// Copied from [canCancelWithoutDeduction].
@ProviderFor(canCancelWithoutDeduction)
const canCancelWithoutDeductionProvider = CanCancelWithoutDeductionFamily();

/// 24-hour cancellation policy check
///
/// Copied from [canCancelWithoutDeduction].
class CanCancelWithoutDeductionFamily extends Family<bool> {
  /// 24-hour cancellation policy check
  ///
  /// Copied from [canCancelWithoutDeduction].
  const CanCancelWithoutDeductionFamily();

  /// 24-hour cancellation policy check
  ///
  /// Copied from [canCancelWithoutDeduction].
  CanCancelWithoutDeductionProvider call(
    Lesson lesson,
  ) {
    return CanCancelWithoutDeductionProvider(
      lesson,
    );
  }

  @override
  CanCancelWithoutDeductionProvider getProviderOverride(
    covariant CanCancelWithoutDeductionProvider provider,
  ) {
    return call(
      provider.lesson,
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
  String? get name => r'canCancelWithoutDeductionProvider';
}

/// 24-hour cancellation policy check
///
/// Copied from [canCancelWithoutDeduction].
class CanCancelWithoutDeductionProvider extends AutoDisposeProvider<bool> {
  /// 24-hour cancellation policy check
  ///
  /// Copied from [canCancelWithoutDeduction].
  CanCancelWithoutDeductionProvider(
    Lesson lesson,
  ) : this._internal(
          (ref) => canCancelWithoutDeduction(
            ref as CanCancelWithoutDeductionRef,
            lesson,
          ),
          from: canCancelWithoutDeductionProvider,
          name: r'canCancelWithoutDeductionProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$canCancelWithoutDeductionHash,
          dependencies: CanCancelWithoutDeductionFamily._dependencies,
          allTransitiveDependencies:
              CanCancelWithoutDeductionFamily._allTransitiveDependencies,
          lesson: lesson,
        );

  CanCancelWithoutDeductionProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.lesson,
  }) : super.internal();

  final Lesson lesson;

  @override
  Override overrideWith(
    bool Function(CanCancelWithoutDeductionRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CanCancelWithoutDeductionProvider._internal(
        (ref) => create(ref as CanCancelWithoutDeductionRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        lesson: lesson,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<bool> createElement() {
    return _CanCancelWithoutDeductionProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CanCancelWithoutDeductionProvider && other.lesson == lesson;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, lesson.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CanCancelWithoutDeductionRef on AutoDisposeProviderRef<bool> {
  /// The parameter `lesson` of this provider.
  Lesson get lesson;
}

class _CanCancelWithoutDeductionProviderElement
    extends AutoDisposeProviderElement<bool> with CanCancelWithoutDeductionRef {
  _CanCancelWithoutDeductionProviderElement(super.provider);

  @override
  Lesson get lesson => (origin as CanCancelWithoutDeductionProvider).lesson;
}

String _$lessonConfirmationNotifierHash() =>
    r'eb52f38171978d4683efe1826fafbb5f5d26a663';

/// Provider for confirming lesson completion
///
/// Copied from [LessonConfirmationNotifier].
@ProviderFor(LessonConfirmationNotifier)
final lessonConfirmationNotifierProvider = AutoDisposeNotifierProvider<
    LessonConfirmationNotifier, AsyncValue<void>>.internal(
  LessonConfirmationNotifier.new,
  name: r'lessonConfirmationNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$lessonConfirmationNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$LessonConfirmationNotifier = AutoDisposeNotifier<AsyncValue<void>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
