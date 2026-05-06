// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_crud_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$studentsHash() => r'cef79720ba000cfd324c5b0c675312b72da9f6a1';

/// All students provider
///
/// Copied from [students].
@ProviderFor(students)
final studentsProvider = FutureProvider<List<Student>>.internal(
  students,
  name: r'studentsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$studentsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef StudentsRef = FutureProviderRef<List<Student>>;
String _$studentHash() => r'1d37bcdef64f6fb4837e95201f99c0bcd6654cc2';

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

/// Single student provider
///
/// Copied from [student].
@ProviderFor(student)
const studentProvider = StudentFamily();

/// Single student provider
///
/// Copied from [student].
class StudentFamily extends Family<AsyncValue<Student?>> {
  /// Single student provider
  ///
  /// Copied from [student].
  const StudentFamily();

  /// Single student provider
  ///
  /// Copied from [student].
  StudentProvider call(
    String id,
  ) {
    return StudentProvider(
      id,
    );
  }

  @override
  StudentProvider getProviderOverride(
    covariant StudentProvider provider,
  ) {
    return call(
      provider.id,
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
  String? get name => r'studentProvider';
}

/// Single student provider
///
/// Copied from [student].
class StudentProvider extends FutureProvider<Student?> {
  /// Single student provider
  ///
  /// Copied from [student].
  StudentProvider(
    String id,
  ) : this._internal(
          (ref) => student(
            ref as StudentRef,
            id,
          ),
          from: studentProvider,
          name: r'studentProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$studentHash,
          dependencies: StudentFamily._dependencies,
          allTransitiveDependencies: StudentFamily._allTransitiveDependencies,
          id: id,
        );

  StudentProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.id,
  }) : super.internal();

  final String id;

  @override
  Override overrideWith(
    FutureOr<Student?> Function(StudentRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: StudentProvider._internal(
        (ref) => create(ref as StudentRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        id: id,
      ),
    );
  }

  @override
  FutureProviderElement<Student?> createElement() {
    return _StudentProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StudentProvider && other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin StudentRef on FutureProviderRef<Student?> {
  /// The parameter `id` of this provider.
  String get id;
}

class _StudentProviderElement extends FutureProviderElement<Student?>
    with StudentRef {
  _StudentProviderElement(super.provider);

  @override
  String get id => (origin as StudentProvider).id;
}

String _$filteredStudentsHash() => r'ffbb3037ed0741ff836dd3091eac828737cf6a3a';

/// See also [filteredStudents].
@ProviderFor(filteredStudents)
final filteredStudentsProvider = FutureProvider<List<Student>>.internal(
  filteredStudents,
  name: r'filteredStudentsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$filteredStudentsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef FilteredStudentsRef = FutureProviderRef<List<Student>>;
String _$studentsByEnrollmentStatusHash() =>
    r'7d12dab0c02ef1cb458d8abf089bb0fd8d044c8b';

/// Provider to get students by enrollment status (trial/active/paused/inactive)
///
/// Copied from [studentsByEnrollmentStatus].
@ProviderFor(studentsByEnrollmentStatus)
const studentsByEnrollmentStatusProvider = StudentsByEnrollmentStatusFamily();

/// Provider to get students by enrollment status (trial/active/paused/inactive)
///
/// Copied from [studentsByEnrollmentStatus].
class StudentsByEnrollmentStatusFamily
    extends Family<AsyncValue<List<Student>>> {
  /// Provider to get students by enrollment status (trial/active/paused/inactive)
  ///
  /// Copied from [studentsByEnrollmentStatus].
  const StudentsByEnrollmentStatusFamily();

  /// Provider to get students by enrollment status (trial/active/paused/inactive)
  ///
  /// Copied from [studentsByEnrollmentStatus].
  StudentsByEnrollmentStatusProvider call(
    StudentStatus status,
  ) {
    return StudentsByEnrollmentStatusProvider(
      status,
    );
  }

  @override
  StudentsByEnrollmentStatusProvider getProviderOverride(
    covariant StudentsByEnrollmentStatusProvider provider,
  ) {
    return call(
      provider.status,
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
  String? get name => r'studentsByEnrollmentStatusProvider';
}

/// Provider to get students by enrollment status (trial/active/paused/inactive)
///
/// Copied from [studentsByEnrollmentStatus].
class StudentsByEnrollmentStatusProvider extends FutureProvider<List<Student>> {
  /// Provider to get students by enrollment status (trial/active/paused/inactive)
  ///
  /// Copied from [studentsByEnrollmentStatus].
  StudentsByEnrollmentStatusProvider(
    StudentStatus status,
  ) : this._internal(
          (ref) => studentsByEnrollmentStatus(
            ref as StudentsByEnrollmentStatusRef,
            status,
          ),
          from: studentsByEnrollmentStatusProvider,
          name: r'studentsByEnrollmentStatusProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$studentsByEnrollmentStatusHash,
          dependencies: StudentsByEnrollmentStatusFamily._dependencies,
          allTransitiveDependencies:
              StudentsByEnrollmentStatusFamily._allTransitiveDependencies,
          status: status,
        );

  StudentsByEnrollmentStatusProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.status,
  }) : super.internal();

  final StudentStatus status;

  @override
  Override overrideWith(
    FutureOr<List<Student>> Function(StudentsByEnrollmentStatusRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: StudentsByEnrollmentStatusProvider._internal(
        (ref) => create(ref as StudentsByEnrollmentStatusRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        status: status,
      ),
    );
  }

  @override
  FutureProviderElement<List<Student>> createElement() {
    return _StudentsByEnrollmentStatusProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StudentsByEnrollmentStatusProvider &&
        other.status == status;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, status.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin StudentsByEnrollmentStatusRef on FutureProviderRef<List<Student>> {
  /// The parameter `status` of this provider.
  StudentStatus get status;
}

class _StudentsByEnrollmentStatusProviderElement
    extends FutureProviderElement<List<Student>>
    with StudentsByEnrollmentStatusRef {
  _StudentsByEnrollmentStatusProviderElement(super.provider);

  @override
  StudentStatus get status =>
      (origin as StudentsByEnrollmentStatusProvider).status;
}

String _$trialStudentsHash() => r'd34a5e96f19ead2e7d2d6748deef43dde751c123';

/// Trial students provider
///
/// Copied from [trialStudents].
@ProviderFor(trialStudents)
final trialStudentsProvider = FutureProvider<List<Student>>.internal(
  trialStudents,
  name: r'trialStudentsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$trialStudentsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef TrialStudentsRef = FutureProviderRef<List<Student>>;
String _$studentSearchQueryHash() =>
    r'1e486155319bc9781b582049c15484e84aef92f1';

/// Search students provider
///
/// Copied from [StudentSearchQuery].
@ProviderFor(StudentSearchQuery)
final studentSearchQueryProvider =
    NotifierProvider<StudentSearchQuery, String>.internal(
  StudentSearchQuery.new,
  name: r'studentSearchQueryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$studentSearchQueryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$StudentSearchQuery = Notifier<String>;
String _$studentsNotifierHash() => r'd52a0f4f7082ff5efe596943c57b559a3bfda914';

/// Student list notifier for CRUD operations
///
/// Copied from [StudentsNotifier].
@ProviderFor(StudentsNotifier)
final studentsNotifierProvider =
    AsyncNotifierProvider<StudentsNotifier, List<Student>>.internal(
  StudentsNotifier.new,
  name: r'studentsNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$studentsNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$StudentsNotifier = AsyncNotifier<List<Student>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
