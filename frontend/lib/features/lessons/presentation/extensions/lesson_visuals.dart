import '../../../../core/l10n/app_strings.dart';
import '../../domain/entities/lesson.dart';

extension LessonStatusVisualX on LessonStatus {
  String get label {
    switch (this) {
      case LessonStatus.scheduled:
        return AppStrings.statusUpcoming;
      case LessonStatus.completed:
        return AppStrings.statusCompleted;
      case LessonStatus.cancelled:
        return AppStrings.statusCancelled;
      case LessonStatus.cancelledByStudentAdvance:
        return AppStrings.statusAdvanceCancel;
      case LessonStatus.cancelledByStudentLate:
        return AppStrings.statusSameDayCancel;
      case LessonStatus.cancelledByTeacher:
        return AppStrings.teacherCancelLabel;
      case LessonStatus.cancelledMutual:
        return AppStrings.statusMutualCancel;
      case LessonStatus.noShow:
        return AppStrings.statusAbsent;
      case LessonStatus.studentAbsent:
        return AppStrings.statusStudentAbsent;
      case LessonStatus.reschedulePending:
        return AppStrings.statusReschedulePending;
    }
  }
}

extension LessonPieceVisualX on LessonPiece {
  String get displayName {
    final parts = <String>[name];
    if (opus != null) parts.add(opus!);
    if (movement != null) parts.add(movement!);
    return parts.join(' - ');
  }
}
