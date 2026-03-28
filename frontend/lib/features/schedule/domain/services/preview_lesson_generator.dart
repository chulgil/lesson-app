import '../../../lessons/domain/entities/lesson.dart';
import '../../../students/domain/entities/class_membership.dart';
import '../../../subscription/domain/entities/subscription.dart';

/// Generates preview (virtual) lessons for weeks beyond subscription coverage.
///
/// Uses [ClassMembership.lessonSlots] to project expected lesson times,
/// then marks them as [Lesson.isPreview] for dashed/light rendering.
class PreviewLessonGenerator {
  PreviewLessonGenerator._();

  /// Generate preview lessons for a given week.
  ///
  /// Returns empty list when:
  /// - Membership has no lessonSlots (flexible schedule)
  /// - Student has no subscription
  /// - Week is within subscription range
  /// - Existing lesson already covers the slot
  static List<Lesson> generateForWeek({
    required DateTime weekStart,
    required List<ClassMembership> memberships,
    required List<Subscription> subscriptions,
    required List<Lesson> existingLessons,
    required Map<String, String> studentNames,
  }) {
    final previews = <Lesson>[];

    for (final membership in memberships) {
      if (membership.lessonSlots.isEmpty) continue;

      final sub = subscriptions
          .where((s) => s.studentId == membership.studentId)
          .where((s) => s.status == SubscriptionStatus.active ||
              s.status == SubscriptionStatus.expiringSoon)
          .firstOrNull;

      if (sub == null) continue;

      for (final slot in membership.lessonSlots) {
        final slotDate = weekStart.add(Duration(days: slot.dayOfWeek));

        // Skip if within subscription range
        if (sub.endDate != null && !slotDate.isAfter(sub.endDate!)) continue;

        // Skip if real lesson already exists at this slot
        final hasExisting = existingLessons.any((l) =>
            l.studentId == membership.studentId &&
            l.date.year == slotDate.year &&
            l.date.month == slotDate.month &&
            l.date.day == slotDate.day &&
            l.startTime == slot.startTime);
        if (hasExisting) continue;

        previews.add(Lesson(
          id: 'preview_${membership.studentId}_${slotDate.toIso8601String()}',
          studentId: membership.studentId,
          studentName: studentNames[membership.studentId] ?? '',
          instrument: membership.instrument,
          date: slotDate,
          startTime: slot.startTime,
          duration: membership.lessonDuration,
          isPreview: true,
          createdAt: DateTime.now(),
        ));
      }
    }

    return previews;
  }
}
