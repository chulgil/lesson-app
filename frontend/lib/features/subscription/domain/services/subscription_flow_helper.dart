import '../../../profile/domain/entities/teacher_settings.dart';
import '../../../schedule/domain/entities/unified_lesson_request.dart';

/// Pure-function helpers for subscription flow branching decisions.
///
/// Used after time confirmation to decide:
/// - Auto-complete (trial free) vs. send proposal (trial paid / regular)
/// - Suggested price lookup from the teacher's price table
class SubscriptionFlowHelper {
  SubscriptionFlowHelper._();

  /// Whether the request should skip the proposal step and complete directly.
  ///
  /// Only true when: trial lesson + teacher has trialLessonFree enabled.
  static bool shouldAutoComplete(
    UnifiedLessonRequest request,
    TeacherSettings settings,
  ) {
    return request.type == LessonRequestType.trial && settings.trialLessonFree;
  }

  /// Whether the teacher needs to send a subscription proposal.
  ///
  /// True for: all regular lessons, or paid trial lessons.
  static bool shouldSendProposal(
    UnifiedLessonRequest request,
    TeacherSettings settings,
  ) {
    return !shouldAutoComplete(request, settings);
  }

  /// Suggested price for the request, based on the teacher's price table.
  ///
  /// Returns:
  /// - `0` for free trial lessons
  /// - Matched price from `lessonPriceTable[instrument][experience]`
  /// - `null` if no matching price found
  static int? suggestedPriceForRequest(
    UnifiedLessonRequest request,
    TeacherSettings settings,
  ) {
    if (request.type == LessonRequestType.trial && settings.trialLessonFree) {
      return 0;
    }
    return settings.getPriceByExperience(request.instrument, request.experience);
  }
}
