// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goal_achievement_storage_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$goalAchievementStorageHash() =>
    r'9933d9e3e01b5935cf5799cd3484726102f8959c';

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

abstract class _$GoalAchievementStorage
    extends BuildlessAsyncNotifier<GoalAchievementState> {
  late final String studentId;

  FutureOr<GoalAchievementState> build(
    String studentId,
  );
}

/// Per-user storage of the most recent daily / weekly goal achievement
/// celebrations.
///
/// The widget tier reads this to ensure the achievement dialog is shown at
/// most once per achievement window (one day for daily goals, one ISO week
/// for weekly goals). Without this dedupe the dialog would re-pop on every
/// tab rebuild while the goal stays achieved.
///
/// Keys follow the user-scoped convention so multiple students on the same
/// device do not share celebration history.
///
/// Copied from [GoalAchievementStorage].
@ProviderFor(GoalAchievementStorage)
const goalAchievementStorageProvider = GoalAchievementStorageFamily();

/// Per-user storage of the most recent daily / weekly goal achievement
/// celebrations.
///
/// The widget tier reads this to ensure the achievement dialog is shown at
/// most once per achievement window (one day for daily goals, one ISO week
/// for weekly goals). Without this dedupe the dialog would re-pop on every
/// tab rebuild while the goal stays achieved.
///
/// Keys follow the user-scoped convention so multiple students on the same
/// device do not share celebration history.
///
/// Copied from [GoalAchievementStorage].
class GoalAchievementStorageFamily
    extends Family<AsyncValue<GoalAchievementState>> {
  /// Per-user storage of the most recent daily / weekly goal achievement
  /// celebrations.
  ///
  /// The widget tier reads this to ensure the achievement dialog is shown at
  /// most once per achievement window (one day for daily goals, one ISO week
  /// for weekly goals). Without this dedupe the dialog would re-pop on every
  /// tab rebuild while the goal stays achieved.
  ///
  /// Keys follow the user-scoped convention so multiple students on the same
  /// device do not share celebration history.
  ///
  /// Copied from [GoalAchievementStorage].
  const GoalAchievementStorageFamily();

  /// Per-user storage of the most recent daily / weekly goal achievement
  /// celebrations.
  ///
  /// The widget tier reads this to ensure the achievement dialog is shown at
  /// most once per achievement window (one day for daily goals, one ISO week
  /// for weekly goals). Without this dedupe the dialog would re-pop on every
  /// tab rebuild while the goal stays achieved.
  ///
  /// Keys follow the user-scoped convention so multiple students on the same
  /// device do not share celebration history.
  ///
  /// Copied from [GoalAchievementStorage].
  GoalAchievementStorageProvider call(
    String studentId,
  ) {
    return GoalAchievementStorageProvider(
      studentId,
    );
  }

  @override
  GoalAchievementStorageProvider getProviderOverride(
    covariant GoalAchievementStorageProvider provider,
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
  String? get name => r'goalAchievementStorageProvider';
}

/// Per-user storage of the most recent daily / weekly goal achievement
/// celebrations.
///
/// The widget tier reads this to ensure the achievement dialog is shown at
/// most once per achievement window (one day for daily goals, one ISO week
/// for weekly goals). Without this dedupe the dialog would re-pop on every
/// tab rebuild while the goal stays achieved.
///
/// Keys follow the user-scoped convention so multiple students on the same
/// device do not share celebration history.
///
/// Copied from [GoalAchievementStorage].
class GoalAchievementStorageProvider extends AsyncNotifierProviderImpl<
    GoalAchievementStorage, GoalAchievementState> {
  /// Per-user storage of the most recent daily / weekly goal achievement
  /// celebrations.
  ///
  /// The widget tier reads this to ensure the achievement dialog is shown at
  /// most once per achievement window (one day for daily goals, one ISO week
  /// for weekly goals). Without this dedupe the dialog would re-pop on every
  /// tab rebuild while the goal stays achieved.
  ///
  /// Keys follow the user-scoped convention so multiple students on the same
  /// device do not share celebration history.
  ///
  /// Copied from [GoalAchievementStorage].
  GoalAchievementStorageProvider(
    String studentId,
  ) : this._internal(
          () => GoalAchievementStorage()..studentId = studentId,
          from: goalAchievementStorageProvider,
          name: r'goalAchievementStorageProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$goalAchievementStorageHash,
          dependencies: GoalAchievementStorageFamily._dependencies,
          allTransitiveDependencies:
              GoalAchievementStorageFamily._allTransitiveDependencies,
          studentId: studentId,
        );

  GoalAchievementStorageProvider._internal(
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
  FutureOr<GoalAchievementState> runNotifierBuild(
    covariant GoalAchievementStorage notifier,
  ) {
    return notifier.build(
      studentId,
    );
  }

  @override
  Override overrideWith(GoalAchievementStorage Function() create) {
    return ProviderOverride(
      origin: this,
      override: GoalAchievementStorageProvider._internal(
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
  AsyncNotifierProviderElement<GoalAchievementStorage, GoalAchievementState>
      createElement() {
    return _GoalAchievementStorageProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GoalAchievementStorageProvider &&
        other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin GoalAchievementStorageRef
    on AsyncNotifierProviderRef<GoalAchievementState> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _GoalAchievementStorageProviderElement
    extends AsyncNotifierProviderElement<GoalAchievementStorage,
        GoalAchievementState> with GoalAchievementStorageRef {
  _GoalAchievementStorageProviderElement(super.provider);

  @override
  String get studentId => (origin as GoalAchievementStorageProvider).studentId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
