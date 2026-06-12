import '../../../schedule/domain/entities/request_event.dart';

/// Returns true if the given [sessionNumber] has 3 or more consecutive
/// scheduleChangeExpired events without any accepted or rejected event in
/// between (i.e., the negotiation never reached a decision).
///
/// Rules (spec §8.1):
/// - Scan events for the given sessionNumber only.
/// - A "streak" is a sequence of propose→expire cycles with no
///   scheduleChangeAccepted / scheduleChangeRejected breaking them.
/// - Each propose→expire pair increments the counter; a terminal accepted or
///   rejected resets it to 0.
/// - Returns true when the counter reaches 3 or more.
bool hasConsecutiveExpiryStreak({
  required List<RequestEvent> events,
  required int sessionNumber,
  int threshold = 3,
}) {
  final sessionEvents =
      events.where((e) => e.sessionNumber == sessionNumber).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  var expiryCount = 0;

  for (final event in sessionEvents) {
    switch (event.eventType) {
      case RequestEventType.scheduleChangeExpired:
        expiryCount++;
      case RequestEventType.scheduleChangeAccepted:
      case RequestEventType.scheduleChangeRejected:
        expiryCount = 0;
      default:
        break;
    }
  }

  return expiryCount >= threshold;
}
