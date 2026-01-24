// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'practice_streak_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$practiceStreakHash() => r'a6a74bcbb0298d0aaa88e9f2bd472e05a84b845b';

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

/// Provider for getting practice streak by student ID
///
/// Copied from [practiceStreak].
@ProviderFor(practiceStreak)
const practiceStreakProvider = PracticeStreakFamily();

/// Provider for getting practice streak by student ID
///
/// Copied from [practiceStreak].
class PracticeStreakFamily extends Family<AsyncValue<PracticeStreak>> {
  /// Provider for getting practice streak by student ID
  ///
  /// Copied from [practiceStreak].
  const PracticeStreakFamily();

  /// Provider for getting practice streak by student ID
  ///
  /// Copied from [practiceStreak].
  PracticeStreakProvider call(
    String studentId,
  ) {
    return PracticeStreakProvider(
      studentId,
    );
  }

  @override
  PracticeStreakProvider getProviderOverride(
    covariant PracticeStreakProvider provider,
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
  String? get name => r'practiceStreakProvider';
}

/// Provider for getting practice streak by student ID
///
/// Copied from [practiceStreak].
class PracticeStreakProvider extends AutoDisposeFutureProvider<PracticeStreak> {
  /// Provider for getting practice streak by student ID
  ///
  /// Copied from [practiceStreak].
  PracticeStreakProvider(
    String studentId,
  ) : this._internal(
          (ref) => practiceStreak(
            ref as PracticeStreakRef,
            studentId,
          ),
          from: practiceStreakProvider,
          name: r'practiceStreakProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$practiceStreakHash,
          dependencies: PracticeStreakFamily._dependencies,
          allTransitiveDependencies:
              PracticeStreakFamily._allTransitiveDependencies,
          studentId: studentId,
        );

