/// Practice task entity
class PracticeTask {
  final String id;
  final String title;
  final String? description;
  final int targetMinutes;
  final bool isCompleted;
  final DateTime? completedAt;
  final String? pieceId;

  const PracticeTask({
    required this.id,
    required this.title,
    this.description,
    this.targetMinutes = 15,
    this.isCompleted = false,
    this.completedAt,
    this.pieceId,
  });

  PracticeTask copyWith({
    String? id,
    String? title,
    String? description,
    int? targetMinutes,
    bool? isCompleted,
    DateTime? completedAt,
    String? pieceId,
  }) {
    return PracticeTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      targetMinutes: targetMinutes ?? this.targetMinutes,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      pieceId: pieceId ?? this.pieceId,
    );
  }
}

/// Daily practice log entity
class PracticeLog {
  final String id;
  final String studentId;
  final DateTime date;
  final int totalMinutes;
  final List<PracticeTask> tasks;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const PracticeLog({
    required this.id,
    required this.studentId,
    required this.date,
    this.totalMinutes = 0,
    this.tasks = const [],
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  /// Get completion rate (0.0 to 1.0)
  double get completionRate {
    if (tasks.isEmpty) return 0.0;
    final completed = tasks.where((t) => t.isCompleted).length;
    return completed / tasks.length;
  }

  /// Check if all tasks are completed
  bool get isFullyCompleted => tasks.isNotEmpty && tasks.every((t) => t.isCompleted);

  /// Get completion level for calendar display
  /// 0: no practice, 1: minimal, 2: partial, 3: full
  int get completionLevel {
    if (tasks.isEmpty && totalMinutes == 0) return 0;
    final rate = completionRate;
    if (rate >= 0.8) return 3;
    if (rate >= 0.5) return 2;
    if (rate > 0 || totalMinutes > 0) return 1;
    return 0;
  }

  PracticeLog copyWith({
    String? id,
    String? studentId,
    DateTime? date,
    int? totalMinutes,
    List<PracticeTask>? tasks,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PracticeLog(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      date: date ?? this.date,
      totalMinutes: totalMinutes ?? this.totalMinutes,
      tasks: tasks ?? this.tasks,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PracticeLog && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
