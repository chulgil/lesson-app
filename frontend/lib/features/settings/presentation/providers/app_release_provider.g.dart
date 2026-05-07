// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_release_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$appReleaseRepositoryHash() =>
    r'6611a16f6cdc3d5628698d5211c722fad103f0cd';

/// See also [appReleaseRepository].
@ProviderFor(appReleaseRepository)
final appReleaseRepositoryProvider = Provider<AppReleaseRepository>.internal(
  appReleaseRepository,
  name: r'appReleaseRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$appReleaseRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AppReleaseRepositoryRef = ProviderRef<AppReleaseRepository>;
String _$appReleaseSnapshotHash() =>
    r'50109dc12aef882e209fd63bd04c8658e975ea90';

/// See also [appReleaseSnapshot].
@ProviderFor(appReleaseSnapshot)
final appReleaseSnapshotProvider = FutureProvider<AppReleaseSnapshot>.internal(
  appReleaseSnapshot,
  name: r'appReleaseSnapshotProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$appReleaseSnapshotHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AppReleaseSnapshotRef = FutureProviderRef<AppReleaseSnapshot>;
String _$appVersionSnapshotHash() =>
    r'63fc71d86ae29d991fb977ae158d1fb2a79f90c2';

/// See also [appVersionSnapshot].
@ProviderFor(appVersionSnapshot)
final appVersionSnapshotProvider = FutureProvider<AppVersionSnapshot>.internal(
  appVersionSnapshot,
  name: r'appVersionSnapshotProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$appVersionSnapshotHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AppVersionSnapshotRef = FutureProviderRef<AppVersionSnapshot>;
String _$appNewsFeedHash() => r'e668847f1a61552f51b26bbb6101329661815b73';

/// See also [appNewsFeed].
@ProviderFor(appNewsFeed)
final appNewsFeedProvider = FutureProvider<List<AppNewsItem>>.internal(
  appNewsFeed,
  name: r'appNewsFeedProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$appNewsFeedHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AppNewsFeedRef = FutureProviderRef<List<AppNewsItem>>;
String _$appRoadmapFeedHash() => r'fb79040b0956d152f32ef892d2ae43494f742884';

/// See also [appRoadmapFeed].
@ProviderFor(appRoadmapFeed)
final appRoadmapFeedProvider = FutureProvider<List<AppRoadmapItem>>.internal(
  appRoadmapFeed,
  name: r'appRoadmapFeedProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$appRoadmapFeedHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AppRoadmapFeedRef = FutureProviderRef<List<AppRoadmapItem>>;
String _$appReviewClientHash() => r'db62f60d95ab9fdea9af3b20d2eb4dc4e3f3e6e6';

/// See also [appReviewClient].
@ProviderFor(appReviewClient)
final appReviewClientProvider = Provider<AppReviewClient>.internal(
  appReviewClient,
  name: r'appReviewClientProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$appReviewClientHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AppReviewClientRef = ProviderRef<AppReviewClient>;
String _$reviewPromptPolicyHash() =>
    r'0e9b7caee1194d52bfac5483aaa50ce4af80a10f';

/// See also [reviewPromptPolicy].
@ProviderFor(reviewPromptPolicy)
final reviewPromptPolicyProvider = Provider<ReviewPromptPolicy>.internal(
  reviewPromptPolicy,
  name: r'reviewPromptPolicyProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$reviewPromptPolicyHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ReviewPromptPolicyRef = ProviderRef<ReviewPromptPolicy>;
String _$shouldPromptForReviewHash() =>
    r'572e321995d566761f511dae825efab0233b1528';

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

/// See also [shouldPromptForReview].
@ProviderFor(shouldPromptForReview)
const shouldPromptForReviewProvider = ShouldPromptForReviewFamily();

/// See also [shouldPromptForReview].
class ShouldPromptForReviewFamily extends Family<bool> {
  /// See also [shouldPromptForReview].
  const ShouldPromptForReviewFamily();

  /// See also [shouldPromptForReview].
  ShouldPromptForReviewProvider call(
    int completedLessonCount,
  ) {
    return ShouldPromptForReviewProvider(
      completedLessonCount,
    );
  }

  @override
  ShouldPromptForReviewProvider getProviderOverride(
    covariant ShouldPromptForReviewProvider provider,
  ) {
    return call(
      provider.completedLessonCount,
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
  String? get name => r'shouldPromptForReviewProvider';
}

/// See also [shouldPromptForReview].
class ShouldPromptForReviewProvider extends Provider<bool> {
  /// See also [shouldPromptForReview].
  ShouldPromptForReviewProvider(
    int completedLessonCount,
  ) : this._internal(
          (ref) => shouldPromptForReview(
            ref as ShouldPromptForReviewRef,
            completedLessonCount,
          ),
          from: shouldPromptForReviewProvider,
          name: r'shouldPromptForReviewProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$shouldPromptForReviewHash,
          dependencies: ShouldPromptForReviewFamily._dependencies,
          allTransitiveDependencies:
              ShouldPromptForReviewFamily._allTransitiveDependencies,
          completedLessonCount: completedLessonCount,
        );

  ShouldPromptForReviewProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.completedLessonCount,
  }) : super.internal();

  final int completedLessonCount;

  @override
  Override overrideWith(
    bool Function(ShouldPromptForReviewRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ShouldPromptForReviewProvider._internal(
        (ref) => create(ref as ShouldPromptForReviewRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        completedLessonCount: completedLessonCount,
      ),
    );
  }

  @override
  ProviderElement<bool> createElement() {
    return _ShouldPromptForReviewProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ShouldPromptForReviewProvider &&
        other.completedLessonCount == completedLessonCount;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, completedLessonCount.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin ShouldPromptForReviewRef on ProviderRef<bool> {
  /// The parameter `completedLessonCount` of this provider.
  int get completedLessonCount;
}

class _ShouldPromptForReviewProviderElement extends ProviderElement<bool>
    with ShouldPromptForReviewRef {
  _ShouldPromptForReviewProviderElement(super.provider);

  @override
  int get completedLessonCount =>
      (origin as ShouldPromptForReviewProvider).completedLessonCount;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
