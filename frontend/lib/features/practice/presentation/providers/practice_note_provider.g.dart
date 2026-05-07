// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'practice_note_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$practiceNoteRepositoryHash() =>
    r'fa5300beb414f464a39814b5a211a9c4b1eed8f9';

/// Practice note repository provider - switches between Mock and Remote.
///
/// Copied from [practiceNoteRepository].
@ProviderFor(practiceNoteRepository)
final practiceNoteRepositoryProvider =
    Provider<PracticeNoteRepository>.internal(
  practiceNoteRepository,
  name: r'practiceNoteRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$practiceNoteRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef PracticeNoteRepositoryRef = ProviderRef<PracticeNoteRepository>;
String _$sectionNotesHash() => r'd9587c2dbc3081d96b41efa9cb444dc786e3f67b';

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

/// Section notes provider - gets all notes for a section
///
/// Copied from [sectionNotes].
@ProviderFor(sectionNotes)
const sectionNotesProvider = SectionNotesFamily();

/// Section notes provider - gets all notes for a section
///
/// Copied from [sectionNotes].
class SectionNotesFamily extends Family<AsyncValue<List<PracticeNote>>> {
  /// Section notes provider - gets all notes for a section
  ///
  /// Copied from [sectionNotes].
  const SectionNotesFamily();

  /// Section notes provider - gets all notes for a section
  ///
  /// Copied from [sectionNotes].
  SectionNotesProvider call(
    String sectionId,
  ) {
    return SectionNotesProvider(
      sectionId,
    );
  }

  @override
  SectionNotesProvider getProviderOverride(
    covariant SectionNotesProvider provider,
  ) {
    return call(
      provider.sectionId,
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
  String? get name => r'sectionNotesProvider';
}

/// Section notes provider - gets all notes for a section
///
/// Copied from [sectionNotes].
class SectionNotesProvider extends FutureProvider<List<PracticeNote>> {
  /// Section notes provider - gets all notes for a section
  ///
  /// Copied from [sectionNotes].
  SectionNotesProvider(
    String sectionId,
  ) : this._internal(
          (ref) => sectionNotes(
            ref as SectionNotesRef,
            sectionId,
          ),
          from: sectionNotesProvider,
          name: r'sectionNotesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$sectionNotesHash,
          dependencies: SectionNotesFamily._dependencies,
          allTransitiveDependencies:
              SectionNotesFamily._allTransitiveDependencies,
          sectionId: sectionId,
        );

  SectionNotesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.sectionId,
  }) : super.internal();

  final String sectionId;

  @override
  Override overrideWith(
    FutureOr<List<PracticeNote>> Function(SectionNotesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SectionNotesProvider._internal(
        (ref) => create(ref as SectionNotesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        sectionId: sectionId,
      ),
    );
  }

  @override
  FutureProviderElement<List<PracticeNote>> createElement() {
    return _SectionNotesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SectionNotesProvider && other.sectionId == sectionId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, sectionId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin SectionNotesRef on FutureProviderRef<List<PracticeNote>> {
  /// The parameter `sectionId` of this provider.
  String get sectionId;
}

class _SectionNotesProviderElement
    extends FutureProviderElement<List<PracticeNote>> with SectionNotesRef {
  _SectionNotesProviderElement(super.provider);

  @override
  String get sectionId => (origin as SectionNotesProvider).sectionId;
}

String _$practiceNoteCrudHash() => r'2188b581b8f25287717b1121bebf679a0cee964c';

/// Practice note CRUD notifier
///
/// Copied from [PracticeNoteCrud].
@ProviderFor(PracticeNoteCrud)
final practiceNoteCrudProvider =
    AsyncNotifierProvider<PracticeNoteCrud, void>.internal(
  PracticeNoteCrud.new,
  name: r'practiceNoteCrudProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$practiceNoteCrudHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$PracticeNoteCrud = AsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
