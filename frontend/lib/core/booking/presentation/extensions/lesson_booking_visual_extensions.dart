import 'package:flutter/material.dart';

import '../../../l10n/app_strings.dart';
import '../../../theme/app_colors.dart';
import '../../entities/lesson_booking.dart';
import '../../entities/time_slot.dart';

const defaultUnavailableMessage = '현재 가능한 시간이 없어 이번에는 어렵습니다.';

extension LessonTypeVisualX on LessonType {
  String get label {
    switch (this) {
      case LessonType.trial:
        return '체험';
      case LessonType.regular:
        return '정규';
      case LessonType.oneTime:
        return '1회';
    }
  }

  Color get color {
    switch (this) {
      case LessonType.trial:
        return AppColors.paperAccent;
      case LessonType.regular:
        return AppColors.paperOk;
      case LessonType.oneTime:
        return AppColors.ink;
    }
  }
}

extension ScheduleTypeVisualX on ScheduleType {
  String get label {
    switch (this) {
      case ScheduleType.fixed:
        return '고정';
      case ScheduleType.flexible:
        return '유동';
    }
  }

  String get description {
    switch (this) {
      case ScheduleType.fixed:
        return '매주 같은 요일/시간에 레슨';
      case ScheduleType.flexible:
        return '매주 가능한 시간 협의';
    }
  }
}

extension BookingStatusVisualX on BookingStatus {
  String get label {
    switch (this) {
      case BookingStatus.pending:
        return '신청완료';
      case BookingStatus.confirmed:
        return '확정';
      case BookingStatus.changeRequested:
        return '변경요청';
      case BookingStatus.completed:
        return '완료';
      case BookingStatus.cancelled:
        return '취소';
      case BookingStatus.unavailable:
        return '일정조율';
      case BookingStatus.expired:
        return '만료';
    }
  }

  String get studentMessage {
    switch (this) {
      case BookingStatus.pending:
        return '선생님 확인 중이에요';
      case BookingStatus.confirmed:
        return '레슨이 확정되었어요';
      case BookingStatus.changeRequested:
        return '일정 변경 요청 중';
      case BookingStatus.completed:
        return '레슨 완료';
      case BookingStatus.cancelled:
        return '취소되었습니다';
      case BookingStatus.unavailable:
        return '다른 시간을 확인해주세요';
      case BookingStatus.expired:
        return '응답 대기 시간이 지났어요';
    }
  }

  Color get color {
    switch (this) {
      case BookingStatus.pending:
        return AppColors.paperAccent;
      case BookingStatus.confirmed:
        return AppColors.ink;
      case BookingStatus.changeRequested:
        return AppColors.paperAccent;
      case BookingStatus.completed:
        return AppColors.paperOk;
      case BookingStatus.cancelled:
        return AppColors.inkTertiary;
      case BookingStatus.unavailable:
        return AppColors.paperAccent;
      case BookingStatus.expired:
        return AppColors.inkSecondary;
    }
  }

  IconData get icon {
    switch (this) {
      case BookingStatus.pending:
        return Icons.schedule;
      case BookingStatus.confirmed:
        return Icons.check_circle;
      case BookingStatus.changeRequested:
        return Icons.swap_horiz;
      case BookingStatus.completed:
        return Icons.done_all;
      case BookingStatus.cancelled:
        return Icons.cancel;
      case BookingStatus.unavailable:
        return Icons.event_busy;
      case BookingStatus.expired:
        return Icons.timer_off;
    }
  }
}

extension LessonGoalVisualX on LessonGoal {
  String get label {
    switch (this) {
      case LessonGoal.hobby:
        return '취미';
      case LessonGoal.exam:
        return '입시';
      case LessonGoal.major:
        return '전공';
    }
  }

  String get description {
    switch (this) {
      case LessonGoal.hobby:
        return '즐겁게 음악을 배우고 싶어요';
      case LessonGoal.exam:
        return '입시 준비가 필요해요';
      case LessonGoal.major:
        return '전공자로 실력을 키우고 싶어요';
    }
  }
}

