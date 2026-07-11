import '../../../profile/domain/entities/teacher_profile.dart';
import '../../../students/students_facade.dart';

/// Location types available in the academy lesson context.
const _academyContext = {LocationType.academyRoom, LocationType.online};

/// Location types available in the private (non-academy) lesson context.
const _privateContext = {
  LocationType.studentHome,
  LocationType.externalPlace,
  LocationType.teacherStudio,
  LocationType.online,
};

/// Derives the subscription location options from the teacher's profile
/// [lessonTypes], intersected with the academy/private context.
///
/// Mapping (profile 3-mode → registration 5-location):
/// - [LessonTypeOption.inPerson] → studio: teacherStudio (or academyRoom)
/// - [LessonTypeOption.visit]     → student home / external place
/// - [LessonTypeOption.online]    → online
///
/// Returns `null` when the teacher has not set any lesson type, so callers keep
/// the current `isAcademy`-only behavior — backward compatible for the many
/// profiles that never set lessonTypes. May return an empty set when the
/// teacher's modes do not intersect the context (callers treat empty like
/// null: no gating, to avoid a zero-option dead end).
Set<LocationType>? allowedLocationTypes(
  List<LessonTypeOption>? lessonTypes, {
  required bool isAcademy,
}) {
  if (lessonTypes == null || lessonTypes.isEmpty) return null;

  final mapped = <LocationType>{};
  for (final type in lessonTypes) {
    switch (type) {
      case LessonTypeOption.inPerson:
        mapped.addAll({LocationType.teacherStudio, LocationType.academyRoom});
      case LessonTypeOption.visit:
        mapped.addAll({LocationType.studentHome, LocationType.externalPlace});
      case LessonTypeOption.online:
        mapped.add(LocationType.online);
    }
  }

  return mapped.intersection(isAcademy ? _academyContext : _privateContext);
}
