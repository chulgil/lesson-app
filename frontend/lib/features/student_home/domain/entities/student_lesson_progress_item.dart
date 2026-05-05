enum StudentLessonProgressKind {
  request,
  proposal,
  payment,
  subscriptionReady,
  scheduleConfirmation,
  scheduleChange,
  renewal,
}

enum StudentLessonProgressPriority { actionRequired, waiting, completed }

class StudentLessonProgressItem {
  final String id;
  final StudentLessonProgressKind kind;
  final StudentLessonProgressPriority priority;
  final String title;
  final String subtitle;
  final String statusLabel;
  final DateTime createdAt;
  final String? route;
  final Object? routeExtra;

  const StudentLessonProgressItem({
    required this.id,
    required this.kind,
    required this.priority,
    required this.title,
    required this.subtitle,
    required this.statusLabel,
    required this.createdAt,
    this.route,
    this.routeExtra,
  });

  static List<StudentLessonProgressItem> sorted(
    Iterable<StudentLessonProgressItem> items,
  ) {
    return List<StudentLessonProgressItem>.of(items)
      ..sort((a, b) => a.priority.index.compareTo(b.priority.index));
  }
}
