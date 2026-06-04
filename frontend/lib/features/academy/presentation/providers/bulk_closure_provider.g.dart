// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bulk_closure_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$bulkClosureRepositoryHash() =>
    r'15661a1f7170d830e33ccf0759f1deff95991597';

/// Singleton mock repository — BE 대기.
///
/// Copied from [bulkClosureRepository].
@ProviderFor(bulkClosureRepository)
final bulkClosureRepositoryProvider = Provider<BulkClosureRepository>.internal(
  bulkClosureRepository,
  name: r'bulkClosureRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$bulkClosureRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef BulkClosureRepositoryRef = ProviderRef<BulkClosureRepository>;
String _$teacherBulkClosuresHash() =>
    r'e81c32d2b6e36905008f4f29a656d68f22976d1b';

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

/// 강사 본인이 영향 받는 closure 목록 (G15 §5).
///
/// Copied from [teacherBulkClosures].
@ProviderFor(teacherBulkClosures)
const teacherBulkClosuresProvider = TeacherBulkClosuresFamily();

/// 강사 본인이 영향 받는 closure 목록 (G15 §5).
///
/// Copied from [teacherBulkClosures].
class TeacherBulkClosuresFamily extends Family<AsyncValue<List<BulkClosure>>> {
  /// 강사 본인이 영향 받는 closure 목록 (G15 §5).
  ///
  /// Copied from [teacherBulkClosures].
  const TeacherBulkClosuresFamily();

  /// 강사 본인이 영향 받는 closure 목록 (G15 §5).
  ///
  /// Copied from [teacherBulkClosures].
  TeacherBulkClosuresProvider call(
    String teacherMemberId,
  ) {
    return TeacherBulkClosuresProvider(
      teacherMemberId,
    );
  }

  @override
  TeacherBulkClosuresProvider getProviderOverride(
    covariant TeacherBulkClosuresProvider provider,
  ) {
    return call(
      provider.teacherMemberId,
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
  String? get name => r'teacherBulkClosuresProvider';
}

/// 강사 본인이 영향 받는 closure 목록 (G15 §5).
///
/// Copied from [teacherBulkClosures].
class TeacherBulkClosuresProvider
    extends AutoDisposeFutureProvider<List<BulkClosure>> {
  /// 강사 본인이 영향 받는 closure 목록 (G15 §5).
  ///
  /// Copied from [teacherBulkClosures].
  TeacherBulkClosuresProvider(
    String teacherMemberId,
  ) : this._internal(
          (ref) => teacherBulkClosures(
            ref as TeacherBulkClosuresRef,
            teacherMemberId,
          ),
          from: teacherBulkClosuresProvider,
          name: r'teacherBulkClosuresProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$teacherBulkClosuresHash,
          dependencies: TeacherBulkClosuresFamily._dependencies,
          allTransitiveDependencies:
              TeacherBulkClosuresFamily._allTransitiveDependencies,
          teacherMemberId: teacherMemberId,
        );

  TeacherBulkClosuresProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.teacherMemberId,
  }) : super.internal();

  final String teacherMemberId;

  @override
  Override overrideWith(
    FutureOr<List<BulkClosure>> Function(TeacherBulkClosuresRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TeacherBulkClosuresProvider._internal(
        (ref) => create(ref as TeacherBulkClosuresRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        teacherMemberId: teacherMemberId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<BulkClosure>> createElement() {
    return _TeacherBulkClosuresProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TeacherBulkClosuresProvider &&
        other.teacherMemberId == teacherMemberId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, teacherMemberId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin TeacherBulkClosuresRef
    on AutoDisposeFutureProviderRef<List<BulkClosure>> {
  /// The parameter `teacherMemberId` of this provider.
  String get teacherMemberId;
}

class _TeacherBulkClosuresProviderElement
    extends AutoDisposeFutureProviderElement<List<BulkClosure>>
    with TeacherBulkClosuresRef {
  _TeacherBulkClosuresProviderElement(super.provider);

  @override
  String get teacherMemberId =>
      (origin as TeacherBulkClosuresProvider).teacherMemberId;
}

String _$bulkClosureDetailHash() => r'cb8fb6865631ed7b24ac2851ea59a2d3a9865538';

/// 단일 closure 상세.
///
/// Copied from [bulkClosureDetail].
@ProviderFor(bulkClosureDetail)
const bulkClosureDetailProvider = BulkClosureDetailFamily();

/// 단일 closure 상세.
///
/// Copied from [bulkClosureDetail].
class BulkClosureDetailFamily extends Family<AsyncValue<BulkClosure?>> {
  /// 단일 closure 상세.
  ///
  /// Copied from [bulkClosureDetail].
  const BulkClosureDetailFamily();

  /// 단일 closure 상세.
  ///
  /// Copied from [bulkClosureDetail].
  BulkClosureDetailProvider call(
    String closureId,
  ) {
    return BulkClosureDetailProvider(
      closureId,
    );
  }

  @override
  BulkClosureDetailProvider getProviderOverride(
    covariant BulkClosureDetailProvider provider,
  ) {
    return call(
      provider.closureId,
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
  String? get name => r'bulkClosureDetailProvider';
}

/// 단일 closure 상세.
///
/// Copied from [bulkClosureDetail].
class BulkClosureDetailProvider
    extends AutoDisposeFutureProvider<BulkClosure?> {
  /// 단일 closure 상세.
  ///
  /// Copied from [bulkClosureDetail].
  BulkClosureDetailProvider(
    String closureId,
  ) : this._internal(
          (ref) => bulkClosureDetail(
            ref as BulkClosureDetailRef,
            closureId,
          ),
          from: bulkClosureDetailProvider,
          name: r'bulkClosureDetailProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$bulkClosureDetailHash,
          dependencies: BulkClosureDetailFamily._dependencies,
          allTransitiveDependencies:
              BulkClosureDetailFamily._allTransitiveDependencies,
          closureId: closureId,
        );

  BulkClosureDetailProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.closureId,
  }) : super.internal();

  final String closureId;

  @override
  Override overrideWith(
    FutureOr<BulkClosure?> Function(BulkClosureDetailRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: BulkClosureDetailProvider._internal(
        (ref) => create(ref as BulkClosureDetailRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        closureId: closureId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<BulkClosure?> createElement() {
    return _BulkClosureDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BulkClosureDetailProvider && other.closureId == closureId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, closureId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin BulkClosureDetailRef on AutoDisposeFutureProviderRef<BulkClosure?> {
  /// The parameter `closureId` of this provider.
  String get closureId;
}

class _BulkClosureDetailProviderElement
    extends AutoDisposeFutureProviderElement<BulkClosure?>
    with BulkClosureDetailRef {
  _BulkClosureDetailProviderElement(super.provider);

  @override
  String get closureId => (origin as BulkClosureDetailProvider).closureId;
}

String _$bulkClosureNotifierHash() =>
    r'24da262d2b589ff0b695f90793b47efb54a9d480';

/// 강사 의견 입력 / 보강 일정 일괄 저장 등 mutation.
///
/// Copied from [BulkClosureNotifier].
@ProviderFor(BulkClosureNotifier)
final bulkClosureNotifierProvider =
    AutoDisposeNotifierProvider<BulkClosureNotifier, void>.internal(
  BulkClosureNotifier.new,
  name: r'bulkClosureNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$bulkClosureNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$BulkClosureNotifier = AutoDisposeNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
