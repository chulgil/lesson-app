// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'streak_freeze_migration_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$streakFreezeBootMigrationHash() =>
    r'888e138fb9104cc3b29260d10a7494d07aeac0aa';

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

/// 학생별 D-day 마이그레이션 — `weeklyGrantIfDue` 강제 호출 (lastGrantedAt=null
/// 이므로 자동 +2) + flag 영속. 재호출 시 flag 검사 후 no-op.
///
/// Hive 미초기화 (테스트 환경 일부) 시 `false` 반환 — boot 차단 회피.
///
/// Copied from [streakFreezeBootMigration].
@ProviderFor(streakFreezeBootMigration)
const streakFreezeBootMigrationProvider = StreakFreezeBootMigrationFamily();

/// 학생별 D-day 마이그레이션 — `weeklyGrantIfDue` 강제 호출 (lastGrantedAt=null
/// 이므로 자동 +2) + flag 영속. 재호출 시 flag 검사 후 no-op.
///
/// Hive 미초기화 (테스트 환경 일부) 시 `false` 반환 — boot 차단 회피.
///
/// Copied from [streakFreezeBootMigration].
class StreakFreezeBootMigrationFamily extends Family<AsyncValue<bool>> {
  /// 학생별 D-day 마이그레이션 — `weeklyGrantIfDue` 강제 호출 (lastGrantedAt=null
  /// 이므로 자동 +2) + flag 영속. 재호출 시 flag 검사 후 no-op.
  ///
  /// Hive 미초기화 (테스트 환경 일부) 시 `false` 반환 — boot 차단 회피.
  ///
  /// Copied from [streakFreezeBootMigration].
  const StreakFreezeBootMigrationFamily();

  /// 학생별 D-day 마이그레이션 — `weeklyGrantIfDue` 강제 호출 (lastGrantedAt=null
  /// 이므로 자동 +2) + flag 영속. 재호출 시 flag 검사 후 no-op.
  ///
  /// Hive 미초기화 (테스트 환경 일부) 시 `false` 반환 — boot 차단 회피.
  ///
  /// Copied from [streakFreezeBootMigration].
  StreakFreezeBootMigrationProvider call(
    String studentId,
  ) {
    return StreakFreezeBootMigrationProvider(
      studentId,
    );
  }

  @override
  StreakFreezeBootMigrationProvider getProviderOverride(
    covariant StreakFreezeBootMigrationProvider provider,
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
  String? get name => r'streakFreezeBootMigrationProvider';
}

/// 학생별 D-day 마이그레이션 — `weeklyGrantIfDue` 강제 호출 (lastGrantedAt=null
/// 이므로 자동 +2) + flag 영속. 재호출 시 flag 검사 후 no-op.
///
/// Hive 미초기화 (테스트 환경 일부) 시 `false` 반환 — boot 차단 회피.
///
/// Copied from [streakFreezeBootMigration].
class StreakFreezeBootMigrationProvider extends FutureProvider<bool> {
  /// 학생별 D-day 마이그레이션 — `weeklyGrantIfDue` 강제 호출 (lastGrantedAt=null
  /// 이므로 자동 +2) + flag 영속. 재호출 시 flag 검사 후 no-op.
  ///
  /// Hive 미초기화 (테스트 환경 일부) 시 `false` 반환 — boot 차단 회피.
  ///
  /// Copied from [streakFreezeBootMigration].
  StreakFreezeBootMigrationProvider(
    String studentId,
  ) : this._internal(
          (ref) => streakFreezeBootMigration(
            ref as StreakFreezeBootMigrationRef,
            studentId,
          ),
          from: streakFreezeBootMigrationProvider,
          name: r'streakFreezeBootMigrationProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$streakFreezeBootMigrationHash,
          dependencies: StreakFreezeBootMigrationFamily._dependencies,
          allTransitiveDependencies:
              StreakFreezeBootMigrationFamily._allTransitiveDependencies,
          studentId: studentId,
        );

