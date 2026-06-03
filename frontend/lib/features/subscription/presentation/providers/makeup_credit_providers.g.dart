// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'makeup_credit_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$makeupCreditRepositoryHash() =>
    r'f02ce90598e751fd59da12acde0931a233952412';

/// Repository provider — switches between Mock and Remote (#432).
///
/// Copied from [makeupCreditRepository].
@ProviderFor(makeupCreditRepository)
final makeupCreditRepositoryProvider =
    Provider<MakeupCreditRepository>.internal(
  makeupCreditRepository,
  name: r'makeupCreditRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$makeupCreditRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef MakeupCreditRepositoryRef = ProviderRef<MakeupCreditRepository>;
String _$studentMakeupCreditsHash() =>
    r'9447d054073d13169013a01d195ffa1fa37f2ecd';

/// Student-side: all of the signed-in student's makeup credits (used + unused).
///
/// Copied from [studentMakeupCredits].
@ProviderFor(studentMakeupCredits)
final studentMakeupCreditsProvider =
    AutoDisposeFutureProvider<List<MakeupCredit>>.internal(
  studentMakeupCredits,
  name: r'studentMakeupCreditsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$studentMakeupCreditsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef StudentMakeupCreditsRef
    = AutoDisposeFutureProviderRef<List<MakeupCredit>>;
String _$studentMakeupCreditBalanceHash() =>
    r'c802d3f06c920328700cef326ef136e33b19ec94';

/// Student-side: spendable balance (not used, not expired) for booking flows.
///
/// Copied from [studentMakeupCreditBalance].
@ProviderFor(studentMakeupCreditBalance)
final studentMakeupCreditBalanceProvider =
    AutoDisposeFutureProvider<MakeupCreditBalance>.internal(
  studentMakeupCreditBalance,
  name: r'studentMakeupCreditBalanceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$studentMakeupCreditBalanceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef StudentMakeupCreditBalanceRef
    = AutoDisposeFutureProviderRef<MakeupCreditBalance>;
String _$teacherMakeupCreditsHash() =>
    r'24d747c160c0c549a14f8d7cb5c181b1aa3c50dd';

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

/// Teacher-side: makeup credits issued for one student.
///
/// Copied from [teacherMakeupCredits].
@ProviderFor(teacherMakeupCredits)
const teacherMakeupCreditsProvider = TeacherMakeupCreditsFamily();

/// Teacher-side: makeup credits issued for one student.
///
/// Copied from [teacherMakeupCredits].
class TeacherMakeupCreditsFamily
    extends Family<AsyncValue<List<MakeupCredit>>> {
  /// Teacher-side: makeup credits issued for one student.
  ///
  /// Copied from [teacherMakeupCredits].
  const TeacherMakeupCreditsFamily();

  /// Teacher-side: makeup credits issued for one student.
  ///
  /// Copied from [teacherMakeupCredits].
  TeacherMakeupCreditsProvider call(
    String studentId,
  ) {
    return TeacherMakeupCreditsProvider(
      studentId,
    );
  }

  @override
  TeacherMakeupCreditsProvider getProviderOverride(
    covariant TeacherMakeupCreditsProvider provider,
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
  String? get name => r'teacherMakeupCreditsProvider';
}

/// Teacher-side: makeup credits issued for one student.
///
/// Copied from [teacherMakeupCredits].
class TeacherMakeupCreditsProvider
    extends AutoDisposeFutureProvider<List<MakeupCredit>> {
  /// Teacher-side: makeup credits issued for one student.
  ///
  /// Copied from [teacherMakeupCredits].
  TeacherMakeupCreditsProvider(
    String studentId,
  ) : this._internal(
          (ref) => teacherMakeupCredits(
            ref as TeacherMakeupCreditsRef,
            studentId,
          ),
          from: teacherMakeupCreditsProvider,
          name: r'teacherMakeupCreditsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$teacherMakeupCreditsHash,
          dependencies: TeacherMakeupCreditsFamily._dependencies,
          allTransitiveDependencies:
              TeacherMakeupCreditsFamily._allTransitiveDependencies,
          studentId: studentId,
        );

  TeacherMakeupCreditsProvider._internal(
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
    FutureOr<List<MakeupCredit>> Function(TeacherMakeupCreditsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TeacherMakeupCreditsProvider._internal(
        (ref) => create(ref as TeacherMakeupCreditsRef),
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
  AutoDisposeFutureProviderElement<List<MakeupCredit>> createElement() {
    return _TeacherMakeupCreditsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TeacherMakeupCreditsProvider &&
        other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin TeacherMakeupCreditsRef
    on AutoDisposeFutureProviderRef<List<MakeupCredit>> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _TeacherMakeupCreditsProviderElement
    extends AutoDisposeFutureProviderElement<List<MakeupCredit>>
    with TeacherMakeupCreditsRef {
  _TeacherMakeupCreditsProviderElement(super.provider);

  @override
  String get studentId => (origin as TeacherMakeupCreditsProvider).studentId;
}

String _$makeupCreditActionsHash() =>
    r'a3d7e9be10bc593fca155f0b6431cb25c7c821de';

/// Teacher-side actions — grant (§4.4) + revoke, with cache invalidation.
///
/// Copied from [makeupCreditActions].
@ProviderFor(makeupCreditActions)
final makeupCreditActionsProvider =
    AutoDisposeProvider<MakeupCreditActions>.internal(
  makeupCreditActions,
  name: r'makeupCreditActionsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$makeupCreditActionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef MakeupCreditActionsRef = AutoDisposeProviderRef<MakeupCreditActions>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
