import '../entities/app_review_state.dart';

/// Repository interface for persisting [AppReviewState].
abstract class AppReviewStateRepository {
  Future<AppReviewState> getState();
  Future<void> saveState(AppReviewState state);

  /// Reset to initial state (debug / test use only).
  Future<void> reset();
}
