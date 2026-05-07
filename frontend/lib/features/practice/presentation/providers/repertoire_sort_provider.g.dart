// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repertoire_sort_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$sortedRepertoiresForDateHash() =>
    r'523cffdb97772d7c7d9206f8af35dba072a5438e';

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

/// Sorted repertoires provider for a date
///
/// Copied from [sortedRepertoiresForDate].
@ProviderFor(sortedRepertoiresForDate)
const sortedRepertoiresForDateProvider = SortedRepertoiresForDateFamily();

/// Sorted repertoires provider for a date
///
/// Copied from [sortedRepertoiresForDate].
class SortedRepertoiresForDateFamily
    extends Family<List<practice.PracticeRepertoire>> {
  /// Sorted repertoires provider for a date
  ///
  /// Copied from [sortedRepertoiresForDate].
  const SortedRepertoiresForDateFamily();

  /// Sorted repertoires provider for a date
  ///
  /// Copied from [sortedRepertoiresForDate].
  SortedRepertoiresForDateProvider call(
    RepertoiresForDateParams params,
  ) {
    return SortedRepertoiresForDateProvider(
      params,
    );
  }

  @override
  SortedRepertoiresForDateProvider getProviderOverride(
    covariant SortedRepertoiresForDateProvider provider,
  ) {
    return call(
      provider.params,
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
  String? get name => r'sortedRepertoiresForDateProvider';
}

/// Sorted repertoires provider for a date
///
/// Copied from [sortedRepertoiresForDate].
class SortedRepertoiresForDateProvider
    extends Provider<List<practice.PracticeRepertoire>> {
  /// Sorted repertoires provider for a date
  ///
  /// Copied from [sortedRepertoiresForDate].
  SortedRepertoiresForDateProvider(
    RepertoiresForDateParams params,
  ) : this._internal(
          (ref) => sortedRepertoiresForDate(
            ref as SortedRepertoiresForDateRef,
            params,
          ),
          from: sortedRepertoiresForDateProvider,
          name: r'sortedRepertoiresForDateProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$sortedRepertoiresForDateHash,
          dependencies: SortedRepertoiresForDateFamily._dependencies,
          allTransitiveDependencies:
              SortedRepertoiresForDateFamily._allTransitiveDependencies,
          params: params,
        );

  SortedRepertoiresForDateProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.params,
  }) : super.internal();

  final RepertoiresForDateParams params;

  @override
  Override overrideWith(
    List<practice.PracticeRepertoire> Function(
            SortedRepertoiresForDateRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SortedRepertoiresForDateProvider._internal(
        (ref) => create(ref as SortedRepertoiresForDateRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        params: params,
      ),
    );
  }

  @override
  ProviderElement<List<practice.PracticeRepertoire>> createElement() {
    return _SortedRepertoiresForDateProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SortedRepertoiresForDateProvider && other.params == params;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, params.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin SortedRepertoiresForDateRef
    on ProviderRef<List<practice.PracticeRepertoire>> {
  /// The parameter `params` of this provider.
  RepertoiresForDateParams get params;
}

class _SortedRepertoiresForDateProviderElement
    extends ProviderElement<List<practice.PracticeRepertoire>>
    with SortedRepertoiresForDateRef {
  _SortedRepertoiresForDateProviderElement(super.provider);

  @override
  RepertoiresForDateParams get params =>
      (origin as SortedRepertoiresForDateProvider).params;
}

String _$repertoireSortTypeStateHash() =>
    r'8ce3cf8f3a8cedc11ec8085b4699bcc4d97f8ffc';

/// Current repertoire sort type provider
///
/// Copied from [RepertoireSortTypeState].
@ProviderFor(RepertoireSortTypeState)
final repertoireSortTypeStateProvider = NotifierProvider<
    RepertoireSortTypeState, domain.RepertoireSortType>.internal(
  RepertoireSortTypeState.new,
  name: r'repertoireSortTypeStateProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$repertoireSortTypeStateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$RepertoireSortTypeState = Notifier<domain.RepertoireSortType>;
String _$repertoireOrderNotifierHash() =>
    r'e3aec9c8d20996a367c6a7c39510ee7d50172d31';

/// Repertoire order notifier for drag and drop
///
/// Copied from [RepertoireOrderNotifier].
@ProviderFor(RepertoireOrderNotifier)
final repertoireOrderNotifierProvider =
    AsyncNotifierProvider<RepertoireOrderNotifier, void>.internal(
  RepertoireOrderNotifier.new,
  name: r'repertoireOrderNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$repertoireOrderNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$RepertoireOrderNotifier = AsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
