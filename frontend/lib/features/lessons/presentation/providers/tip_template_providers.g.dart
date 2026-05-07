// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tip_template_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$tipTemplateRepositoryHash() =>
    r'500648120ee16c63aebdea734c0395021942dfd8';

/// Repository provider
///
/// Copied from [tipTemplateRepository].
@ProviderFor(tipTemplateRepository)
final tipTemplateRepositoryProvider = Provider<TipTemplateRepository>.internal(
  tipTemplateRepository,
  name: r'tipTemplateRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$tipTemplateRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef TipTemplateRepositoryRef = ProviderRef<TipTemplateRepository>;
String _$currentTeacherIdHash() => r'7a11ed00390260955da3b0cfbb0ce5a4f11351b3';

/// Current teacher ID provider - uses currentUserIdProvider from auth
///
/// Copied from [currentTeacherId].
@ProviderFor(currentTeacherId)
final currentTeacherIdProvider = Provider<String>.internal(
  currentTeacherId,
  name: r'currentTeacherIdProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentTeacherIdHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef CurrentTeacherIdRef = ProviderRef<String>;
String _$tipTemplatesHash() => r'71d76438d376692fb2dac62cd6e7461383b19345';

/// All templates for current teacher
///
/// Copied from [tipTemplates].
@ProviderFor(tipTemplates)
final tipTemplatesProvider = FutureProvider<List<TipTemplate>>.internal(
  tipTemplates,
  name: r'tipTemplatesProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$tipTemplatesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef TipTemplatesRef = FutureProviderRef<List<TipTemplate>>;
String _$tipTemplatesByCategoryHash() =>
    r'23444b6691b5671e9286afa0732b0743c09d134e';

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

/// Templates by category
///
/// Copied from [tipTemplatesByCategory].
@ProviderFor(tipTemplatesByCategory)
const tipTemplatesByCategoryProvider = TipTemplatesByCategoryFamily();

/// Templates by category
///
/// Copied from [tipTemplatesByCategory].
class TipTemplatesByCategoryFamily
    extends Family<AsyncValue<List<TipTemplate>>> {
  /// Templates by category
  ///
  /// Copied from [tipTemplatesByCategory].
  const TipTemplatesByCategoryFamily();

  /// Templates by category
  ///
  /// Copied from [tipTemplatesByCategory].
  TipTemplatesByCategoryProvider call(
    TipCategory category,
  ) {
    return TipTemplatesByCategoryProvider(
      category,
    );
  }

  @override
  TipTemplatesByCategoryProvider getProviderOverride(
    covariant TipTemplatesByCategoryProvider provider,
  ) {
    return call(
      provider.category,
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
  String? get name => r'tipTemplatesByCategoryProvider';
}

/// Templates by category
///
/// Copied from [tipTemplatesByCategory].
class TipTemplatesByCategoryProvider extends FutureProvider<List<TipTemplate>> {
  /// Templates by category
  ///
  /// Copied from [tipTemplatesByCategory].
  TipTemplatesByCategoryProvider(
    TipCategory category,
  ) : this._internal(
          (ref) => tipTemplatesByCategory(
            ref as TipTemplatesByCategoryRef,
            category,
          ),
          from: tipTemplatesByCategoryProvider,
          name: r'tipTemplatesByCategoryProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$tipTemplatesByCategoryHash,
          dependencies: TipTemplatesByCategoryFamily._dependencies,
          allTransitiveDependencies:
              TipTemplatesByCategoryFamily._allTransitiveDependencies,
          category: category,
        );

  TipTemplatesByCategoryProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.category,
  }) : super.internal();

  final TipCategory category;

  @override
  Override overrideWith(
    FutureOr<List<TipTemplate>> Function(TipTemplatesByCategoryRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TipTemplatesByCategoryProvider._internal(
        (ref) => create(ref as TipTemplatesByCategoryRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        category: category,
      ),
    );
  }

  @override
  FutureProviderElement<List<TipTemplate>> createElement() {
    return _TipTemplatesByCategoryProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TipTemplatesByCategoryProvider &&
        other.category == category;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, category.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin TipTemplatesByCategoryRef on FutureProviderRef<List<TipTemplate>> {
  /// The parameter `category` of this provider.
  TipCategory get category;
}

class _TipTemplatesByCategoryProviderElement
    extends FutureProviderElement<List<TipTemplate>>
    with TipTemplatesByCategoryRef {
  _TipTemplatesByCategoryProviderElement(super.provider);

  @override
  TipCategory get category =>
      (origin as TipTemplatesByCategoryProvider).category;
}

String _$tipTemplatesByInstrumentHash() =>
    r'1d654bb22470cfc3a13eb440a58e85b189ef0a3c';

/// Templates for specific instrument (includes general tips)
///
/// Copied from [tipTemplatesByInstrument].
@ProviderFor(tipTemplatesByInstrument)
const tipTemplatesByInstrumentProvider = TipTemplatesByInstrumentFamily();

/// Templates for specific instrument (includes general tips)
///
/// Copied from [tipTemplatesByInstrument].
class TipTemplatesByInstrumentFamily
    extends Family<AsyncValue<List<TipTemplate>>> {
  /// Templates for specific instrument (includes general tips)
  ///
  /// Copied from [tipTemplatesByInstrument].
  const TipTemplatesByInstrumentFamily();

  /// Templates for specific instrument (includes general tips)
  ///
  /// Copied from [tipTemplatesByInstrument].
  TipTemplatesByInstrumentProvider call(
    String? instrument,
  ) {
    return TipTemplatesByInstrumentProvider(
      instrument,
    );
  }

  @override
  TipTemplatesByInstrumentProvider getProviderOverride(
    covariant TipTemplatesByInstrumentProvider provider,
  ) {
    return call(
      provider.instrument,
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
  String? get name => r'tipTemplatesByInstrumentProvider';
}

/// Templates for specific instrument (includes general tips)
///
/// Copied from [tipTemplatesByInstrument].
class TipTemplatesByInstrumentProvider
    extends FutureProvider<List<TipTemplate>> {
  /// Templates for specific instrument (includes general tips)
  ///
  /// Copied from [tipTemplatesByInstrument].
  TipTemplatesByInstrumentProvider(
    String? instrument,
  ) : this._internal(
          (ref) => tipTemplatesByInstrument(
            ref as TipTemplatesByInstrumentRef,
            instrument,
          ),
          from: tipTemplatesByInstrumentProvider,
          name: r'tipTemplatesByInstrumentProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$tipTemplatesByInstrumentHash,
          dependencies: TipTemplatesByInstrumentFamily._dependencies,
          allTransitiveDependencies:
              TipTemplatesByInstrumentFamily._allTransitiveDependencies,
          instrument: instrument,
        );

  TipTemplatesByInstrumentProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.instrument,
  }) : super.internal();

  final String? instrument;

  @override
  Override overrideWith(
    FutureOr<List<TipTemplate>> Function(TipTemplatesByInstrumentRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TipTemplatesByInstrumentProvider._internal(
        (ref) => create(ref as TipTemplatesByInstrumentRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        instrument: instrument,
      ),
    );
  }

  @override
  FutureProviderElement<List<TipTemplate>> createElement() {
    return _TipTemplatesByInstrumentProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TipTemplatesByInstrumentProvider &&
        other.instrument == instrument;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, instrument.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin TipTemplatesByInstrumentRef on FutureProviderRef<List<TipTemplate>> {
  /// The parameter `instrument` of this provider.
  String? get instrument;
}

class _TipTemplatesByInstrumentProviderElement
    extends FutureProviderElement<List<TipTemplate>>
    with TipTemplatesByInstrumentRef {
  _TipTemplatesByInstrumentProviderElement(super.provider);

  @override
  String? get instrument =>
      (origin as TipTemplatesByInstrumentProvider).instrument;
}

String _$frequentTipTemplatesHash() =>
    r'b23714e41ccfb5afb1294747200ce16be0037248';

/// Frequently used templates
///
/// Copied from [frequentTipTemplates].
@ProviderFor(frequentTipTemplates)
final frequentTipTemplatesProvider = FutureProvider<List<TipTemplate>>.internal(
  frequentTipTemplates,
  name: r'frequentTipTemplatesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$frequentTipTemplatesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef FrequentTipTemplatesRef = FutureProviderRef<List<TipTemplate>>;
String _$tipTemplateSearchHash() => r'1086b9a74f63a432db4d2814e81dd99838c39968';

/// Search templates
///
/// Copied from [tipTemplateSearch].
@ProviderFor(tipTemplateSearch)
const tipTemplateSearchProvider = TipTemplateSearchFamily();

/// Search templates
///
/// Copied from [tipTemplateSearch].
class TipTemplateSearchFamily extends Family<AsyncValue<List<TipTemplate>>> {
  /// Search templates
  ///
  /// Copied from [tipTemplateSearch].
  const TipTemplateSearchFamily();

  /// Search templates
  ///
  /// Copied from [tipTemplateSearch].
  TipTemplateSearchProvider call(
    String query,
  ) {
    return TipTemplateSearchProvider(
      query,
    );
  }

  @override
  TipTemplateSearchProvider getProviderOverride(
    covariant TipTemplateSearchProvider provider,
  ) {
    return call(
      provider.query,
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
  String? get name => r'tipTemplateSearchProvider';
}

/// Search templates
///
/// Copied from [tipTemplateSearch].
class TipTemplateSearchProvider extends FutureProvider<List<TipTemplate>> {
  /// Search templates
  ///
  /// Copied from [tipTemplateSearch].
  TipTemplateSearchProvider(
    String query,
  ) : this._internal(
          (ref) => tipTemplateSearch(
            ref as TipTemplateSearchRef,
            query,
          ),
          from: tipTemplateSearchProvider,
          name: r'tipTemplateSearchProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$tipTemplateSearchHash,
          dependencies: TipTemplateSearchFamily._dependencies,
          allTransitiveDependencies:
              TipTemplateSearchFamily._allTransitiveDependencies,
          query: query,
        );

  TipTemplateSearchProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.query,
  }) : super.internal();

  final String query;

  @override
  Override overrideWith(
    FutureOr<List<TipTemplate>> Function(TipTemplateSearchRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TipTemplateSearchProvider._internal(
        (ref) => create(ref as TipTemplateSearchRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        query: query,
      ),
    );
  }

  @override
  FutureProviderElement<List<TipTemplate>> createElement() {
    return _TipTemplateSearchProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TipTemplateSearchProvider && other.query == query;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, query.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin TipTemplateSearchRef on FutureProviderRef<List<TipTemplate>> {
  /// The parameter `query` of this provider.
  String get query;
}

class _TipTemplateSearchProviderElement
    extends FutureProviderElement<List<TipTemplate>> with TipTemplateSearchRef {
  _TipTemplateSearchProviderElement(super.provider);

  @override
  String get query => (origin as TipTemplateSearchProvider).query;
}

String _$tipTemplatesNotifierHash() =>
    r'1572d7108d8a38c4fd59004ef5a36f2717392830';

/// Notifier for CRUD operations
///
/// Copied from [TipTemplatesNotifier].
@ProviderFor(TipTemplatesNotifier)
final tipTemplatesNotifierProvider =
    AsyncNotifierProvider<TipTemplatesNotifier, List<TipTemplate>>.internal(
  TipTemplatesNotifier.new,
  name: r'tipTemplatesNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$tipTemplatesNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$TipTemplatesNotifier = AsyncNotifier<List<TipTemplate>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
