// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_stats.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MonthlyAttendanceAdapter extends TypeAdapter<MonthlyAttendance> {
  @override
  final int typeId = 96;

  @override
  MonthlyAttendance read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MonthlyAttendance(
      year: fields[0] as int,
      month: fields[1] as int,
      totalLessons: fields[2] as int,
      completed: fields[3] as int,
      studentAbsent: fields[4] as int,
      teacherCancelled: fields[5] as int,
      noShow: fields[6] as int,
      mutualCancelled: fields[7] as int,
      cancelledByStudentLate: fields[8] as int,
    );
  }

  @override
  void write(BinaryWriter writer, MonthlyAttendance obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.year)
      ..writeByte(1)
      ..write(obj.month)
      ..writeByte(2)
      ..write(obj.totalLessons)
      ..writeByte(3)
      ..write(obj.completed)
      ..writeByte(4)
      ..write(obj.studentAbsent)
      ..writeByte(5)
      ..write(obj.teacherCancelled)
      ..writeByte(6)
      ..write(obj.noShow)
      ..writeByte(7)
      ..write(obj.mutualCancelled)
      ..writeByte(8)
      ..write(obj.cancelledByStudentLate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonthlyAttendanceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AttendanceStatsAdapter extends TypeAdapter<AttendanceStats> {
  @override
  final int typeId = 97;

  @override
  AttendanceStats read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AttendanceStats(
      studentId: fields[0] as String,
      totalLessons: fields[1] as int,
      completedLessons: fields[2] as int,
      absentCount: fields[3] as int,
      noShowCount: fields[4] as int,
      cancelledByStudentLateCount: fields[5] as int,
      cancelledByTeacherCount: fields[6] as int,
      mutualCancelledCount: fields[7] as int,
      monthlyBreakdown: (fields[8] as List).cast<MonthlyAttendance>(),
    );
  }

  @override
  void write(BinaryWriter writer, AttendanceStats obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.studentId)
      ..writeByte(1)
      ..write(obj.totalLessons)
      ..writeByte(2)
      ..write(obj.completedLessons)
      ..writeByte(3)
      ..write(obj.absentCount)
      ..writeByte(4)
      ..write(obj.noShowCount)
      ..writeByte(5)
      ..write(obj.cancelledByStudentLateCount)
      ..writeByte(6)
      ..write(obj.cancelledByTeacherCount)
      ..writeByte(7)
      ..write(obj.mutualCancelledCount)
      ..writeByte(8)
      ..write(obj.monthlyBreakdown);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceStatsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MonthlyAttendance _$MonthlyAttendanceFromJson(Map<String, dynamic> json) =>
    MonthlyAttendance(
      year: (json['year'] as num).toInt(),
      month: (json['month'] as num).toInt(),
      totalLessons: (json['total_lessons'] as num?)?.toInt() ?? 0,
      completed: (json['completed'] as num?)?.toInt() ?? 0,
      studentAbsent: (json['student_absent'] as num?)?.toInt() ?? 0,
      teacherCancelled: (json['teacher_cancelled'] as num?)?.toInt() ?? 0,
      noShow: (json['no_show'] as num?)?.toInt() ?? 0,
      mutualCancelled: (json['mutual_cancelled'] as num?)?.toInt() ?? 0,
      cancelledByStudentLate:
          (json['cancelled_by_student_late'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$MonthlyAttendanceToJson(MonthlyAttendance instance) =>
    <String, dynamic>{
      'year': instance.year,
      'month': instance.month,
      'total_lessons': instance.totalLessons,
      'completed': instance.completed,
      'student_absent': instance.studentAbsent,
      'teacher_cancelled': instance.teacherCancelled,
      'no_show': instance.noShow,
      'mutual_cancelled': instance.mutualCancelled,
      'cancelled_by_student_late': instance.cancelledByStudentLate,
    };

AttendanceStats _$AttendanceStatsFromJson(Map<String, dynamic> json) =>
    AttendanceStats(
      studentId: json['student_id'] as String,
      totalLessons: (json['total_lessons'] as num?)?.toInt() ?? 0,
      completedLessons: (json['completed_lessons'] as num?)?.toInt() ?? 0,
      absentCount: (json['absent_count'] as num?)?.toInt() ?? 0,
      noShowCount: (json['no_show_count'] as num?)?.toInt() ?? 0,
      cancelledByStudentLateCount:
          (json['cancelled_by_student_late_count'] as num?)?.toInt() ?? 0,
      cancelledByTeacherCount:
          (json['cancelled_by_teacher_count'] as num?)?.toInt() ?? 0,
      mutualCancelledCount:
          (json['mutual_cancelled_count'] as num?)?.toInt() ?? 0,
      monthlyBreakdown: (json['monthly_breakdown'] as List<dynamic>?)
              ?.map(
                  (e) => MonthlyAttendance.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$AttendanceStatsToJson(AttendanceStats instance) =>
    <String, dynamic>{
      'student_id': instance.studentId,
      'total_lessons': instance.totalLessons,
      'completed_lessons': instance.completedLessons,
      'absent_count': instance.absentCount,
      'no_show_count': instance.noShowCount,
      'cancelled_by_student_late_count': instance.cancelledByStudentLateCount,
      'cancelled_by_teacher_count': instance.cancelledByTeacherCount,
      'mutual_cancelled_count': instance.mutualCancelledCount,
      'monthly_breakdown':
          instance.monthlyBreakdown.map((e) => e.toJson()).toList(),
    };
