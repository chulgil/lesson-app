// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recording_feedback_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$recordingFeedbackCountHash() =>
    r'30349c7c41fd73edd1baa3a3aa0b74919f5aee3f';

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

/// Count of feedbacks for a recording (for list indicators).
///
/// Copied from [recordingFeedbackCount].
@ProviderFor(recordingFeedbackCount)
const recordingFeedbackCountProvider = RecordingFeedbackCountFamily();

/// Count of feedbacks for a recording (for list indicators).
///
/// Copied from [recordingFeedbackCount].
class RecordingFeedbackCountFamily extends Family<int> {
  /// Count of feedbacks for a recording (for list indicators).
  ///
  /// Copied from [recordingFeedbackCount].
  const RecordingFeedbackCountFamily();

  /// Count of feedbacks for a recording (for list indicators).
  ///
  /// Copied from [recordingFeedbackCount].
  RecordingFeedbackCountProvider call(
    String recordingId,
  ) {
    return RecordingFeedbackCountProvider(
      recordingId,
    );
  }

  @override
  RecordingFeedbackCountProvider getProviderOverride(
    covariant RecordingFeedbackCountProvider provider,
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
  String? get name => r'recordingFeedbackCountProvider';
}

/// Count of feedbacks for a recording (for list indicators).
///
/// Copied from [recordingFeedbackCount].
class RecordingFeedbackCountProvider extends AutoDisposeProvider<int> {
  /// Count of feedbacks for a recording (for list indicators).
  ///
  /// Copied from [recordingFeedbackCount].
  RecordingFeedbackCountProvider(
    String recordingId,
  ) : this._internal(
          (ref) => recordingFeedbackCount(
            ref as RecordingFeedbackCountRef,
            recordingId,
          ),
          from: recordingFeedbackCountProvider,
          name: r'recordingFeedbackCountProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$recordingFeedbackCountHash,
          dependencies: RecordingFeedbackCountFamily._dependencies,
          allTransitiveDependencies:
              RecordingFeedbackCountFamily._allTransitiveDependencies,
          recordingId: recordingId,
        );

  RecordingFeedbackCountProvider._internal(
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
    int Function(RecordingFeedbackCountRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: RecordingFeedbackCountProvider._internal(
        (ref) => create(ref as RecordingFeedbackCountRef),
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
  AutoDisposeProviderElement<int> createElement() {
    return _RecordingFeedbackCountProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RecordingFeedbackCountProvider &&
        other.recordingId == recordingId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, recordingId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin RecordingFeedbackCountRef on AutoDisposeProviderRef<int> {
  /// The parameter `recordingId` of this provider.
  String get recordingId;
}

class _RecordingFeedbackCountProviderElement
    extends AutoDisposeProviderElement<int> with RecordingFeedbackCountRef {
  _RecordingFeedbackCountProviderElement(super.provider);

  @override
  String get recordingId =>
      (origin as RecordingFeedbackCountProvider).recordingId;
}

String _$recordingFeedbackListHash() =>
    r'd531727dbdf6f6b1edc24fa9aafa791edbf6e38f';

abstract class _$RecordingFeedbackList
    extends BuildlessNotifier<List<RecordingFeedback>> {
  late final String recordingId;

  List<RecordingFeedback> build(
    String recordingId,
  );
}

/// Feedbacks keyed by recordingId.
///
/// Copied from [RecordingFeedbackList].
@ProviderFor(RecordingFeedbackList)
const recordingFeedbackListProvider = RecordingFeedbackListFamily();

/// Feedbacks keyed by recordingId.
///
/// Copied from [RecordingFeedbackList].
class RecordingFeedbackListFamily extends Family<List<RecordingFeedback>> {
  /// Feedbacks keyed by recordingId.
  ///
  /// Copied from [RecordingFeedbackList].
  const RecordingFeedbackListFamily();

  /// Feedbacks keyed by recordingId.
  ///
  /// Copied from [RecordingFeedbackList].
  RecordingFeedbackListProvider call(
    String recordingId,
  ) {
    return RecordingFeedbackListProvider(
      recordingId,
    );
  }

  @override
  RecordingFeedbackListProvider getProviderOverride(
    covariant RecordingFeedbackListProvider provider,
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
  String? get name => r'recordingFeedbackListProvider';
}

/// Feedbacks keyed by recordingId.
///
/// Copied from [RecordingFeedbackList].
class RecordingFeedbackListProvider extends NotifierProviderImpl<
    RecordingFeedbackList, List<RecordingFeedback>> {
  /// Feedbacks keyed by recordingId.
  ///
  /// Copied from [RecordingFeedbackList].
  RecordingFeedbackListProvider(
    String recordingId,
  ) : this._internal(
          () => RecordingFeedbackList()..recordingId = recordingId,
          from: recordingFeedbackListProvider,
          name: r'recordingFeedbackListProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$recordingFeedbackListHash,
          dependencies: RecordingFeedbackListFamily._dependencies,
          allTransitiveDependencies:
              RecordingFeedbackListFamily._allTransitiveDependencies,
          recordingId: recordingId,
        );

  RecordingFeedbackListProvider._internal(
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
  List<RecordingFeedback> runNotifierBuild(
    covariant RecordingFeedbackList notifier,
  ) {
    return notifier.build(
      recordingId,
    );
  }

  @override
  Override overrideWith(RecordingFeedbackList Function() create) {
    return ProviderOverride(
      origin: this,
      override: RecordingFeedbackListProvider._internal(
        () => create()..recordingId = recordingId,
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
  NotifierProviderElement<RecordingFeedbackList, List<RecordingFeedback>>
      createElement() {
    return _RecordingFeedbackListProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RecordingFeedbackListProvider &&
        other.recordingId == recordingId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, recordingId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin RecordingFeedbackListRef on NotifierProviderRef<List<RecordingFeedback>> {
  /// The parameter `recordingId` of this provider.
  String get recordingId;
}

class _RecordingFeedbackListProviderElement extends NotifierProviderElement<
    RecordingFeedbackList,
    List<RecordingFeedback>> with RecordingFeedbackListRef {
  _RecordingFeedbackListProviderElement(super.provider);

  @override
  String get recordingId =>
      (origin as RecordingFeedbackListProvider).recordingId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
