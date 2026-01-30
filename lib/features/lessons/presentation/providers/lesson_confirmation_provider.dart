import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../models/lesson.dart';
import '../../../subscription/domain/entities/subscription_usage.dart';
import '../../../subscription/presentation/providers/subscription_providers.dart';
import '../widgets/lesson_confirmation_dialog.dart';
import 'lesson_crud_provider.dart';
import 'lesson_repository_provider.dart';

part 'lesson_confirmation_provider.g.dart';

/// Result of lesson confirmation action
class LessonConfirmationActionResult {
  final bool success;
  final Lesson? updatedLesson;
  final String? errorMessage;
  final bool needsReschedule; // true if teacher/mutual cancellation

  const LessonConfirmationActionResult({
    required this.success,
    this.updatedLesson,
    this.errorMessage,
    this.needsReschedule = false,
  });
}

/// Provider for confirming lesson completion
@riverpod
class LessonConfirmationNotifier extends _$LessonConfirmationNotifier {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  /// Confirm lesson as completed
  Future<LessonConfirmationActionResult> confirmLessonCompleted(
    Lesson lesson,
  ) async {
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(lessonRepositoryProvider);

      // Update lesson status to completed
      final updatedLesson = lesson.copyWith(
        status: LessonStatus.completed,
        updatedAt: DateTime.now(),
      );

      await repository.updateLesson(updatedLesson);

      // Record subscription usage
      await _recordSubscriptionUsage(
        lesson: lesson,
        usageType: UsageType.normal,
        deducted: true,
      );

      // Refresh lessons list
      ref.invalidate(lessonsProvider);
      ref.invalidate(lessonProvider(lesson.id));

      state = const AsyncValue.data(null);

      return LessonConfirmationActionResult(
        success: true,
        updatedLesson: updatedLesson,
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return LessonConfirmationActionResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Handle lesson non-completion with reason
  Future<LessonConfirmationActionResult> handleLessonNonCompletion(
    Lesson lesson,
    LessonConfirmationResult confirmationResult,
  ) async {
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(lessonRepositoryProvider);
      final reason = confirmationResult.nonCompletionReason;

      if (reason == null) {
        throw ArgumentError('Non-completion reason is required');
      }

      // Determine lesson status and usage type
      final lessonStatus = reason.lessonStatus;
      final isDeducted = reason.isDeducted;
      final needsReschedule = reason.allowsReschedule;

      // Update lesson status
      final updatedLesson = lesson.copyWith(
        status: lessonStatus,
        feedback: confirmationResult.note ?? lesson.feedback,
        updatedAt: DateTime.now(),
      );

      await repository.updateLesson(updatedLesson);

      // Record subscription usage if deducted
      if (isDeducted) {
        final usageType = reason == LessonNonCompletionReason.studentAbsent
            ? UsageType.studentAbsent
            : UsageType.lateCancellation;

        await _recordSubscriptionUsage(
          lesson: lesson,
          usageType: usageType,
          deducted: true,
          note: confirmationResult.note,
        );
      }

      // Refresh lessons list
      ref.invalidate(lessonsProvider);
      ref.invalidate(lessonProvider(lesson.id));

      state = const AsyncValue.data(null);

      return LessonConfirmationActionResult(
        success: true,
        updatedLesson: updatedLesson,
        needsReschedule: needsReschedule,
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return LessonConfirmationActionResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Record subscription usage
  Future<void> _recordSubscriptionUsage({
    required Lesson lesson,
    required UsageType usageType,
    required bool deducted,
    String? note,
  }) async {
    try {
      // Get active subscription for student
      final subscriptions = await ref.read(
        activeStudentSubscriptionsProvider(lesson.studentId).future,
      );

      if (subscriptions.isEmpty) {
        // No active subscription, skip usage recording
        return;
      }

      // Use the first active subscription
      final subscription = subscriptions.first;

      // Create usage record
      final usage = SubscriptionUsage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        subscriptionId: subscription.id,
        lessonId: lesson.id,
        usedAt: lesson.date,
        teacherName: lesson.teacherName,
        instrument: lesson.instrument,
        note: note ?? usageType.label,
        createdAt: DateTime.now(),
        usageType: usageType,
        deducted: deducted,
      );

      // Save usage record
      final subscriptionRepo = ref.read(subscriptionRepositoryProvider);
      await subscriptionRepo.addUsage(usage);

      // Refresh subscription data
      ref.invalidate(activeStudentSubscriptionsProvider(lesson.studentId));
    } catch (e) {
      // Log error but don't fail the main operation
      // In production, this should be logged properly
    }
  }
}

/// Check if lesson needs confirmation (past scheduled lesson without notes)
@riverpod
Future<bool> lessonNeedsConfirmation(Ref ref, String lessonId) async {
  final lesson = await ref.watch(lessonProvider(lessonId).future);
  if (lesson == null) return false;

  // Only scheduled lessons need confirmation
  if (lesson.status != LessonStatus.scheduled) return false;

  // Check if lesson time has passed
  final now = DateTime.now();
  final lessonEndTime = _parseLessonEndTime(lesson);

  return lessonEndTime.isBefore(now);
}

/// Get lessons that need confirmation (past scheduled lessons)
@riverpod
Future<List<Lesson>> lessonsNeedingConfirmation(Ref ref) async {
  final lessons = await ref.watch(lessonsProvider.future);
  final now = DateTime.now();

  return lessons.where((lesson) {
    // Only scheduled lessons
    if (lesson.status != LessonStatus.scheduled) return false;

    // Check if lesson time has passed
    final lessonEndTime = _parseLessonEndTime(lesson);
    return lessonEndTime.isBefore(now);
  }).toList()
    ..sort((a, b) => b.date.compareTo(a.date)); // Most recent first
}

/// Parse lesson end time from date and startTime
DateTime _parseLessonEndTime(Lesson lesson) {
  final parts = lesson.startTime.split(':');
  final startHour = int.tryParse(parts[0]) ?? 0;
  final startMinute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;

  return DateTime(
    lesson.date.year,
    lesson.date.month,
    lesson.date.day,
    startHour,
    startMinute,
  ).add(Duration(minutes: lesson.duration));
}

/// 24-hour cancellation policy check
@riverpod
bool canCancelWithoutDeduction(Ref ref, Lesson lesson) {
  final now = DateTime.now();
  final lessonStart = _parseLessonStartTime(lesson);

  // Calculate hours until lesson
  final hoursUntilLesson = lessonStart.difference(now).inHours;

  // 24 hours or more = no deduction
  return hoursUntilLesson >= 24;
}

DateTime _parseLessonStartTime(Lesson lesson) {
  final parts = lesson.startTime.split(':');
  final startHour = int.tryParse(parts[0]) ?? 0;
  final startMinute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;

  return DateTime(
    lesson.date.year,
    lesson.date.month,
    lesson.date.day,
    startHour,
    startMinute,
  );
}
