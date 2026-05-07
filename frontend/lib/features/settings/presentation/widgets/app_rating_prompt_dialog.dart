import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/notebook/notebook_alert_dialog.dart';
import '../../../../core/widgets/notebook/notebook_glyph.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../domain/services/app_review_trigger_service.dart';
import '../providers/app_review_providers.dart';

// ignore: widget-smoke-test
// Smoke test: test/features/settings/app_rating_prompt_dialog_test.dart

// ---------------------------------------------------------------------------
// 1단계: 만족도 확인 다이얼로그
// ---------------------------------------------------------------------------

/// Step 1 of the app rating flow: ask if the app is helpful.
class AppRatingPromptDialog extends StatelessWidget {
  const AppRatingPromptDialog({
    super.key,
    required this.onSatisfied,
    required this.onDissatisfied,
  });

  final VoidCallback onSatisfied;
  final VoidCallback onDissatisfied;

  @override
  Widget build(BuildContext context) {
    return NotebookAlertDialog(
      icon: const NotebookGlyph(
        NotebookGlyph.eighthNote,
        size: 32,
        semanticLabel: '음악 아이콘',
      ),
      title: AppStrings.ratingQuestion,
      content: Text(
        AppStrings.ratingPromptBody,
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.inkSecondary,
        ),
        textAlign: TextAlign.center,
      ),
      actions: [
        TextButton(
          onPressed: onDissatisfied,
          child: Text(
            AppStrings.ratingNo,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
        ),
        TextButton(
          onPressed: onSatisfied,
          child: Text(
            AppStrings.ratingYes,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 2단계 B: 피드백 수집 다이얼로그
// ---------------------------------------------------------------------------

/// Step 2B of the app rating flow: collect feedback when user is dissatisfied.
class AppRatingFeedbackDialog extends StatelessWidget {
  const AppRatingFeedbackDialog({
    super.key,
    required this.onFeedback,
    required this.onLater,
  });

  final VoidCallback onFeedback;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    return NotebookAlertDialog(
      title: AppStrings.ratingFeedbackQuestion,
      content: Text(
        AppStrings.ratingFeedbackBody,
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.inkSecondary,
        ),
        textAlign: TextAlign.center,
      ),
      actions: [
        TextButton(
          onPressed: onLater,
          child: Text(
            AppStrings.ratingLater,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
        ),
        TextButton(
          onPressed: onFeedback,
          child: Text(
            AppStrings.ratingSendFeedback,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Helper: show prompt if conditions are met
// ---------------------------------------------------------------------------

/// Shows the app rating prompt if all spec §2 conditions are satisfied.
///
/// Call this from a lesson-complete or practice-complete screen's
/// `initState` / `addPostFrameCallback`.
///
/// The 1.5 s delay matches spec §2.2 (wait for transition animation).
Future<void> showAppRatingPromptIfNeeded({
  required BuildContext context,
  required WidgetRef ref,
  required AppReviewTriggerContext triggerContext,
}) async {
  final service = ref.read(appReviewTriggerServiceProvider);
  final should = await service.shouldShowPrompt(triggerContext);
  if (!should || !context.mounted) return;

  // 1.5 s delay per spec §2.2 (wait for transition animation)
  await Future.delayed(const Duration(milliseconds: 1500));
  if (!context.mounted) return;

  // Capture navigator before any further awaits.
  final navigator = Navigator.of(context);

  await service.onPromptShown();

  // ignore: use_build_context_synchronously — mounted check performed above
  final result = await showDialog<_RatingResult>(
    context: context,
    barrierDismissible: false,
    builder: (_) => AppRatingPromptDialog(
      onSatisfied: () => navigator.pop(_RatingResult.satisfied),
      onDissatisfied: () => navigator.pop(_RatingResult.dissatisfied),
    ),
  );

  if (result == _RatingResult.satisfied) {
    await service.onSatisfied();
    return;
  }

  if (result == _RatingResult.dissatisfied) {
    // ignore: use_build_context_synchronously — navigator captured before awaits
    final feedbackResult = await showDialog<_FeedbackResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AppRatingFeedbackDialog(
        onFeedback: () => navigator.pop(_FeedbackResult.send),
        onLater: () => navigator.pop(_FeedbackResult.later),
      ),
    );

    if (feedbackResult == _FeedbackResult.send) {
      await service.onFeedbackSent();
      navigator.pushNamed('/settings/feedback');
    } else {
      await service.onDismissed();
    }
  }
}

// ---------------------------------------------------------------------------
// Internal enums
// ---------------------------------------------------------------------------

enum _RatingResult { satisfied, dissatisfied }

enum _FeedbackResult { send, later }

// ---------------------------------------------------------------------------
// Convenience factory for AppReviewTriggerContext
// ---------------------------------------------------------------------------

/// Creates a [AppReviewTriggerContext] for a teacher trigger point.
AppReviewTriggerContext teacherRatingContext({
  required int completedLessonCount,
  DateTime? firstInstallDate,
}) =>
    AppReviewTriggerContext(
      userRole: UserRole.teacher,
      completedLessonCount: completedLessonCount,
      firstInstallDate: firstInstallDate,
    );

/// Creates a [AppReviewTriggerContext] for a student trigger point.
AppReviewTriggerContext studentRatingContext({
  required int completedPracticeCount,
  DateTime? firstInstallDate,
}) =>
    AppReviewTriggerContext(
      userRole: UserRole.student,
      completedPracticeCount: completedPracticeCount,
      firstInstallDate: firstInstallDate,
    );
