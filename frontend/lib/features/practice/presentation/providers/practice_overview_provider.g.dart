// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'practice_overview_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$studentPracticeOverviewHash() =>
    r'2b56d09662842892c7528248cad6b24c49ce0381';

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

/// Provider for teacher's view of student practice overview.
/// Returns weekly practice entries and shared recordings.
///
/// Copied from [studentPracticeOverview].
@ProviderFor(studentPracticeOverview)
const studentPracticeOverviewProvider = StudentPracticeOverviewFamily();

/// Provider for teacher's view of student practice overview.
/// Returns weekly practice entries and shared recordings.
///
/// Copied from [studentPracticeOverview].
class StudentPracticeOverviewFamily
    extends Family<AsyncValue<StudentPracticeOverview>> {
  /// Provider for teacher's view of student practice overview.
  /// Returns weekly practice entries and shared recordings.
  ///
  /// Copied from [studentPracticeOverview].
  const StudentPracticeOverviewFamily();

  /// Provider for teacher's view of student practice overview.
  /// Returns weekly practice entries and shared recordings.
  ///
  /// Copied from [studentPracticeOverview].
  StudentPracticeOverviewProvider call(
    String studentId,
  ) {
    return StudentPracticeOverviewProvider(
      studentId,
    );
  }

  @override
  StudentPracticeOverviewProvider getProviderOverride(
    covariant StudentPracticeOverviewProvider provider,
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
  String? get name => r'studentPracticeOverviewProvider';
}

/// Provider for teacher's view of student practice overview.
/// Returns weekly practice entries and shared recordings.
///
/// Copied from [studentPracticeOverview].
class StudentPracticeOverviewProvider
    extends AutoDisposeFutureProvider<StudentPracticeOverview> {
  /// Provider for teacher's view of student practice overview.
  /// Returns weekly practice entries and shared recordings.
  ///
  /// Copied from [studentPracticeOverview].
  StudentPracticeOverviewProvider(
    String studentId,
  ) : this._internal(
          (ref) => studentPracticeOverview(
            ref as StudentPracticeOverviewRef,
            studentId,
          ),
          from: studentPracticeOverviewProvider,
          name: r'studentPracticeOverviewProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$studentPracticeOverviewHash,
          dependencies: StudentPracticeOverviewFamily._dependencies,
          allTransitiveDependencies:
              StudentPracticeOverviewFamily._allTransitiveDependencies,
          studentId: studentId,
        );

  StudentPracticeOverviewProvider._internal(
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
    FutureOr<StudentPracticeOverview> Function(
            StudentPracticeOverviewRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: StudentPracticeOverviewProvider._internal(
        (ref) => create(ref as StudentPracticeOverviewRef),
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
  AutoDisposeFutureProviderElement<StudentPracticeOverview> createElement() {
    return _StudentPracticeOverviewProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StudentPracticeOverviewProvider &&
        other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin StudentPracticeOverviewRef
    on AutoDisposeFutureProviderRef<StudentPracticeOverview> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _StudentPracticeOverviewProviderElement
    extends AutoDisposeFutureProviderElement<StudentPracticeOverview>
    with StudentPracticeOverviewRef {
  _StudentPracticeOverviewProviderElement(super.provider);

  @override
  String get studentId => (origin as StudentPracticeOverviewProvider).studentId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
