/// Calendar event type for lesson schedule display
enum CalendarEventType {
  lesson,
  practice,
  break_;

  String get label {
    switch (this) {
      case CalendarEventType.lesson:
        return '레슨';
      case CalendarEventType.practice:
        return '연습';
      case CalendarEventType.break_:
        return '휴강';
    }
  }
}

/// Calendar view type
enum CalendarViewType {
  month,
  week,
  day;

  String get label {
    switch (this) {
      case CalendarViewType.month:
        return '월';
      case CalendarViewType.week:
        return '주';
      case CalendarViewType.day:
        return '일';
    }
  }
}
