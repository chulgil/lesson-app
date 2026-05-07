// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'section_sort_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$sortedSectionsHash() => r'31c950117ec6b5ff84574c0f2e0bdd192a9625f4';

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

/// Sorted sections provider for a repertoire
///
/// Copied from [sortedSections].
@ProviderFor(sortedSections)
const sortedSectionsProvider = SortedSectionsFamily();

/// Sorted sections provider for a repertoire
///
/// Copied from [sortedSections].
class SortedSectionsFamily extends Family<List<entities.PracticeSection>> {
  /// Sorted sections provider for a repertoire
  ///
  /// Copied from [sortedSections].
  const SortedSectionsFamily();

  /// Sorted sections provider for a repertoire
  ///
  /// Copied from [sortedSections].
  SortedSectionsProvider call(String repertoireId) {
    return SortedSectionsProvider(repertoireId);
  }

  @override
  SortedSectionsProvider getProviderOverride(
    covariant SortedSectionsProvider provider,
  ) {
    return call(provider.repertoireId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'sortedSectionsProvider';
}

/// Sorted sections provider for a repertoire
///
/// Copied from [sortedSections].
class SortedSectionsProvider extends Provider<List<entities.PracticeSection>> {
  /// Sorted sections provider for a repertoire
  ///
  /// Copied from [sortedSections].
  SortedSectionsProvider(String repertoireId)
    : this._internal(
        (ref) => sortedSections(ref as SortedSectionsRef, repertoireId),
        from: sortedSectionsProvider,
        name: r'sortedSectionsProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$sortedSectionsHash,
        dependencies: SortedSectionsFamily._dependencies,
        allTransitiveDependencies:
            SortedSectionsFamily._allTransitiveDependencies,
        repertoireId: repertoireId,
      );

  SortedSectionsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.repertoireId,
  }) : super.internal();

  final String repertoireId;

  @override
  Override overrideWith(
    List<entities.PracticeSection> Function(SortedSectionsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SortedSectionsProvider._internal(
        (ref) => create(ref as SortedSectionsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        repertoireId: repertoireId,
      ),
    );
  }

  @override
  ProviderElement<List<entities.PracticeSection>> createElement() {
    return _SortedSectionsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SortedSectionsProvider &&
        other.repertoireId == repertoireId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, repertoireId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin SortedSectionsRef on ProviderRef<List<entities.PracticeSection>> {
  /// The parameter `repertoireId` of this provider.
  String get repertoireId;
}

class _SortedSectionsProviderElement
    extends ProviderElement<List<entities.PracticeSection>>
    with SortedSectionsRef {
  _SortedSectionsProviderElement(super.provider);

  @override
  String get repertoireId => (origin as SortedSectionsProvider).repertoireId;
}

String _$sectionSortTypeStateHash() =>
    r'd2cff84ad60e2f64086fdf7466160da581d196a1';

/// Current section sort type provider
///
/// Copied from [SectionSortTypeState].
@ProviderFor(SectionSortTypeState)
final sectionSortTypeStateProvider =
    NotifierProvider<SectionSortTypeState, entities.SectionSortType>.internal(
      SectionSortTypeState.new,
      name: r'sectionSortTypeStateProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$sectionSortTypeStateHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SectionSortTypeState = Notifier<entities.SectionSortType>;
String _$sectionOrderNotifierHash() =>
    r'5747917a094c21e63c60789c07648cda85b69863';

/// Section order notifier for drag and drop
///
/// Copied from [SectionOrderNotifier].
@ProviderFor(SectionOrderNotifier)
final sectionOrderNotifierProvider =
    AsyncNotifierProvider<SectionOrderNotifier, void>.internal(
      SectionOrderNotifier.new,
      name: r'sectionOrderNotifierProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$sectionOrderNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SectionOrderNotifier = AsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
