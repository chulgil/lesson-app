// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'badge_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$badgeCheckerHash() => r'dc7b552deaf9ed991b116e8f3425e3b788fd7b6f';

/// Stateless badge checker — kept alive (no per-build cost).
///
/// Copied from [badgeChecker].
@ProviderFor(badgeChecker)
final badgeCheckerProvider = Provider<BadgeChecker>.internal(
  badgeChecker,
  name: r'badgeCheckerProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$badgeCheckerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef BadgeCheckerRef = ProviderRef<BadgeChecker>;
String _$practiceBadgeCollectionHash() =>
    r'f1c095fe3b1e52ed092702b46e8419d8ccc5a3a9';

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

/// Gallery view: ordered list of every [BadgeType] with earned status applied.
///
/// Copied from [practiceBadgeCollection].
@ProviderFor(practiceBadgeCollection)
const practiceBadgeCollectionProvider = PracticeBadgeCollectionFamily();

/// Gallery view: ordered list of every [BadgeType] with earned status applied.
///
/// Copied from [practiceBadgeCollection].
class PracticeBadgeCollectionFamily extends Family<List<Badge>> {
  /// Gallery view: ordered list of every [BadgeType] with earned status applied.
  ///
  /// Copied from [practiceBadgeCollection].
  const PracticeBadgeCollectionFamily();

  /// Gallery view: ordered list of every [BadgeType] with earned status applied.
  ///
  /// Copied from [practiceBadgeCollection].
  PracticeBadgeCollectionProvider call(
    String studentId,
  ) {
    return PracticeBadgeCollectionProvider(
      studentId,
    );
  }

  @override
  PracticeBadgeCollectionProvider getProviderOverride(
    covariant PracticeBadgeCollectionProvider provider,
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
  String? get name => r'practiceBadgeCollectionProvider';
}

/// Gallery view: ordered list of every [BadgeType] with earned status applied.
///
/// Copied from [practiceBadgeCollection].
class PracticeBadgeCollectionProvider extends AutoDisposeProvider<List<Badge>> {
  /// Gallery view: ordered list of every [BadgeType] with earned status applied.
  ///
  /// Copied from [practiceBadgeCollection].
  PracticeBadgeCollectionProvider(
    String studentId,
  ) : this._internal(
          (ref) => practiceBadgeCollection(
            ref as PracticeBadgeCollectionRef,
            studentId,
          ),
          from: practiceBadgeCollectionProvider,
          name: r'practiceBadgeCollectionProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$practiceBadgeCollectionHash,
          dependencies: PracticeBadgeCollectionFamily._dependencies,
          allTransitiveDependencies:
              PracticeBadgeCollectionFamily._allTransitiveDependencies,
          studentId: studentId,
        );

  PracticeBadgeCollectionProvider._internal(
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
    List<Badge> Function(PracticeBadgeCollectionRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PracticeBadgeCollectionProvider._internal(
        (ref) => create(ref as PracticeBadgeCollectionRef),
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
  AutoDisposeProviderElement<List<Badge>> createElement() {
    return _PracticeBadgeCollectionProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PracticeBadgeCollectionProvider &&
        other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin PracticeBadgeCollectionRef on AutoDisposeProviderRef<List<Badge>> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _PracticeBadgeCollectionProviderElement
    extends AutoDisposeProviderElement<List<Badge>>
    with PracticeBadgeCollectionRef {
  _PracticeBadgeCollectionProviderElement(super.provider);

  @override
  String get studentId => (origin as PracticeBadgeCollectionProvider).studentId;
}

String _$practiceBadgeStateNotifierHash() =>
    r'863b6721dc3d32a1000c53bba840f69efec878cb';

abstract class _$PracticeBadgeStateNotifier
    extends BuildlessNotifier<PracticeBadgeState> {
  late final String studentId;

  PracticeBadgeState build(
    String studentId,
  );
}

/// Mutable badge state per student. Kept alive so popups outlive
/// rebuilds of the listening widget.
///
/// Copied from [PracticeBadgeStateNotifier].
@ProviderFor(PracticeBadgeStateNotifier)
const practiceBadgeStateNotifierProvider = PracticeBadgeStateNotifierFamily();

/// Mutable badge state per student. Kept alive so popups outlive
/// rebuilds of the listening widget.
///
/// Copied from [PracticeBadgeStateNotifier].
class PracticeBadgeStateNotifierFamily extends Family<PracticeBadgeState> {
  /// Mutable badge state per student. Kept alive so popups outlive
  /// rebuilds of the listening widget.
  ///
  /// Copied from [PracticeBadgeStateNotifier].
  const PracticeBadgeStateNotifierFamily();

  /// Mutable badge state per student. Kept alive so popups outlive
  /// rebuilds of the listening widget.
  ///
  /// Copied from [PracticeBadgeStateNotifier].
  PracticeBadgeStateNotifierProvider call(
    String studentId,
  ) {
    return PracticeBadgeStateNotifierProvider(
      studentId,
    );
  }

  @override
  PracticeBadgeStateNotifierProvider getProviderOverride(
    covariant PracticeBadgeStateNotifierProvider provider,
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
  String? get name => r'practiceBadgeStateNotifierProvider';
}

/// Mutable badge state per student. Kept alive so popups outlive
/// rebuilds of the listening widget.
///
/// Copied from [PracticeBadgeStateNotifier].
class PracticeBadgeStateNotifierProvider extends NotifierProviderImpl<
    PracticeBadgeStateNotifier, PracticeBadgeState> {
  /// Mutable badge state per student. Kept alive so popups outlive
  /// rebuilds of the listening widget.
  ///
  /// Copied from [PracticeBadgeStateNotifier].
  PracticeBadgeStateNotifierProvider(
    String studentId,
  ) : this._internal(
          () => PracticeBadgeStateNotifier()..studentId = studentId,
          from: practiceBadgeStateNotifierProvider,
          name: r'practiceBadgeStateNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$practiceBadgeStateNotifierHash,
          dependencies: PracticeBadgeStateNotifierFamily._dependencies,
          allTransitiveDependencies:
              PracticeBadgeStateNotifierFamily._allTransitiveDependencies,
          studentId: studentId,
        );

  PracticeBadgeStateNotifierProvider._internal(
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
  PracticeBadgeState runNotifierBuild(
    covariant PracticeBadgeStateNotifier notifier,
  ) {
    return notifier.build(
      studentId,
    );
  }

  @override
  Override overrideWith(PracticeBadgeStateNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: PracticeBadgeStateNotifierProvider._internal(
        () => create()..studentId = studentId,
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
  NotifierProviderElement<PracticeBadgeStateNotifier, PracticeBadgeState>
      createElement() {
    return _PracticeBadgeStateNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PracticeBadgeStateNotifierProvider &&
        other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin PracticeBadgeStateNotifierRef on NotifierProviderRef<PracticeBadgeState> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _PracticeBadgeStateNotifierProviderElement
    extends NotifierProviderElement<PracticeBadgeStateNotifier,
        PracticeBadgeState> with PracticeBadgeStateNotifierRef {
  _PracticeBadgeStateNotifierProviderElement(super.provider);

  @override
  String get studentId =>
      (origin as PracticeBadgeStateNotifierProvider).studentId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
