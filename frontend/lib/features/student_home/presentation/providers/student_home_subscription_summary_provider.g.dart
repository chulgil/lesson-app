// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_home_subscription_summary_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$studentHomeSubscriptionSummariesHash() =>
    r'ae0291d63f2ae16a6e9c8f21a8c85d806bb31bb6';

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

/// See also [studentHomeSubscriptionSummaries].
@ProviderFor(studentHomeSubscriptionSummaries)
const studentHomeSubscriptionSummariesProvider =
    StudentHomeSubscriptionSummariesFamily();

/// See also [studentHomeSubscriptionSummaries].
class StudentHomeSubscriptionSummariesFamily
    extends Family<AsyncValue<List<StudentHomeSubscriptionSummaryItem>>> {
  /// See also [studentHomeSubscriptionSummaries].
  const StudentHomeSubscriptionSummariesFamily();

  /// See also [studentHomeSubscriptionSummaries].
  StudentHomeSubscriptionSummariesProvider call(
    String studentId,
  ) {
    return StudentHomeSubscriptionSummariesProvider(
      studentId,
    );
  }

  @override
  StudentHomeSubscriptionSummariesProvider getProviderOverride(
    covariant StudentHomeSubscriptionSummariesProvider provider,
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
  String? get name => r'studentHomeSubscriptionSummariesProvider';
}

/// See also [studentHomeSubscriptionSummaries].
class StudentHomeSubscriptionSummariesProvider
    extends AutoDisposeFutureProvider<
        List<StudentHomeSubscriptionSummaryItem>> {
  /// See also [studentHomeSubscriptionSummaries].
  StudentHomeSubscriptionSummariesProvider(
    String studentId,
  ) : this._internal(
          (ref) => studentHomeSubscriptionSummaries(
            ref as StudentHomeSubscriptionSummariesRef,
            studentId,
          ),
          from: studentHomeSubscriptionSummariesProvider,
          name: r'studentHomeSubscriptionSummariesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$studentHomeSubscriptionSummariesHash,
          dependencies: StudentHomeSubscriptionSummariesFamily._dependencies,
          allTransitiveDependencies:
              StudentHomeSubscriptionSummariesFamily._allTransitiveDependencies,
          studentId: studentId,
        );

  StudentHomeSubscriptionSummariesProvider._internal(
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
    FutureOr<List<StudentHomeSubscriptionSummaryItem>> Function(
            StudentHomeSubscriptionSummariesRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: StudentHomeSubscriptionSummariesProvider._internal(
        (ref) => create(ref as StudentHomeSubscriptionSummariesRef),
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
  AutoDisposeFutureProviderElement<List<StudentHomeSubscriptionSummaryItem>>
      createElement() {
    return _StudentHomeSubscriptionSummariesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StudentHomeSubscriptionSummariesProvider &&
        other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin StudentHomeSubscriptionSummariesRef
    on AutoDisposeFutureProviderRef<List<StudentHomeSubscriptionSummaryItem>> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _StudentHomeSubscriptionSummariesProviderElement
    extends AutoDisposeFutureProviderElement<
        List<StudentHomeSubscriptionSummaryItem>>
    with StudentHomeSubscriptionSummariesRef {
  _StudentHomeSubscriptionSummariesProviderElement(super.provider);

  @override
  String get studentId =>
      (origin as StudentHomeSubscriptionSummariesProvider).studentId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