  PracticeStreakProvider._internal(
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
    FutureOr<PracticeStreak> Function(PracticeStreakRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PracticeStreakProvider._internal(
        (ref) => create(ref as PracticeStreakRef),
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
  AutoDisposeFutureProviderElement<PracticeStreak> createElement() {
    return _PracticeStreakProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PracticeStreakProvider && other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PracticeStreakRef on AutoDisposeFutureProviderRef<PracticeStreak> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _PracticeStreakProviderElement
    extends AutoDisposeFutureProviderElement<PracticeStreak>
    with PracticeStreakRef {
  _PracticeStreakProviderElement(super.provider);

  @override
  String get studentId => (origin as PracticeStreakProvider).studentId;
}

String _$recordPracticeHash() => r'aec77b9a7f33cb27c35cd05cb72a1f961a55d9e4';

/// Provider for recording practice and updating streak
///
/// Copied from [recordPractice].
@ProviderFor(recordPractice)
const recordPracticeProvider = RecordPracticeFamily();

/// Provider for recording practice and updating streak
///
/// Copied from [recordPractice].
class RecordPracticeFamily extends Family<AsyncValue<PracticeStreak>> {
  /// Provider for recording practice and updating streak
  ///
  /// Copied from [recordPractice].
  const RecordPracticeFamily();

  /// Provider for recording practice and updating streak
  ///
  /// Copied from [recordPractice].
  RecordPracticeProvider call(
    String studentId,
  ) {
    return RecordPracticeProvider(
      studentId,
    );
  }

  @override
  RecordPracticeProvider getProviderOverride(
    covariant RecordPracticeProvider provider,
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
  String? get name => r'recordPracticeProvider';
}

/// Provider for recording practice and updating streak
///
/// Copied from [recordPractice].
class RecordPracticeProvider extends AutoDisposeFutureProvider<PracticeStreak> {
  /// Provider for recording practice and updating streak
  ///
  /// Copied from [recordPractice].
  RecordPracticeProvider(
    String studentId,
  ) : this._internal(
          (ref) => recordPractice(
            ref as RecordPracticeRef,
            studentId,
          ),
          from: recordPracticeProvider,
          name: r'recordPracticeProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$recordPracticeHash,
          dependencies: RecordPracticeFamily._dependencies,
          allTransitiveDependencies:
              RecordPracticeFamily._allTransitiveDependencies,
          studentId: studentId,
        );

  RecordPracticeProvider._internal(
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
    FutureOr<PracticeStreak> Function(RecordPracticeRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: RecordPracticeProvider._internal(
        (ref) => create(ref as RecordPracticeRef),
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
  AutoDisposeFutureProviderElement<PracticeStreak> createElement() {
    return _RecordPracticeProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RecordPracticeProvider && other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin RecordPracticeRef on AutoDisposeFutureProviderRef<PracticeStreak> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _RecordPracticeProviderElement
    extends AutoDisposeFutureProviderElement<PracticeStreak>
    with RecordPracticeRef {
  _RecordPracticeProviderElement(super.provider);

  @override
  String get studentId => (origin as RecordPracticeProvider).studentId;
}

String _$currentUserStreakHash() => r'9750602edeb21b5527cfc03ed35ea8c88eea053d';

/// Provider for current user's streak
///
/// Copied from [currentUserStreak].
@ProviderFor(currentUserStreak)
final currentUserStreakProvider =
    AutoDisposeFutureProvider<PracticeStreak>.internal(
  currentUserStreak,
  name: r'currentUserStreakProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentUserStreakHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentUserStreakRef = AutoDisposeFutureProviderRef<PracticeStreak>;
String _$streakNotifierHash() => r'2335a6f53fb3b91ba9228444d4503833505f7871';

abstract class _$StreakNotifier
    extends BuildlessAutoDisposeAsyncNotifier<PracticeStreak> {
  late final String studentId;

  FutureOr<PracticeStreak> build(
    String studentId,
  );
}

/// State notifier for managing streak updates
///
/// Copied from [StreakNotifier].
@ProviderFor(StreakNotifier)
const streakNotifierProvider = StreakNotifierFamily();

/// State notifier for managing streak updates
///
/// Copied from [StreakNotifier].
class StreakNotifierFamily extends Family<AsyncValue<PracticeStreak>> {
  /// State notifier for managing streak updates
  ///
  /// Copied from [StreakNotifier].
  const StreakNotifierFamily();

  /// State notifier for managing streak updates
  ///
  /// Copied from [StreakNotifier].
  StreakNotifierProvider call(
    String studentId,
  ) {
    return StreakNotifierProvider(
      studentId,
    );
  }

  @override
  StreakNotifierProvider getProviderOverride(
    covariant StreakNotifierProvider provider,
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
  String? get name => r'streakNotifierProvider';
}

/// State notifier for managing streak updates
///
/// Copied from [StreakNotifier].
class StreakNotifierProvider extends AutoDisposeAsyncNotifierProviderImpl<
    StreakNotifier, PracticeStreak> {
  /// State notifier for managing streak updates
  ///
  /// Copied from [StreakNotifier].
  StreakNotifierProvider(
    String studentId,
  ) : this._internal(
          () => StreakNotifier()..studentId = studentId,
          from: streakNotifierProvider,
          name: r'streakNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$streakNotifierHash,
          dependencies: StreakNotifierFamily._dependencies,
          allTransitiveDependencies:
              StreakNotifierFamily._allTransitiveDependencies,
          studentId: studentId,
        );

  StreakNotifierProvider._internal(
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
  FutureOr<PracticeStreak> runNotifierBuild(
    covariant StreakNotifier notifier,
  ) {
    return notifier.build(
      studentId,
    );
  }

  @override
  Override overrideWith(StreakNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: StreakNotifierProvider._internal(
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
  AutoDisposeAsyncNotifierProviderElement<StreakNotifier, PracticeStreak>
      createElement() {
    return _StreakNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StreakNotifierProvider && other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin StreakNotifierRef on AutoDisposeAsyncNotifierProviderRef<PracticeStreak> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _StreakNotifierProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<StreakNotifier,
        PracticeStreak> with StreakNotifierRef {
  _StreakNotifierProviderElement(super.provider);

  @override
  String get studentId => (origin as StreakNotifierProvider).studentId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
