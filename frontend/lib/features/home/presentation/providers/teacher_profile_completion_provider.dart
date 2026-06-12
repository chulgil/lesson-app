import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../auth/auth_facade.dart' show currentUserIdProvider;
import '../../../onboarding/onboarding_facade.dart';
import '../../../schedule/schedule_facade.dart'
    show teacherAvailabilityProvider;
import '../../../settings/settings_facade.dart';
import 'assignment_summary_provider.dart';
import 'home_lesson_summary_provider.dart';

part 'teacher_profile_completion_provider.g.dart';

/// Whether the teacher has at least one active weekly schedule (운영시간).
///
/// W1 2026-06-11 — Source changed from `TeacherSettings.availableSlots`
/// (deprecated) to `TeacherAvailability.weeklySchedules` (SSOT per spec §5.4).
/// architect P0 #1 directive — schedule 도메인 단일 진실 소스.
@Riverpod(keepAlive: true)
bool hasAvailableSlots(HasAvailableSlotsRef ref) {
  final teacherId = ref.watch(currentUserIdProvider);
  final availabilityAsync = ref.watch(teacherAvailabilityProvider(teacherId));
  return availabilityAsync.valueOrNull?.weeklySchedules.any(
        (schedule) => schedule.isActive,
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

/// 2026-06-10 UX fix — 악기 설정 quest. 가격 설정의 prerequisite.
/// FE 가입 흐름에서 onboarding profile setup 단계 A 에 악기를 입력하나,
/// 빠뜨리거나 추후 추가하려는 경우 진입점이 모호했음 → quest 카드 명시.
@Riverpod(keepAlive: true)
bool hasInstruments(HasInstrumentsRef ref) {
  final profile = ref.watch(currentTeacherProfileProvider).valueOrNull;
  return (profile?.instruments.isNotEmpty ?? false);
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

/// 게이지 산정의 입력 — 11개 mandatory quest (Q1~Q10 + Q3b) + Q11 (보너스).
///
/// 순수 데이터 클래스 — provider 의존성과 분리되어 단위 테스트 가능.
class QuestCompletionInput {
  final bool hasSlots;
  final bool hasPhoto;
  final bool hasIntro;
  final bool hasInstruments;
  final bool hasPrice;
  final bool hasBankAccount;
  final bool hasStudents;
  final bool hasSubscription;
  final bool hasCompletedLesson;
  final bool hasLessonNote;
  final bool hasPracticeAssigned;

  /// Q11 — 게이지 가중치 0 (보너스 표시만).
  final bool isPhoneVerified;

  const QuestCompletionInput({
    required this.hasSlots,
    required this.hasPhoto,
    required this.hasIntro,
    required this.hasInstruments,
    required this.hasPrice,
    required this.hasBankAccount,
    required this.hasStudents,
    required this.hasSubscription,
    required this.hasCompletedLesson,
    required this.hasLessonNote,
    required this.hasPracticeAssigned,
    required this.isPhoneVerified,
  });
}

/// Q1~Q10 + Q3b 모두 완료 시 true — 게이지 100% 와 동치 (SC-6).
///
/// Q11 (보너스) 은 영향 없음.
bool isAllMandatoryQuestsCompleted(QuestCompletionInput input) {
  return input.hasSlots &&
      input.hasPhoto &&
      input.hasIntro &&
      input.hasInstruments &&
      input.hasPrice &&
      input.hasBankAccount &&
      input.hasStudents &&
      input.hasSubscription &&
      input.hasCompletedLesson &&
      input.hasLessonNote &&
      input.hasPracticeAssigned;
}

/// 게이지 산정 순수 함수 — SC-6 1:1 정합성 검증용.
///
/// 가중치 합 100 분배:
///   === Setup Phase (40%) — 6 quests ===
///   Q1.  Available slots          : 8
///   Q2.  Profile image            : 7
///   Q3.  Introduction             : 7
///   Q3b. Instruments              : 6   (W5 신규 weight)
///   Q4.  Lesson price table       : 6
///   Q5.  Bank account             : 6
///   === Action Phase (60%) — 5 quests ===
///   Q6.  First student invite     : 12
///   Q7.  First subscription       : 15
///   Q8.  First lesson completed   : 13
///   Q9.  First lesson note        : 10
///   Q10. First practice assigned  : 10
///   === Bonus (0%) ===
///   Q11. Phone verification       : 0   (보너스 — 게이지 미반영)
int computeProfileCompletionPercent(QuestCompletionInput input) {
  var total = 0;

  // Setup Phase (40%)
  if (input.hasSlots) total += 8;
  if (input.hasPhoto) total += 7;
  if (input.hasIntro) total += 7;
  if (input.hasInstruments) total += 6;
  if (input.hasPrice) total += 6;
  if (input.hasBankAccount) total += 6;

  // Action Phase (60%)
  if (input.hasStudents) total += 12;
  if (input.hasSubscription) total += 15;
  if (input.hasCompletedLesson) total += 13;
  if (input.hasLessonNote) total += 10;
  if (input.hasPracticeAssigned) total += 10;

  // Q11 (전화인증) 보너스 — 가중치 0.

  return total.clamp(0, 100);
}

/// Quest board completion percentage (0–100).
///
/// W5 SC-6 (spec §9.3) — 11개 mandatory quest (Q1~Q10 + Q3b 악기) 모두 완료 시 100%.
/// Q11 (전화인증) 은 보너스 — percent 에 영향 없음 (가중치 0).
@Riverpod(keepAlive: true)
int profileCompletionPercent(ProfileCompletionPercentRef ref) {
  final input = QuestCompletionInput(
    hasSlots: ref.watch(hasAvailableSlotsProvider),
    hasPhoto: ref.watch(hasProfileImageProvider),
    hasIntro: ref.watch(hasIntroductionProvider),
    hasInstruments: ref.watch(hasInstrumentsProvider),
    hasPrice: ref.watch(hasPriceTableProvider),
    hasBankAccount: ref.watch(hasBankAccountProvider),
    hasStudents:
        ref.watch(homeStudentsProvider).valueOrNull?.isNotEmpty == true,
    hasSubscription: ref.watch(hasIssuedSubscriptionProvider),
    hasCompletedLesson: ref.watch(homeHasCompletedLessonProvider),
    hasLessonNote: ref.watch(hasWrittenLessonNoteProvider),
    hasPracticeAssigned: ref.watch(hasAssignedPracticeProvider),
    isPhoneVerified: ref.watch(homeTeacherPhoneVerifiedProvider),
  );
  return computeProfileCompletionPercent(input);
}

/// Q1~Q10 + Q3b 11개 mandatory quest 모두 완료 여부.
///
/// 졸업 트리거 신호 — `profileCompletionPercent == 100` 과 동치 (SC-6).
@Riverpod(keepAlive: true)
bool allMandatoryQuestsCompleted(AllMandatoryQuestsCompletedRef ref) {
  final input = QuestCompletionInput(
    hasSlots: ref.watch(hasAvailableSlotsProvider),
    hasPhoto: ref.watch(hasProfileImageProvider),
    hasIntro: ref.watch(hasIntroductionProvider),
    hasInstruments: ref.watch(hasInstrumentsProvider),
    hasPrice: ref.watch(hasPriceTableProvider),
    hasBankAccount: ref.watch(hasBankAccountProvider),
    hasStudents:
        ref.watch(homeStudentsProvider).valueOrNull?.isNotEmpty == true,
    hasSubscription: ref.watch(hasIssuedSubscriptionProvider),
    hasCompletedLesson: ref.watch(homeHasCompletedLessonProvider),
    hasLessonNote: ref.watch(hasWrittenLessonNoteProvider),
    hasPracticeAssigned: ref.watch(hasAssignedPracticeProvider),
    isPhoneVerified: ref.watch(homeTeacherPhoneVerifiedProvider),
  );
  return isAllMandatoryQuestsCompleted(input);
}
