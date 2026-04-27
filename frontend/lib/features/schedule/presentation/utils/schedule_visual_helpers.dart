import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/teacher_availability.dart';

/// Day type for visual distinction in weekly grid.
///
/// Mirrored from `_ScheduleWeeklyGridViewState._DayType` so visual helpers
/// can be tested without instantiating the State class.
enum ScheduleDayType { past, today, future }

/// §7.120 — 주간 그리드 컬럼 배경 4단 우선순위.
///
/// 우선순위: 쉬는 날 > 오늘 > 주말 > zebra(홀수 인덱스).
/// alpha 상한 0.10 유지로 레슨 카드 가독성 보호.
///
/// Spec: docs/specs/design/notebook/README.md §7.120
Color? weeklyColumnBackground({
  required ScheduleDayType dayType,
  required bool isRestDay,
  required bool isWeekend,
  required int dayIndex,
}) {
  if (isRestDay) {
    return AppColors.scheduleMutedBackground.withValues(alpha: 0.5);
  }
  if (dayType == ScheduleDayType.today) {
    return AppColors.paperAccent.withValues(alpha: 0.10);
  }
  if (isWeekend) {
    return AppColors.paperAccentSoft.withValues(alpha: 0.06);
  }
  return dayIndex.isOdd ? AppColors.ink.withValues(alpha: 0.025) : null;
}

/// §7.121 — selectedDate 가 선생님 weeklySchedules 에 등록되지 않은 요일이면 휴무.
///
/// WeeklySchedule.dayOfWeek 는 0=월..6=일, DateTime.weekday 는 1=월..7=일.
/// availability null → false (정보 없음 시 정상 근무로 가정).
///
/// Spec: docs/specs/design/notebook/README.md §7.121
bool isTeacherRestDay({
  required TeacherAvailability? availability,
  required DateTime date,
}) {
  if (availability == null) return false;
  final dayIndex = date.weekday - 1;
  final hasActiveSchedule = availability.weeklySchedules.any(
    (s) => s.isActive && s.dayOfWeek == dayIndex,
  );
  return !hasActiveSchedule;
}
