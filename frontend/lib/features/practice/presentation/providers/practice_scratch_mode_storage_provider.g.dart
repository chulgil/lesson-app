// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'practice_scratch_mode_storage_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$practiceScratchModeStorageHash() =>
    r'0aaee0191c874449346e864cd656e3cc4c5d9cb7';

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

abstract class _$PracticeScratchModeStorage
    extends BuildlessAsyncNotifier<bool> {
  late final String studentId;

  FutureOr<bool> build(
    String studentId,
  );
}

/// Per-user preference for the practice repeat-count stamp interaction
/// (`ScratchStampSheet`, P1 daily-satisfaction gamification).
///
/// When enabled ("빠른 체크 모드"), tapping an empty practice-repeat slot
/// increments the count immediately without opening the scratch popup.
/// Default is disabled — the founder's vision is the tactile
/// scratch-to-color ritual; quick-check is an opt-in escape hatch for
/// students who find the ritual tedious.
///
/// Keys follow the user-scoped convention so multiple students on the same
/// device do not share this preference.
///
/// Copied from [PracticeScratchModeStorage].
@ProviderFor(PracticeScratchModeStorage)
const practiceScratchModeStorageProvider = PracticeScratchModeStorageFamily();

/// Per-user preference for the practice repeat-count stamp interaction
/// (`ScratchStampSheet`, P1 daily-satisfaction gamification).
///
/// When enabled ("빠른 체크 모드"), tapping an empty practice-repeat slot
/// increments the count immediately without opening the scratch popup.
/// Default is disabled — the founder's vision is the tactile
/// scratch-to-color ritual; quick-check is an opt-in escape hatch for
/// students who find the ritual tedious.
///
/// Keys follow the user-scoped convention so multiple students on the same
/// device do not share this preference.
///
/// Copied from [PracticeScratchModeStorage].
class PracticeScratchModeStorageFamily extends Family<AsyncValue<bool>> {
  /// Per-user preference for the practice repeat-count stamp interaction
  /// (`ScratchStampSheet`, P1 daily-satisfaction gamification).
  ///
  /// When enabled ("빠른 체크 모드"), tapping an empty practice-repeat slot
  /// increments the count immediately without opening the scratch popup.
  /// Default is disabled — the founder's vision is the tactile
  /// scratch-to-color ritual; quick-check is an opt-in escape hatch for
  /// students who find the ritual tedious.
  ///
  /// Keys follow the user-scoped convention so multiple students on the same
  /// device do not share this preference.
  ///
  /// Copied from [PracticeScratchModeStorage].
  const PracticeScratchModeStorageFamily();

  /// Per-user preference for the practice repeat-count stamp interaction
  /// (`ScratchStampSheet`, P1 daily-satisfaction gamification).
  ///
  /// When enabled ("빠른 체크 모드"), tapping an empty practice-repeat slot
  /// increments the count immediately without opening the scratch popup.
  /// Default is disabled — the founder's vision is the tactile
  /// scratch-to-color ritual; quick-check is an opt-in escape hatch for
  /// students who find the ritual tedious.
  ///
  /// Keys follow the user-scoped convention so multiple students on the same
  /// device do not share this preference.
  ///
  /// Copied from [PracticeScratchModeStorage].
  PracticeScratchModeStorageProvider call(
    String studentId,
  ) {
    return PracticeScratchModeStorageProvider(
      studentId,
    );
  }

  @override
  PracticeScratchModeStorageProvider getProviderOverride(
    covariant PracticeScratchModeStorageProvider provider,
  ) {
    return call(
      provider.studentId,
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
  String? get name => r'practiceScratchModeStorageProvider';
}

/// Per-user preference for the practice repeat-count stamp interaction
/// (`ScratchStampSheet`, P1 daily-satisfaction gamification).
///
/// When enabled ("빠른 체크 모드"), tapping an empty practice-repeat slot
/// increments the count immediately without opening the scratch popup.
/// Default is disabled — the founder's vision is the tactile
/// scratch-to-color ritual; quick-check is an opt-in escape hatch for
/// students who find the ritual tedious.
///
/// Keys follow the user-scoped convention so multiple students on the same
/// device do not share this preference.
///
/// Copied from [PracticeScratchModeStorage].
class PracticeScratchModeStorageProvider
    extends AsyncNotifierProviderImpl<PracticeScratchModeStorage, bool> {
  /// Per-user preference for the practice repeat-count stamp interaction
  /// (`ScratchStampSheet`, P1 daily-satisfaction gamification).
  ///
  /// When enabled ("빠른 체크 모드"), tapping an empty practice-repeat slot
  /// increments the count immediately without opening the scratch popup.
  /// Default is disabled — the founder's vision is the tactile
  /// scratch-to-color ritual; quick-check is an opt-in escape hatch for
  /// students who find the ritual tedious.
  ///
  /// Keys follow the user-scoped convention so multiple students on the same
  /// device do not share this preference.
  ///
  /// Copied from [PracticeScratchModeStorage].
  PracticeScratchModeStorageProvider(
    String studentId,
  ) : this._internal(
          () => PracticeScratchModeStorage()..studentId = studentId,
          from: practiceScratchModeStorageProvider,
          name: r'practiceScratchModeStorageProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$practiceScratchModeStorageHash,
          dependencies: PracticeScratchModeStorageFamily._dependencies,
          allTransitiveDependencies:
              PracticeScratchModeStorageFamily._allTransitiveDependencies,
          studentId: studentId,
        );

  PracticeScratchModeStorageProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.studentId,
  }) : super.internal();

  final String studentId;

  @override
  FutureOr<bool> runNotifierBuild(
    covariant PracticeScratchModeStorage notifier,
  ) {
    return notifier.build(
      studentId,
    );
  }

  @override
  Override overrideWith(PracticeScratchModeStorage Function() create) {
    return ProviderOverride(
      origin: this,
      override: PracticeScratchModeStorageProvider._internal(
        () => create()..studentId = studentId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        studentId: studentId,
      ),
    );
  }

  @override
  AsyncNotifierProviderElement<PracticeScratchModeStorage, bool>
      createElement() {
    return _PracticeScratchModeStorageProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PracticeScratchModeStorageProvider &&
        other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin PracticeScratchModeStorageRef on AsyncNotifierProviderRef<bool> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _PracticeScratchModeStorageProviderElement
    extends AsyncNotifierProviderElement<PracticeScratchModeStorage, bool>
    with PracticeScratchModeStorageRef {
  _PracticeScratchModeStorageProviderElement(super.provider);

  @override
  String get studentId =>
      (origin as PracticeScratchModeStorageProvider).studentId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
