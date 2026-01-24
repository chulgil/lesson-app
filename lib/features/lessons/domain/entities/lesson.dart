/// Lesson status enum
enum LessonStatus {
  scheduled,
  completed,
  cancelled,
  noShow;

  String get label {
    switch (this) {
      case LessonStatus.scheduled:
        return '예정';
      case LessonStatus.completed:
        return '완료';
      case LessonStatus.cancelled:
        return '취소';
      case LessonStatus.noShow:
        return '결석';
    }
  }
}

/// Piece practiced in a lesson
class LessonPiece {
  final String id;
  final String name;
  final String? composer;
  final String? opus;
  final String? movement;
  final String? notes;

  const LessonPiece({
    required this.id,
    required this.name,
    this.composer,
    this.opus,
    this.movement,
    this.notes,
  });

  String get displayName {
    final parts = <String>[name];
    if (opus != null) parts.add(opus!);
    if (movement != null) parts.add(movement!);
    return parts.join(' - ');
  }

  LessonPiece copyWith({
    String? id,
    String? name,
    String? composer,
    String? opus,
    String? movement,
    String? notes,
  }) {
    return LessonPiece(
      id: id ?? this.id,
      name: name ?? this.name,
      composer: composer ?? this.composer,
      opus: opus ?? this.opus,
      movement: movement ?? this.movement,
      notes: notes ?? this.notes,
    );
  }
}

/// Recording attached to a lesson
class LessonRecording {
  final String id;
  final String filePath;
  final Duration duration;
  final DateTime recordedAt;
  final String? transcription;
  final String? aiSummary;

  const LessonRecording({
    required this.id,
    required this.filePath,
    required this.duration,
    required this.recordedAt,
    this.transcription,
    this.aiSummary,
  });
}

/// Lesson location info (simplified for display)
class LessonLocationInfo {
  final String name; // "스튜디오 메이트", "학생 집"
  final String? address; // Optional address

  const LessonLocationInfo({
    required this.name,
    this.address,
  });
}

/// Lesson model
class Lesson {
  final String id;
  final String studentId;
  final String studentName;
  final String? teacherId;
  final String? teacherName;
  final String instrument;
  final DateTime date;
  final String startTime;
  final int duration; // in minutes
  final LessonStatus status;
  final List<LessonPiece> pieces;
  final String? feedback;
  final List<String>? keyPoints;
  final String? practiceTips;
  final List<LessonRecording>? recordings;
  final List<String>? assignments;
  final LessonLocationInfo? location; // Lesson location
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Lesson({
    required this.id,
    required this.studentId,
    required this.studentName,
    this.teacherId,
    this.teacherName,
    required this.instrument,
    required this.date,
    required this.startTime,
    this.duration = 60,
    this.status = LessonStatus.scheduled,
    this.pieces = const [],
    this.feedback,
    this.keyPoints,
    this.practiceTips,
    this.recordings,
    this.assignments,
    this.location,
    required this.createdAt,
    this.updatedAt,
  });

  /// Check if lesson is upcoming
  bool get isUpcoming =>
      status == LessonStatus.scheduled && date.isAfter(DateTime.now());

  /// Check if lesson is today
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Check if lesson has recordings
  bool get hasRecordings => recordings != null && recordings!.isNotEmpty;

  /// Check if lesson has feedback
  bool get hasFeedback => feedback != null && feedback!.isNotEmpty;

  /// Get days until/since lesson
  int get daysFromNow {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lessonDate = DateTime(date.year, date.month, date.day);
    return lessonDate.difference(today).inDays;
  }

  /// Copy with new values
  Lesson copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? teacherId,
    String? teacherName,
    String? instrument,
    DateTime? date,
    String? startTime,
    int? duration,
    LessonStatus? status,
    List<LessonPiece>? pieces,
    String? feedback,
    List<String>? keyPoints,
    String? practiceTips,
    List<LessonRecording>? recordings,
    List<String>? assignments,
    LessonLocationInfo? location,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Lesson(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      instrument: instrument ?? this.instrument,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      duration: duration ?? this.duration,
      status: status ?? this.status,
      pieces: pieces ?? this.pieces,
      feedback: feedback ?? this.feedback,
      keyPoints: keyPoints ?? this.keyPoints,
      practiceTips: practiceTips ?? this.practiceTips,
      recordings: recordings ?? this.recordings,
      assignments: assignments ?? this.assignments,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Lesson && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
