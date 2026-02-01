import 'package:uuid/uuid.dart';

import '../../domain/entities/schedule_confirmation_card.dart';
import '../../domain/repositories/schedule_confirmation_card_repository.dart';

/// Mock implementation of ScheduleConfirmationCardRepository.
class MockScheduleConfirmationCardRepository
    implements ScheduleConfirmationCardRepository {
  final _uuid = const Uuid();

  // In-memory storage for cards
  final List<ScheduleConfirmationCard> _cards = [];

  MockScheduleConfirmationCardRepository() {
    _initializeMockData();
  }

  void _initializeMockData() {
    // Add sample pending card for testing
    _cards.add(
      ScheduleConfirmationCard(
        id: 'card_1',
        studentId: 'student_1',
        teacherId: 'teacher_1',
        teacherName: '김바이올린',
        instrument: '바이올린',
        subscriptionId: 'sub_1',
        suggestedDay: 6, // Saturday
        suggestedTime: '15:00',
        lessonDuration: 60,
        cardType: ScheduleCardType.afterTrial,
        status: ScheduleCardStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        totalLessons: 8,
      ),
    );
  }

  @override
  Future<List<ScheduleConfirmationCard>> getPendingCardsForStudent(
      String studentId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _cards
        .where((card) =>
            card.studentId == studentId &&
            card.status == ScheduleCardStatus.pending)
        .toList();
  }

  @override
  Future<ScheduleConfirmationCard?> getCardById(String cardId) async {
    await Future.delayed(const Duration(milliseconds: 50));
    try {
      return _cards.firstWhere((card) => card.id == cardId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<ScheduleConfirmationCard> createCard(
      ScheduleConfirmationCard card) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final newCard = ScheduleConfirmationCard(
      id: card.id.isEmpty ? _uuid.v4() : card.id,
      studentId: card.studentId,
      teacherId: card.teacherId,
      teacherName: card.teacherName,
      instrument: card.instrument,
      subscriptionId: card.subscriptionId,
      suggestedDay: card.suggestedDay,
      suggestedTime: card.suggestedTime,
      lessonDuration: card.lessonDuration,
      cardType: card.cardType,
      status: ScheduleCardStatus.pending,
      createdAt: DateTime.now(),
      totalLessons: card.totalLessons,
      lessonRequestId: card.lessonRequestId,
    );

    _cards.add(newCard);
    return newCard;
  }

  @override
  Future<ScheduleConfirmationCard> updateCardStatus(
    String cardId,
    ScheduleCardStatus status, {
    DateTime? respondedAt,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final index = _cards.indexWhere((card) => card.id == cardId);
    if (index == -1) {
      throw Exception('Card not found: $cardId');
    }

    final updatedCard = _cards[index].copyWith(
      status: status,
      respondedAt: respondedAt ?? DateTime.now(),
    );

    _cards[index] = updatedCard;
    return updatedCard;
  }

  @override
  Future<void> dismissAllPendingCards(String studentId) async {
    await Future.delayed(const Duration(milliseconds: 100));

    for (var i = 0; i < _cards.length; i++) {
      if (_cards[i].studentId == studentId &&
          _cards[i].status == ScheduleCardStatus.pending) {
        _cards[i] = _cards[i].copyWith(
          status: ScheduleCardStatus.dismissed,
          respondedAt: DateTime.now(),
        );
      }
    }
  }

  @override
  Future<ScheduleConfirmationCard?> getCardBySubscriptionId(
      String subscriptionId) async {
    await Future.delayed(const Duration(milliseconds: 50));
    try {
      return _cards.firstWhere((card) => card.subscriptionId == subscriptionId);
    } catch (_) {
      return null;
    }
  }

  /// Add a card directly (for testing/demo purposes)
  void addCard(ScheduleConfirmationCard card) {
    _cards.add(card);
  }

  /// Clear all cards (for testing)
  void clearCards() {
    _cards.clear();
  }
}
