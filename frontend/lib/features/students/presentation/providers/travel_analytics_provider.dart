import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/class_membership.dart';
import 'membership_providers.dart';
import 'lesson_class_providers.dart';

part 'travel_analytics_provider.g.dart';

/// Monthly travel time summary for the teacher.
class TravelAnalytics {
  final int totalMinutes;
  final int visitCount;
  final int uniqueLocations;

  const TravelAnalytics({
    this.totalMinutes = 0,
    this.visitCount = 0,
    this.uniqueLocations = 0,
  });

  /// Format total travel time as hours and minutes.
  String get formattedTotal {
    if (totalMinutes == 0) return '0분';
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours > 0 && minutes > 0) return '${hours}시간 ${minutes}분';
    if (hours > 0) return '${hours}시간';
    return '${minutes}분';
  }

  /// Average travel time per visit.
  int get averageMinutes => visitCount > 0 ? totalMinutes ~/ visitCount : 0;
}

/// Calculate monthly travel analytics from memberships.
///
/// Estimates based on: travel_time × lessons_per_week × 4 weeks.
@riverpod
Future<TravelAnalytics> monthlyTravelAnalytics(
  MonthlyTravelAnalyticsRef ref,
  String teacherId,
) async {
  final classes = await ref.watch(teacherLessonClassesProvider(teacherId).future);

  int totalMinutes = 0;
  int visitCount = 0;
  final locationIds = <String>{};

  for (final lessonClass in classes) {
    final memberships = await ref.watch(
      classMembershipsProvider(lessonClass.id).future,
    );

    for (final m in memberships) {
      if (m.travelTimeMinutes > 0) {
        final weeklyVisits = m.lessonsPerWeek;
        final monthlyVisits = weeklyVisits * 4;
        totalMinutes += m.travelTimeMinutes * monthlyVisits;
        visitCount += monthlyVisits;
        if (m.lessonLocationId != null) {
          locationIds.add(m.lessonLocationId!);
        }
      }
    }
  }

  return TravelAnalytics(
    totalMinutes: totalMinutes,
    visitCount: visitCount,
    uniqueLocations: locationIds.length,
  );
}
