import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../auth/auth_facade.dart';
import '../../../lessons/lessons_facade.dart';
import '../../../schedule/schedule_facade.dart';
import '../../../subscription/subscription_facade.dart';

part 'home_dashboard_provider.g.dart';

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

@Riverpod(keepAlive: true)
HomeDashboardData homeDashboard(HomeDashboardRef ref) {
  final teacherId = ref.watch(currentUserIdProvider);

  return HomeDashboardData(
    lessons: ref.watch(lessonsProvider),
    lessonStats: ref.watch(lessonStatsProvider),
    teacherId: teacherId,
    unpaidSummary: ref.watch(unpaidSummaryProvider(teacherId)),
    needsConfirmation: ref.watch(lessonsNeedingConfirmationProvider),
  );
}

@Riverpod(keepAlive: true)
HomeDashboardRefresh homeDashboardRefresh(HomeDashboardRefreshRef ref) {
  return HomeDashboardRefresh(ref);
}

class HomeDashboardRefresh {
  final HomeDashboardRefreshRef _ref;

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
