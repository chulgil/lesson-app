// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'teacher_stats.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MonthlyTrend _$MonthlyTrendFromJson(Map<String, dynamic> json) => MonthlyTrend(
      month: DateTime.parse(json['month'] as String),
      lessonCount: (json['lesson_count'] as num).toInt(),
      revenue: (json['revenue'] as num).toInt(),
    );

Map<String, dynamic> _$MonthlyTrendToJson(MonthlyTrend instance) =>
    <String, dynamic>{
      'month': instance.month.toIso8601String(),
      'lesson_count': instance.lessonCount,
      'revenue': instance.revenue,
    };

StudentPracticeRank _$StudentPracticeRankFromJson(Map<String, dynamic> json) =>
    StudentPracticeRank(
      studentId: json['student_id'] as String,
      studentName: json['student_name'] as String,
      instrument: json['instrument'] as String,
      practiceRate: (json['practice_rate'] as num).toDouble(),
      practiceMinutes: (json['practice_minutes'] as num).toInt(),
    );

Map<String, dynamic> _$StudentPracticeRankToJson(
        StudentPracticeRank instance) =>
    <String, dynamic>{
      'student_id': instance.studentId,
      'student_name': instance.studentName,
      'instrument': instance.instrument,
      'practice_rate': instance.practiceRate,
      'practice_minutes': instance.practiceMinutes,
    };

TeacherMonthlyStats _$TeacherMonthlyStatsFromJson(Map<String, dynamic> json) =>
    TeacherMonthlyStats(
      month: DateTime.parse(json['month'] as String),
      totalLessons: (json['total_lessons'] as num).toInt(),
      completedLessons: (json['completed_lessons'] as num).toInt(),
      cancelledLessons: (json['cancelled_lessons'] as num).toInt(),
      noShowLessons: (json['no_show_lessons'] as num).toInt(),
      totalRevenue: (json['total_revenue'] as num).toInt(),
      revenueChangePercent: (json['revenue_change_percent'] as num).toDouble(),
      totalStudents: (json['total_students'] as num).toInt(),
      newStudents: (json['new_students'] as num).toInt(),
      churnedStudents: (json['churned_students'] as num).toInt(),
      attendanceRate: (json['attendance_rate'] as num).toDouble(),
      lessonTrend: (json['lesson_trend'] as List<dynamic>)
          .map((e) => MonthlyTrend.fromJson(e as Map<String, dynamic>))
          .toList(),
      practiceRanking: (json['practice_ranking'] as List<dynamic>)
          .map((e) => StudentPracticeRank.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$TeacherMonthlyStatsToJson(
        TeacherMonthlyStats instance) =>
    <String, dynamic>{
      'month': instance.month.toIso8601String(),
      'total_lessons': instance.totalLessons,
      'completed_lessons': instance.completedLessons,
      'cancelled_lessons': instance.cancelledLessons,
      'no_show_lessons': instance.noShowLessons,
      'total_revenue': instance.totalRevenue,
      'revenue_change_percent': instance.revenueChangePercent,
      'total_students': instance.totalStudents,
      'new_students': instance.newStudents,
      'churned_students': instance.churnedStudents,
      'attendance_rate': instance.attendanceRate,
      'lesson_trend': instance.lessonTrend.map((e) => e.toJson()).toList(),
      'practice_ranking':
          instance.practiceRanking.map((e) => e.toJson()).toList(),
    };
