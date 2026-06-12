// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'streak_freeze_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$streakFreezeRepositoryHash() =>
    r'aa48e01a49a169b611cbf9c7c23e0276f7e5d1dc';

/// P2: Mock 우선 (P1 패턴 일관). HiveStreakFreezeRepository 운영 통합은 Job 5
/// D-day 마이그레이션 + Job 10 e2e 단계에서 환경 분기 추가.
///
/// Copied from [streakFreezeRepository].
@ProviderFor(streakFreezeRepository)
final streakFreezeRepositoryProvider =
    Provider<StreakFreezeRepository>.internal(
  streakFreezeRepository,
  name: r'streakFreezeRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$streakFreezeRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef StreakFreezeRepositoryRef = ProviderRef<StreakFreezeRepository>;
String _$streakFreezeServiceHash() =>
    r'c2399b64998f334db2e1a89681bcbbe42737d5ae';

/// 자동 발급/적용/시험 모드 로직 — KST 정렬 책임.
///
/// Copied from [streakFreezeService].
@ProviderFor(streakFreezeService)
final streakFreezeServiceProvider = Provider<StreakFreezeService>.internal(
  streakFreezeService,
  name: r'streakFreezeServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$streakFreezeServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef StreakFreezeServiceRef = ProviderRef<StreakFreezeService>;
String _$studentStreakFreezeHash() =>
    r'776eacdc681cedfd7ce69e5e0cfaa40445f20448';

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

/// 학생별 StreakFreeze 조회 — autoDispose (Family).
///
/// Copied from [studentStreakFreeze].
@ProviderFor(studentStreakFreeze)
const studentStreakFreezeProvider = StudentStreakFreezeFamily();

/// 학생별 StreakFreeze 조회 — autoDispose (Family).
///
/// Copied from [studentStreakFreeze].
class StudentStreakFreezeFamily extends Family<AsyncValue<StreakFreeze>> {
  /// 학생별 StreakFreeze 조회 — autoDispose (Family).
  ///
  /// Copied from [studentStreakFreeze].
  const StudentStreakFreezeFamily();

  /// 학생별 StreakFreeze 조회 — autoDispose (Family).
  ///
  /// Copied from [studentStreakFreeze].
  StudentStreakFreezeProvider call(
    String studentId,
  ) {
    return StudentStreakFreezeProvider(
      studentId,
    );
  }

  @override
  StudentStreakFreezeProvider getProviderOverride(
    covariant StudentStreakFreezeProvider provider,
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
  String? get name => r'studentStreakFreezeProvider';
}

/// 학생별 StreakFreeze 조회 — autoDispose (Family).
///
/// Copied from [studentStreakFreeze].
class StudentStreakFreezeProvider
    extends AutoDisposeFutureProvider<StreakFreeze> {
  /// 학생별 StreakFreeze 조회 — autoDispose (Family).
  ///
  /// Copied from [studentStreakFreeze].
  StudentStreakFreezeProvider(
    String studentId,
  ) : this._internal(
          (ref) => studentStreakFreeze(
            ref as StudentStreakFreezeRef,
            studentId,
          ),
          from: studentStreakFreezeProvider,
          name: r'studentStreakFreezeProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$studentStreakFreezeHash,
          dependencies: StudentStreakFreezeFamily._dependencies,
          allTransitiveDependencies:
              StudentStreakFreezeFamily._allTransitiveDependencies,
          studentId: studentId,
        );

  StudentStreakFreezeProvider._internal(
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
    FutureOr<StreakFreeze> Function(StudentStreakFreezeRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: StudentStreakFreezeProvider._internal(
        (ref) => create(ref as StudentStreakFreezeRef),
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
  AutoDisposeFutureProviderElement<StreakFreeze> createElement() {
    return _StudentStreakFreezeProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StudentStreakFreezeProvider && other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin StudentStreakFreezeRef on AutoDisposeFutureProviderRef<StreakFreeze> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _StudentStreakFreezeProviderElement
    extends AutoDisposeFutureProviderElement<StreakFreeze>
    with StudentStreakFreezeRef {
  _StudentStreakFreezeProviderElement(super.provider);

  @override
  String get studentId => (origin as StudentStreakFreezeProvider).studentId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
