import 'package:flutter/painting.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/teacher_availability.dart';

/// Day type for visual distinction in weekly grid.
///
/// Mirrored from `_ScheduleWeeklyGridViewState._DayType` so visual helpers
/// can be tested without instantiating the State class.
enum ScheduleDayType { past, today, future }

/// §7.123 — 컬럼 단위 휴식 종류.
///
/// 우선순위: vacation > holiday > regular > none.
/// 모두 동일한 배경색(scheduleRestDayBackground) 을 공유하고, 라벨 칩으로 변별.
///
/// Spec: docs/specs/design/notebook/README.md §7.123
enum ColumnRestKind {
  /// 정상 근무일 (휴식 아님)
  none,

  /// 다일 휴가 (TimeException type=vacation)
  vacation,

  /// 단일 휴무 (TimeException type=holiday)
  holiday,

  /// 정기 휴무일 (weeklySchedules 미등록 요일)
  regular,
}

/// 컬럼 라벨 칩 (헤더 위 오버레이) 텍스트.
extension ColumnRestKindExtension on ColumnRestKind {
  bool get isRest => this != ColumnRestKind.none;

  /// 컬럼 상단 오버레이 칩에 표시할 라벨.
  /// `regular` 은 라벨 없음 — 헤더의 요일/날짜로 이미 변별.
  /// `additionalSlot` 은 슬롯 자체로 표현 (컬럼 라벨 없음).
  String? get chipLabel {
    switch (this) {
      case ColumnRestKind.vacation:
        return '휴가';
      case ColumnRestKind.holiday:
        return '휴무';
      case ColumnRestKind.regular:
      case ColumnRestKind.none:
        return null;
    }
  }
}

/// §7.123 (Mode A) — 주간 그리드 컬럼 배경 미니멀 팔레트.
///
/// 휴식(vacation/holiday/regular) → `ink alpha 0.10` (따뜻한 진한 회색).
/// 그 외 (today 포함) → 투명. 변별은 라벨 칩 + 수직 디바이더(§7.122) 담당.
///
/// Why ink alpha 0.10: 종이 베이스(#F2ECDD, warm cream) 위 무채색 중성 회색
/// (#E8E8E8) 은 동시대비로 cool tone 인지됨. ink 알파 블렌딩은 종이 톤을
/// 유지하면서 채도만 낮춰 warm dark gray 로 인지된다 (≈ #DDD8CB).
///
/// Why today 톤 제거: 헤더의 요일/날짜 칩이 이미 today 변별을 담당
/// (§1.3.2 평탄화 — 변동은 단일 채널로).
///
/// Spec: docs/specs/design/notebook/README.md §7.123
Color? weeklyColumnBackground({
  required ScheduleDayType dayType,
  required ColumnRestKind restKind,
}) {
  if (restKind.isRest) {
    return AppColors.ink.withValues(alpha: 0.10);
  }
  return null;
}

/// §7.123 — 날짜에 적용되는 휴식 종류 판정.
///
/// 우선순위:
/// 1. vacation (다일 휴가) — `TimeException(type=vacation, startDate~endDate)`
/// 2. holiday (단일 휴무) — `TimeException(type=holiday, startDate~endDate)`
/// 3. regular (정기 휴무일) — `weeklySchedules` 에 active 스케줄 없음
/// 4. none — 정상 근무일
///
/// availability null → none (정보 없음 시 정상 근무로 가정).
ColumnRestKind columnRestKindForDate({
  required TeacherAvailability? availability,
  required DateTime date,
}) {
  if (availability == null) return ColumnRestKind.none;

  for (final ex in availability.exceptions) {
    if (ex.type == ExceptionType.vacation && ex.containsDate(date)) {
      return ColumnRestKind.vacation;
    }
  }

  for (final ex in availability.exceptions) {
    if (ex.type == ExceptionType.holiday && ex.containsDate(date)) {
      return ColumnRestKind.holiday;
    }
  }

  final dayIndex = date.weekday - 1;
  final hasActiveSchedule = availability.weeklySchedules.any(
    (s) => s.isActive && s.dayOfWeek == dayIndex,
  );
  if (!hasActiveSchedule) return ColumnRestKind.regular;

  return ColumnRestKind.none;
}

/// §7.121 / §7.123 — selectedDate 가 휴식인지(any kind) 판정.
///
/// `columnRestKindForDate` 의 boolean 별칭. 기존 호출처 호환용.
/// vacation/holiday/regular 모두 true 반환 (§7.123 에서 확장).
///
/// Spec: docs/specs/design/notebook/README.md §7.121, §7.123
bool isTeacherRestDay({
  required TeacherAvailability? availability,
  required DateTime date,
}) {
  return columnRestKindForDate(availability: availability, date: date).isRest;
}

/// §7.123 — slot 시작 시간이 해당 요일의 근무시간 내인지.
///
/// `WeeklySchedule.startTime <= slot < endTime` (end 미포함).
/// 휴무 요일(active schedule 없음) 은 false.
/// availability null → true (정보 없음 시 정상으로 가정).
///
/// Spec: docs/specs/design/notebook/README.md §7.123
bool isWithinWorkHours({
  required TeacherAvailability? availability,
  required DateTime slotStart,
}) {
  if (availability == null) return true;
  final dayIndex = slotStart.weekday - 1;
  final matching = availability.weeklySchedules.where(
    (s) => s.isActive && s.dayOfWeek == dayIndex,
  );
  if (matching.isEmpty) return false;
  final schedule = matching.first;
  final startMinutes = _parseHHmmToMinutes(schedule.startTime);
  final endMinutes = _parseHHmmToMinutes(schedule.endTime);
  if (startMinutes == null || endMinutes == null) return true;
  final slotMinutes = slotStart.hour * 60 + slotStart.minute;
  return slotMinutes >= startMinutes && slotMinutes < endMinutes;
}

/// §7.123 — slot 시작 시간이 추가오픈 예외(additionalSlot) 범위 내인지.
///
/// `TimeException(type=additionalSlot, startTime~endTime)` 의 시간 범위 내면 true.
/// startTime/endTime 미설정인 additionalSlot 은 무시 (시간 범위 불명확).
///
/// Spec: docs/specs/design/notebook/README.md §7.123
bool isAdditionalOpenSlot({
  required TeacherAvailability? availability,
  required DateTime slotStart,
}) {
  if (availability == null) return false;
  final slotMinutes = slotStart.hour * 60 + slotStart.minute;
  for (final ex in availability.exceptions) {
    if (ex.type != ExceptionType.additionalSlot) continue;
    if (!ex.containsDate(slotStart)) continue;
    final start = _parseHHmmToMinutes(ex.startTime);
    final end = _parseHHmmToMinutes(ex.endTime);
    if (start == null || end == null) continue;
    if (slotMinutes >= start && slotMinutes < end) return true;
  }
  return false;
}

/// "HH:mm" → 분 단위 (00:00 = 0). 파싱 실패 시 null.
int? _parseHHmmToMinutes(String? hhmm) {
  if (hhmm == null) return null;
  final parts = hhmm.split(':');
  if (parts.length != 2) return null;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null) return null;
  return h * 60 + m;
}
