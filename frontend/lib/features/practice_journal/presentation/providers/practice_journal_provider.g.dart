// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'practice_journal_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$practiceJournalRepositoryHash() =>
    r'070e92c1ccb3daedf26b5caa6af9dc2ea7aa6904';

/// See also [practiceJournalRepository].
@ProviderFor(practiceJournalRepository)
final practiceJournalRepositoryProvider =
    Provider<PracticeJournalRepository>.internal(
  practiceJournalRepository,
  name: r'practiceJournalRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$practiceJournalRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef PracticeJournalRepositoryRef = ProviderRef<PracticeJournalRepository>;
String _$practiceLedgerHash() => r'b797d0f58bc9ca9e14869b17f8bd4b82a00b71f6';

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

/// See also [practiceLedger].
@ProviderFor(practiceLedger)
const practiceLedgerProvider = PracticeLedgerFamily();

/// See also [practiceLedger].
class PracticeLedgerFamily extends Family<AsyncValue<PracticeLedger>> {
  /// See also [practiceLedger].
  const PracticeLedgerFamily();

  /// See also [practiceLedger].
  PracticeLedgerProvider call({
    required String childProfileId,
    required int year,
    required int month,
  }) {
    return PracticeLedgerProvider(
      childProfileId: childProfileId,
      year: year,
      month: month,
    );
  }

  @override
  PracticeLedgerProvider getProviderOverride(
    covariant PracticeLedgerProvider provider,
  ) {
    return call(
      childProfileId: provider.childProfileId,
      year: provider.year,
      month: provider.month,
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
  String? get name => r'practiceLedgerProvider';
}

/// See also [practiceLedger].
class PracticeLedgerProvider extends AutoDisposeFutureProvider<PracticeLedger> {
  /// See also [practiceLedger].
  PracticeLedgerProvider({
    required String childProfileId,
    required int year,
    required int month,
  }) : this._internal(
          (ref) => practiceLedger(
            ref as PracticeLedgerRef,
            childProfileId: childProfileId,
            year: year,
            month: month,
          ),
          from: practiceLedgerProvider,
          name: r'practiceLedgerProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$practiceLedgerHash,
          dependencies: PracticeLedgerFamily._dependencies,
          allTransitiveDependencies:
              PracticeLedgerFamily._allTransitiveDependencies,
          childProfileId: childProfileId,
          year: year,
          month: month,
        );

  PracticeLedgerProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.childProfileId,
    required this.year,
    required this.month,
  }) : super.internal();

  final String childProfileId;
  final int year;
  final int month;

  @override
  Override overrideWith(
    FutureOr<PracticeLedger> Function(PracticeLedgerRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PracticeLedgerProvider._internal(
        (ref) => create(ref as PracticeLedgerRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        childProfileId: childProfileId,
        year: year,
        month: month,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<PracticeLedger> createElement() {
    return _PracticeLedgerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PracticeLedgerProvider &&
        other.childProfileId == childProfileId &&
        other.year == year &&
        other.month == month;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, childProfileId.hashCode);
    hash = _SystemHash.combine(hash, year.hashCode);
    hash = _SystemHash.combine(hash, month.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin PracticeLedgerRef on AutoDisposeFutureProviderRef<PracticeLedger> {
  /// The parameter `childProfileId` of this provider.
  String get childProfileId;

  /// The parameter `year` of this provider.
  int get year;

  /// The parameter `month` of this provider.
  int get month;
}

class _PracticeLedgerProviderElement
    extends AutoDisposeFutureProviderElement<PracticeLedger>
    with PracticeLedgerRef {
  _PracticeLedgerProviderElement(super.provider);

  @override
  String get childProfileId =>
      (origin as PracticeLedgerProvider).childProfileId;
  @override
  int get year => (origin as PracticeLedgerProvider).year;
  @override
  int get month => (origin as PracticeLedgerProvider).month;
}

String _$boundVolumesHash() => r'075caeb5c0a69a5f2a225b6f83bef3c3d7c52a08';

/// 자녀 프로필의 완성본 목록(책장). 곡 완성(제본) 후 invalidate 로 갱신.
///
/// Copied from [boundVolumes].
@ProviderFor(boundVolumes)
const boundVolumesProvider = BoundVolumesFamily();

/// 자녀 프로필의 완성본 목록(책장). 곡 완성(제본) 후 invalidate 로 갱신.
///
/// Copied from [boundVolumes].
class BoundVolumesFamily extends Family<AsyncValue<List<BoundVolume>>> {
  /// 자녀 프로필의 완성본 목록(책장). 곡 완성(제본) 후 invalidate 로 갱신.
  ///
  /// Copied from [boundVolumes].
  const BoundVolumesFamily();

  /// 자녀 프로필의 완성본 목록(책장). 곡 완성(제본) 후 invalidate 로 갱신.
  ///
  /// Copied from [boundVolumes].
  BoundVolumesProvider call(
    String childProfileId,
  ) {
    return BoundVolumesProvider(
      childProfileId,
    );
  }

  @override
  BoundVolumesProvider getProviderOverride(
    covariant BoundVolumesProvider provider,
  ) {
    return call(
      provider.childProfileId,
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
  String? get name => r'boundVolumesProvider';
}

/// 자녀 프로필의 완성본 목록(책장). 곡 완성(제본) 후 invalidate 로 갱신.
///
/// Copied from [boundVolumes].
class BoundVolumesProvider
    extends AutoDisposeFutureProvider<List<BoundVolume>> {
  /// 자녀 프로필의 완성본 목록(책장). 곡 완성(제본) 후 invalidate 로 갱신.
  ///
  /// Copied from [boundVolumes].
  BoundVolumesProvider(
    String childProfileId,
  ) : this._internal(
          (ref) => boundVolumes(
            ref as BoundVolumesRef,
            childProfileId,
          ),
          from: boundVolumesProvider,
          name: r'boundVolumesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$boundVolumesHash,
          dependencies: BoundVolumesFamily._dependencies,
          allTransitiveDependencies:
              BoundVolumesFamily._allTransitiveDependencies,
          childProfileId: childProfileId,
        );

  BoundVolumesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.childProfileId,
  }) : super.internal();

  final String childProfileId;

  @override
  Override overrideWith(
    FutureOr<List<BoundVolume>> Function(BoundVolumesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: BoundVolumesProvider._internal(
        (ref) => create(ref as BoundVolumesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        childProfileId: childProfileId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<BoundVolume>> createElement() {
    return _BoundVolumesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BoundVolumesProvider &&
        other.childProfileId == childProfileId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, childProfileId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin BoundVolumesRef on AutoDisposeFutureProviderRef<List<BoundVolume>> {
  /// The parameter `childProfileId` of this provider.
  String get childProfileId;
}

class _BoundVolumesProviderElement
    extends AutoDisposeFutureProviderElement<List<BoundVolume>>
    with BoundVolumesRef {
  _BoundVolumesProviderElement(super.provider);

  @override
  String get childProfileId => (origin as BoundVolumesProvider).childProfileId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
