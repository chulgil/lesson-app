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
String _$profileCompletionPercentHash() =>
    r'f01c55116d10e8aedc1987a3019cb0cd42cfdc50';

/// Profile completion percentage (0–100).
///
/// Weights (5 quests — phone verification is mandatory at signup, not a quest):
///   I.   Available slots                                  : 25
///   II.  Profile image                                    : 20
///   III. Introduction (20+ chars)                         : 20
///   IV.  Lesson price table                               : 15
///   V.   First student (last — requires setup complete)   : 20
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
