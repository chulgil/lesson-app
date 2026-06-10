// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'challenge_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$studentChallengesHash() => r'25338dbd50e1c46cb03f84eba080d5e4dd0ed1a4';

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

/// Provides the list of active challenges for a student.
///
/// Copied from [studentChallenges].
@ProviderFor(studentChallenges)
const studentChallengesProvider = StudentChallengesFamily();

/// Provides the list of active challenges for a student.
///
/// Copied from [studentChallenges].
class StudentChallengesFamily extends Family<AsyncValue<List<Challenge>>> {
  /// Provides the list of active challenges for a student.
  ///
  /// Copied from [studentChallenges].
  const StudentChallengesFamily();

  /// Provides the list of active challenges for a student.
  ///
  /// Copied from [studentChallenges].
  StudentChallengesProvider call(
    String studentId,
  ) {
    return StudentChallengesProvider(
      studentId,
    );
  }

  @override
  StudentChallengesProvider getProviderOverride(
    covariant StudentChallengesProvider provider,
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
  String? get name => r'studentChallengesProvider';
}

/// Provides the list of active challenges for a student.
///
/// Copied from [studentChallenges].
class StudentChallengesProvider
    extends AutoDisposeFutureProvider<List<Challenge>> {
  /// Provides the list of active challenges for a student.
  ///
  /// Copied from [studentChallenges].
  StudentChallengesProvider(
    String studentId,
  ) : this._internal(
          (ref) => studentChallenges(
            ref as StudentChallengesRef,
            studentId,
          ),
          from: studentChallengesProvider,
          name: r'studentChallengesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$studentChallengesHash,
          dependencies: StudentChallengesFamily._dependencies,
          allTransitiveDependencies:
              StudentChallengesFamily._allTransitiveDependencies,
          studentId: studentId,
        );

  StudentChallengesProvider._internal(
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
    FutureOr<List<Challenge>> Function(StudentChallengesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: StudentChallengesProvider._internal(
        (ref) => create(ref as StudentChallengesRef),
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
  AutoDisposeFutureProviderElement<List<Challenge>> createElement() {
    return _StudentChallengesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StudentChallengesProvider && other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin StudentChallengesRef on AutoDisposeFutureProviderRef<List<Challenge>> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _StudentChallengesProviderElement
    extends AutoDisposeFutureProviderElement<List<Challenge>>
    with StudentChallengesRef {
  _StudentChallengesProviderElement(super.provider);

  @override
  String get studentId => (origin as StudentChallengesProvider).studentId;
}

String _$activeChallengesHash() => r'bcc323035f3814d22aea75fff0c8f439e59d64c8';

/// Provides only active (non-completed, non-expired) challenges.
///
/// Copied from [activeChallenges].
@ProviderFor(activeChallenges)
const activeChallengesProvider = ActiveChallengesFamily();

/// Provides only active (non-completed, non-expired) challenges.
///
/// Copied from [activeChallenges].
class ActiveChallengesFamily extends Family<AsyncValue<List<Challenge>>> {
  /// Provides only active (non-completed, non-expired) challenges.
  ///
  /// Copied from [activeChallenges].
  const ActiveChallengesFamily();

  /// Provides only active (non-completed, non-expired) challenges.
  ///
  /// Copied from [activeChallenges].
  ActiveChallengesProvider call(
    String studentId,
  ) {
    return ActiveChallengesProvider(
      studentId,
    );
  }

  @override
  ActiveChallengesProvider getProviderOverride(
    covariant ActiveChallengesProvider provider,
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
  String? get name => r'activeChallengesProvider';
}

/// Provides only active (non-completed, non-expired) challenges.
///
/// Copied from [activeChallenges].
class ActiveChallengesProvider
    extends AutoDisposeFutureProvider<List<Challenge>> {
  /// Provides only active (non-completed, non-expired) challenges.
  ///
  /// Copied from [activeChallenges].
  ActiveChallengesProvider(
    String studentId,
  ) : this._internal(
          (ref) => activeChallenges(
            ref as ActiveChallengesRef,
            studentId,
          ),
          from: activeChallengesProvider,
          name: r'activeChallengesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$activeChallengesHash,
          dependencies: ActiveChallengesFamily._dependencies,
          allTransitiveDependencies:
              ActiveChallengesFamily._allTransitiveDependencies,
          studentId: studentId,
        );

  ActiveChallengesProvider._internal(
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
    FutureOr<List<Challenge>> Function(ActiveChallengesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ActiveChallengesProvider._internal(
        (ref) => create(ref as ActiveChallengesRef),
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
  AutoDisposeFutureProviderElement<List<Challenge>> createElement() {
    return _ActiveChallengesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ActiveChallengesProvider && other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin ActiveChallengesRef on AutoDisposeFutureProviderRef<List<Challenge>> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _ActiveChallengesProviderElement
    extends AutoDisposeFutureProviderElement<List<Challenge>>
    with ActiveChallengesRef {
  _ActiveChallengesProviderElement(super.provider);

  @override
  String get studentId => (origin as ActiveChallengesProvider).studentId;
}

String _$completedChallengesHash() =>
    r'14fc2a1610e39921a4fb666a650adcfad64b0793';

/// Provides completed challenges.
///
/// Copied from [completedChallenges].
@ProviderFor(completedChallenges)
const completedChallengesProvider = CompletedChallengesFamily();

/// Provides completed challenges.
///
/// Copied from [completedChallenges].
class CompletedChallengesFamily extends Family<AsyncValue<List<Challenge>>> {
  /// Provides completed challenges.
  ///
  /// Copied from [completedChallenges].
  const CompletedChallengesFamily();

  /// Provides completed challenges.
  ///
  /// Copied from [completedChallenges].
  CompletedChallengesProvider call(
    String studentId,
  ) {
    return CompletedChallengesProvider(
      studentId,
    );
  }

  @override
  CompletedChallengesProvider getProviderOverride(
    covariant CompletedChallengesProvider provider,
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
  String? get name => r'completedChallengesProvider';
}

/// Provides completed challenges.
///
/// Copied from [completedChallenges].
class CompletedChallengesProvider
    extends AutoDisposeFutureProvider<List<Challenge>> {
  /// Provides completed challenges.
  ///
  /// Copied from [completedChallenges].
  CompletedChallengesProvider(
    String studentId,
  ) : this._internal(
          (ref) => completedChallenges(
            ref as CompletedChallengesRef,
            studentId,
          ),
          from: completedChallengesProvider,
          name: r'completedChallengesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$completedChallengesHash,
          dependencies: CompletedChallengesFamily._dependencies,
          allTransitiveDependencies:
              CompletedChallengesFamily._allTransitiveDependencies,
          studentId: studentId,
        );

  CompletedChallengesProvider._internal(
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
    FutureOr<List<Challenge>> Function(CompletedChallengesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CompletedChallengesProvider._internal(
        (ref) => create(ref as CompletedChallengesRef),
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
  AutoDisposeFutureProviderElement<List<Challenge>> createElement() {
    return _CompletedChallengesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CompletedChallengesProvider && other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin CompletedChallengesRef on AutoDisposeFutureProviderRef<List<Challenge>> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _CompletedChallengesProviderElement
    extends AutoDisposeFutureProviderElement<List<Challenge>>
    with CompletedChallengesRef {
  _CompletedChallengesProviderElement(super.provider);

  @override
  String get studentId => (origin as CompletedChallengesProvider).studentId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