  StreakFreezeBootMigrationProvider._internal(
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
    FutureOr<bool> Function(StreakFreezeBootMigrationRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: StreakFreezeBootMigrationProvider._internal(
        (ref) => create(ref as StreakFreezeBootMigrationRef),
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
  FutureProviderElement<bool> createElement() {
    return _StreakFreezeBootMigrationProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StreakFreezeBootMigrationProvider &&
        other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin StreakFreezeBootMigrationRef on FutureProviderRef<bool> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _StreakFreezeBootMigrationProviderElement
    extends FutureProviderElement<bool> with StreakFreezeBootMigrationRef {
  _StreakFreezeBootMigrationProviderElement(super.provider);

  @override
  String get studentId =>
      (origin as StreakFreezeBootMigrationProvider).studentId;
}

String _$streakFreezeMigrationToastShownHash() =>
    r'ddfa803bd69a3366fbcc4ead63e319e676163b69';

/// 학생별 마이그레이션 안내 토스트 노출 상태.
///
/// `false` → 미노출 (토스트 표시 필요). `true` → 이미 노출 (skip).
///
/// Copied from [streakFreezeMigrationToastShown].
@ProviderFor(streakFreezeMigrationToastShown)
const streakFreezeMigrationToastShownProvider =
    StreakFreezeMigrationToastShownFamily();

/// 학생별 마이그레이션 안내 토스트 노출 상태.
///
/// `false` → 미노출 (토스트 표시 필요). `true` → 이미 노출 (skip).
///
/// Copied from [streakFreezeMigrationToastShown].
class StreakFreezeMigrationToastShownFamily extends Family<AsyncValue<bool>> {
  /// 학생별 마이그레이션 안내 토스트 노출 상태.
  ///
  /// `false` → 미노출 (토스트 표시 필요). `true` → 이미 노출 (skip).
  ///
  /// Copied from [streakFreezeMigrationToastShown].
  const StreakFreezeMigrationToastShownFamily();

  /// 학생별 마이그레이션 안내 토스트 노출 상태.
  ///
  /// `false` → 미노출 (토스트 표시 필요). `true` → 이미 노출 (skip).
  ///
  /// Copied from [streakFreezeMigrationToastShown].
  StreakFreezeMigrationToastShownProvider call(
    String studentId,
  ) {
    return StreakFreezeMigrationToastShownProvider(
      studentId,
    );
  }

  @override
  StreakFreezeMigrationToastShownProvider getProviderOverride(
    covariant StreakFreezeMigrationToastShownProvider provider,
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
  String? get name => r'streakFreezeMigrationToastShownProvider';
}

/// 학생별 마이그레이션 안내 토스트 노출 상태.
///
/// `false` → 미노출 (토스트 표시 필요). `true` → 이미 노출 (skip).
///
/// Copied from [streakFreezeMigrationToastShown].
class StreakFreezeMigrationToastShownProvider
    extends AutoDisposeFutureProvider<bool> {
  /// 학생별 마이그레이션 안내 토스트 노출 상태.
  ///
  /// `false` → 미노출 (토스트 표시 필요). `true` → 이미 노출 (skip).
  ///
  /// Copied from [streakFreezeMigrationToastShown].
  StreakFreezeMigrationToastShownProvider(
    String studentId,
  ) : this._internal(
          (ref) => streakFreezeMigrationToastShown(
            ref as StreakFreezeMigrationToastShownRef,
            studentId,
          ),
          from: streakFreezeMigrationToastShownProvider,
          name: r'streakFreezeMigrationToastShownProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$streakFreezeMigrationToastShownHash,
          dependencies: StreakFreezeMigrationToastShownFamily._dependencies,
          allTransitiveDependencies:
              StreakFreezeMigrationToastShownFamily._allTransitiveDependencies,
          studentId: studentId,
        );

  StreakFreezeMigrationToastShownProvider._internal(
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
    FutureOr<bool> Function(StreakFreezeMigrationToastShownRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: StreakFreezeMigrationToastShownProvider._internal(
        (ref) => create(ref as StreakFreezeMigrationToastShownRef),
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
  AutoDisposeFutureProviderElement<bool> createElement() {
    return _StreakFreezeMigrationToastShownProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StreakFreezeMigrationToastShownProvider &&
        other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin StreakFreezeMigrationToastShownRef on AutoDisposeFutureProviderRef<bool> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _StreakFreezeMigrationToastShownProviderElement
    extends AutoDisposeFutureProviderElement<bool>
    with StreakFreezeMigrationToastShownRef {
  _StreakFreezeMigrationToastShownProviderElement(super.provider);

  @override
  String get studentId =>
      (origin as StreakFreezeMigrationToastShownProvider).studentId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
