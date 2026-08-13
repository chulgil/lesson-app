import '../../../../core/router/app_routes.dart';
import '../../domain/entities/request_event.dart';
import '../../domain/entities/unified_lesson_request.dart';

/// Extracted from [RequestDetailScreen] — pure phase/event filtering and
/// subscription route lookup used by the chat-style request detail screen
/// and covered directly by unit tests.
List<RequestEvent> requestDetailVisibleEventsForCurrentPhase(
  UnifiedLessonRequest request,
  List<RequestEvent> events,
) {
  final phase = request.currentPhase;
  if (phase == RequestPhase.request || phase == RequestPhase.terminal) {
    return events;
  }
  return events
      .where((event) => requestDetailEventBelongsToPhase(event, phase))
      .toList();
}

bool requestDetailEventBelongsToPhase(RequestEvent event, RequestPhase phase) {
  return switch (phase) {
    RequestPhase.request => _requestPhaseEventTypes.contains(event.eventType),
    RequestPhase.subscription =>
      _requestPhaseDecisionEventTypes.contains(event.eventType) ||
          _subscriptionPhaseEventTypes.contains(event.eventType),
    RequestPhase.lessons => _lessonPhaseEventTypes.contains(event.eventType),
    RequestPhase.completed => _completedPhaseEventTypes.contains(
      event.eventType,
    ),
    RequestPhase.terminal => true,
  };
}

const _requestPhaseEventTypes = {
  RequestEventType.initialRequest,
  RequestEventType.approve,
  RequestEventType.reject,
  RequestEventType.proposeAlternative,
  RequestEventType.counterPropose,
  RequestEventType.acceptAlternative,
  RequestEventType.withdrawApproval,
  RequestEventType.cancel,
  RequestEventType.expire,
  RequestEventType.proposalSent,
  RequestEventType.proposalAccepted,
  RequestEventType.paymentNotified,
};

const _requestPhaseDecisionEventTypes = {
  RequestEventType.approve,
  RequestEventType.acceptAlternative,
  RequestEventType.withdrawApproval,
};

const _subscriptionPhaseEventTypes = {
  RequestEventType.paymentRequested,
  RequestEventType.paymentConfirmed,
  RequestEventType.subscriptionIssued,
};

const _lessonPhaseEventTypes = {
  RequestEventType.lessonCompleted,
  RequestEventType.lessonCancelled,
  RequestEventType.scheduleChanged,
  RequestEventType.lessonNoteAdded,
};

const _completedPhaseEventTypes = {
  RequestEventType.subscriptionRenewed,
  RequestEventType.subscriptionCompleted,
  RequestEventType.completed,
};

String? requestDetailSubscriptionRoute(List<RequestEvent> events) {
  final subscriptionEvents =
      events.where((event) => event.subscriptionId != null).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  if (subscriptionEvents.isEmpty) return null;
  final subscriptionId = subscriptionEvents.first.subscriptionId!;
  return AppRoutes.subscriptionDetail.replaceFirst(':id', subscriptionId);
}
