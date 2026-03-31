// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pitch_analysis_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$pitchAnalysisHash() => r'aa88940ece63521ae2618b586c9adccd0eff934e';

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

/// Provides pitch analysis for a recording.
/// In mock mode, generates realistic sample data.
///
/// Copied from [pitchAnalysis].
@ProviderFor(pitchAnalysis)
const pitchAnalysisProvider = PitchAnalysisFamily();

/// Provides pitch analysis for a recording.
/// In mock mode, generates realistic sample data.
///
/// Copied from [pitchAnalysis].
class PitchAnalysisFamily extends Family<AsyncValue<PitchAnalysisResult?>> {
  /// Provides pitch analysis for a recording.
  /// In mock mode, generates realistic sample data.
  ///
  /// Copied from [pitchAnalysis].
  const PitchAnalysisFamily();

  /// Provides pitch analysis for a recording.
  /// In mock mode, generates realistic sample data.
  ///
  /// Copied from [pitchAnalysis].
  PitchAnalysisProvider call(
    String recordingId,
  ) {
    return PitchAnalysisProvider(
      recordingId,
    );
  }

  @override
  PitchAnalysisProvider getProviderOverride(
    covariant PitchAnalysisProvider provider,
  ) {
    return call(
      provider.recordingId,
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
  String? get name => r'pitchAnalysisProvider';
}

/// Provides pitch analysis for a recording.
/// In mock mode, generates realistic sample data.
///
/// Copied from [pitchAnalysis].
class PitchAnalysisProvider
    extends AutoDisposeFutureProvider<PitchAnalysisResult?> {
  /// Provides pitch analysis for a recording.
  /// In mock mode, generates realistic sample data.
  ///
  /// Copied from [pitchAnalysis].
  PitchAnalysisProvider(
    String recordingId,
  ) : this._internal(
          (ref) => pitchAnalysis(
            ref as PitchAnalysisRef,
            recordingId,
          ),
          from: pitchAnalysisProvider,
          name: r'pitchAnalysisProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$pitchAnalysisHash,
          dependencies: PitchAnalysisFamily._dependencies,
          allTransitiveDependencies:
              PitchAnalysisFamily._allTransitiveDependencies,
          recordingId: recordingId,
        );

  PitchAnalysisProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.recordingId,
  }) : super.internal();

  final String recordingId;

  @override
  Override overrideWith(
    FutureOr<PitchAnalysisResult?> Function(PitchAnalysisRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PitchAnalysisProvider._internal(
        (ref) => create(ref as PitchAnalysisRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        recordingId: recordingId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<PitchAnalysisResult?> createElement() {
    return _PitchAnalysisProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PitchAnalysisProvider && other.recordingId == recordingId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, recordingId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin PitchAnalysisRef on AutoDisposeFutureProviderRef<PitchAnalysisResult?> {
  /// The parameter `recordingId` of this provider.
  String get recordingId;
}

class _PitchAnalysisProviderElement
    extends AutoDisposeFutureProviderElement<PitchAnalysisResult?>
    with PitchAnalysisRef {
  _PitchAnalysisProviderElement(super.provider);

  @override
  String get recordingId => (origin as PitchAnalysisProvider).recordingId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
