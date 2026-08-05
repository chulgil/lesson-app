import '../../domain/entities/entities.dart';

/// Body for `PUT /lessons/{id}` — the backend's `LessonUpdate` whitelist.
///
/// Sending the whole entity used to drop status/feedback/key_points silently
/// with a 200 OK (#1236 / #1237); the backend now rejects unsupported keys
/// (#1238), so the schedule-level edit must send exactly these fields. Status
/// and note writes have dedicated repository methods.
///
/// `location` is flattened to `location_name` — the entity's nested object key
/// never matched the backend field, so location edits were dropped too.
Map<String, dynamic> lessonScheduleUpdatePayload(Lesson lesson) {
  return {
    'instrument': lesson.instrument,
    'date': _dateOnly(lesson.date),
    'start_time': lesson.startTime,
    'duration': lesson.duration,
    'pieces': [
      for (final piece in lesson.pieces)
        {
          'name': piece.name,
          if (piece.composer != null) 'composer': piece.composer,
          if (piece.movement != null) 'movement': piece.movement,
        },
    ],
    if (lesson.location?.name != null) 'location_name': lesson.location!.name,
  };
}

String _dateOnly(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
