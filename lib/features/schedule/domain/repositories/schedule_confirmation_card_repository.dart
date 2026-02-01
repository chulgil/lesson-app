import '../entities/schedule_confirmation_card.dart';

/// Repository interface for schedule confirmation cards.
abstract class ScheduleConfirmationCardRepository {
  /// Get all pending cards for a student
  Future<List<ScheduleConfirmationCard>> getPendingCardsForStudent(
      String studentId);

  /// Get a specific card by ID
  Future<ScheduleConfirmationCard?> getCardById(String cardId);

  /// Create a new schedule confirmation card
  Future<ScheduleConfirmationCard> createCard(ScheduleConfirmationCard card);

  /// Update card status (confirm, change time, dismiss)
  Future<ScheduleConfirmationCard> updateCardStatus(
    String cardId,
    ScheduleCardStatus status, {
    DateTime? respondedAt,
  });

  /// Dismiss all pending cards for a student (e.g., when they book manually)
  Future<void> dismissAllPendingCards(String studentId);

  /// Get card by subscription ID
  Future<ScheduleConfirmationCard?> getCardBySubscriptionId(
      String subscriptionId);
}
