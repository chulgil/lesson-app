// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lesson.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LessonPiece _$LessonPieceFromJson(Map<String, dynamic> json) => LessonPiece(
      id: json['id'] as String,
      name: json['name'] as String,
      composer: json['composer'] as String?,
      opus: json['opus'] as String?,
      movement: json['movement'] as String?,
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$LessonPieceToJson(LessonPiece instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'composer': instance.composer,
      'opus': instance.opus,
      'movement': instance.movement,
      'notes': instance.notes,
    };

LessonRecording _$LessonRecordingFromJson(Map<String, dynamic> json) =>
    LessonRecording(
      id: json['id'] as String,
      filePath: json['file_path'] as String,
      duration: _durationFromSeconds((json['duration'] as num).toInt()),
      recordedAt: DateTime.parse(json['recorded_at'] as String),
      transcription: json['transcription'] as String?,
      aiSummary: json['ai_summary'] as String?,
    );

Map<String, dynamic> _$LessonRecordingToJson(LessonRecording instance) =>
    <String, dynamic>{
      'id': instance.id,
      'file_path': instance.filePath,
      'duration': _durationToSeconds(instance.duration),
      'recorded_at': instance.recordedAt.toIso8601String(),
      'transcription': instance.transcription,
      'ai_summary': instance.aiSummary,
    };

LessonLocationInfo _$LessonLocationInfoFromJson(Map<String, dynamic> json) =>
    LessonLocationInfo(
      name: json['name'] as String,
      address: json['address'] as String?,
    );

Map<String, dynamic> _$LessonLocationInfoToJson(LessonLocationInfo instance) =>
    <String, dynamic>{
      'name': instance.name,
      'address': instance.address,
    };

Lesson _$LessonFromJson(Map<String, dynamic> json) => Lesson(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      studentName: json['student_name'] as String,
      teacherId: json['teacher_id'] as String?,
      teacherName: json['teacher_name'] as String?,
      instrument: json['instrument'] as String,
      date: DateTime.parse(json['date'] as String),
      startTime: json['start_time'] as String,
      duration: (json['duration'] as num?)?.toInt() ?? 60,
      status: $enumDecodeNullable(_$LessonStatusEnumMap, json['status']) ??
          LessonStatus.scheduled,
      pieces: (json['pieces'] as List<dynamic>?)
              ?.map((e) => LessonPiece.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      feedback: json['feedback'] as String?,
      keyPoints: (json['key_points'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      practiceTips: json['practice_tips'] as String?,
      recordings: (json['recordings'] as List<dynamic>?)
          ?.map((e) => LessonRecording.fromJson(e as Map<String, dynamic>))
          .toList(),
      assignments: (json['assignments'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      location: json['location'] == null
          ? null
          : LessonLocationInfo.fromJson(
              json['location'] as Map<String, dynamic>),
      studentNote: json['student_note'] as String?,
      travelTimeMinutes: (json['travel_time_minutes'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$LessonToJson(Lesson instance) => <String, dynamic>{
      'id': instance.id,
      'student_id': instance.studentId,
      'student_name': instance.studentName,
      'teacher_id': instance.teacherId,
      'teacher_name': instance.teacherName,
      'instrument': instance.instrument,
      'date': instance.date.toIso8601String(),
      'start_time': instance.startTime,
      'duration': instance.duration,
      'status': _$LessonStatusEnumMap[instance.status]!,
      'pieces': instance.pieces.map((e) => e.toJson()).toList(),
      'feedback': instance.feedback,
      'key_points': instance.keyPoints,
      'practice_tips': instance.practiceTips,
      'recordings': instance.recordings?.map((e) => e.toJson()).toList(),
      'assignments': instance.assignments,
      'location': instance.location?.toJson(),
      'student_note': instance.studentNote,
      'travel_time_minutes': instance.travelTimeMinutes,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

const _$LessonStatusEnumMap = {
  LessonStatus.scheduled: 'scheduled',
  LessonStatus.completed: 'completed',
  LessonStatus.cancelled: 'cancelled',
  LessonStatus.cancelledByStudentAdvance: 'cancelledByStudentAdvance',
  LessonStatus.cancelledByStudentLate: 'cancelledByStudentLate',
  LessonStatus.cancelledByTeacher: 'cancelledByTeacher',
  LessonStatus.cancelledMutual: 'cancelledMutual',
  LessonStatus.noShow: 'noShow',
  LessonStatus.studentAbsent: 'studentAbsent',
  LessonStatus.reschedulePending: 'reschedulePending',
};
