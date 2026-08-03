// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_session_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$reviewSessionHash() => r'dea65e16ca979c236466dfb57df4f9e231cf7eda';

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

abstract class _$ReviewSession
    extends BuildlessAutoDisposeAsyncNotifier<ReviewSessionState> {
  late final String? setId;

  FutureOr<ReviewSessionState> build(
    String? setId,
  );
}

/// Drives a flashcard review session (#1124).
///
/// [setId] null = review across every set (the panel's global session); a
/// non-null id scopes to one set. The due queue is read **once** at [build] (a
/// snapshot, not a live watch), so persisting each grade never resets the
/// session. On the final grade it refreshes the library's due counts.
///
/// Copied from [ReviewSession].
@ProviderFor(ReviewSession)
const reviewSessionProvider = ReviewSessionFamily();

/// Drives a flashcard review session (#1124).
///
/// [setId] null = review across every set (the panel's global session); a
/// non-null id scopes to one set. The due queue is read **once** at [build] (a
/// snapshot, not a live watch), so persisting each grade never resets the
/// session. On the final grade it refreshes the library's due counts.
///
/// Copied from [ReviewSession].
class ReviewSessionFamily extends Family<AsyncValue<ReviewSessionState>> {
  /// Drives a flashcard review session (#1124).
  ///
  /// [setId] null = review across every set (the panel's global session); a
  /// non-null id scopes to one set. The due queue is read **once** at [build] (a
  /// snapshot, not a live watch), so persisting each grade never resets the
  /// session. On the final grade it refreshes the library's due counts.
  ///
  /// Copied from [ReviewSession].
  const ReviewSessionFamily();

  /// Drives a flashcard review session (#1124).
  ///
  /// [setId] null = review across every set (the panel's global session); a
  /// non-null id scopes to one set. The due queue is read **once** at [build] (a
  /// snapshot, not a live watch), so persisting each grade never resets the
  /// session. On the final grade it refreshes the library's due counts.
  ///
  /// Copied from [ReviewSession].
  ReviewSessionProvider call(
    String? setId,
  ) {
    return ReviewSessionProvider(
      setId,
    );
  }

  @override
  ReviewSessionProvider getProviderOverride(
    covariant ReviewSessionProvider provider,
  ) {
    return call(
      provider.setId,
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
  String? get name => r'reviewSessionProvider';
}

/// Drives a flashcard review session (#1124).
///
/// [setId] null = review across every set (the panel's global session); a
/// non-null id scopes to one set. The due queue is read **once** at [build] (a
/// snapshot, not a live watch), so persisting each grade never resets the
/// session. On the final grade it refreshes the library's due counts.
///
/// Copied from [ReviewSession].
class ReviewSessionProvider extends AutoDisposeAsyncNotifierProviderImpl<
    ReviewSession, ReviewSessionState> {
  /// Drives a flashcard review session (#1124).
  ///
  /// [setId] null = review across every set (the panel's global session); a
  /// non-null id scopes to one set. The due queue is read **once** at [build] (a
  /// snapshot, not a live watch), so persisting each grade never resets the
  /// session. On the final grade it refreshes the library's due counts.
  ///
  /// Copied from [ReviewSession].
  ReviewSessionProvider(
    String? setId,
  ) : this._internal(
          () => ReviewSession()..setId = setId,
          from: reviewSessionProvider,
          name: r'reviewSessionProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$reviewSessionHash,
          dependencies: ReviewSessionFamily._dependencies,
          allTransitiveDependencies:
              ReviewSessionFamily._allTransitiveDependencies,
          setId: setId,
        );

  ReviewSessionProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.setId,
  }) : super.internal();

  final String? setId;

  @override
  FutureOr<ReviewSessionState> runNotifierBuild(
    covariant ReviewSession notifier,
  ) {
    return notifier.build(
      setId,
    );
  }

  @override
  Override overrideWith(ReviewSession Function() create) {
    return ProviderOverride(
      origin: this,
      override: ReviewSessionProvider._internal(
        () => create()..setId = setId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        setId: setId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<ReviewSession, ReviewSessionState>
      createElement() {
    return _ReviewSessionProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ReviewSessionProvider && other.setId == setId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, setId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin ReviewSessionRef
    on AutoDisposeAsyncNotifierProviderRef<ReviewSessionState> {
  /// The parameter `setId` of this provider.
  String? get setId;
}

class _ReviewSessionProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<ReviewSession,
        ReviewSessionState> with ReviewSessionRef {
  _ReviewSessionProviderElement(super.provider);

  @override
  String? get setId => (origin as ReviewSessionProvider).setId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
