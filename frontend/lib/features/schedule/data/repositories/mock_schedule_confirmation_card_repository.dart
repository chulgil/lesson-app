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
    final now = DateTime.now();

    // card_1: 최유진 체험 후 정규 등록 대기
    _cards.add(
      ScheduleConfirmationCard(
        id: 'card_1',
        studentId: 'student_4',
        teacherId: 'teacher_1',
        teacherName: '김지수',
        instrument: '플루트',
        subscriptionId: 'sub_4',
        suggestedDay: 6, // Saturday
        suggestedTime: '15:00',
        lessonDuration: 60,
        cardType: ScheduleCardType.afterTrial,
        status: ScheduleCardStatus.pending,
        createdAt: now.subtract(const Duration(hours: 2)),
        totalLessons: 8,
      ),
    );

    // card_2: 김민준 이전 수강권 만료 후 재등록 대기
    _cards.add(
      ScheduleConfirmationCard(
        id: 'card_2',
        studentId: 'student_1',
        teacherId: 'teacher_1',
        teacherName: '김지수',
        instrument: '바이올린',
        subscriptionId: 'sub_1',
        suggestedDay: 3, // Wednesday
        suggestedTime: '10:00',
        lessonDuration: 60,
        cardType: ScheduleCardType.reEnrollment,
        status: ScheduleCardStatus.pending,
        createdAt: now.subtract(const Duration(hours: 5)),
        totalLessons: 12,
      ),
    );

    // card_3: 이하은 피아노 추가 악기 (자유 선택)
    _cards.add(
      ScheduleConfirmationCard(
        id: 'card_3',
        studentId: 'student_11',
        teacherId: 'teacher_1',
        teacherName: '김지수',
        instrument: '피아노',
        subscriptionId: 'sub_11',
        suggestedDay: null,
        suggestedTime: null,
        lessonDuration: 45,
        cardType: ScheduleCardType.additionalInstrument,
        status: ScheduleCardStatus.pending,
        createdAt: now.subtract(const Duration(hours: 1)),
        totalLessons: 4,
      ),
    );

    // card_4: 이서연 체험 후 등록 확정 완료
    _cards.add(
      ScheduleConfirmationCard(
        id: 'card_4',
        studentId: 'student_2',
        teacherId: 'teacher_1',
        teacherName: '김지수',
        instrument: '피아노',
        subscriptionId: 'sub_2',
        suggestedDay: 2, // Tuesday
        suggestedTime: '16:00',
        lessonDuration: 60,
        cardType: ScheduleCardType.afterTrial,
        status: ScheduleCardStatus.confirmed,
        createdAt: now.subtract(const Duration(days: 3)),
        respondedAt: now.subtract(const Duration(days: 2)),
        totalLessons: 8,
      ),
    );

    // card_5: 김민준 재등록 거절
    _cards.add(
      ScheduleConfirmationCard(
        id: 'card_5',
        studentId: 'student_1',
        teacherId: 'teacher_1',
        teacherName: '김지수',
        instrument: '바이올린',
        subscriptionId: 'sub_1_old',
        suggestedDay: 5, // Friday
        suggestedTime: '14:00',
        lessonDuration: 60,
        cardType: ScheduleCardType.reEnrollment,
        status: ScheduleCardStatus.dismissed,
        createdAt: now.subtract(const Duration(days: 7)),
        respondedAt: now.subtract(const Duration(days: 6)),
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
