// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'youtube_search_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$youtubeSearchApiHash() => r'7d778bec5be6477e92ba2fac783b3d57bccf860d';

/// Singleton mock API instance (swap for real implementation later)
///
/// Copied from [youtubeSearchApi].
@ProviderFor(youtubeSearchApi)
final youtubeSearchApiProvider = Provider<MockYoutubeSearchApi>.internal(
  youtubeSearchApi,
  name: r'youtubeSearchApiProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$youtubeSearchApiHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef YoutubeSearchApiRef = ProviderRef<MockYoutubeSearchApi>;
String _$youtubeSearchHash() => r'50b3db82746f512ae6d407504127c14a494497c2';

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

/// Provider that executes a YouTube search for [query].
/// Returns an empty list when [query] is blank.
///
/// Copied from [youtubeSearch].
@ProviderFor(youtubeSearch)
const youtubeSearchProvider = YoutubeSearchFamily();

/// Provider that executes a YouTube search for [query].
/// Returns an empty list when [query] is blank.
///
/// Copied from [youtubeSearch].
class YoutubeSearchFamily
    extends Family<AsyncValue<List<YoutubeSearchResult>>> {
  /// Provider that executes a YouTube search for [query].
  /// Returns an empty list when [query] is blank.
  ///
  /// Copied from [youtubeSearch].
  const YoutubeSearchFamily();

  /// Provider that executes a YouTube search for [query].
  /// Returns an empty list when [query] is blank.
  ///
  /// Copied from [youtubeSearch].
  YoutubeSearchProvider call(
    String query,
  ) {
    return YoutubeSearchProvider(
      query,
    );
  }

  @override
  YoutubeSearchProvider getProviderOverride(
    covariant YoutubeSearchProvider provider,
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
  String? get name => r'youtubeSearchProvider';
}

/// Provider that executes a YouTube search for [query].
/// Returns an empty list when [query] is blank.
///
/// Copied from [youtubeSearch].
class YoutubeSearchProvider
    extends AutoDisposeFutureProvider<List<YoutubeSearchResult>> {
  /// Provider that executes a YouTube search for [query].
  /// Returns an empty list when [query] is blank.
  ///
  /// Copied from [youtubeSearch].
  YoutubeSearchProvider(
    String query,
  ) : this._internal(
          (ref) => youtubeSearch(
            ref as YoutubeSearchRef,
            query,
          ),
          from: youtubeSearchProvider,
          name: r'youtubeSearchProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$youtubeSearchHash,
          dependencies: YoutubeSearchFamily._dependencies,
          allTransitiveDependencies:
              YoutubeSearchFamily._allTransitiveDependencies,
          query: query,
        );

  YoutubeSearchProvider._internal(
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
    FutureOr<List<YoutubeSearchResult>> Function(YoutubeSearchRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: YoutubeSearchProvider._internal(
        (ref) => create(ref as YoutubeSearchRef),
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
  AutoDisposeFutureProviderElement<List<YoutubeSearchResult>> createElement() {
    return _YoutubeSearchProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is YoutubeSearchProvider && other.query == query;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, query.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin YoutubeSearchRef
    on AutoDisposeFutureProviderRef<List<YoutubeSearchResult>> {
  /// The parameter `query` of this provider.
  String get query;
}

class _YoutubeSearchProviderElement
    extends AutoDisposeFutureProviderElement<List<YoutubeSearchResult>>
    with YoutubeSearchRef {
  _YoutubeSearchProviderElement(super.provider);

  @override
  String get query => (origin as YoutubeSearchProvider).query;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
