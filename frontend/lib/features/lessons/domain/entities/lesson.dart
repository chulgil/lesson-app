import 'package:json_annotation/json_annotation.dart';

part 'lesson.g.dart';

/// Lesson status enum
enum LessonStatus {
  // Basic states
  scheduled,
  completed,

  // Cancellation states (detailed)
  cancelled, // Generic cancelled (legacy compatibility)
  cancelledByStudentAdvance, // Student cancelled 24h+ in advance (no deduction)
  cancelledByStudentLate, // Student cancelled within 24h (deducted)
  cancelledByTeacher, // Teacher cancelled (reschedule, no deduction)
  cancelledMutual, // Mutual agreement (reschedule, no deduction)

  // Absence
  noShow, // Legacy no-show
  studentAbsent, // Student absent (deducted)

  // Reschedule pending
  reschedulePending; // Reschedule requested, waiting for confirmation

  String get label {
    switch (this) {
      case LessonStatus.scheduled:
        return '예정';
      case LessonStatus.completed:
        return '완료';
      case LessonStatus.cancelled:
        return '취소';
      case LessonStatus.cancelledByStudentAdvance:
        return '사전 취소';
      case LessonStatus.cancelledByStudentLate:
        return '당일 취소';
      case LessonStatus.cancelledByTeacher:
        return '선생님 취소';
      case LessonStatus.cancelledMutual:
        return '합의 취소';
      case LessonStatus.noShow:
        return '결석';
      case LessonStatus.studentAbsent:
        return '학생 불참';
      case LessonStatus.reschedulePending:
        return '변경 대기';
    }
  }

  /// Whether this status results in subscription deduction
  bool get isDeducted {
    switch (this) {
      case LessonStatus.completed:
      case LessonStatus.cancelledByStudentLate:
      case LessonStatus.noShow:
      case LessonStatus.studentAbsent:
        return true;
      default:
        return false;
    }
  }

  /// Whether this status allows rescheduling
  bool get allowsReschedule {
    switch (this) {
      case LessonStatus.cancelledByStudentAdvance:
      case LessonStatus.cancelledByTeacher:
      case LessonStatus.cancelledMutual:
      case LessonStatus.reschedulePending:
        return true;
      default:
        return false;
    }
  }
}

/// Piece practiced in a lesson
@JsonSerializable()
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

  factory LessonPiece.fromJson(Map<String, dynamic> json) =>
      _$LessonPieceFromJson(json);

  Map<String, dynamic> toJson() => _$LessonPieceToJson(this);

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
@JsonSerializable()
class LessonRecording {
  final String id;
  final String filePath;
  @JsonKey(fromJson: _durationFromSeconds, toJson: _durationToSeconds)
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

  factory LessonRecording.fromJson(Map<String, dynamic> json) =>
      _$LessonRecordingFromJson(json);

  Map<String, dynamic> toJson() => _$LessonRecordingToJson(this);
}

Duration _durationFromSeconds(int seconds) => Duration(seconds: seconds);
int _durationToSeconds(Duration duration) => duration.inSeconds;

/// Lesson location info (simplified for display)
@JsonSerializable()
class LessonLocationInfo {
  final String name; // "남부터미널 우드브릿지", "학생 집"
  final String? address; // Optional address

  const LessonLocationInfo({required this.name, this.address});

  factory LessonLocationInfo.fromJson(Map<String, dynamic> json) =>
      _$LessonLocationInfoFromJson(json);

  Map<String, dynamic> toJson() => _$LessonLocationInfoToJson(this);
}

/// Lesson model
@JsonSerializable()
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

  factory Lesson.fromJson(Map<String, dynamic> json) => _$LessonFromJson(json);

  Map<String, dynamic> toJson() => _$LessonToJson(this);

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
