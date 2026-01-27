import 'package:flutter/material.dart';

import '../../../lessons/domain/entities/lesson.dart';
import '../entities/availability_slot.dart';

/// Service for recommending time slots based on lesson history
///
/// Analyzes past lesson patterns to suggest optimal booking times.
/// Uses configurable time windows for history analysis.
class SlotRecommendationService {
  /// Default analysis window in days (3 months)
  static const int defaultAnalysisWindowDays = 90;

  /// Minimum lesson count to consider a pattern
  static const int minPatternCount = 2;

  /// Analyze lesson history and return slot patterns
  ///
  /// Examines lessons within [analysisWindowDays] to identify
  /// recurring time patterns (same day of week and time).
  static List<LessonTimePattern> analyzeLessonHistory({
    required List<Lesson> lessons,
    required String teacherId,
    int analysisWindowDays = defaultAnalysisWindowDays,
  }) {
    final cutoffDate = DateTime.now().subtract(
      Duration(days: analysisWindowDays),
    );

    // Filter lessons within analysis window and for specific teacher
    final relevantLessons = lessons.where((lesson) {
      return lesson.teacherId == teacherId &&
          lesson.date.isAfter(cutoffDate) &&
          (lesson.status == LessonStatus.completed ||
              lesson.status == LessonStatus.scheduled);
    }).toList();

    if (relevantLessons.isEmpty) return [];

    // Group by day of week and time
    final patternMap = <String, LessonTimePattern>{};

    for (final lesson in relevantLessons) {
      final timeParts = lesson.startTime.split(':');
      final hour = int.tryParse(timeParts[0]) ?? 0;
      final minute = int.tryParse(timeParts.length > 1 ? timeParts[1] : '0') ?? 0;

      final key = '${lesson.date.weekday}_${hour}_$minute';

      if (patternMap.containsKey(key)) {
        patternMap[key] = patternMap[key]!.copyWith(
          count: patternMap[key]!.count + 1,
          lastLessonDate: lesson.date.isAfter(patternMap[key]!.lastLessonDate)
              ? lesson.date
              : patternMap[key]!.lastLessonDate,
        );
      } else {
        patternMap[key] = LessonTimePattern(
          dayOfWeek: lesson.date.weekday,
          hour: hour,
          minute: minute,
          count: 1,
          lastLessonDate: lesson.date,
        );
      }
    }

    // Filter patterns with minimum count and sort by frequency
    return patternMap.values
        .where((p) => p.count >= minPatternCount)
        .toList()
      ..sort((a, b) {
        // Sort by count descending, then by recency
        final countCompare = b.count.compareTo(a.count);
        if (countCompare != 0) return countCompare;
        return b.lastLessonDate.compareTo(a.lastLessonDate);
      });
  }

  /// Mark recommended slots based on lesson patterns
  ///
  /// Returns a new list with [isRecommended] set to true for
  /// slots matching the student's usual lesson times.
  static List<AvailabilitySlot> markRecommendedSlots({
    required List<AvailabilitySlot> slots,
    required List<LessonTimePattern> patterns,
  }) {
    if (patterns.isEmpty) return slots;

    return slots.map((slot) {
      final isRecommended = patterns.any((pattern) =>
          slot.date.weekday == pattern.dayOfWeek &&
          slot.startTime.hour == pattern.hour &&
          slot.startTime.minute == pattern.minute);

      if (isRecommended && slot.status == AvailabilitySlotStatus.available) {
        return slot.copyWith(isRecommended: true);
      }
      return slot;
    }).toList();
  }

  /// Get recommended slots from available slots
  ///
  /// Filters and returns only the slots that match lesson patterns.
  static List<AvailabilitySlot> getRecommendedSlots({
    required List<AvailabilitySlot> slots,
    required List<LessonTimePattern> patterns,
    int limit = 5,
  }) {
    if (patterns.isEmpty) return [];

    final recommended = <AvailabilitySlot>[];

    for (final slot in slots) {
      if (slot.status != AvailabilitySlotStatus.available) continue;

      final matchingPattern = patterns.firstWhere(
        (pattern) =>
            slot.date.weekday == pattern.dayOfWeek &&
            slot.startTime.hour == pattern.hour &&
            slot.startTime.minute == pattern.minute,
        orElse: () => LessonTimePattern.empty(),
      );

      if (matchingPattern.count > 0) {
        recommended.add(slot.copyWith(
          isRecommended: true,
        ));
      }

      if (recommended.length >= limit) break;
    }

    return recommended;
  }

