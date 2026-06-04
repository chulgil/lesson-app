// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feedback_template_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$feedbackTemplateRepositoryHash() =>
    r'23e04ab6e39d2d8b5381b290a386c42364b016a9';

/// Repository provider — singleton mock for now.
///
/// Copied from [feedbackTemplateRepository].
@ProviderFor(feedbackTemplateRepository)
final feedbackTemplateRepositoryProvider =
    Provider<FeedbackTemplateRepository>.internal(
  feedbackTemplateRepository,
  name: r'feedbackTemplateRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$feedbackTemplateRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef FeedbackTemplateRepositoryRef = ProviderRef<FeedbackTemplateRepository>;
String _$currentTeacherIdHash() => r'197a10e6bca401eb00d313b721e64665ed93e49c';

/// See also [_currentTeacherId].
@ProviderFor(_currentTeacherId)
final _currentTeacherIdProvider = Provider<String>.internal(
  _currentTeacherId,
  name: r'_currentTeacherIdProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentTeacherIdHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _CurrentTeacherIdRef = ProviderRef<String>;
String _$feedbackTemplatesHash() => r'4a4c585a529b44ef5a55ca641aaa3de7e3108ef7';

/// All templates owned by the current teacher.
///
/// Copied from [feedbackTemplates].
@ProviderFor(feedbackTemplates)
final feedbackTemplatesProvider =
    FutureProvider<List<FeedbackTemplate>>.internal(
  feedbackTemplates,
  name: r'feedbackTemplatesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$feedbackTemplatesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef FeedbackTemplatesRef = FutureProviderRef<List<FeedbackTemplate>>;
String _$feedbackTemplatesByCategoryHash() =>
    r'09b09593551e8b1e50a8cadfd51fab00216cbb4f';

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

/// Templates filtered by category.
///
/// Copied from [feedbackTemplatesByCategory].
@ProviderFor(feedbackTemplatesByCategory)
const feedbackTemplatesByCategoryProvider = FeedbackTemplatesByCategoryFamily();

/// Templates filtered by category.
///
/// Copied from [feedbackTemplatesByCategory].
class FeedbackTemplatesByCategoryFamily
    extends Family<AsyncValue<List<FeedbackTemplate>>> {
  /// Templates filtered by category.
  ///
  /// Copied from [feedbackTemplatesByCategory].
  const FeedbackTemplatesByCategoryFamily();

  /// Templates filtered by category.
  ///
  /// Copied from [feedbackTemplatesByCategory].
  FeedbackTemplatesByCategoryProvider call(
    FeedbackCategory category,
  ) {
    return FeedbackTemplatesByCategoryProvider(
      category,
    );
  }

  @override
  FeedbackTemplatesByCategoryProvider getProviderOverride(
    covariant FeedbackTemplatesByCategoryProvider provider,
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
  String? get name => r'feedbackTemplatesByCategoryProvider';
}

/// Templates filtered by category.
///
/// Copied from [feedbackTemplatesByCategory].
class FeedbackTemplatesByCategoryProvider
    extends FutureProvider<List<FeedbackTemplate>> {
  /// Templates filtered by category.
  ///
  /// Copied from [feedbackTemplatesByCategory].
  FeedbackTemplatesByCategoryProvider(
    FeedbackCategory category,
  ) : this._internal(
          (ref) => feedbackTemplatesByCategory(
            ref as FeedbackTemplatesByCategoryRef,
            category,
          ),
          from: feedbackTemplatesByCategoryProvider,
          name: r'feedbackTemplatesByCategoryProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$feedbackTemplatesByCategoryHash,
          dependencies: FeedbackTemplatesByCategoryFamily._dependencies,
          allTransitiveDependencies:
              FeedbackTemplatesByCategoryFamily._allTransitiveDependencies,
          category: category,
        );

  FeedbackTemplatesByCategoryProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.category,
  }) : super.internal();

  final FeedbackCategory category;

  @override
  Override overrideWith(
    FutureOr<List<FeedbackTemplate>> Function(
            FeedbackTemplatesByCategoryRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: FeedbackTemplatesByCategoryProvider._internal(
        (ref) => create(ref as FeedbackTemplatesByCategoryRef),
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
  FutureProviderElement<List<FeedbackTemplate>> createElement() {
    return _FeedbackTemplatesByCategoryProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FeedbackTemplatesByCategoryProvider &&
        other.category == category;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, category.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin FeedbackTemplatesByCategoryRef
    on FutureProviderRef<List<FeedbackTemplate>> {
  /// The parameter `category` of this provider.
  FeedbackCategory get category;
}

class _FeedbackTemplatesByCategoryProviderElement
    extends FutureProviderElement<List<FeedbackTemplate>>
    with FeedbackTemplatesByCategoryRef {
  _FeedbackTemplatesByCategoryProviderElement(super.provider);

  @override
  FeedbackCategory get category =>
      (origin as FeedbackTemplatesByCategoryProvider).category;
}

String _$frequentFeedbackTemplatesHash() =>
    r'd699b06790605b658f02e79d875c2b622c5a7b4a';

/// Top-N most-used templates (for the picker's "자주 사용" section).
///
/// Copied from [frequentFeedbackTemplates].
@ProviderFor(frequentFeedbackTemplates)
final frequentFeedbackTemplatesProvider =
    FutureProvider<List<FeedbackTemplate>>.internal(
  frequentFeedbackTemplates,
  name: r'frequentFeedbackTemplatesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$frequentFeedbackTemplatesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef FrequentFeedbackTemplatesRef
    = FutureProviderRef<List<FeedbackTemplate>>;
String _$feedbackTemplateSearchHash() =>
    r'5fee31d3fd6654c5de8c48e09e91272b3fee177e';

/// Search by title/body/tags.
///
/// Copied from [feedbackTemplateSearch].
@ProviderFor(feedbackTemplateSearch)
const feedbackTemplateSearchProvider = FeedbackTemplateSearchFamily();

/// Search by title/body/tags.
///
/// Copied from [feedbackTemplateSearch].
class FeedbackTemplateSearchFamily
    extends Family<AsyncValue<List<FeedbackTemplate>>> {
  /// Search by title/body/tags.
  ///
  /// Copied from [feedbackTemplateSearch].
  const FeedbackTemplateSearchFamily();

  /// Search by title/body/tags.
  ///
  /// Copied from [feedbackTemplateSearch].
  FeedbackTemplateSearchProvider call(
    String query,
  ) {
    return FeedbackTemplateSearchProvider(
      query,
    );
  }

  @override
  FeedbackTemplateSearchProvider getProviderOverride(
    covariant FeedbackTemplateSearchProvider provider,
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
  String? get name => r'feedbackTemplateSearchProvider';
}

/// Search by title/body/tags.
///
/// Copied from [feedbackTemplateSearch].
class FeedbackTemplateSearchProvider
    extends FutureProvider<List<FeedbackTemplate>> {
  /// Search by title/body/tags.
  ///
  /// Copied from [feedbackTemplateSearch].
  FeedbackTemplateSearchProvider(
    String query,
  ) : this._internal(
          (ref) => feedbackTemplateSearch(
            ref as FeedbackTemplateSearchRef,
            query,
          ),
          from: feedbackTemplateSearchProvider,
          name: r'feedbackTemplateSearchProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$feedbackTemplateSearchHash,
          dependencies: FeedbackTemplateSearchFamily._dependencies,
          allTransitiveDependencies:
              FeedbackTemplateSearchFamily._allTransitiveDependencies,
          query: query,
        );

  FeedbackTemplateSearchProvider._internal(
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
    FutureOr<List<FeedbackTemplate>> Function(
            FeedbackTemplateSearchRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: FeedbackTemplateSearchProvider._internal(
        (ref) => create(ref as FeedbackTemplateSearchRef),
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
  FutureProviderElement<List<FeedbackTemplate>> createElement() {
    return _FeedbackTemplateSearchProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FeedbackTemplateSearchProvider && other.query == query;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, query.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin FeedbackTemplateSearchRef on FutureProviderRef<List<FeedbackTemplate>> {
  /// The parameter `query` of this provider.
  String get query;
}

class _FeedbackTemplateSearchProviderElement
    extends FutureProviderElement<List<FeedbackTemplate>>
    with FeedbackTemplateSearchRef {
  _FeedbackTemplateSearchProviderElement(super.provider);

  @override
  String get query => (origin as FeedbackTemplateSearchProvider).query;
}

String _$feedbackTemplatesNotifierHash() =>
    r'5decd8dd3ba9a2aa79d3fd4579f22c8b500cecc2';

/// CRUD notifier mirroring TipTemplatesNotifier conventions.
///
/// Copied from [FeedbackTemplatesNotifier].
@ProviderFor(FeedbackTemplatesNotifier)
final feedbackTemplatesNotifierProvider = AsyncNotifierProvider<
    FeedbackTemplatesNotifier, List<FeedbackTemplate>>.internal(
  FeedbackTemplatesNotifier.new,
  name: r'feedbackTemplatesNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$feedbackTemplatesNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$FeedbackTemplatesNotifier = AsyncNotifier<List<FeedbackTemplate>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
