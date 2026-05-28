import 'package:json_annotation/json_annotation.dart';
import '../../../academy/domain/entities/academy_enums.dart';

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
  final String? studentNote; // Student's own memo about the lesson
  final int travelTimeMinutes; // Teacher's travel time after this lesson
  final String?
  subscriptionId; // Linked subscription (null for trial-free lessons)
  final bool isPreview; // Preview lesson (beyond subscription range)
  final bool isArchived; // Archived lesson (hidden from active views)
  final DateTime? archivedAt; // When the lesson was archived
  final String? academyId; // Academy ID if lesson is linked to academy
  final LessonVisibility visibility; // Academy visibility setting
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
    this.studentNote,
    this.travelTimeMinutes = 0,
    this.subscriptionId,
    this.isPreview = false,
    this.isArchived = false,
    this.archivedAt,
    this.academyId,
    this.visibility = LessonVisibility.academyFull,
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

  /// Check if lesson is linked to a subscription
  bool get hasSubscription => subscriptionId != null;

  /// Display status — auto-completes past scheduled lessons based on time.
  /// UI should use this instead of raw `status` for rendering.
  LessonStatus get displayStatus {
    if (status != LessonStatus.scheduled) return status;
    final endTime = _calculateEndDateTime();
    return endTime.isBefore(DateTime.now())
        ? LessonStatus.completed
        : LessonStatus.scheduled;
  }

  /// Calculate lesson end time from date + startTime + duration.
  DateTime _calculateEndDateTime() {
    final parts = startTime.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return DateTime(
      date.year,
      date.month,
      date.day,
      hour,
      minute,
    ).add(Duration(minutes: duration));
  }

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
    String? studentNote,
    int? travelTimeMinutes,
    String? subscriptionId,
    bool? isPreview,
    bool? isArchived,
    DateTime? archivedAt,
    String? academyId,
    LessonVisibility? visibility,
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
      studentNote: studentNote ?? this.studentNote,
      travelTimeMinutes: travelTimeMinutes ?? this.travelTimeMinutes,
      subscriptionId: subscriptionId ?? this.subscriptionId,
      isPreview: isPreview ?? this.isPreview,
      isArchived: isArchived ?? this.isArchived,
      archivedAt: archivedAt ?? this.archivedAt,
      academyId: academyId ?? this.academyId,
      visibility: visibility ?? this.visibility,
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
