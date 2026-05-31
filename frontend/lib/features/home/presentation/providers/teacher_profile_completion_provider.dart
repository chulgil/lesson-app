import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../onboarding/onboarding_facade.dart';
import '../../../settings/presentation/providers/teacher_settings_provider.dart';
import 'home_lesson_summary_provider.dart';

part 'teacher_profile_completion_provider.g.dart';

/// Whether the teacher has at least one active available time slot.
@Riverpod(keepAlive: true)
bool hasAvailableSlots(HasAvailableSlotsRef ref) {
  final settingsAsync = ref.watch(teacherSettingsProvider);
  return settingsAsync.valueOrNull?.availableSlots.any(
        (slot) => slot.isActive,
      ) ??
      false;
}

/// Whether the teacher has a real profile image set.
/// Filters out mock placeholder URLs and OAuth account avatars.
bool isTeacherProfileImageQuestEligible(String? image) {
  final value = image?.trim();
  if (value == null || value.isEmpty) return false;

  final uri = Uri.tryParse(value);
  final host = uri?.host.toLowerCase() ?? '';
  if (host == 'example.com' || host.endsWith('.example.com')) return false;
  if (host == 'googleusercontent.com' ||
      host.endsWith('.googleusercontent.com')) {
    return false;
  }

  return true;
}

/// Whether the teacher has a real profile image set.
@Riverpod(keepAlive: true)
bool hasProfileImage(HasProfileImageRef ref) {
  final profile = ref.watch(currentTeacherProfileProvider).valueOrNull;
  return isTeacherProfileImageQuestEligible(profile?.profileImage);
}

/// Whether the teacher has an introduction of at least 20 characters.
@Riverpod(keepAlive: true)
bool hasIntroduction(HasIntroductionRef ref) {
  final profile = ref.watch(currentTeacherProfileProvider).valueOrNull;
  return (profile?.introduction.length ?? 0) >= 20;
}

/// Whether the teacher has set a lesson price table.
@Riverpod(keepAlive: true)
bool hasPriceTable(HasPriceTableRef ref) {
  final settingsAsync = ref.watch(teacherSettingsProvider);
  final table = settingsAsync.valueOrNull?.lessonPriceTable;
  return table != null && table.isNotEmpty;
}

/// Whether the teacher has registered a bank account.
@Riverpod(keepAlive: true)
bool hasBankAccount(HasBankAccountRef ref) {
  final profile = ref.watch(currentTeacherProfileProvider).valueOrNull;
  if (profile == null) return false;
  final defaultAccount = profile.defaultBankAccount;
  return defaultAccount != null;
}

/// Whether the teacher has issued at least one subscription.
/// With auto-subscription (Plan B), having a lesson implies a subscription exists.
@Riverpod(keepAlive: true)
bool hasIssuedSubscription(HasIssuedSubscriptionRef ref) {
  return ref.watch(homeHasLessonsProvider);
}

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
@Riverpod(keepAlive: true)
int profileCompletionPercent(ProfileCompletionPercentRef ref) {
  var total = 0;

  // Setup Phase
  if (ref.watch(hasAvailableSlotsProvider)) total += 12;
  if (ref.watch(hasProfileImageProvider)) total += 10;
  if (ref.watch(hasIntroductionProvider)) total += 10;
  if (ref.watch(hasPriceTableProvider)) total += 8;
  if (ref.watch(hasBankAccountProvider)) total += 10;

  // Action Phase
  if (ref.watch(homeStudentsProvider).valueOrNull?.isNotEmpty == true) {
    total += 15;
  }
  if (ref.watch(hasIssuedSubscriptionProvider)) total += 20;
  if (ref.watch(homeHasCompletedLessonProvider)) total += 15;

  return total.clamp(0, 100);
}