  /// Calculate recommendation score for a slot
  ///
  /// Higher scores indicate better matches based on:
  /// - Pattern frequency (lesson count)
  /// - Recency of last lesson at this time
  static double calculateRecommendationScore(
    AvailabilitySlot slot,
    List<LessonTimePattern> patterns,
  ) {
    final matchingPattern = patterns.firstWhere(
      (pattern) =>
          slot.date.weekday == pattern.dayOfWeek &&
          slot.startTime.hour == pattern.hour &&
          slot.startTime.minute == pattern.minute,
      orElse: () => LessonTimePattern.empty(),
    );

    if (matchingPattern.count == 0) return 0.0;

    // Base score from frequency (max 50 points)
    final frequencyScore = (matchingPattern.count / 10).clamp(0.0, 5.0) * 10;

    // Recency bonus (max 30 points, decreases over 30 days)
    final daysSinceLastLesson =
        DateTime.now().difference(matchingPattern.lastLessonDate).inDays;
    final recencyScore =
        ((30 - daysSinceLastLesson) / 30).clamp(0.0, 1.0) * 30;

    // Day proximity bonus (max 20 points for closer dates)
    final daysUntilSlot = slot.date.difference(DateTime.now()).inDays;
    final proximityScore = ((14 - daysUntilSlot) / 14).clamp(0.0, 1.0) * 20;

    return frequencyScore + recencyScore + proximityScore;
  }
}

/// Represents a recurring lesson time pattern
class LessonTimePattern {
  /// Day of week (1=Monday, 7=Sunday)
  final int dayOfWeek;

  /// Hour of day (0-23)
  final int hour;

  /// Minute (0-59)
  final int minute;

  /// Number of lessons at this time
  final int count;

  /// Date of most recent lesson at this time
  final DateTime lastLessonDate;

  const LessonTimePattern({
    required this.dayOfWeek,
    required this.hour,
    required this.minute,
    required this.count,
    required this.lastLessonDate,
  });

  /// Empty pattern (for null safety)
  factory LessonTimePattern.empty() => LessonTimePattern(
        dayOfWeek: 0,
        hour: 0,
        minute: 0,
        count: 0,
        lastLessonDate: DateTime(1970),
      );

  /// Get TimeOfDay representation
  TimeOfDay get timeOfDay => TimeOfDay(hour: hour, minute: minute);

  /// Get weekday name in Korean
  String get weekdayName {
    const names = ['월', '화', '수', '목', '금', '토', '일'];
    if (dayOfWeek < 1 || dayOfWeek > 7) return '';
    return names[dayOfWeek - 1];
  }

  /// Get formatted time string
  String get formattedTime {
    final hourStr = hour.toString().padLeft(2, '0');
    final minuteStr = minute.toString().padLeft(2, '0');
    return '$hourStr:$minuteStr';
  }

  /// Get description for display
  String get description => '$weekdayName요일 $formattedTime ($count회)';

  LessonTimePattern copyWith({
    int? dayOfWeek,
    int? hour,
    int? minute,
    int? count,
    DateTime? lastLessonDate,
  }) {
    return LessonTimePattern(
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      count: count ?? this.count,
      lastLessonDate: lastLessonDate ?? this.lastLessonDate,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LessonTimePattern &&
        other.dayOfWeek == dayOfWeek &&
        other.hour == hour &&
        other.minute == minute;
  }

  @override
  int get hashCode => Object.hash(dayOfWeek, hour, minute);

  @override
  String toString() =>
      'LessonTimePattern($weekdayName $formattedTime, count: $count)';
}
