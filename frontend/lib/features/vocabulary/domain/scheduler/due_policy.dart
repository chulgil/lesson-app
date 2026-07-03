import '../entities/vocab_card.dart';

/// Whether [card] is due for review at [now] — its due date is today or earlier
/// (#1124).
///
/// Calendar-day granularity, matching [Sm2Scheduler]'s local-midnight due dates:
/// a card is due iff its [dueDate] falls before the start of tomorrow, so a card
/// due "today" counts regardless of the current time of day and a card due
/// tomorrow does not.
bool isCardDue(VocabCard card, DateTime now) => card.reviewState.dueDate
    .isBefore(DateTime(now.year, now.month, now.day + 1));
