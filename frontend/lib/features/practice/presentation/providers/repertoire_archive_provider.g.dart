// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repertoire_archive_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$activeRepertoiresHash() => r'759c0efcadae81a044f1017b74f13eebb6a4fc15';

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

/// Active (non-archived) repertoires provider
///
/// Copied from [activeRepertoires].
@ProviderFor(activeRepertoires)
const activeRepertoiresProvider = ActiveRepertoiresFamily();

/// Active (non-archived) repertoires provider
///
/// Copied from [activeRepertoires].
class ActiveRepertoiresFamily
    extends Family<AsyncValue<List<PracticeRepertoire>>> {
  /// Active (non-archived) repertoires provider
  ///
  /// Copied from [activeRepertoires].
  const ActiveRepertoiresFamily();

  /// Active (non-archived) repertoires provider
  ///
  /// Copied from [activeRepertoires].
  ActiveRepertoiresProvider call(
    String studentId,
  ) {
    return ActiveRepertoiresProvider(
      studentId,
    );
  }

  @override
  ActiveRepertoiresProvider getProviderOverride(
    covariant ActiveRepertoiresProvider provider,
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
  String? get name => r'activeRepertoiresProvider';
}

/// Active (non-archived) repertoires provider
///
/// Copied from [activeRepertoires].
class ActiveRepertoiresProvider
    extends FutureProvider<List<PracticeRepertoire>> {
  /// Active (non-archived) repertoires provider
  ///
  /// Copied from [activeRepertoires].
  ActiveRepertoiresProvider(
    String studentId,
  ) : this._internal(
          (ref) => activeRepertoires(
            ref as ActiveRepertoiresRef,
            studentId,
          ),
          from: activeRepertoiresProvider,
          name: r'activeRepertoiresProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$activeRepertoiresHash,
          dependencies: ActiveRepertoiresFamily._dependencies,
          allTransitiveDependencies:
              ActiveRepertoiresFamily._allTransitiveDependencies,
          studentId: studentId,
        );

  ActiveRepertoiresProvider._internal(
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
    FutureOr<List<PracticeRepertoire>> Function(ActiveRepertoiresRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ActiveRepertoiresProvider._internal(
        (ref) => create(ref as ActiveRepertoiresRef),
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
  FutureProviderElement<List<PracticeRepertoire>> createElement() {
    return _ActiveRepertoiresProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ActiveRepertoiresProvider && other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin ActiveRepertoiresRef on FutureProviderRef<List<PracticeRepertoire>> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _ActiveRepertoiresProviderElement
    extends FutureProviderElement<List<PracticeRepertoire>>
    with ActiveRepertoiresRef {
  _ActiveRepertoiresProviderElement(super.provider);

  @override
  String get studentId => (origin as ActiveRepertoiresProvider).studentId;
}

String _$archivedRepertoiresHash() =>
    r'0978feab0dd5bcd81748d37d3900c0ffbd049f2a';

/// Archived repertoires provider
///
/// Copied from [archivedRepertoires].
@ProviderFor(archivedRepertoires)
const archivedRepertoiresProvider = ArchivedRepertoiresFamily();

/// Archived repertoires provider
///
/// Copied from [archivedRepertoires].
class ArchivedRepertoiresFamily
    extends Family<AsyncValue<List<PracticeRepertoire>>> {
  /// Archived repertoires provider
  ///
  /// Copied from [archivedRepertoires].
  const ArchivedRepertoiresFamily();

  /// Archived repertoires provider
  ///
  /// Copied from [archivedRepertoires].
  ArchivedRepertoiresProvider call(
    String studentId,
  ) {
    return ArchivedRepertoiresProvider(
      studentId,
    );
  }

  @override
  ArchivedRepertoiresProvider getProviderOverride(
    covariant ArchivedRepertoiresProvider provider,
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
  String? get name => r'archivedRepertoiresProvider';
}

/// Archived repertoires provider
///
/// Copied from [archivedRepertoires].
class ArchivedRepertoiresProvider
    extends FutureProvider<List<PracticeRepertoire>> {
  /// Archived repertoires provider
  ///
  /// Copied from [archivedRepertoires].
  ArchivedRepertoiresProvider(
    String studentId,
  ) : this._internal(
          (ref) => archivedRepertoires(
            ref as ArchivedRepertoiresRef,
            studentId,
          ),
          from: archivedRepertoiresProvider,
          name: r'archivedRepertoiresProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$archivedRepertoiresHash,
          dependencies: ArchivedRepertoiresFamily._dependencies,
          allTransitiveDependencies:
              ArchivedRepertoiresFamily._allTransitiveDependencies,
          studentId: studentId,
        );

  ArchivedRepertoiresProvider._internal(
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
    FutureOr<List<PracticeRepertoire>> Function(ArchivedRepertoiresRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ArchivedRepertoiresProvider._internal(
        (ref) => create(ref as ArchivedRepertoiresRef),
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
  FutureProviderElement<List<PracticeRepertoire>> createElement() {
    return _ArchivedRepertoiresProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ArchivedRepertoiresProvider && other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin ArchivedRepertoiresRef on FutureProviderRef<List<PracticeRepertoire>> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _ArchivedRepertoiresProviderElement
    extends FutureProviderElement<List<PracticeRepertoire>>
    with ArchivedRepertoiresRef {
  _ArchivedRepertoiresProviderElement(super.provider);

  @override
  String get studentId => (origin as ArchivedRepertoiresProvider).studentId;
}

String _$repertoireArchiveNotifierHash() =>
    r'ca0c3c1166d0f781654c0e22bb428bb898449f23';

/// Repertoire archive notifier
///
/// Copied from [RepertoireArchiveNotifier].
@ProviderFor(RepertoireArchiveNotifier)
final repertoireArchiveNotifierProvider =
    AsyncNotifierProvider<RepertoireArchiveNotifier, void>.internal(
  RepertoireArchiveNotifier.new,
  name: r'repertoireArchiveNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$repertoireArchiveNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$RepertoireArchiveNotifier = AsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
