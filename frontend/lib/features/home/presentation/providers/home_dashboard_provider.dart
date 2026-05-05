import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/auth_facade.dart';
import '../../../lessons/lessons_facade.dart';
import '../../../schedule/schedule_facade.dart';
import '../../../subscription/subscription_facade.dart';

class HomeDashboardData {
  final AsyncValue<List<Lesson>> lessons;
  final AsyncValue<Map<String, int>> lessonStats;
  final String teacherId;
  final AsyncValue<({int studentCount, int totalAmount})> unpaidSummary;
  final AsyncValue<List<Lesson>> needsConfirmation;

  const HomeDashboardData({
    required this.lessons,
    required this.lessonStats,
    required this.teacherId,
    required this.unpaidSummary,
    required this.needsConfirmation,
  });
}

final homeDashboardProvider = Provider<HomeDashboardData>((ref) {
  final teacherId = ref.watch(currentUserIdProvider);

  return HomeDashboardData(
    lessons: ref.watch(lessonsProvider),
    lessonStats: ref.watch(lessonStatsProvider),
    teacherId: teacherId,
    unpaidSummary: ref.watch(unpaidSummaryProvider(teacherId)),
    needsConfirmation: ref.watch(lessonsNeedingConfirmationProvider),
  );
});

final homeDashboardRefreshProvider = Provider<HomeDashboardRefresh>(
  HomeDashboardRefresh.new,
);

class HomeDashboardRefresh {
  final Ref _ref;

  const HomeDashboardRefresh(this._ref);

  Future<void> refresh(String teacherId) async {
    _ref
      ..invalidate(lessonsProvider)
      ..invalidate(lessonStatsProvider)
      ..invalidate(unpaidSummaryProvider(teacherId))
      ..invalidate(pendingBookingsCountProvider(teacherId))
      ..invalidate(todayRequestsProvider(teacherId))
      ..invalidate(expiringSoonSubscriptionsProvider)
      ..invalidate(expiredSubscriptionsProvider)
      ..invalidate(lessonsNeedingConfirmationProvider);
  }
}
