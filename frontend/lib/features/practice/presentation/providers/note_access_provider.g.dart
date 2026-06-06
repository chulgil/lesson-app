// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note_access_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$noteAccessRepositoryHash() =>
    r'803307a78cfb87adde19de87aa0804fedb30d869';

/// Note access repository provider - switches between Mock and Remote
///
/// Copied from [noteAccessRepository].
@ProviderFor(noteAccessRepository)
final noteAccessRepositoryProvider = Provider<NoteAccessRepository>.internal(
  noteAccessRepository,
  name: r'noteAccessRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$noteAccessRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef NoteAccessRepositoryRef = ProviderRef<NoteAccessRepository>;
String _$activeNoteAccessHash() => r'48d6527f796938dbbe03def393ffb2f46a829a0e';

/// Get the current active note access (banner display)
///
/// Copied from [activeNoteAccess].
@ProviderFor(activeNoteAccess)
final activeNoteAccessProvider =
    AutoDisposeFutureProvider<NoteAccessRequest?>.internal(
  activeNoteAccess,
  name: r'activeNoteAccessProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$activeNoteAccessHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ActiveNoteAccessRef = AutoDisposeFutureProviderRef<NoteAccessRequest?>;
String _$allNoteAccessRequestsHash() =>
    r'daa727463242bf760feea2cff3979969f64816bc';

/// Get all note access requests (for history/management)
///
/// Copied from [allNoteAccessRequests].
@ProviderFor(allNoteAccessRequests)
final allNoteAccessRequestsProvider =
    AutoDisposeFutureProvider<List<NoteAccessRequest>>.internal(
  allNoteAccessRequests,
  name: r'allNoteAccessRequestsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$allNoteAccessRequestsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AllNoteAccessRequestsRef
    = AutoDisposeFutureProviderRef<List<NoteAccessRequest>>;
String _$noteAccessRequestHash() => r'1de226c9a3bd5a02d10e4bb7f2766609879d4c27';

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

/// Get a specific request by ID
///
/// Copied from [noteAccessRequest].
@ProviderFor(noteAccessRequest)
const noteAccessRequestProvider = NoteAccessRequestFamily();

/// Get a specific request by ID
///
/// Copied from [noteAccessRequest].
class NoteAccessRequestFamily extends Family<AsyncValue<NoteAccessRequest?>> {
  /// Get a specific request by ID
  ///
  /// Copied from [noteAccessRequest].
  const NoteAccessRequestFamily();

  /// Get a specific request by ID
  ///
  /// Copied from [noteAccessRequest].
  NoteAccessRequestProvider call(
    String requestId,
  ) {
    return NoteAccessRequestProvider(
      requestId,
    );
  }

  @override
  NoteAccessRequestProvider getProviderOverride(
    covariant NoteAccessRequestProvider provider,
  ) {
    return call(
      provider.requestId,
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
  String? get name => r'noteAccessRequestProvider';
}

/// Get a specific request by ID
///
/// Copied from [noteAccessRequest].
class NoteAccessRequestProvider
    extends AutoDisposeFutureProvider<NoteAccessRequest?> {
  /// Get a specific request by ID
  ///
  /// Copied from [noteAccessRequest].
  NoteAccessRequestProvider(
    String requestId,
  ) : this._internal(
          (ref) => noteAccessRequest(
            ref as NoteAccessRequestRef,
            requestId,
          ),
          from: noteAccessRequestProvider,
          name: r'noteAccessRequestProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$noteAccessRequestHash,
          dependencies: NoteAccessRequestFamily._dependencies,
          allTransitiveDependencies:
              NoteAccessRequestFamily._allTransitiveDependencies,
          requestId: requestId,
        );

  NoteAccessRequestProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.requestId,
  }) : super.internal();

  final String requestId;

  @override
  Override overrideWith(
    FutureOr<NoteAccessRequest?> Function(NoteAccessRequestRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: NoteAccessRequestProvider._internal(
        (ref) => create(ref as NoteAccessRequestRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        requestId: requestId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<NoteAccessRequest?> createElement() {
    return _NoteAccessRequestProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is NoteAccessRequestProvider && other.requestId == requestId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, requestId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin NoteAccessRequestRef on AutoDisposeFutureProviderRef<NoteAccessRequest?> {
  /// The parameter `requestId` of this provider.
  String get requestId;
}

class _NoteAccessRequestProviderElement
    extends AutoDisposeFutureProviderElement<NoteAccessRequest?>
    with NoteAccessRequestRef {
  _NoteAccessRequestProviderElement(super.provider);

  @override
  String get requestId => (origin as NoteAccessRequestProvider).requestId;
}

String _$noteAccessActionsHash() => r'36df1c97428c1b5d47c060ec8bc4e5dd806ad1a6';

/// State notifier for managing note access actions
///
/// Copied from [NoteAccessActions].
@ProviderFor(NoteAccessActions)
final noteAccessActionsProvider =
    AsyncNotifierProvider<NoteAccessActions, void>.internal(
  NoteAccessActions.new,
  name: r'noteAccessActionsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$noteAccessActionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$NoteAccessActions = AsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
