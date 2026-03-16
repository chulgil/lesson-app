// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feedback_preset_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$feedbackPresetRepositoryHash() =>
    r'8be5135f996c9f7646f6e83d85759a815739a2af';

/// Repository provider for feedback presets.
///
/// Copied from [feedbackPresetRepository].
@ProviderFor(feedbackPresetRepository)
final feedbackPresetRepositoryProvider =
    Provider<FeedbackPresetRepository>.internal(
  feedbackPresetRepository,
  name: r'feedbackPresetRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$feedbackPresetRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FeedbackPresetRepositoryRef = ProviderRef<FeedbackPresetRepository>;
String _$feedbackPresetNotifierHash() =>
    r'b86004973466cde8005e482a11eebd1e587fcc25';

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

abstract class _$FeedbackPresetNotifier
    extends BuildlessAutoDisposeAsyncNotifier<List<FeedbackPreset>> {
  late final String? teacherId;

  FutureOr<List<FeedbackPreset>> build({
    String? teacherId,
  });
}

/// Provider for active feedback presets (visible, sorted).
///
/// Copied from [FeedbackPresetNotifier].
@ProviderFor(FeedbackPresetNotifier)
const feedbackPresetNotifierProvider = FeedbackPresetNotifierFamily();

/// Provider for active feedback presets (visible, sorted).
///
/// Copied from [FeedbackPresetNotifier].
class FeedbackPresetNotifierFamily
    extends Family<AsyncValue<List<FeedbackPreset>>> {
  /// Provider for active feedback presets (visible, sorted).
  ///
  /// Copied from [FeedbackPresetNotifier].
  const FeedbackPresetNotifierFamily();

  /// Provider for active feedback presets (visible, sorted).
  ///
  /// Copied from [FeedbackPresetNotifier].
  FeedbackPresetNotifierProvider call({
    String? teacherId,
  }) {
    return FeedbackPresetNotifierProvider(
      teacherId: teacherId,
    );
  }

  @override
  FeedbackPresetNotifierProvider getProviderOverride(
    covariant FeedbackPresetNotifierProvider provider,
  ) {
    return call(
      teacherId: provider.teacherId,
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
  String? get name => r'feedbackPresetNotifierProvider';
}

/// Provider for active feedback presets (visible, sorted).
///
/// Copied from [FeedbackPresetNotifier].
class FeedbackPresetNotifierProvider
    extends AutoDisposeAsyncNotifierProviderImpl<FeedbackPresetNotifier,
        List<FeedbackPreset>> {
  /// Provider for active feedback presets (visible, sorted).
  ///
  /// Copied from [FeedbackPresetNotifier].
  FeedbackPresetNotifierProvider({
    String? teacherId,
  }) : this._internal(
          () => FeedbackPresetNotifier()..teacherId = teacherId,
          from: feedbackPresetNotifierProvider,
          name: r'feedbackPresetNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$feedbackPresetNotifierHash,
          dependencies: FeedbackPresetNotifierFamily._dependencies,
          allTransitiveDependencies:
              FeedbackPresetNotifierFamily._allTransitiveDependencies,
          teacherId: teacherId,
        );

  FeedbackPresetNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.teacherId,
  }) : super.internal();

  final String? teacherId;

  @override
  FutureOr<List<FeedbackPreset>> runNotifierBuild(
    covariant FeedbackPresetNotifier notifier,
  ) {
    return notifier.build(
      teacherId: teacherId,
    );
  }

  @override
  Override overrideWith(FeedbackPresetNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: FeedbackPresetNotifierProvider._internal(
        () => create()..teacherId = teacherId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        teacherId: teacherId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<FeedbackPresetNotifier,
      List<FeedbackPreset>> createElement() {
    return _FeedbackPresetNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FeedbackPresetNotifierProvider &&
        other.teacherId == teacherId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, teacherId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin FeedbackPresetNotifierRef
    on AutoDisposeAsyncNotifierProviderRef<List<FeedbackPreset>> {
  /// The parameter `teacherId` of this provider.
  String? get teacherId;
}

class _FeedbackPresetNotifierProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<FeedbackPresetNotifier,
        List<FeedbackPreset>> with FeedbackPresetNotifierRef {
  _FeedbackPresetNotifierProviderElement(super.provider);

  @override
  String? get teacherId => (origin as FeedbackPresetNotifierProvider).teacherId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
