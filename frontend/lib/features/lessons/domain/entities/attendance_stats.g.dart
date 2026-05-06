// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_stats.dart';

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

AttendanceStats _$AttendanceStatsFromJson(
  Map<String, dynamic> json,
) => AttendanceStats(
  studentId: json['student_id'] as String,
  totalLessons: (json['total_lessons'] as num?)?.toInt() ?? 0,
  completedLessons: (json['completed_lessons'] as num?)?.toInt() ?? 0,
  absentCount: (json['absent_count'] as num?)?.toInt() ?? 0,
  noShowCount: (json['no_show_count'] as num?)?.toInt() ?? 0,
  cancelledByStudentLateCount:
      (json['cancelled_by_student_late_count'] as num?)?.toInt() ?? 0,
  cancelledByTeacherCount:
      (json['cancelled_by_teacher_count'] as num?)?.toInt() ?? 0,
  mutualCancelledCount: (json['mutual_cancelled_count'] as num?)?.toInt() ?? 0,
  monthlyBreakdown:
      (json['monthly_breakdown'] as List<dynamic>?)
          ?.map((e) => MonthlyAttendance.fromJson(e as Map<String, dynamic>))
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
