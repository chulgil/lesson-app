// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'practice_loop_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$practiceLoopOverrideRepositoryHash() =>
    r'e12eb1a510b89a35be309abaf09f5d812867b2bb';

/// Singleton repository for student-side loop overrides.
///
/// Copied from [practiceLoopOverrideRepository].
@ProviderFor(practiceLoopOverrideRepository)
final practiceLoopOverrideRepositoryProvider =
    Provider<PracticeLoopOverrideRepository>.internal(
  practiceLoopOverrideRepository,
  name: r'practiceLoopOverrideRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$practiceLoopOverrideRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef PracticeLoopOverrideRepositoryRef
    = ProviderRef<PracticeLoopOverrideRepository>;
String _$audioRoutingServiceHash() =>
    r'7b3eb73e458c3c5f115c896615be88f9d6980dd7';

/// Singleton audio routing service (headphone detection).
///
/// Copied from [audioRoutingService].
@ProviderFor(audioRoutingService)
final audioRoutingServiceProvider = Provider<AudioRoutingService>.internal(
  audioRoutingService,
  name: r'audioRoutingServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$audioRoutingServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AudioRoutingServiceRef = ProviderRef<AudioRoutingService>;
String _$practiceAudioMixServiceHash() =>
    r'0ae68950884d28f2f15e59b355a0d571b11f75cb';

/// Singleton audio mix service (audio session translator).
///
/// Copied from [practiceAudioMixService].
@ProviderFor(practiceAudioMixService)
final practiceAudioMixServiceProvider =
    Provider<PracticeAudioMixService>.internal(
  practiceAudioMixService,
  name: r'practiceAudioMixServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$practiceAudioMixServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef PracticeAudioMixServiceRef = ProviderRef<PracticeAudioMixService>;
String _$practiceLoopOverrideNotifierHash() =>
    r'7013c3fbd236ee50db7192250504830f9de8930c';

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

abstract class _$PracticeLoopOverrideNotifier
    extends BuildlessAutoDisposeAsyncNotifier<PracticeLoopOverride> {
  late final String sectionId;

  FutureOr<PracticeLoopOverride> build(
    String sectionId,
  );
}

/// Loop override state for a specific [sectionId].
///
/// Loads the override from Hive on init, exposes mutation methods that persist
/// every change. Returns a non-null default when no override exists yet.
///
/// Copied from [PracticeLoopOverrideNotifier].
@ProviderFor(PracticeLoopOverrideNotifier)
const practiceLoopOverrideNotifierProvider =
    PracticeLoopOverrideNotifierFamily();

/// Loop override state for a specific [sectionId].
///
/// Loads the override from Hive on init, exposes mutation methods that persist
/// every change. Returns a non-null default when no override exists yet.
///
/// Copied from [PracticeLoopOverrideNotifier].
class PracticeLoopOverrideNotifierFamily
    extends Family<AsyncValue<PracticeLoopOverride>> {
  /// Loop override state for a specific [sectionId].
  ///
  /// Loads the override from Hive on init, exposes mutation methods that persist
  /// every change. Returns a non-null default when no override exists yet.
  ///
  /// Copied from [PracticeLoopOverrideNotifier].
  const PracticeLoopOverrideNotifierFamily();

  /// Loop override state for a specific [sectionId].
  ///
  /// Loads the override from Hive on init, exposes mutation methods that persist
  /// every change. Returns a non-null default when no override exists yet.
  ///
  /// Copied from [PracticeLoopOverrideNotifier].
  PracticeLoopOverrideNotifierProvider call(
    String sectionId,
  ) {
    return PracticeLoopOverrideNotifierProvider(
      sectionId,
    );
  }

  @override
  PracticeLoopOverrideNotifierProvider getProviderOverride(
    covariant PracticeLoopOverrideNotifierProvider provider,
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
  String? get name => r'practiceLoopOverrideNotifierProvider';
}

/// Loop override state for a specific [sectionId].
///
/// Loads the override from Hive on init, exposes mutation methods that persist
/// every change. Returns a non-null default when no override exists yet.
///
/// Copied from [PracticeLoopOverrideNotifier].
class PracticeLoopOverrideNotifierProvider
    extends AutoDisposeAsyncNotifierProviderImpl<PracticeLoopOverrideNotifier,
        PracticeLoopOverride> {
  /// Loop override state for a specific [sectionId].
  ///
  /// Loads the override from Hive on init, exposes mutation methods that persist
  /// every change. Returns a non-null default when no override exists yet.
  ///
  /// Copied from [PracticeLoopOverrideNotifier].
  PracticeLoopOverrideNotifierProvider(
    String sectionId,
  ) : this._internal(
          () => PracticeLoopOverrideNotifier()..sectionId = sectionId,
          from: practiceLoopOverrideNotifierProvider,
          name: r'practiceLoopOverrideNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$practiceLoopOverrideNotifierHash,
          dependencies: PracticeLoopOverrideNotifierFamily._dependencies,
          allTransitiveDependencies:
              PracticeLoopOverrideNotifierFamily._allTransitiveDependencies,
          sectionId: sectionId,
        );

  PracticeLoopOverrideNotifierProvider._internal(
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
  FutureOr<PracticeLoopOverride> runNotifierBuild(
    covariant PracticeLoopOverrideNotifier notifier,
  ) {
    return notifier.build(
      sectionId,
    );
  }

  @override
  Override overrideWith(PracticeLoopOverrideNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: PracticeLoopOverrideNotifierProvider._internal(
        () => create()..sectionId = sectionId,
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
  AutoDisposeAsyncNotifierProviderElement<PracticeLoopOverrideNotifier,
      PracticeLoopOverride> createElement() {
    return _PracticeLoopOverrideNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PracticeLoopOverrideNotifierProvider &&
        other.sectionId == sectionId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, sectionId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin PracticeLoopOverrideNotifierRef
    on AutoDisposeAsyncNotifierProviderRef<PracticeLoopOverride> {
  /// The parameter `sectionId` of this provider.
  String get sectionId;
}

class _PracticeLoopOverrideNotifierProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<
        PracticeLoopOverrideNotifier,
        PracticeLoopOverride> with PracticeLoopOverrideNotifierRef {
  _PracticeLoopOverrideNotifierProviderElement(super.provider);

  @override
  String get sectionId =>
      (origin as PracticeLoopOverrideNotifierProvider).sectionId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
