import '../entities/request_event.dart';
import '../entities/unified_lesson_request.dart';
import '../repositories/unified_lesson_request_repository.dart';

class UnifiedLessonRequestWorkflowService {
  final UnifiedLessonRequestRepository _repository;

  UnifiedLessonRequestWorkflowService(this._repository);

  Future<UnifiedLessonRequest> createRequest(
    UnifiedLessonRequest request, {
    required String currentUserId,
  }) async {
    final studentId =
        request.studentId.isNotEmpty ? request.studentId : currentUserId;
    final effectiveRequest = request.copyWith(studentId: studentId);
    final result = await _repository.create(effectiveRequest);

    await _repository.addEvent(
      RequestEvent(
        id: _eventId(),
        requestId: result.id,
        actorType: ProposerRole.student,
        actorId: studentId,
        eventType: RequestEventType.initialRequest,
        suggestedSlots:
            effectiveRequest.preferredSlots
                .map(
                  (ps) => TimeSlotOption(
                    id: 'slot_${ps.priority}',
                    dayOfWeek: ps.dayOfWeek ?? 0,
                    startTime: ps.startTime,
                    endTime: ps.endTime,
                  ),
                )
                .toList(),
        message: effectiveRequest.message,
        createdAt: DateTime.now(),
      ),
    );

    return result;
  }

  Future<UnifiedLessonRequest> approveRequest(
    String requestId, {
    required String teacherId,
    int? selectedSlotIndex,
    String? message,
  }) async {
    final request = await _repository.getById(requestId);
    if (request == null) {
      throw Exception('Request not found: $requestId');
    }

    final result = await _repository.update(
      request.copyWith(
        status: UnifiedRequestStatus.timeConfirmed,
        confirmedAt: request.confirmedAt ?? DateTime.now(),
      ),
    );

    await _repository.addEvent(
      RequestEvent(
        id: _eventId(),
        requestId: requestId,
        actorType: ProposerRole.teacher,
        actorId: teacherId,
        eventType: RequestEventType.approve,
        selectedSlotIndex: selectedSlotIndex,
        message: message,
        createdAt: DateTime.now(),
      ),
    );

    return result;
  }

  Future<UnifiedLessonRequest> acceptAlternativeRequest(
    String requestId, {
    required String studentId,
    int? selectedSlotIndex,
    String? message,
  }) async {
    final result = await _repository.approve(requestId);

    await _repository.addEvent(
      RequestEvent(
        id: _eventId(),
        requestId: requestId,
        actorType: ProposerRole.student,
        actorId: studentId,
        eventType: RequestEventType.acceptAlternative,
        selectedSlotIndex: selectedSlotIndex,
        message: message,
        createdAt: DateTime.now(),
      ),
    );

    return result;
  }

  Future<UnifiedLessonRequest> withdrawApprovalRequest(
    String requestId, {
    required String teacherId,
    required String studentId,
    ProposerRole actorRole = ProposerRole.teacher,
  }) async {
    final events = await _repository.getEventsByRequestId(requestId);
    int? prevSlotIndex;
    for (var i = events.length - 1; i >= 0; i--) {
      if ((events[i].eventType == RequestEventType.approve ||
              events[i].eventType == RequestEventType.acceptAlternative) &&
          events[i].selectedSlotIndex != null) {
        prevSlotIndex = events[i].selectedSlotIndex;
        break;
      }
    }

    final result = await _repository.withdrawApproval(requestId);

    await _repository.addEvent(
      RequestEvent(
        id: _eventId(),
        requestId: requestId,
        actorType: actorRole,
        actorId: actorRole == ProposerRole.teacher ? teacherId : studentId,
        eventType: RequestEventType.withdrawApproval,
        selectedSlotIndex: prevSlotIndex,
        createdAt: DateTime.now(),
      ),
    );

    return result;
  }

  Future<UnifiedLessonRequest> rejectRequest(
    String requestId, {
    required String teacherId,
    String? reason,
  }) async {
    final result = await _repository.reject(requestId, reason: reason);

    await _repository.addEvent(
      RequestEvent(
        id: _eventId(),
        requestId: requestId,
        actorType: ProposerRole.teacher,
        actorId: teacherId,
        eventType: RequestEventType.reject,
        message: reason,
        createdAt: DateTime.now(),
      ),
    );

    return result;
  }

  Future<UnifiedLessonRequest> proposeAlternatives(
    String requestId, {
    required List<TimeSlotOption> slots,
    String? message,
  }) {
    return _repository.proposeAlternatives(
      requestId,
      slots: slots,
      message: message,
    );
  }

  Future<UnifiedLessonRequest> acceptAlternative(
    String requestId, {
    required int selectedSlotIndex,
    String? message,
  }) {
    return _repository.acceptAlternative(
      requestId,
      selectedSlotIndex: selectedSlotIndex,
      message: message,
    );
  }

  Future<UnifiedLessonRequest> counterPropose(
    String requestId, {
    required TimeSlotOption slot,
    String? message,
  }) {
    return _repository.counterPropose(requestId, slot: slot, message: message);
  }

  String _eventId() => 'evt_${DateTime.now().millisecondsSinceEpoch}';
}
