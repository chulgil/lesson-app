// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'effective_streak_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$effectiveStreakHash() => r'8e6b280694e5f8fb58b133e4a27025d2f90f6b63';

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
/// 스펙 §6.5 / §14.1 / §14.2. 표시용 SSOT — 학생 화면의 모든 스트릭 숫자는
/// 이 provider 를 통한다 (`docs/specs/practice/streak_ssot.md` §1 Phase 3).
///
/// 읽기 시 두 가지 부수효과가 일어난다. 둘 다 멱등이라 재빌드에 안전하다.
/// 1. §14.1 주간 발급 — `lastGrantedAt` 게이트 (주 1회만 +2)
/// 2. §14.2 결석일 차감 — `usedAt` 게이트 (같은 날짜 재차감 X)
///
/// Copied from [effectiveStreak].
@ProviderFor(effectiveStreak)
const effectiveStreakProvider = EffectiveStreakFamily();

/// 학생의 effective streak — raw [PracticeStreak] + [StreakFreeze] 종합 결과.
///
/// 스펙 §6.5 / §14.1 / §14.2. 표시용 SSOT — 학생 화면의 모든 스트릭 숫자는
/// 이 provider 를 통한다 (`docs/specs/practice/streak_ssot.md` §1 Phase 3).
///
/// 읽기 시 두 가지 부수효과가 일어난다. 둘 다 멱등이라 재빌드에 안전하다.
/// 1. §14.1 주간 발급 — `lastGrantedAt` 게이트 (주 1회만 +2)
/// 2. §14.2 결석일 차감 — `usedAt` 게이트 (같은 날짜 재차감 X)
///
/// Copied from [effectiveStreak].
class EffectiveStreakFamily extends Family<AsyncValue<StreakWithFreezeResult>> {
  /// 학생의 effective streak — raw [PracticeStreak] + [StreakFreeze] 종합 결과.
  ///
  /// 스펙 §6.5 / §14.1 / §14.2. 표시용 SSOT — 학생 화면의 모든 스트릭 숫자는
  /// 이 provider 를 통한다 (`docs/specs/practice/streak_ssot.md` §1 Phase 3).
  ///
  /// 읽기 시 두 가지 부수효과가 일어난다. 둘 다 멱등이라 재빌드에 안전하다.
  /// 1. §14.1 주간 발급 — `lastGrantedAt` 게이트 (주 1회만 +2)
  /// 2. §14.2 결석일 차감 — `usedAt` 게이트 (같은 날짜 재차감 X)
  ///
  /// Copied from [effectiveStreak].
  const EffectiveStreakFamily();

  /// 학생의 effective streak — raw [PracticeStreak] + [StreakFreeze] 종합 결과.
  ///
  /// 스펙 §6.5 / §14.1 / §14.2. 표시용 SSOT — 학생 화면의 모든 스트릭 숫자는
  /// 이 provider 를 통한다 (`docs/specs/practice/streak_ssot.md` §1 Phase 3).
  ///
  /// 읽기 시 두 가지 부수효과가 일어난다. 둘 다 멱등이라 재빌드에 안전하다.
  /// 1. §14.1 주간 발급 — `lastGrantedAt` 게이트 (주 1회만 +2)
  /// 2. §14.2 결석일 차감 — `usedAt` 게이트 (같은 날짜 재차감 X)
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
/// 스펙 §6.5 / §14.1 / §14.2. 표시용 SSOT — 학생 화면의 모든 스트릭 숫자는
/// 이 provider 를 통한다 (`docs/specs/practice/streak_ssot.md` §1 Phase 3).
///
/// 읽기 시 두 가지 부수효과가 일어난다. 둘 다 멱등이라 재빌드에 안전하다.
/// 1. §14.1 주간 발급 — `lastGrantedAt` 게이트 (주 1회만 +2)
/// 2. §14.2 결석일 차감 — `usedAt` 게이트 (같은 날짜 재차감 X)
///
/// Copied from [effectiveStreak].
class EffectiveStreakProvider
    extends AutoDisposeFutureProvider<StreakWithFreezeResult> {
  /// 학생의 effective streak — raw [PracticeStreak] + [StreakFreeze] 종합 결과.
  ///
  /// 스펙 §6.5 / §14.1 / §14.2. 표시용 SSOT — 학생 화면의 모든 스트릭 숫자는
  /// 이 provider 를 통한다 (`docs/specs/practice/streak_ssot.md` §1 Phase 3).
  ///
  /// 읽기 시 두 가지 부수효과가 일어난다. 둘 다 멱등이라 재빌드에 안전하다.
  /// 1. §14.1 주간 발급 — `lastGrantedAt` 게이트 (주 1회만 +2)
  /// 2. §14.2 결석일 차감 — `usedAt` 게이트 (같은 날짜 재차감 X)
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
