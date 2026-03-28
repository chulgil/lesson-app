// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_notes_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$aiNotesServiceHash() => r'816e62043e0bc7dabd907515238baf7c300c1260';

/// Provider for AiNotesService.
///
/// Copied from [aiNotesService].
@ProviderFor(aiNotesService)
final aiNotesServiceProvider = AutoDisposeProvider<AiNotesService>.internal(
  aiNotesService,
  name: r'aiNotesServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$aiNotesServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AiNotesServiceRef = AutoDisposeProviderRef<AiNotesService>;
String _$aiNoteGeneratorHash() => r'7f269235f3884a373bc65301dab7a6a0f72295c4';

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

abstract class _$AiNoteGenerator extends BuildlessAutoDisposeNotifier<
    ({AiNoteStatus status, AiNoteResult? result, String? error})> {
  late final String lessonId;

  ({AiNoteStatus status, AiNoteResult? result, String? error}) build(
    String lessonId,
  );
}

/// Notifier that manages the AI note generation lifecycle.
///
/// Copied from [AiNoteGenerator].
@ProviderFor(AiNoteGenerator)
const aiNoteGeneratorProvider = AiNoteGeneratorFamily();

/// Notifier that manages the AI note generation lifecycle.
///
/// Copied from [AiNoteGenerator].
class AiNoteGeneratorFamily extends Family<
    ({AiNoteStatus status, AiNoteResult? result, String? error})> {
  /// Notifier that manages the AI note generation lifecycle.
  ///
  /// Copied from [AiNoteGenerator].
  const AiNoteGeneratorFamily();

  /// Notifier that manages the AI note generation lifecycle.
  ///
  /// Copied from [AiNoteGenerator].
  AiNoteGeneratorProvider call(
    String lessonId,
  ) {
    return AiNoteGeneratorProvider(
      lessonId,
    );
  }

  @override
  AiNoteGeneratorProvider getProviderOverride(
    covariant AiNoteGeneratorProvider provider,
  ) {
    return call(
      provider.lessonId,
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
  String? get name => r'aiNoteGeneratorProvider';
}

/// Notifier that manages the AI note generation lifecycle.
///
/// Copied from [AiNoteGenerator].
class AiNoteGeneratorProvider extends AutoDisposeNotifierProviderImpl<
    AiNoteGenerator,
    ({AiNoteStatus status, AiNoteResult? result, String? error})> {
  /// Notifier that manages the AI note generation lifecycle.
  ///
  /// Copied from [AiNoteGenerator].
  AiNoteGeneratorProvider(
    String lessonId,
  ) : this._internal(
          () => AiNoteGenerator()..lessonId = lessonId,
          from: aiNoteGeneratorProvider,
          name: r'aiNoteGeneratorProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$aiNoteGeneratorHash,
          dependencies: AiNoteGeneratorFamily._dependencies,
          allTransitiveDependencies:
              AiNoteGeneratorFamily._allTransitiveDependencies,
          lessonId: lessonId,
        );

  AiNoteGeneratorProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.lessonId,
  }) : super.internal();

  final String lessonId;

  @override
  ({AiNoteStatus status, AiNoteResult? result, String? error}) runNotifierBuild(
    covariant AiNoteGenerator notifier,
  ) {
    return notifier.build(
      lessonId,
    );
  }

  @override
  Override overrideWith(AiNoteGenerator Function() create) {
    return ProviderOverride(
      origin: this,
      override: AiNoteGeneratorProvider._internal(
        () => create()..lessonId = lessonId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        lessonId: lessonId,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<AiNoteGenerator,
          ({AiNoteStatus status, AiNoteResult? result, String? error})>
      createElement() {
    return _AiNoteGeneratorProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AiNoteGeneratorProvider && other.lessonId == lessonId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, lessonId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin AiNoteGeneratorRef on AutoDisposeNotifierProviderRef<
    ({AiNoteStatus status, AiNoteResult? result, String? error})> {
  /// The parameter `lessonId` of this provider.
  String get lessonId;
}

class _AiNoteGeneratorProviderElement
    extends AutoDisposeNotifierProviderElement<AiNoteGenerator,
        ({AiNoteStatus status, AiNoteResult? result, String? error})>
    with AiNoteGeneratorRef {
  _AiNoteGeneratorProviderElement(super.provider);

  @override
  String get lessonId => (origin as AiNoteGeneratorProvider).lessonId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
