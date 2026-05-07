// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lesson_note_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$studentLessonNotesHash() =>
    r'1a0416bea42e6fb578db1990d59f409c65df4ee1';

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

/// Lessons with notes for a student (sorted newest first).
///
/// Copied from [studentLessonNotes].
@ProviderFor(studentLessonNotes)
const studentLessonNotesProvider = StudentLessonNotesFamily();

/// Lessons with notes for a student (sorted newest first).
///
/// Copied from [studentLessonNotes].
class StudentLessonNotesFamily extends Family<AsyncValue<List<Lesson>>> {
  /// Lessons with notes for a student (sorted newest first).
  ///
  /// Copied from [studentLessonNotes].
  const StudentLessonNotesFamily();

  /// Lessons with notes for a student (sorted newest first).
  ///
  /// Copied from [studentLessonNotes].
  StudentLessonNotesProvider call(
    String studentId,
  ) {
    return StudentLessonNotesProvider(
      studentId,
    );
  }

  @override
  StudentLessonNotesProvider getProviderOverride(
    covariant StudentLessonNotesProvider provider,
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
  String? get name => r'studentLessonNotesProvider';
}

/// Lessons with notes for a student (sorted newest first).
///
/// Copied from [studentLessonNotes].
class StudentLessonNotesProvider extends FutureProvider<List<Lesson>> {
  /// Lessons with notes for a student (sorted newest first).
  ///
  /// Copied from [studentLessonNotes].
  StudentLessonNotesProvider(
    String studentId,
  ) : this._internal(
          (ref) => studentLessonNotes(
            ref as StudentLessonNotesRef,
            studentId,
          ),
          from: studentLessonNotesProvider,
          name: r'studentLessonNotesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$studentLessonNotesHash,
          dependencies: StudentLessonNotesFamily._dependencies,
          allTransitiveDependencies:
              StudentLessonNotesFamily._allTransitiveDependencies,
          studentId: studentId,
        );

  StudentLessonNotesProvider._internal(
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
    FutureOr<List<Lesson>> Function(StudentLessonNotesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: StudentLessonNotesProvider._internal(
        (ref) => create(ref as StudentLessonNotesRef),
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
  FutureProviderElement<List<Lesson>> createElement() {
    return _StudentLessonNotesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StudentLessonNotesProvider && other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin StudentLessonNotesRef on FutureProviderRef<List<Lesson>> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _StudentLessonNotesProviderElement
    extends FutureProviderElement<List<Lesson>> with StudentLessonNotesRef {
  _StudentLessonNotesProviderElement(super.provider);

  @override
  String get studentId => (origin as StudentLessonNotesProvider).studentId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
