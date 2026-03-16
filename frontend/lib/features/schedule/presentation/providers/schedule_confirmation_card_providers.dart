import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/config/environment.dart';
import '../../data/repositories/mock_schedule_confirmation_card_repository.dart';
import '../../domain/entities/schedule_confirmation_card.dart';
import '../../domain/repositories/schedule_confirmation_card_repository.dart';

part 'schedule_confirmation_card_providers.g.dart';

/// Repository provider for schedule confirmation cards.
@Riverpod(keepAlive: true)
ScheduleConfirmationCardRepository scheduleConfirmationCardRepository(
  ScheduleConfirmationCardRepositoryRef ref,
) {
  if (EnvironmentConfig.useMockData) {
    return MockScheduleConfirmationCardRepository();
  }
  // Backend API 미구현 — 스케줄 확인 카드 엔드포인트 필요
  return MockScheduleConfirmationCardRepository();
}

/// Get all pending schedule confirmation cards for a student.
@riverpod
Future<List<ScheduleConfirmationCard>> pendingScheduleConfirmationCards(
  PendingScheduleConfirmationCardsRef ref,
  String studentId,
) async {
  final repository = ref.watch(scheduleConfirmationCardRepositoryProvider);
  return repository.getPendingCardsForStudent(studentId);
}

/// Get a specific schedule confirmation card by ID.
@riverpod
Future<ScheduleConfirmationCard?> scheduleConfirmationCard(
  ScheduleConfirmationCardRef ref,
  String cardId,
) async {
  final repository = ref.watch(scheduleConfirmationCardRepositoryProvider);
  return repository.getCardById(cardId);
}

/// Notifier for managing schedule confirmation card actions.
@riverpod
class ScheduleConfirmationCardNotifier
    extends _$ScheduleConfirmationCardNotifier {
  @override
  FutureOr<void> build() {
    // Initial state
  }

  /// Create a new schedule confirmation card.
  Future<ScheduleConfirmationCard> createCard({
    required String studentId,
    required String teacherId,
    required String teacherName,
    String? instrument,
    required String subscriptionId,
    int? suggestedDay,
    String? suggestedTime,
    int? lessonDuration,
    required ScheduleCardType cardType,
    int? totalLessons,
    String? lessonRequestId,
    int? suggestedDay2,
    String? suggestedTime2,
    int? suggestedDay3,
    String? suggestedTime3,
  }) async {
    state = const AsyncLoading();

    try {
      final repository = ref.read(scheduleConfirmationCardRepositoryProvider);
      final card = await repository.createCard(
        ScheduleConfirmationCard(
          id: '',
          studentId: studentId,
          teacherId: teacherId,
          teacherName: teacherName,
          instrument: instrument,
          subscriptionId: subscriptionId,
          suggestedDay: suggestedDay,
          suggestedTime: suggestedTime,
          lessonDuration: lessonDuration,
          cardType: cardType,
          createdAt: DateTime.now(),
          totalLessons: totalLessons,
          lessonRequestId: lessonRequestId,
          suggestedDay2: suggestedDay2,
          suggestedTime2: suggestedTime2,
          suggestedDay3: suggestedDay3,
          suggestedTime3: suggestedTime3,
        ),
      );

      state = const AsyncData(null);

      // Invalidate pending cards for the student
      ref.invalidate(pendingScheduleConfirmationCardsProvider(studentId));

      return card;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Confirm the suggested schedule (student accepts).
  Future<void> confirmSchedule(String cardId, String studentId) async {
    state = const AsyncLoading();

    try {
      final repository = ref.read(scheduleConfirmationCardRepositoryProvider);
      await repository.updateCardStatus(
        cardId,
        ScheduleCardStatus.confirmed,
        respondedAt: DateTime.now(),
      );

      state = const AsyncData(null);

      // Invalidate to refresh the list
      ref.invalidate(pendingScheduleConfirmationCardsProvider(studentId));
      ref.invalidate(scheduleConfirmationCardProvider(cardId));
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Mark that student chose a different time.
  Future<void> selectDifferentTime(String cardId, String studentId) async {
    state = const AsyncLoading();

    try {
      final repository = ref.read(scheduleConfirmationCardRepositoryProvider);
      await repository.updateCardStatus(
        cardId,
        ScheduleCardStatus.changedTime,
        respondedAt: DateTime.now(),
      );

      state = const AsyncData(null);

      // Invalidate to refresh the list
      ref.invalidate(pendingScheduleConfirmationCardsProvider(studentId));
      ref.invalidate(scheduleConfirmationCardProvider(cardId));
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Dismiss a card (e.g., user swipes away).
  Future<void> dismissCard(String cardId, String studentId) async {
    state = const AsyncLoading();

    try {
      final repository = ref.read(scheduleConfirmationCardRepositoryProvider);
      await repository.updateCardStatus(
        cardId,
        ScheduleCardStatus.dismissed,
        respondedAt: DateTime.now(),
      );

      state = const AsyncData(null);

      // Invalidate to refresh the list
      ref.invalidate(pendingScheduleConfirmationCardsProvider(studentId));
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}
