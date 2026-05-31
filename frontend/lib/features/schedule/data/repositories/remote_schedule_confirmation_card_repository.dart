import '../../../../core/network/api_client.dart';
import '../../domain/entities/schedule_confirmation_card.dart';
import '../../domain/repositories/schedule_confirmation_card_repository.dart';

/// Remote implementation of [ScheduleConfirmationCardRepository].
///
/// Maps to /api/v1/schedule/confirmation-cards endpoints.
/// Backend uses snake_case; Flutter entity uses snake_case JSON keys
/// (via @JsonSerializable). Field name differences are mapped here.
class RemoteScheduleConfirmationCardRepository
    implements ScheduleConfirmationCardRepository {
  final ApiClient _apiClient;

  RemoteScheduleConfirmationCardRepository(this._apiClient);

  @override
  Future<List<ScheduleConfirmationCard>> getPendingCardsForStudent(
    String studentId,
  ) async {
    final response = await _apiClient.get(
      '/schedule/confirmation-cards',
      queryParameters: {'student_id': studentId, 'status': 'pending'},
    );
    final items = response.data as List<dynamic>;
    return items
        .map((e) => _fromBackendJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ScheduleConfirmationCard?> getCardById(String cardId) async {
    final response = await _apiClient.get(
      '/schedule/confirmation-cards/$cardId',
    );
    return _fromBackendJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<ScheduleConfirmationCard?> getCardBySubscriptionId(
    String subscriptionId,
  ) async {
    final response = await _apiClient.get(
      '/schedule/confirmation-cards/by-subscription/$subscriptionId',
    );
    return _fromBackendJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<ScheduleConfirmationCard> createCard(
    ScheduleConfirmationCard card,
  ) async {
    final response = await _apiClient.post(
      '/schedule/confirmation-cards',
      data: {
        'student_id': card.studentId,
        'subscription_id': card.subscriptionId,
        if (card.lessonRequestId != null)
          'lesson_request_id': card.lessonRequestId,
        'card_type': card.cardType.name,
        'title': _titleFor(card),
        if (card.instrument != null) 'instrument': card.instrument,
        if (card.suggestedDay != null) 'proposed_day': card.suggestedDay,
        if (card.suggestedTime != null) 'proposed_time': card.suggestedTime,
        if (card.lessonDuration != null)
          'proposed_duration': card.lessonDuration,
        if (_proposedSlotsFor(card).isNotEmpty)
          'proposed_slots': _proposedSlotsFor(card),
        if (card.totalLessons != null) 'total_lessons': card.totalLessons,
      },
    );
    return _fromBackendJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<ScheduleConfirmationCard> updateCardStatus(
    String cardId,
    ScheduleCardStatus status, {
    DateTime? respondedAt,
  }) async {
    final response = await _apiClient.patch(
      '/schedule/confirmation-cards/$cardId/status',
      data: {
        'status': status.name,
        if (respondedAt != null) 'responded_at': respondedAt.toIso8601String(),
      },
    );
    return _fromBackendJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> dismissAllPendingCards(String studentId) async {
    await _apiClient.post(
      '/schedule/confirmation-cards/dismiss-all',
      data: {'student_id': studentId},
    );
  }

  /// Maps backend response fields to Flutter entity JSON keys.
  ///
  /// Backend uses `proposed_day`/`proposed_time`/`proposed_duration`,
  /// Flutter entity expects `suggested_day`/`suggested_time`/`lesson_duration`.
  ScheduleConfirmationCard _fromBackendJson(Map<String, dynamic> json) {
    // Map backend field names to Flutter entity field names
    final mapped = <String, dynamic>{
      'id': json['id'],
      'student_id': json['student_id'],
      'teacher_id': json['teacher_id'],
      'teacher_name': json['teacher_name'] ?? '',
      'instrument': json['instrument'],
      'subscription_id': json['subscription_id'] ?? '',
      'suggested_day':
          json['proposed_day'] != null
              ? int.tryParse(json['proposed_day'].toString())
              : json['suggested_day'] != null
              ? int.tryParse(json['suggested_day'].toString())
              : null,
      'suggested_time': json['proposed_time'] ?? json['suggested_time'],
      'lesson_duration': json['proposed_duration'] ?? json['lesson_duration'],
      'card_type': json['card_type'] ?? 'afterTrial',
      'status': json['status'] ?? 'pending',
      'created_at': json['created_at'],
      'responded_at': json['responded_at'],
      'total_lessons': json['total_lessons'],
      'lesson_request_id': json['lesson_request_id'],
      'suggested_day2': json['suggested_day2'],
      'suggested_time2': json['suggested_time2'],
      'suggested_day3': json['suggested_day3'],
      'suggested_time3': json['suggested_time3'],
    };

    // Map proposed_slots array to suggestedDay2/3 if present
    final slots = json['proposed_slots'] as List<dynamic>?;
    if (slots != null && slots.length >= 2) {
      final slot2 = slots[1] as Map<String, dynamic>;
      mapped['suggested_day2'] = int.tryParse(slot2['day'].toString());
      mapped['suggested_time2'] = slot2['time'];
    }
    if (slots != null && slots.length >= 3) {
      final slot3 = slots[2] as Map<String, dynamic>;
      mapped['suggested_day3'] = int.tryParse(slot3['day'].toString());
      mapped['suggested_time3'] = slot3['time'];
    }

    return ScheduleConfirmationCard.fromJson(mapped);
  }

  List<Map<String, dynamic>> _proposedSlotsFor(ScheduleConfirmationCard card) {
    final slots = <Map<String, dynamic>>[];
    void addSlot(int? day, String? time) {
      if (day != null && time != null) {
        slots.add({'day': day, 'time': time});
      }
    }

    addSlot(card.suggestedDay, card.suggestedTime);
    addSlot(card.suggestedDay2, card.suggestedTime2);
    addSlot(card.suggestedDay3, card.suggestedTime3);
    return slots;
  }

  String _titleFor(ScheduleConfirmationCard card) {
    final instrument = card.instrument;
    if (instrument == null || instrument.isEmpty) {
      return '스케줄 확인';
    }
    return '$instrument 스케줄 확인';
  }
}
