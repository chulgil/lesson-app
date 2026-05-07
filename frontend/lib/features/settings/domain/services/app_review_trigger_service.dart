import '../../../auth/domain/entities/user_role.dart';
import '../repositories/app_release_repository.dart';
import '../repositories/app_review_state_repository.dart';

/// Context values required for trigger condition evaluation.
class AppReviewTriggerContext {
  const AppReviewTriggerContext({
    required this.userRole,
    this.completedLessonCount = 0,
    this.completedPracticeCount = 0,
    this.firstInstallDate,
  });

  /// User role determines which metric to check.
  final UserRole userRole;

  /// Completed lessons (teacher eligibility check).
  final int completedLessonCount;

  /// Completed practice sessions (student eligibility check).
  final int completedPracticeCount;

  /// Date of first install. Null = unknown (condition skipped).
  final DateTime? firstInstallDate;
}

/// Determines whether to show the app rating prompt and
/// records state transitions per spec §5.
///
/// Spec: `docs/specs/settings/app_rating_prompt_spec.md` §2–5
class AppReviewTriggerService {
  AppReviewTriggerService({
    required AppReviewStateRepository stateRepository,
    required AppReviewClient reviewClient,
  })  : _stateRepository = stateRepository,
        _reviewClient = reviewClient;

  final AppReviewStateRepository _stateRepository;
  final AppReviewClient _reviewClient;

  /// Returns true when all conditions from spec §2 are satisfied.
  Future<bool> shouldShowPrompt(AppReviewTriggerContext context) async {
    final state = await _stateRepository.getState();

    if (state.isPermanentlySuppressed) return false;
    if (!state.canShowAgain) return false;

    if (context.firstInstallDate != null) {
      final daysSinceInstall =
          DateTime.now().difference(context.firstInstallDate!).inDays;
      if (daysSinceInstall < 7) return false;
    }

    if (context.userRole == UserRole.teacher) {
      if (context.completedLessonCount < 5) return false;
    } else {
      if (context.completedPracticeCount < 3) return false;
    }

    return true;
  }

  /// Call when the prompt dialog is first displayed.
  /// Records [lastPromptDate] so the 90-day cooldown starts.
  Future<void> onPromptShown() async {
    final state = await _stateRepository.getState();
    await _stateRepository.saveState(
      state.copyWith(lastPromptDate: DateTime.now()),
    );
  }

  /// Satisfied path (스토어 평가 요청).
  Future<void> onSatisfied() async {
    final state = await _stateRepository.getState();
    await _reviewClient.requestReview();
    await _stateRepository.saveState(
      state.copyWith(
        hasRated: true,
        lastPromptDate: DateTime.now(),
      ),
    );
  }

  /// Dissatisfied + feedback sent path.
  Future<void> onFeedbackSent() async {
    final state = await _stateRepository.getState();
    await _stateRepository.saveState(
      state.copyWith(lastPromptDate: DateTime.now()),
    );
  }

  /// Dissatisfied + "나중에" dismissed path.
  Future<void> onDismissed() async {
    final state = await _stateRepository.getState();
    await _stateRepository.saveState(
      state.copyWith(
        dismissCount: state.dismissCount + 1,
        lastPromptDate: DateTime.now(),
      ),
    );
  }
}
