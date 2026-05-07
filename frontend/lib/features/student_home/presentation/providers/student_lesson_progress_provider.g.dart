// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_lesson_progress_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$studentLessonProgressHash() =>
    r'8d173b082ab53cfc7fe64204522482840695ac4c';

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

/// See also [studentLessonProgress].
@ProviderFor(studentLessonProgress)
const studentLessonProgressProvider = StudentLessonProgressFamily();

/// See also [studentLessonProgress].
class StudentLessonProgressFamily
    extends Family<AsyncValue<List<StudentLessonProgressItem>>> {
  /// See also [studentLessonProgress].
  const StudentLessonProgressFamily();

  /// See also [studentLessonProgress].
  StudentLessonProgressProvider call(String studentId) {
    return StudentLessonProgressProvider(studentId);
  }

  @override
  StudentLessonProgressProvider getProviderOverride(
    covariant StudentLessonProgressProvider provider,
  ) {
    return call(provider.studentId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'studentLessonProgressProvider';
}

/// See also [studentLessonProgress].
class StudentLessonProgressProvider
    extends FutureProvider<List<StudentLessonProgressItem>> {
  /// See also [studentLessonProgress].
  StudentLessonProgressProvider(String studentId)
    : this._internal(
        (ref) =>
            studentLessonProgress(ref as StudentLessonProgressRef, studentId),
        from: studentLessonProgressProvider,
        name: r'studentLessonProgressProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$studentLessonProgressHash,
        dependencies: StudentLessonProgressFamily._dependencies,
        allTransitiveDependencies:
            StudentLessonProgressFamily._allTransitiveDependencies,
        studentId: studentId,
      );

  StudentLessonProgressProvider._internal(
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
    FutureOr<List<StudentLessonProgressItem>> Function(
      StudentLessonProgressRef provider,
    )
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: StudentLessonProgressProvider._internal(
        (ref) => create(ref as StudentLessonProgressRef),
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
  FutureProviderElement<List<StudentLessonProgressItem>> createElement() {
    return _StudentLessonProgressProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StudentLessonProgressProvider &&
        other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin StudentLessonProgressRef
    on FutureProviderRef<List<StudentLessonProgressItem>> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _StudentLessonProgressProviderElement
    extends FutureProviderElement<List<StudentLessonProgressItem>>
    with StudentLessonProgressRef {
  _StudentLessonProgressProviderElement(super.provider);

  @override
  String get studentId => (origin as StudentLessonProgressProvider).studentId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
