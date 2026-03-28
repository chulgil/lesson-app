// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repertoire_history_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$repertoireTimelineHash() =>
    r'3be74c34979bf7ab7f7ee2a4f7eac2ac34b87934';

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

/// Provides a timeline of all repertoires for a student, grouped by month
///
/// Copied from [repertoireTimeline].
@ProviderFor(repertoireTimeline)
const repertoireTimelineProvider = RepertoireTimelineFamily();

/// Provides a timeline of all repertoires for a student, grouped by month
///
/// Copied from [repertoireTimeline].
class RepertoireTimelineFamily extends Family<AsyncValue<RepertoireTimeline>> {
  /// Provides a timeline of all repertoires for a student, grouped by month
  ///
  /// Copied from [repertoireTimeline].
  const RepertoireTimelineFamily();

  /// Provides a timeline of all repertoires for a student, grouped by month
  ///
  /// Copied from [repertoireTimeline].
  RepertoireTimelineProvider call(
    String studentId,
  ) {
    return RepertoireTimelineProvider(
      studentId,
    );
  }

  @override
  RepertoireTimelineProvider getProviderOverride(
    covariant RepertoireTimelineProvider provider,
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
  String? get name => r'repertoireTimelineProvider';
}

/// Provides a timeline of all repertoires for a student, grouped by month
///
/// Copied from [repertoireTimeline].
class RepertoireTimelineProvider
    extends AutoDisposeFutureProvider<RepertoireTimeline> {
  /// Provides a timeline of all repertoires for a student, grouped by month
  ///
  /// Copied from [repertoireTimeline].
  RepertoireTimelineProvider(
    String studentId,
  ) : this._internal(
          (ref) => repertoireTimeline(
            ref as RepertoireTimelineRef,
            studentId,
          ),
          from: repertoireTimelineProvider,
          name: r'repertoireTimelineProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$repertoireTimelineHash,
          dependencies: RepertoireTimelineFamily._dependencies,
          allTransitiveDependencies:
              RepertoireTimelineFamily._allTransitiveDependencies,
          studentId: studentId,
        );

  RepertoireTimelineProvider._internal(
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
  Override overrideWith(
    FutureOr<RepertoireTimeline> Function(RepertoireTimelineRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: RepertoireTimelineProvider._internal(
        (ref) => create(ref as RepertoireTimelineRef),
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
  AutoDisposeFutureProviderElement<RepertoireTimeline> createElement() {
    return _RepertoireTimelineProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RepertoireTimelineProvider && other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin RepertoireTimelineRef
    on AutoDisposeFutureProviderRef<RepertoireTimeline> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _RepertoireTimelineProviderElement
    extends AutoDisposeFutureProviderElement<RepertoireTimeline>
    with RepertoireTimelineRef {
  _RepertoireTimelineProviderElement(super.provider);

  @override
  String get studentId => (origin as RepertoireTimelineProvider).studentId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
