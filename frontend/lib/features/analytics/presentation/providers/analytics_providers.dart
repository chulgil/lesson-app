// Analytics providers for teacher dashboard.

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/mock_analytics_repository.dart';
import '../../domain/entities/teacher_stats.dart';

part 'analytics_providers.g.dart';

@Riverpod(keepAlive: true)
MockAnalyticsRepository analyticsRepository(AnalyticsRepositoryRef ref) {
  return MockAnalyticsRepository();
}

@riverpod
Future<TeacherMonthlyStats> teacherMonthlyStats(
  TeacherMonthlyStatsRef ref,
  DateTime month,
) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  return repository.getTeacherMonthlyStats(month);
}
