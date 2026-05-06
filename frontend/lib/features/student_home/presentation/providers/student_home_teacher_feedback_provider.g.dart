// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_home_teacher_feedback_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$studentHomeLatestTeacherFeedbackHash() =>
    r'3ce751f45de9a6ac2430312428ff492ae60d5f6f';

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

/// See also [studentHomeLatestTeacherFeedback].
@ProviderFor(studentHomeLatestTeacherFeedback)
const studentHomeLatestTeacherFeedbackProvider =
    StudentHomeLatestTeacherFeedbackFamily();

/// See also [studentHomeLatestTeacherFeedback].
class StudentHomeLatestTeacherFeedbackFamily
    extends Family<AsyncValue<Lesson?>> {
  /// See also [studentHomeLatestTeacherFeedback].
  const StudentHomeLatestTeacherFeedbackFamily();

  /// See also [studentHomeLatestTeacherFeedback].
  StudentHomeLatestTeacherFeedbackProvider call(String studentId) {
    return StudentHomeLatestTeacherFeedbackProvider(studentId);
  }

  @override
  StudentHomeLatestTeacherFeedbackProvider getProviderOverride(
    covariant StudentHomeLatestTeacherFeedbackProvider provider,
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
  String? get name => r'studentHomeLatestTeacherFeedbackProvider';
}

/// See also [studentHomeLatestTeacherFeedback].
class StudentHomeLatestTeacherFeedbackProvider
    extends AutoDisposeFutureProvider<Lesson?> {
  /// See also [studentHomeLatestTeacherFeedback].
  StudentHomeLatestTeacherFeedbackProvider(String studentId)
    : this._internal(
        (ref) => studentHomeLatestTeacherFeedback(
          ref as StudentHomeLatestTeacherFeedbackRef,
          studentId,
        ),
        from: studentHomeLatestTeacherFeedbackProvider,
        name: r'studentHomeLatestTeacherFeedbackProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$studentHomeLatestTeacherFeedbackHash,
        dependencies: StudentHomeLatestTeacherFeedbackFamily._dependencies,
        allTransitiveDependencies:
            StudentHomeLatestTeacherFeedbackFamily._allTransitiveDependencies,
        studentId: studentId,
      );

  StudentHomeLatestTeacherFeedbackProvider._internal(
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
    FutureOr<Lesson?> Function(StudentHomeLatestTeacherFeedbackRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: StudentHomeLatestTeacherFeedbackProvider._internal(
        (ref) => create(ref as StudentHomeLatestTeacherFeedbackRef),
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
  AutoDisposeFutureProviderElement<Lesson?> createElement() {
    return _StudentHomeLatestTeacherFeedbackProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StudentHomeLatestTeacherFeedbackProvider &&
        other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin StudentHomeLatestTeacherFeedbackRef
    on AutoDisposeFutureProviderRef<Lesson?> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _StudentHomeLatestTeacherFeedbackProviderElement
    extends AutoDisposeFutureProviderElement<Lesson?>
    with StudentHomeLatestTeacherFeedbackRef {
  _StudentHomeLatestTeacherFeedbackProviderElement(super.provider);

  @override
  String get studentId =>
      (origin as StudentHomeLatestTeacherFeedbackProvider).studentId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
