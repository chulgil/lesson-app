// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_home_profile_edit_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$studentHomeProfileEditStudentHash() =>
    r'4d030b451a4bbe40eee4eb6b57d024c8b35dc200';

/// See also [studentHomeProfileEditStudent].
@ProviderFor(studentHomeProfileEditStudent)
final studentHomeProfileEditStudentProvider =
    AutoDisposeFutureProvider<Student?>.internal(
  studentHomeProfileEditStudent,
  name: r'studentHomeProfileEditStudentProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$studentHomeProfileEditStudentHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef StudentHomeProfileEditStudentRef
    = AutoDisposeFutureProviderRef<Student?>;
String _$studentHomeProfileEditImagePathHash() =>
    r'1ebb6ed6161818888c6dbafddb1ca7067cbffb42';

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

/// See also [studentHomeProfileEditImagePath].
@ProviderFor(studentHomeProfileEditImagePath)
const studentHomeProfileEditImagePathProvider =
    StudentHomeProfileEditImagePathFamily();

/// See also [studentHomeProfileEditImagePath].
class StudentHomeProfileEditImagePathFamily
    extends Family<AsyncValue<String?>> {
  /// See also [studentHomeProfileEditImagePath].
  const StudentHomeProfileEditImagePathFamily();

  /// See also [studentHomeProfileEditImagePath].
  StudentHomeProfileEditImagePathProvider call(
    String studentId,
  ) {
    return StudentHomeProfileEditImagePathProvider(
      studentId,
    );
  }

  @override
  StudentHomeProfileEditImagePathProvider getProviderOverride(
    covariant StudentHomeProfileEditImagePathProvider provider,
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
  String? get name => r'studentHomeProfileEditImagePathProvider';
}

/// See also [studentHomeProfileEditImagePath].
class StudentHomeProfileEditImagePathProvider
    extends AutoDisposeFutureProvider<String?> {
  /// See also [studentHomeProfileEditImagePath].
  StudentHomeProfileEditImagePathProvider(
    String studentId,
  ) : this._internal(
          (ref) => studentHomeProfileEditImagePath(
            ref as StudentHomeProfileEditImagePathRef,
            studentId,
          ),
          from: studentHomeProfileEditImagePathProvider,
          name: r'studentHomeProfileEditImagePathProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$studentHomeProfileEditImagePathHash,
          dependencies: StudentHomeProfileEditImagePathFamily._dependencies,
          allTransitiveDependencies:
              StudentHomeProfileEditImagePathFamily._allTransitiveDependencies,
          studentId: studentId,
        );

  StudentHomeProfileEditImagePathProvider._internal(
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
    FutureOr<String?> Function(StudentHomeProfileEditImagePathRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: StudentHomeProfileEditImagePathProvider._internal(
        (ref) => create(ref as StudentHomeProfileEditImagePathRef),
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
  AutoDisposeFutureProviderElement<String?> createElement() {
    return _StudentHomeProfileEditImagePathProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StudentHomeProfileEditImagePathProvider &&
        other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin StudentHomeProfileEditImagePathRef
    on AutoDisposeFutureProviderRef<String?> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _StudentHomeProfileEditImagePathProviderElement
    extends AutoDisposeFutureProviderElement<String?>
    with StudentHomeProfileEditImagePathRef {
  _StudentHomeProfileEditImagePathProviderElement(super.provider);

  @override
  String get studentId =>
      (origin as StudentHomeProfileEditImagePathProvider).studentId;
}

String _$studentHomeProfileEditActionsHash() =>
    r'd4d7d7254caa9546940b1e7d11214030b014549f';

/// See also [studentHomeProfileEditActions].
@ProviderFor(studentHomeProfileEditActions)
final studentHomeProfileEditActionsProvider =
    AutoDisposeProvider<StudentHomeProfileEditActions>.internal(
  studentHomeProfileEditActions,
  name: r'studentHomeProfileEditActionsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$studentHomeProfileEditActionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef StudentHomeProfileEditActionsRef
    = AutoDisposeProviderRef<StudentHomeProfileEditActions>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
