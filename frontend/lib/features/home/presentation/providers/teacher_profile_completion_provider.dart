import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../onboarding/onboarding_facade.dart';
import '../../../settings/presentation/providers/teacher_settings_provider.dart';
import 'assignment_summary_provider.dart';
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

/// Whether the teacher has written at least one lesson note (feedback).
@Riverpod(keepAlive: true)
bool hasWrittenLessonNote(HasWrittenLessonNoteRef ref) {
  return ref.watch(homeHasLessonNotesProvider);
}

/// Whether the teacher has assigned at least one practice item.
@Riverpod(keepAlive: true)
bool hasAssignedPractice(HasAssignedPracticeRef ref) {
  final summary = ref.watch(weeklyAssignmentSummaryProvider).valueOrNull;
  return (summary?.totalItems ?? 0) > 0;
}

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
@Riverpod(keepAlive: true)
int profileCompletionPercent(ProfileCompletionPercentRef ref) {
  var total = 0;

  // Setup Phase (40%)
  if (ref.watch(hasAvailableSlotsProvider)) total += 10;
  if (ref.watch(hasProfileImageProvider)) total += 8;
  if (ref.watch(hasIntroductionProvider)) total += 8;
  if (ref.watch(hasPriceTableProvider)) total += 7;
  if (ref.watch(hasBankAccountProvider)) total += 7;

  // Action Phase (60%)
  if (ref.watch(homeStudentsProvider).valueOrNull?.isNotEmpty == true) {
    total += 12;
  }
  if (ref.watch(hasIssuedSubscriptionProvider)) total += 15;
  if (ref.watch(homeHasCompletedLessonProvider)) total += 13;
  if (ref.watch(hasWrittenLessonNoteProvider)) total += 10;
  if (ref.watch(hasAssignedPracticeProvider)) total += 10;

  return total.clamp(0, 100);
}
