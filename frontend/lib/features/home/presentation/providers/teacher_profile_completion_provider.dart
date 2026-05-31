import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../onboarding/onboarding_facade.dart';
import '../../../settings/presentation/providers/teacher_settings_provider.dart';
import 'home_lesson_summary_provider.dart';

part 'teacher_profile_completion_provider.g.dart';

/// Whether the teacher has at least one active available time slot.
@Riverpod(keepAlive: true)
bool hasAvailableSlots(HasAvailableSlotsRef ref) {
  final settingsAsync = ref.watch(teacherSettingsProvider);
  return settingsAsync.valueOrNull?.availableSlots
          .any((slot) => slot.isActive) ??
      false;
}

/// Whether the teacher has a profile image set.
@Riverpod(keepAlive: true)
bool hasProfileImage(HasProfileImageRef ref) {
  final profile = ref.watch(currentTeacherProfileProvider).valueOrNull;
  return profile?.profileImage != null && profile!.profileImage!.isNotEmpty;
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
/// Weights:
///   I.   Name + Instrument (always done post-onboarding) : 15
///   II.  Available slots                                  : 15
///   III. First student                                    : 15
///   IV.  Profile image                                    : 15
///   V.   Introduction (20+ chars)                        : 15
///   VI.  Lesson price table                               : 10
///   VII. Phone verification                               : 10
///   (remaining 5% reserved for future video feature)
@Riverpod(keepAlive: true)
int profileCompletionPercent(ProfileCompletionPercentRef ref) {
  var total = 0;

  // Quest I — always completed after onboarding
  total += 15;

  if (ref.watch(hasAvailableSlotsProvider)) total += 15;
  if (ref.watch(homeStudentsProvider).valueOrNull?.isNotEmpty == true) {
    total += 15;
  }
  if (ref.watch(hasProfileImageProvider)) total += 15;
  if (ref.watch(hasIntroductionProvider)) total += 15;
  if (ref.watch(hasPriceTableProvider)) total += 10;
  if (ref.watch(homeTeacherPhoneVerifiedProvider)) total += 10;

  return total.clamp(0, 100);
}
