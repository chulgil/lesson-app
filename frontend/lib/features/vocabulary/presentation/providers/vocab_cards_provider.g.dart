// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vocab_cards_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$vocabCardsHash() => r'bc87aded190d676a010eaa5779d03d61f8148f51';

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

/// All cards in set [setId], oldest first (#1124).
///
/// Copied from [vocabCards].
@ProviderFor(vocabCards)
const vocabCardsProvider = VocabCardsFamily();

/// All cards in set [setId], oldest first (#1124).
///
/// Copied from [vocabCards].
class VocabCardsFamily extends Family<AsyncValue<List<VocabCard>>> {
  /// All cards in set [setId], oldest first (#1124).
  ///
  /// Copied from [vocabCards].
  const VocabCardsFamily();

  /// All cards in set [setId], oldest first (#1124).
  ///
  /// Copied from [vocabCards].
  VocabCardsProvider call(
    String setId,
  ) {
    return VocabCardsProvider(
      setId,
    );
  }

  @override
  VocabCardsProvider getProviderOverride(
    covariant VocabCardsProvider provider,
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
  String? get name => r'vocabCardsProvider';
}

/// All cards in set [setId], oldest first (#1124).
///
/// Copied from [vocabCards].
class VocabCardsProvider extends AutoDisposeFutureProvider<List<VocabCard>> {
  /// All cards in set [setId], oldest first (#1124).
  ///
  /// Copied from [vocabCards].
  VocabCardsProvider(
    String setId,
  ) : this._internal(
          (ref) => vocabCards(
            ref as VocabCardsRef,
            setId,
          ),
          from: vocabCardsProvider,
          name: r'vocabCardsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$vocabCardsHash,
          dependencies: VocabCardsFamily._dependencies,
          allTransitiveDependencies:
              VocabCardsFamily._allTransitiveDependencies,
          setId: setId,
        );

  VocabCardsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.setId,
  }) : super.internal();

  final String setId;

  @override
  Override overrideWith(
    FutureOr<List<VocabCard>> Function(VocabCardsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: VocabCardsProvider._internal(
        (ref) => create(ref as VocabCardsRef),
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
  AutoDisposeFutureProviderElement<List<VocabCard>> createElement() {
    return _VocabCardsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is VocabCardsProvider && other.setId == setId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, setId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin VocabCardsRef on AutoDisposeFutureProviderRef<List<VocabCard>> {
  /// The parameter `setId` of this provider.
  String get setId;
}

class _VocabCardsProviderElement
    extends AutoDisposeFutureProviderElement<List<VocabCard>>
    with VocabCardsRef {
  _VocabCardsProviderElement(super.provider);

  @override
  String get setId => (origin as VocabCardsProvider).setId;
}

String _$dueCardsHash() => r'71ce41ff5c22ff87b0987b158276cc3ad976cc16';

/// The due-for-review queue for a review session (#1124).
///
/// [setId] null = review across every set (the panel's global session); a
/// non-null id scopes to one set (the set page's session). Ordered by due date
/// (most overdue first) so the earliest-due cards are seen first.
///
/// Copied from [dueCards].
@ProviderFor(dueCards)
const dueCardsProvider = DueCardsFamily();

/// The due-for-review queue for a review session (#1124).
///
/// [setId] null = review across every set (the panel's global session); a
/// non-null id scopes to one set (the set page's session). Ordered by due date
/// (most overdue first) so the earliest-due cards are seen first.
///
/// Copied from [dueCards].
class DueCardsFamily extends Family<AsyncValue<List<VocabCard>>> {
  /// The due-for-review queue for a review session (#1124).
  ///
  /// [setId] null = review across every set (the panel's global session); a
  /// non-null id scopes to one set (the set page's session). Ordered by due date
  /// (most overdue first) so the earliest-due cards are seen first.
  ///
  /// Copied from [dueCards].
  const DueCardsFamily();

  /// The due-for-review queue for a review session (#1124).
  ///
  /// [setId] null = review across every set (the panel's global session); a
  /// non-null id scopes to one set (the set page's session). Ordered by due date
  /// (most overdue first) so the earliest-due cards are seen first.
  ///
  /// Copied from [dueCards].
  DueCardsProvider call(
    String? setId,
  ) {
    return DueCardsProvider(
      setId,
    );
  }

  @override
  DueCardsProvider getProviderOverride(
    covariant DueCardsProvider provider,
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
  String? get name => r'dueCardsProvider';
}

/// The due-for-review queue for a review session (#1124).
///
/// [setId] null = review across every set (the panel's global session); a
/// non-null id scopes to one set (the set page's session). Ordered by due date
/// (most overdue first) so the earliest-due cards are seen first.
///
/// Copied from [dueCards].
class DueCardsProvider extends AutoDisposeFutureProvider<List<VocabCard>> {
  /// The due-for-review queue for a review session (#1124).
  ///
  /// [setId] null = review across every set (the panel's global session); a
  /// non-null id scopes to one set (the set page's session). Ordered by due date
  /// (most overdue first) so the earliest-due cards are seen first.
  ///
  /// Copied from [dueCards].
  DueCardsProvider(
    String? setId,
  ) : this._internal(
          (ref) => dueCards(
            ref as DueCardsRef,
            setId,
          ),
          from: dueCardsProvider,
          name: r'dueCardsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$dueCardsHash,
          dependencies: DueCardsFamily._dependencies,
          allTransitiveDependencies: DueCardsFamily._allTransitiveDependencies,
          setId: setId,
        );

  DueCardsProvider._internal(
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
  Override overrideWith(
    FutureOr<List<VocabCard>> Function(DueCardsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: DueCardsProvider._internal(
        (ref) => create(ref as DueCardsRef),
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
  AutoDisposeFutureProviderElement<List<VocabCard>> createElement() {
    return _DueCardsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DueCardsProvider && other.setId == setId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, setId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin DueCardsRef on AutoDisposeFutureProviderRef<List<VocabCard>> {
  /// The parameter `setId` of this provider.
  String? get setId;
}

class _DueCardsProviderElement
    extends AutoDisposeFutureProviderElement<List<VocabCard>> with DueCardsRef {
  _DueCardsProviderElement(super.provider);

  @override
  String? get setId => (origin as DueCardsProvider).setId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
