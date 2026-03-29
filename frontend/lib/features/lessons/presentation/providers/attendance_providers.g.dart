// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$studentAttendanceStatsHash() =>
    r'befcc170ebcfa070cc27172afc469bdc66b2024b';

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

/// Calculate attendance stats for a student from their lessons.
///
/// Copied from [studentAttendanceStats].
@ProviderFor(studentAttendanceStats)
const studentAttendanceStatsProvider = StudentAttendanceStatsFamily();

/// Calculate attendance stats for a student from their lessons.
///
/// Copied from [studentAttendanceStats].
class StudentAttendanceStatsFamily extends Family<AsyncValue<AttendanceStats>> {
  /// Calculate attendance stats for a student from their lessons.
  ///
  /// Copied from [studentAttendanceStats].
  const StudentAttendanceStatsFamily();

  /// Calculate attendance stats for a student from their lessons.
  ///
  /// Copied from [studentAttendanceStats].
  StudentAttendanceStatsProvider call(
    String studentId,
  ) {
    return StudentAttendanceStatsProvider(
      studentId,
    );
  }

  @override
  StudentAttendanceStatsProvider getProviderOverride(
    covariant StudentAttendanceStatsProvider provider,
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
  String? get name => r'studentAttendanceStatsProvider';
}

/// Calculate attendance stats for a student from their lessons.
///
/// Copied from [studentAttendanceStats].
class StudentAttendanceStatsProvider
    extends AutoDisposeFutureProvider<AttendanceStats> {
  /// Calculate attendance stats for a student from their lessons.
  ///
  /// Copied from [studentAttendanceStats].
  StudentAttendanceStatsProvider(
    String studentId,
  ) : this._internal(
          (ref) => studentAttendanceStats(
            ref as StudentAttendanceStatsRef,
            studentId,
          ),
          from: studentAttendanceStatsProvider,
          name: r'studentAttendanceStatsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$studentAttendanceStatsHash,
          dependencies: StudentAttendanceStatsFamily._dependencies,
          allTransitiveDependencies:
              StudentAttendanceStatsFamily._allTransitiveDependencies,
          studentId: studentId,
        );

  StudentAttendanceStatsProvider._internal(
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
    FutureOr<AttendanceStats> Function(StudentAttendanceStatsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: StudentAttendanceStatsProvider._internal(
        (ref) => create(ref as StudentAttendanceStatsRef),
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
  AutoDisposeFutureProviderElement<AttendanceStats> createElement() {
    return _StudentAttendanceStatsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StudentAttendanceStatsProvider &&
        other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin StudentAttendanceStatsRef
    on AutoDisposeFutureProviderRef<AttendanceStats> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _StudentAttendanceStatsProviderElement
    extends AutoDisposeFutureProviderElement<AttendanceStats>
    with StudentAttendanceStatsRef {
  _StudentAttendanceStatsProviderElement(super.provider);

  @override
  String get studentId => (origin as StudentAttendanceStatsProvider).studentId;
}

String _$teacherAttendanceOverviewHash() =>
    r'382a839d01dbb9c97693537006306ca849e0a6ec';

/// Teacher-wide attendance overview: per-student rates + recent absences.
///
/// Copied from [teacherAttendanceOverview].
@ProviderFor(teacherAttendanceOverview)
final teacherAttendanceOverviewProvider =
    AutoDisposeFutureProvider<TeacherAttendanceOverview>.internal(
  teacherAttendanceOverview,
  name: r'teacherAttendanceOverviewProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$teacherAttendanceOverviewHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef TeacherAttendanceOverviewRef
    = AutoDisposeFutureProviderRef<TeacherAttendanceOverview>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