extension ExperienceLevelVisualX on ExperienceLevel {
  String get label {
    switch (this) {
      case ExperienceLevel.none:
        return '처음';
      case ExperienceLevel.beginner:
        return '1년 미만';
      case ExperienceLevel.some:
        return '1-3년';
      case ExperienceLevel.experienced:
        return '3년 이상';
    }
  }
}

extension ScheduleOptionVisualX on ScheduleOption {
  String get timeRange {
    if (startTime == null || endTime == null) return '';
    return '${startTime!.format24Hour()} - ${endTime!.format24Hour()}';
  }

  String get formattedDate {
    if (date == null) return '';
    final weekday = AppStrings.dayNamesShort[date!.weekday - 1];
    return '${date!.month}/${date!.day}($weekday)';
  }

  String get fullFormattedDate {
    if (date == null) return '';
    final weekday = _fullDayNames[date!.weekday - 1];
    return '${date!.year}년 ${date!.month}월 ${date!.day}일 $weekday';
  }

  String get dayName {
    if (dayOfWeek == null) return '';
    return _fullDayNames[dayOfWeek! - 1];
  }

  String get shortDayName {
    if (dayOfWeek == null) return '';
    return AppStrings.dayNamesShort[dayOfWeek! - 1];
  }

  String get secondDayName {
    if (secondDayOfWeek == null) return '';
    return _fullDayNames[secondDayOfWeek! - 1];
  }

  String get secondShortDayName {
    if (secondDayOfWeek == null) return '';
    return AppStrings.dayNamesShort[secondDayOfWeek! - 1];
  }

  String get secondTimeRange {
    if (secondStartTime == null || secondEndTime == null) return '';
    return '${secondStartTime!.format24Hour()} - ${secondEndTime!.format24Hour()}';
  }

  String get singleLessonSummary => '$formattedDate $timeRange';

  String get regularLessonSummary {
    if (isWeekly2x) {
      return '$shortDayName $timeRange + $secondShortDayName $secondTimeRange';
    }
    return '매주 $dayName $timeRange';
  }

  String get priorityLabel => '$priority순위';
}

extension LessonBookingVisualX on LessonBooking {
  String get timeRange =>
      '${startTime.format24Hour()} - ${endTime.format24Hour()}';

  String get formattedDate {
    final weekday = AppStrings.dayNamesShort[lessonDate.weekday - 1];
    return '${lessonDate.month}/${lessonDate.day}($weekday)';
  }

  String get fullFormattedDate {
    final weekday = _fullDayNames[lessonDate.weekday - 1];
    return '${lessonDate.year}년 ${lessonDate.month}월 ${lessonDate.day}일 $weekday';
  }

  String get formattedFee {
    final formatter = fee.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    return '$formatter원';
  }

  String? get requestedTimeRange {
    if (requestedStartTime == null || requestedEndTime == null) return null;
    return '${requestedStartTime!.format24Hour()} - ${requestedEndTime!.format24Hour()}';
  }

  String? get formattedRequestedDate {
    if (requestedDate == null) return null;
    final weekday = AppStrings.dayNamesShort[requestedDate!.weekday - 1];
    return '${requestedDate!.month}/${requestedDate!.day}($weekday)';
  }

  String? get displayMessage {
    if (status == BookingStatus.unavailable && unavailableMessage != null) {
      return unavailableMessage!;
    }
    if (status == BookingStatus.expired) {
      return status.studentMessage;
    }
    return null;
  }
}

extension TimeSlotVisualX on TimeSlot {
  String get dayName => AppStrings.dayNamesShort[dayOfWeek - 1];

  String get fullDayName => _fullDayNames[dayOfWeek - 1];

  String get displayLabel {
    if (specificDate != null) {
      return '${specificDate!.month}/${specificDate!.day}($dayName) $timeRange';
    }
    return '$dayName $timeRange';
  }

  String get timeRange =>
      '${startTime.format24Hour()} - ${endTime.format24Hour()}';
}

const _fullDayNames = ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];
