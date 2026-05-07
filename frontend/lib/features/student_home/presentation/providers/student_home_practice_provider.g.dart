// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_home_practice_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$studentHomePracticeLogsHash() =>
    r'e7e5c3dca0151f6b19bfc67d09266780e5b35fec';

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

/// See also [studentHomePracticeLogs].
@ProviderFor(studentHomePracticeLogs)
const studentHomePracticeLogsProvider = StudentHomePracticeLogsFamily();

/// See also [studentHomePracticeLogs].
class StudentHomePracticeLogsFamily
    extends Family<AsyncValue<List<PracticeLog>>> {
  /// See also [studentHomePracticeLogs].
  const StudentHomePracticeLogsFamily();

  /// See also [studentHomePracticeLogs].
  StudentHomePracticeLogsProvider call(
    String studentId,
  ) {
    return StudentHomePracticeLogsProvider(
      studentId,
    );
  }

  @override
  StudentHomePracticeLogsProvider getProviderOverride(
    covariant StudentHomePracticeLogsProvider provider,
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
  String? get name => r'studentHomePracticeLogsProvider';
}

/// See also [studentHomePracticeLogs].
class StudentHomePracticeLogsProvider
    extends AutoDisposeFutureProvider<List<PracticeLog>> {
  /// See also [studentHomePracticeLogs].
  StudentHomePracticeLogsProvider(
    String studentId,
  ) : this._internal(
          (ref) => studentHomePracticeLogs(
            ref as StudentHomePracticeLogsRef,
            studentId,
          ),
          from: studentHomePracticeLogsProvider,
          name: r'studentHomePracticeLogsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$studentHomePracticeLogsHash,
          dependencies: StudentHomePracticeLogsFamily._dependencies,
          allTransitiveDependencies:
              StudentHomePracticeLogsFamily._allTransitiveDependencies,
          studentId: studentId,
        );

  StudentHomePracticeLogsProvider._internal(
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
    FutureOr<List<PracticeLog>> Function(StudentHomePracticeLogsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: StudentHomePracticeLogsProvider._internal(
        (ref) => create(ref as StudentHomePracticeLogsRef),
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
  AutoDisposeFutureProviderElement<List<PracticeLog>> createElement() {
    return _StudentHomePracticeLogsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StudentHomePracticeLogsProvider &&
        other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin StudentHomePracticeLogsRef
    on AutoDisposeFutureProviderRef<List<PracticeLog>> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _StudentHomePracticeLogsProviderElement
    extends AutoDisposeFutureProviderElement<List<PracticeLog>>
    with StudentHomePracticeLogsRef {
  _StudentHomePracticeLogsProviderElement(super.provider);

  @override
  String get studentId => (origin as StudentHomePracticeLogsProvider).studentId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
