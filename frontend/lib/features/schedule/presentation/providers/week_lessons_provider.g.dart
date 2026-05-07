// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'week_lessons_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$weekLessonsHash() => r'6ba01a46689d9bd9487c6c9db2db4ccae98e6fae';

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

/// Provider that loads all lessons for a given week (Mon-Sun).
/// [weekStartDate] should be the Monday of the target week.
///
/// Copied from [weekLessons].
@ProviderFor(weekLessons)
const weekLessonsProvider = WeekLessonsFamily();

/// Provider that loads all lessons for a given week (Mon-Sun).
/// [weekStartDate] should be the Monday of the target week.
///
/// Copied from [weekLessons].
class WeekLessonsFamily extends Family<AsyncValue<List<Lesson>>> {
  /// Provider that loads all lessons for a given week (Mon-Sun).
  /// [weekStartDate] should be the Monday of the target week.
  ///
  /// Copied from [weekLessons].
  const WeekLessonsFamily();

  /// Provider that loads all lessons for a given week (Mon-Sun).
  /// [weekStartDate] should be the Monday of the target week.
  ///
  /// Copied from [weekLessons].
  WeekLessonsProvider call(
    DateTime weekStartDate,
  ) {
    return WeekLessonsProvider(
      weekStartDate,
    );
  }

  @override
  WeekLessonsProvider getProviderOverride(
    covariant WeekLessonsProvider provider,
  ) {
    return call(
      provider.weekStartDate,
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
  String? get name => r'weekLessonsProvider';
}

/// Provider that loads all lessons for a given week (Mon-Sun).
/// [weekStartDate] should be the Monday of the target week.
///
/// Copied from [weekLessons].
class WeekLessonsProvider extends FutureProvider<List<Lesson>> {
  /// Provider that loads all lessons for a given week (Mon-Sun).
  /// [weekStartDate] should be the Monday of the target week.
  ///
  /// Copied from [weekLessons].
  WeekLessonsProvider(
    DateTime weekStartDate,
  ) : this._internal(
          (ref) => weekLessons(
            ref as WeekLessonsRef,
            weekStartDate,
          ),
          from: weekLessonsProvider,
          name: r'weekLessonsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$weekLessonsHash,
          dependencies: WeekLessonsFamily._dependencies,
          allTransitiveDependencies:
              WeekLessonsFamily._allTransitiveDependencies,
          weekStartDate: weekStartDate,
        );

  WeekLessonsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.weekStartDate,
  }) : super.internal();

  final DateTime weekStartDate;

