// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'teacher_profile_completion_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$hasAvailableSlotsHash() => r'4e17ab5ec32f2999fceedd055e5dffce7a04a9d9';

/// Whether the teacher has at least one active available time slot.
///
/// Copied from [hasAvailableSlots].
@ProviderFor(hasAvailableSlots)
final hasAvailableSlotsProvider = Provider<bool>.internal(
  hasAvailableSlots,
  name: r'hasAvailableSlotsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$hasAvailableSlotsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef HasAvailableSlotsRef = ProviderRef<bool>;
String _$hasProfileImageHash() => r'a9a5175cd8ef534a6f99da6ece956869cdfb2ca7';

/// Whether the teacher has a real profile image set.
///
/// Copied from [hasProfileImage].
@ProviderFor(hasProfileImage)
final hasProfileImageProvider = Provider<bool>.internal(
  hasProfileImage,
  name: r'hasProfileImageProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$hasProfileImageHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef HasProfileImageRef = ProviderRef<bool>;
String _$hasIntroductionHash() => r'cc3efffc4b8e7a73eaf3b22e7ecc0debf2d1b8d2';

/// Whether the teacher has an introduction of at least 20 characters.
///
/// Copied from [hasIntroduction].
@ProviderFor(hasIntroduction)
final hasIntroductionProvider = Provider<bool>.internal(
  hasIntroduction,
  name: r'hasIntroductionProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$hasIntroductionHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef HasIntroductionRef = ProviderRef<bool>;
String _$hasPriceTableHash() => r'68b50ac005bbf33344daf58b8ac2ea682915d71a';

/// Whether the teacher has set a lesson price table.
///
/// Copied from [hasPriceTable].
@ProviderFor(hasPriceTable)
final hasPriceTableProvider = Provider<bool>.internal(
  hasPriceTable,
  name: r'hasPriceTableProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$hasPriceTableHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef HasPriceTableRef = ProviderRef<bool>;
String _$hasBankAccountHash() => r'24b8179f8863b39cd5ecf6b0b4ad1c39d46244cd';

/// Whether the teacher has registered a bank account.
///
/// Copied from [hasBankAccount].
@ProviderFor(hasBankAccount)
final hasBankAccountProvider = Provider<bool>.internal(
  hasBankAccount,
  name: r'hasBankAccountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$hasBankAccountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef HasBankAccountRef = ProviderRef<bool>;
String _$hasIssuedSubscriptionHash() =>
    r'31d4bd5f238eac272337fa9d1e80a533807a45a9';

/// Whether the teacher has issued at least one subscription.
/// With auto-subscription (Plan B), having a lesson implies a subscription exists.
///
/// Copied from [hasIssuedSubscription].
@ProviderFor(hasIssuedSubscription)
final hasIssuedSubscriptionProvider = Provider<bool>.internal(
  hasIssuedSubscription,
  name: r'hasIssuedSubscriptionProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$hasIssuedSubscriptionHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef HasIssuedSubscriptionRef = ProviderRef<bool>;
String _$profileCompletionPercentHash() =>
    r'9bb1cade6332c5a2df2e88c46dfa2d9c37288d09';

/// Quest board completion percentage (0–100).
///
/// 8 quests total (phone verification is mandatory at signup):
///   === Setup Phase (50%) ===
///   I.   Available slots          : 12
///   II.  Profile image            : 10
///   III. Introduction             : 10
///   IV.  Lesson price table       : 8
///   V.   Bank account             : 10
///   === Action Phase (50%) ===
///   VI.  First student invite     : 15
///   VII. First subscription       : 20
///   VIII.First lesson completed   : 15
///
/// Copied from [profileCompletionPercent].
@ProviderFor(profileCompletionPercent)
final profileCompletionPercentProvider = Provider<int>.internal(
  profileCompletionPercent,
  name: r'profileCompletionPercentProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$profileCompletionPercentHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ProfileCompletionPercentRef = ProviderRef<int>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
