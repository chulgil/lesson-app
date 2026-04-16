import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../lessons/domain/entities/lesson.dart';

/// 시간대 인식 컨텍스트 배너 (home_master.md §3.5).
///
/// 선생님의 일일 루틴(아침/낮/저녁)에 맞춰 다른 메시지 표시.
/// - 06~10시: 오늘 레슨 N건 안내
/// - 10~18시: 다음 레슨 카운트다운
/// - 18~22시: 완료 요약 + 노트 미작성 알림
/// - 22~06시: 내일 레슨 안내
///
/// 표시할 정보가 없으면 SizedBox.shrink로 자동 숨김.
class TimeContextBanner extends StatelessWidget {
  final List<Lesson> todayLessons;

  const TimeContextBanner({super.key, required this.todayLessons});

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
    // 아침 (06~10시): 오늘 레슨 안내
    if (hour >= 6 && hour < 10) {
      if (todayLessons.isEmpty) return null;
      return '좋은 아침이에요. 오늘 ${todayLessons.length}건의 레슨이 있어요';
    }

    // 낮~오후 (10~18시): 다음 레슨 카운트다운
    if (hour >= 10 && hour < 18) {
      final next = _findNextLesson(now);
      if (next != null) {
        final minutesUntil = next.dateTime.difference(now).inMinutes;
        if (minutesUntil <= 0) {
          return '${next.startTime} 레슨 진행 중이에요';
        }
        if (minutesUntil < 60) {
          return '다음 레슨: ${next.startTime} ($minutesUntil분 후)';
        }
        final hoursUntil = (minutesUntil / 60).floor();
        return '다음 레슨: ${next.startTime} (약 $hoursUntil시간 후)';
      }
      // 오늘 남은 레슨 없음
      if (todayLessons.isNotEmpty) {
        return '오늘 모든 레슨이 끝났어요. 수고하셨어요';
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
        return '오늘 $completed건 완료. 노트 미작성 $notesNeeded건';
      }
      return '오늘 $completed건 완료. 수고하셨어요';
    }

    // 밤 (22~06시): 내일 안내 — 데이터 없으므로 일반 메시지
    if (hour >= 22 || hour < 6) {
      return '편안한 밤 되세요. 내일도 좋은 레슨 되시길 바랍니다';
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