  @override
  Override overrideWith(
    FutureOr<List<Lesson>> Function(WeekLessonsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: WeekLessonsProvider._internal(
        (ref) => create(ref as WeekLessonsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        weekStartDate: weekStartDate,
      ),
    );
  }

  @override
  FutureProviderElement<List<Lesson>> createElement() {
    return _WeekLessonsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is WeekLessonsProvider && other.weekStartDate == weekStartDate;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, weekStartDate.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin WeekLessonsRef on FutureProviderRef<List<Lesson>> {
  /// The parameter `weekStartDate` of this provider.
  DateTime get weekStartDate;
}

class _WeekLessonsProviderElement extends FutureProviderElement<List<Lesson>>
    with WeekLessonsRef {
  _WeekLessonsProviderElement(super.provider);

  @override
  DateTime get weekStartDate => (origin as WeekLessonsProvider).weekStartDate;
}

String _$weekLessonsWithPreviewHash() =>
    r'5d721f271ecc8a76e994b5d7696f1e3fe6b4b2cf';

/// Provider that loads lessons + preview lessons for a given week.
///
/// Preview lessons are generated from ClassMembership.lessonSlots for weeks
/// beyond subscription coverage. Rendered with dashed borders in the grid.
///
/// Copied from [weekLessonsWithPreview].
@ProviderFor(weekLessonsWithPreview)
const weekLessonsWithPreviewProvider = WeekLessonsWithPreviewFamily();

/// Provider that loads lessons + preview lessons for a given week.
///
/// Preview lessons are generated from ClassMembership.lessonSlots for weeks
/// beyond subscription coverage. Rendered with dashed borders in the grid.
///
/// Copied from [weekLessonsWithPreview].
class WeekLessonsWithPreviewFamily extends Family<AsyncValue<List<Lesson>>> {
  /// Provider that loads lessons + preview lessons for a given week.
  ///
  /// Preview lessons are generated from ClassMembership.lessonSlots for weeks
  /// beyond subscription coverage. Rendered with dashed borders in the grid.
  ///
  /// Copied from [weekLessonsWithPreview].
  const WeekLessonsWithPreviewFamily();

  /// Provider that loads lessons + preview lessons for a given week.
  ///
  /// Preview lessons are generated from ClassMembership.lessonSlots for weeks
  /// beyond subscription coverage. Rendered with dashed borders in the grid.
  ///
  /// Copied from [weekLessonsWithPreview].
  WeekLessonsWithPreviewProvider call(
    ({String teacherId, DateTime weekStart}) params,
  ) {
    return WeekLessonsWithPreviewProvider(
      params,
    );
  }

  @override
  WeekLessonsWithPreviewProvider getProviderOverride(
    covariant WeekLessonsWithPreviewProvider provider,
  ) {
    return call(
      provider.params,
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
  String? get name => r'weekLessonsWithPreviewProvider';
}

/// Provider that loads lessons + preview lessons for a given week.
///
/// Preview lessons are generated from ClassMembership.lessonSlots for weeks
/// beyond subscription coverage. Rendered with dashed borders in the grid.
///
/// Copied from [weekLessonsWithPreview].
class WeekLessonsWithPreviewProvider extends FutureProvider<List<Lesson>> {
  /// Provider that loads lessons + preview lessons for a given week.
  ///
  /// Preview lessons are generated from ClassMembership.lessonSlots for weeks
  /// beyond subscription coverage. Rendered with dashed borders in the grid.
  ///
  /// Copied from [weekLessonsWithPreview].
  WeekLessonsWithPreviewProvider(
    ({String teacherId, DateTime weekStart}) params,
  ) : this._internal(
          (ref) => weekLessonsWithPreview(
            ref as WeekLessonsWithPreviewRef,
            params,
          ),
          from: weekLessonsWithPreviewProvider,
          name: r'weekLessonsWithPreviewProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$weekLessonsWithPreviewHash,
          dependencies: WeekLessonsWithPreviewFamily._dependencies,
          allTransitiveDependencies:
              WeekLessonsWithPreviewFamily._allTransitiveDependencies,
          params: params,
        );

  WeekLessonsWithPreviewProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.params,
  }) : super.internal();

  final ({String teacherId, DateTime weekStart}) params;

  @override
  Override overrideWith(
    FutureOr<List<Lesson>> Function(WeekLessonsWithPreviewRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: WeekLessonsWithPreviewProvider._internal(
        (ref) => create(ref as WeekLessonsWithPreviewRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        params: params,
      ),
    );
  }

  @override
  FutureProviderElement<List<Lesson>> createElement() {
    return _WeekLessonsWithPreviewProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is WeekLessonsWithPreviewProvider && other.params == params;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, params.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin WeekLessonsWithPreviewRef on FutureProviderRef<List<Lesson>> {
  /// The parameter `params` of this provider.
  ({String teacherId, DateTime weekStart}) get params;
}

class _WeekLessonsWithPreviewProviderElement
    extends FutureProviderElement<List<Lesson>> with WeekLessonsWithPreviewRef {
  _WeekLessonsWithPreviewProviderElement(super.provider);

  @override
  ({String teacherId, DateTime weekStart}) get params =>
      (origin as WeekLessonsWithPreviewProvider).params;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
