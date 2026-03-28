// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recording_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$recordingRepositoryHash() =>
    r'425d8abb6bd46886426fe3d089aec789c54cbf60';

/// Provider for recording repository - switches between Hive (local) and Remote.
///
/// Copied from [recordingRepository].
@ProviderFor(recordingRepository)
final recordingRepositoryProvider = Provider<RecordingRepository>.internal(
  recordingRepository,
  name: r'recordingRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$recordingRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef RecordingRepositoryRef = ProviderRef<RecordingRepository>;
String _$audioRecorderServiceHash() =>
    r'3ff32787ba080237c937f9de520e986b5cf8f1c4';

/// Provider for audio recorder service.
///
/// Copied from [audioRecorderService].
@ProviderFor(audioRecorderService)
final audioRecorderServiceProvider = Provider<AudioRecorderService>.internal(
  audioRecorderService,
  name: r'audioRecorderServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$audioRecorderServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AudioRecorderServiceRef = ProviderRef<AudioRecorderService>;
String _$audioPlayerServiceHash() =>
    r'101d77a30e3547cf864a612adddb0a444f6b87bc';

/// Provider for audio player service.
///
/// Copied from [audioPlayerService].
@ProviderFor(audioPlayerService)
final audioPlayerServiceProvider = Provider<AudioPlayerService>.internal(
  audioPlayerService,
  name: r'audioPlayerServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$audioPlayerServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AudioPlayerServiceRef = ProviderRef<AudioPlayerService>;
String _$microphonePermissionHash() =>
    r'a0c112647a854774ec00b20723d99bb029abd309';

/// Provider for checking microphone permission status.
///
/// Copied from [microphonePermission].
@ProviderFor(microphonePermission)
final microphonePermissionProvider = AutoDisposeFutureProvider<bool>.internal(
  microphonePermission,
  name: r'microphonePermissionProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$microphonePermissionHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef MicrophonePermissionRef = AutoDisposeFutureProviderRef<bool>;
String _$recordingNotifierHash() => r'1fb08fa49cba9e8d6623057f3637e27df60de6e0';

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

abstract class _$RecordingNotifier
    extends BuildlessAutoDisposeNotifier<RecordingState> {
  late final String repertoireId;
  late final String studentId;

  RecordingState build(
    String repertoireId,
    String studentId,
  );
}

/// Main recording provider for a repertoire.
///
/// Copied from [RecordingNotifier].
@ProviderFor(RecordingNotifier)
const recordingNotifierProvider = RecordingNotifierFamily();

/// Main recording provider for a repertoire.
///
/// Copied from [RecordingNotifier].
class RecordingNotifierFamily extends Family<RecordingState> {
  /// Main recording provider for a repertoire.
  ///
  /// Copied from [RecordingNotifier].
  const RecordingNotifierFamily();

  /// Main recording provider for a repertoire.
  ///
  /// Copied from [RecordingNotifier].
  RecordingNotifierProvider call(
    String repertoireId,
    String studentId,
  ) {
    return RecordingNotifierProvider(
      repertoireId,
      studentId,
    );
  }

  @override
  RecordingNotifierProvider getProviderOverride(
    covariant RecordingNotifierProvider provider,
  ) {
    return call(
      provider.repertoireId,
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
  String? get name => r'recordingNotifierProvider';
}

/// Main recording provider for a repertoire.
///
/// Copied from [RecordingNotifier].
class RecordingNotifierProvider
    extends AutoDisposeNotifierProviderImpl<RecordingNotifier, RecordingState> {
  /// Main recording provider for a repertoire.
  ///
  /// Copied from [RecordingNotifier].
  RecordingNotifierProvider(
    String repertoireId,
    String studentId,
  ) : this._internal(
          () => RecordingNotifier()
            ..repertoireId = repertoireId
            ..studentId = studentId,
          from: recordingNotifierProvider,
          name: r'recordingNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$recordingNotifierHash,
          dependencies: RecordingNotifierFamily._dependencies,
          allTransitiveDependencies:
              RecordingNotifierFamily._allTransitiveDependencies,
          repertoireId: repertoireId,
          studentId: studentId,
        );

  RecordingNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.repertoireId,
    required this.studentId,
  }) : super.internal();

  final String repertoireId;
  final String studentId;

  @override
  RecordingState runNotifierBuild(
    covariant RecordingNotifier notifier,
  ) {
    return notifier.build(
      repertoireId,
      studentId,
    );
  }

  @override
  Override overrideWith(RecordingNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: RecordingNotifierProvider._internal(
        () => create()
          ..repertoireId = repertoireId
          ..studentId = studentId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        repertoireId: repertoireId,
        studentId: studentId,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<RecordingNotifier, RecordingState>
      createElement() {
    return _RecordingNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RecordingNotifierProvider &&
        other.repertoireId == repertoireId &&
        other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, repertoireId.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin RecordingNotifierRef on AutoDisposeNotifierProviderRef<RecordingState> {
  /// The parameter `repertoireId` of this provider.
  String get repertoireId;

  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _RecordingNotifierProviderElement
    extends AutoDisposeNotifierProviderElement<RecordingNotifier,
        RecordingState> with RecordingNotifierRef {
  _RecordingNotifierProviderElement(super.provider);

  @override
  String get repertoireId => (origin as RecordingNotifierProvider).repertoireId;
  @override
  String get studentId => (origin as RecordingNotifierProvider).studentId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
