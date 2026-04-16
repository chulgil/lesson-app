import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../lessons/domain/entities/lesson.dart';

/// Viewer role for time-aware banner messages.
enum TimeBannerRole { teacher, student }

/// 시간대 인식 컨텍스트 배너 (home_master.md §3.5).
///
/// 사용자의 일일 루틴(아침/낮/저녁)에 맞춰 다른 메시지 표시.
///
/// 표시할 정보가 없으면 SizedBox.shrink로 자동 숨김.
class TimeContextBanner extends StatelessWidget {
  final List<Lesson> todayLessons;
  final TimeBannerRole role;

  /// 학생 전용: 현재 연속 연습 일수 (학생일 때만 사용)
  final int? streakDays;

  const TimeContextBanner({
    super.key,
    required this.todayLessons,
    this.role = TimeBannerRole.teacher,
    this.streakDays,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final hour = now.hour;
    final message = _buildMessage(now, hour);

    if (message == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space4),
      margin: const EdgeInsets.only(bottom: AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
            child: Icon(_iconForHour(hour), size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimaryLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForHour(int hour) {
    if (hour >= 6 && hour < 10) return Icons.wb_sunny_outlined;
    if (hour >= 10 && hour < 18) return Icons.schedule;
    if (hour >= 18 && hour < 22) return Icons.nights_stay_outlined;
    return Icons.bedtime_outlined;
  }

  /// 시간대별 메시지 생성. null 반환 시 배너 숨김.
  String? _buildMessage(DateTime now, int hour) {
    return role == TimeBannerRole.student
        ? _buildStudentMessage(now, hour)
        : _buildTeacherMessage(now, hour);
  }

  /// 선생님 메시지
  String? _buildTeacherMessage(DateTime now, int hour) {
    // 아침 (06~10시): 오늘 레슨 안내
    if (hour >= 6 && hour < 10) {
      if (todayLessons.isEmpty) return null;
      return AppStrings.timeBannerTeacherMorning(todayLessons.length);
    }

    // 낮~오후 (10~18시): 다음 레슨 카운트다운
    if (hour >= 10 && hour < 18) {
      final next = _findNextLesson(now);
      if (next != null) {
        final minutesUntil = next.dateTime.difference(now).inMinutes;
        if (minutesUntil <= 0) {
          return AppStrings.timeBannerNextLessonInProgress(next.startTime);
        }
        if (minutesUntil < 60) {
          return AppStrings.timeBannerNextLessonMinutes(
            next.startTime,
            minutesUntil,
          );
        }
        final hoursUntil = (minutesUntil / 60).floor();
        return AppStrings.timeBannerNextLessonHours(next.startTime, hoursUntil);
      }
      if (todayLessons.isNotEmpty) {
        return AppStrings.timeBannerTeacherDayDone;
      }
      return null;
    }

    // 저녁 (18~22시): 완료 요약 + 노트 미작성
    if (hour >= 18 && hour < 22) {
      final completed =
          todayLessons.where((l) => l.status == LessonStatus.completed).length;
      if (completed == 0) return null;

      final notesNeeded =
          todayLessons
              .where(
                (l) =>
                    l.status == LessonStatus.completed &&
                    (l.feedback == null || l.feedback!.isEmpty),
              )
              .length;

      if (notesNeeded > 0) {
        return AppStrings.timeBannerTeacherEveningNotes(completed, notesNeeded);
      }
      return AppStrings.timeBannerTeacherEveningDone(completed);
    }

    // 밤 (22~06시)
    if (hour >= 22 || hour < 6) {
      return AppStrings.timeBannerTeacherNight;
    }

    return null;
  }

  /// 학생 메시지 (연습 중심 + 격려)
  String? _buildStudentMessage(DateTime now, int hour) {
    final streak = streakDays ?? 0;

    // 아침 (06~10시)
    if (hour >= 6 && hour < 10) {
      if (todayLessons.isNotEmpty) {
        return AppStrings.timeBannerStudentMorningLesson;
      }
      if (streak > 0) {
        return AppStrings.timeBannerStudentMorningStreak(streak);
      }
      return AppStrings.timeBannerStudentMorningPractice;
    }

    // 낮~오후 (10~18시): 다음 레슨 카운트다운
    if (hour >= 10 && hour < 18) {
      final next = _findNextLesson(now);
      if (next != null) {
        final minutesUntil = next.dateTime.difference(now).inMinutes;
        if (minutesUntil <= 0) {
          return AppStrings.timeBannerStudentLessonTime(next.startTime);
        }
        if (minutesUntil < 60) {
          return AppStrings.timeBannerNextLessonMinutes(
            next.startTime,
            minutesUntil,
          );
        }
        final hoursUntil = (minutesUntil / 60).floor();
        return AppStrings.timeBannerNextLessonHours(next.startTime, hoursUntil);
      }
      // 오후 연습 독려
      if (streak > 0) {
        return AppStrings.timeBannerStudentStreakKeep(streak);
      }
      return null;
    }

    // 저녁 (18~22시): 연습 독려 / 스트릭 축하
    if (hour >= 18 && hour < 22) {
      if (streak >= 7) {
        return AppStrings.timeBannerStudentStreakGreat(streak);
      }
      if (streak > 0) {
        return AppStrings.timeBannerStudentStreakContinue(streak);
      }
      return AppStrings.timeBannerStudentEveningAsk;
    }

    // 밤 (22~06시)
    if (hour >= 22 || hour < 6) {
      if (streak > 0) {
        return AppStrings.timeBannerStudentNightStreak(streak);
      }
      return AppStrings.timeBannerStudentNight;
    }

    return null;
  }

  /// 현재 시간 이후의 가장 가까운 미완료 레슨 찾기.
  _NextLessonInfo? _findNextLesson(DateTime now) {
    final upcoming =
        todayLessons
            .where((l) => l.status == LessonStatus.scheduled)
            .map((l) {
              final parts = l.startTime.split(':');
              if (parts.length < 2) return null;
              final hour = int.tryParse(parts[0]) ?? 0;
              final minute = int.tryParse(parts[1]) ?? 0;
              final dt = DateTime(
                l.date.year,
                l.date.month,
                l.date.day,
                hour,
                minute,
              );
              return _NextLessonInfo(startTime: l.startTime, dateTime: dt);
            })
            .whereType<_NextLessonInfo>()
            .where((info) => info.dateTime.isAfter(now))
            .toList()
          ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    return upcoming.isNotEmpty ? upcoming.first : null;
  }
}

class _NextLessonInfo {
  final String startTime;
  final DateTime dateTime;

  _NextLessonInfo({required this.startTime, required this.dateTime});
}
