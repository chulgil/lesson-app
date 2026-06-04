import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/entities/user_role.dart';
import '../../domain/services/app_review_trigger_service.dart';
import '../providers/app_review_providers.dart';
import 'app_rating_feedback_dialog.dart';
import 'app_rating_prompt_dialog.dart';

/// Show the app rating flow only when [AppReviewTriggerService] allows it.
///
/// Call sites: lesson complete (teacher), practice session complete (student).
/// Spec: `docs/specs/settings/app_rating_prompt_spec.md` §2–5.
///
/// Returns immediately (no-op) when:
/// - State is permanently suppressed (hasRated || dismissCount ≥ 3)
/// - 90-day cooldown not elapsed
/// - User has fewer completed events than threshold (teacher: 5 lessons, student: 3 practices)
/// - Within first 7 days since install
Future<void> showAppRatingPromptIfNeeded({
  required BuildContext context,
  required WidgetRef ref,
  required UserRole userRole,
  int completedLessonCount = 0,
  int completedPracticeCount = 0,
  DateTime? firstInstallDate,
}) async {
  final service = ref.read(appReviewTriggerServiceProvider);

  final triggerContext = AppReviewTriggerContext(
    userRole: userRole,
    completedLessonCount: completedLessonCount,
    completedPracticeCount: completedPracticeCount,
    firstInstallDate: firstInstallDate,
  );

  final shouldShow = await service.shouldShowPrompt(triggerContext);
  if (!shouldShow || !context.mounted) return;

  await service.onPromptShown();
  if (!context.mounted) return;

  final satisfied = await AppRatingPromptDialog.show(context);
  if (satisfied == null) {
    // Barrier dismissed — treat as dismissed.
    await service.onDismissed();
    return;
  }

  if (satisfied) {
    await service.onSatisfied();
    return;
  }

  // Dissatisfied — collect feedback.
  if (!context.mounted) return;
  final feedback = await AppRatingFeedbackDialog.show(context);
  if (feedback == null) {
    await service.onDismissed();
  } else {
    await service.onFeedbackSent();
    // TODO: dispatch feedback to BE (when feedback endpoint lands).
  }
}
