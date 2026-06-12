// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'effective_streak_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$effectiveStreakHash() => r'aa7591fa3abc92f5c4c0cfa5b63b8dfaa1278a3e';

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

/// 학생의 effective streak — raw [PracticeStreak] + [StreakFreeze] 종합 결과.
///
/// 스펙 §6.5 / §14.2 / 플랜 Job 5 Task 5.1. side-effect 0 — 자동 freeze
/// 적용 trigger 는 Task 5.1.b (recordPractice 진입 시).
///
/// Copied from [effectiveStreak].
@ProviderFor(effectiveStreak)
const effectiveStreakProvider = EffectiveStreakFamily();

/// 학생의 effective streak — raw [PracticeStreak] + [StreakFreeze] 종합 결과.
///
/// 스펙 §6.5 / §14.2 / 플랜 Job 5 Task 5.1. side-effect 0 — 자동 freeze
/// 적용 trigger 는 Task 5.1.b (recordPractice 진입 시).
///
/// Copied from [effectiveStreak].
class EffectiveStreakFamily extends Family<AsyncValue<StreakWithFreezeResult>> {
  /// 학생의 effective streak — raw [PracticeStreak] + [StreakFreeze] 종합 결과.
  ///
  /// 스펙 §6.5 / §14.2 / 플랜 Job 5 Task 5.1. side-effect 0 — 자동 freeze
  /// 적용 trigger 는 Task 5.1.b (recordPractice 진입 시).
  ///
  /// Copied from [effectiveStreak].
  const EffectiveStreakFamily();

  /// 학생의 effective streak — raw [PracticeStreak] + [StreakFreeze] 종합 결과.
  ///
  /// 스펙 §6.5 / §14.2 / 플랜 Job 5 Task 5.1. side-effect 0 — 자동 freeze
  /// 적용 trigger 는 Task 5.1.b (recordPractice 진입 시).
  ///
  /// Copied from [effectiveStreak].
  EffectiveStreakProvider call(
    String studentId,
  ) {
    return EffectiveStreakProvider(
      studentId,
    );
  }

  @override
  EffectiveStreakProvider getProviderOverride(
    covariant EffectiveStreakProvider provider,
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
  String? get name => r'effectiveStreakProvider';
}

/// 학생의 effective streak — raw [PracticeStreak] + [StreakFreeze] 종합 결과.
///
/// 스펙 §6.5 / §14.2 / 플랜 Job 5 Task 5.1. side-effect 0 — 자동 freeze
/// 적용 trigger 는 Task 5.1.b (recordPractice 진입 시).
///
/// Copied from [effectiveStreak].
class EffectiveStreakProvider
    extends AutoDisposeFutureProvider<StreakWithFreezeResult> {
  /// 학생의 effective streak — raw [PracticeStreak] + [StreakFreeze] 종합 결과.
  ///
  /// 스펙 §6.5 / §14.2 / 플랜 Job 5 Task 5.1. side-effect 0 — 자동 freeze
  /// 적용 trigger 는 Task 5.1.b (recordPractice 진입 시).
  ///
  /// Copied from [effectiveStreak].
  EffectiveStreakProvider(
    String studentId,
  ) : this._internal(
          (ref) => effectiveStreak(
            ref as EffectiveStreakRef,
            studentId,
          ),
          from: effectiveStreakProvider,
          name: r'effectiveStreakProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$effectiveStreakHash,
          dependencies: EffectiveStreakFamily._dependencies,
          allTransitiveDependencies:
              EffectiveStreakFamily._allTransitiveDependencies,
          studentId: studentId,
        );

  EffectiveStreakProvider._internal(
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
    FutureOr<StreakWithFreezeResult> Function(EffectiveStreakRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: EffectiveStreakProvider._internal(
        (ref) => create(ref as EffectiveStreakRef),
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
  AutoDisposeFutureProviderElement<StreakWithFreezeResult> createElement() {
    return _EffectiveStreakProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is EffectiveStreakProvider && other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin EffectiveStreakRef
    on AutoDisposeFutureProviderRef<StreakWithFreezeResult> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _EffectiveStreakProviderElement
    extends AutoDisposeFutureProviderElement<StreakWithFreezeResult>
    with EffectiveStreakRef {
  _EffectiveStreakProviderElement(super.provider);

  @override
  String get studentId => (origin as EffectiveStreakProvider).studentId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
