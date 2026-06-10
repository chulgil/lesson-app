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
String _$hasInstrumentsHash() => r'7993c4eb48b9a28b9271f68f73e7441a55e874c2';

/// 2026-06-10 UX fix — 악기 설정 quest. 가격 설정의 prerequisite.
/// FE 가입 흐름에서 onboarding profile setup 단계 A 에 악기를 입력하나,
/// 빠뜨리거나 추후 추가하려는 경우 진입점이 모호했음 → quest 카드 명시.
///
/// Copied from [hasInstruments].
@ProviderFor(hasInstruments)
final hasInstrumentsProvider = Provider<bool>.internal(
  hasInstruments,
  name: r'hasInstrumentsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$hasInstrumentsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef HasInstrumentsRef = ProviderRef<bool>;
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
String _$hasWrittenLessonNoteHash() =>
    r'9991dbe87cd44e25b0ba760e938e4f424196a054';

/// Whether the teacher has written at least one lesson note (feedback).
///
/// Copied from [hasWrittenLessonNote].
@ProviderFor(hasWrittenLessonNote)
final hasWrittenLessonNoteProvider = Provider<bool>.internal(
  hasWrittenLessonNote,
  name: r'hasWrittenLessonNoteProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$hasWrittenLessonNoteHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef HasWrittenLessonNoteRef = ProviderRef<bool>;
String _$hasAssignedPracticeHash() =>
    r'6a2b976093b59a0f16fda2dc4bf469ec19137639';

/// Whether the teacher has assigned at least one practice item.
///
/// Copied from [hasAssignedPractice].
@ProviderFor(hasAssignedPractice)
final hasAssignedPracticeProvider = Provider<bool>.internal(
  hasAssignedPractice,
  name: r'hasAssignedPracticeProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$hasAssignedPracticeHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef HasAssignedPracticeRef = ProviderRef<bool>;
String _$profileCompletionPercentHash() =>
    r'ee330208f625ea8bcb670aabe3e33be15deb7392';

/// Quest board completion percentage (0–100).
///
/// 10 quests total (phone verification is mandatory at signup):
///   === Setup Phase (40%) ===
///   I.   Available slots          : 10
///   II.  Profile image            : 8
///   III. Introduction             : 8
///   IV.  Lesson price table       : 7
///   V.   Bank account             : 7
///   === Action Phase (60%) ===
///   VI.  First student invite     : 12
///   VII. First subscription       : 15
///   VIII.First lesson completed   : 13
///   IX.  First lesson note        : 10
///   X.   First practice assigned  : 10
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
