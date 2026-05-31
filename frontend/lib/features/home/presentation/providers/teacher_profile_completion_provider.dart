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

/// Profile completion percentage (0–100).
///
/// Weights (5 quests — phone verification is mandatory at signup, not a quest):
///   I.   Available slots                                  : 25
///   II.  Profile image                                    : 20
///   III. Introduction (20+ chars)                         : 20
///   IV.  Lesson price table                               : 15
///   V.   First student (last — requires setup complete)   : 20
@Riverpod(keepAlive: true)
int profileCompletionPercent(ProfileCompletionPercentRef ref) {
  var total = 0;

  if (ref.watch(hasAvailableSlotsProvider)) total += 25;
  if (ref.watch(hasProfileImageProvider)) total += 20;
  if (ref.watch(hasIntroductionProvider)) total += 20;
  if (ref.watch(hasPriceTableProvider)) total += 15;
  if (ref.watch(homeStudentsProvider).valueOrNull?.isNotEmpty == true) {
    total += 20;
  }

  return total.clamp(0, 100);
}
