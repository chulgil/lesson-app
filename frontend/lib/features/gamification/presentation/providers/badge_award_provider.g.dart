// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'badge_award_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$checkBadgeEligibilityHash() =>
    r'172e63afd9e5318c19d21f8281b45c39c30e8006';

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

/// Check badge eligibility and return newly eligible badges.
///
/// Compares [autoBadgeConditions] against the student's current gamification
/// state. Returns only badges that satisfy conditions but are not yet earned.
///
/// Copied from [checkBadgeEligibility].
@ProviderFor(checkBadgeEligibility)
const checkBadgeEligibilityProvider = CheckBadgeEligibilityFamily();

/// Check badge eligibility and return newly eligible badges.
///
/// Compares [autoBadgeConditions] against the student's current gamification
/// state. Returns only badges that satisfy conditions but are not yet earned.
///
/// Copied from [checkBadgeEligibility].
class CheckBadgeEligibilityFamily
    extends Family<AsyncValue<List<PracticeBadge>>> {
  /// Check badge eligibility and return newly eligible badges.
  ///
  /// Compares [autoBadgeConditions] against the student's current gamification
  /// state. Returns only badges that satisfy conditions but are not yet earned.
  ///
  /// Copied from [checkBadgeEligibility].
  const CheckBadgeEligibilityFamily();

  /// Check badge eligibility and return newly eligible badges.
  ///
  /// Compares [autoBadgeConditions] against the student's current gamification
  /// state. Returns only badges that satisfy conditions but are not yet earned.
  ///
  /// Copied from [checkBadgeEligibility].
  CheckBadgeEligibilityProvider call(
    String studentId,
  ) {
    return CheckBadgeEligibilityProvider(
      studentId,
    );
  }

  @override
  CheckBadgeEligibilityProvider getProviderOverride(
    covariant CheckBadgeEligibilityProvider provider,
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
  String? get name => r'checkBadgeEligibilityProvider';
}

/// Check badge eligibility and return newly eligible badges.
///
/// Compares [autoBadgeConditions] against the student's current gamification
/// state. Returns only badges that satisfy conditions but are not yet earned.
///
/// Copied from [checkBadgeEligibility].
class CheckBadgeEligibilityProvider
    extends AutoDisposeFutureProvider<List<PracticeBadge>> {
  /// Check badge eligibility and return newly eligible badges.
  ///
  /// Compares [autoBadgeConditions] against the student's current gamification
  /// state. Returns only badges that satisfy conditions but are not yet earned.
  ///
  /// Copied from [checkBadgeEligibility].
  CheckBadgeEligibilityProvider(
    String studentId,
  ) : this._internal(
          (ref) => checkBadgeEligibility(
            ref as CheckBadgeEligibilityRef,
            studentId,
          ),
          from: checkBadgeEligibilityProvider,
          name: r'checkBadgeEligibilityProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$checkBadgeEligibilityHash,
          dependencies: CheckBadgeEligibilityFamily._dependencies,
          allTransitiveDependencies:
              CheckBadgeEligibilityFamily._allTransitiveDependencies,
          studentId: studentId,
        );

  CheckBadgeEligibilityProvider._internal(
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
    FutureOr<List<PracticeBadge>> Function(CheckBadgeEligibilityRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CheckBadgeEligibilityProvider._internal(
        (ref) => create(ref as CheckBadgeEligibilityRef),
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
  AutoDisposeFutureProviderElement<List<PracticeBadge>> createElement() {
    return _CheckBadgeEligibilityProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CheckBadgeEligibilityProvider &&
        other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin CheckBadgeEligibilityRef
    on AutoDisposeFutureProviderRef<List<PracticeBadge>> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _CheckBadgeEligibilityProviderElement
    extends AutoDisposeFutureProviderElement<List<PracticeBadge>>
    with CheckBadgeEligibilityRef {
  _CheckBadgeEligibilityProviderElement(super.provider);

  @override
  String get studentId => (origin as CheckBadgeEligibilityProvider).studentId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
