// Analytics providers for teacher dashboard.

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/repository_provider.dart';
import '../../data/repositories/mock_analytics_repository.dart';
import '../../data/repositories/remote_analytics_repository.dart';
import '../../domain/entities/teacher_stats.dart';
import '../../domain/repositories/analytics_repository.dart';

part 'analytics_providers.g.dart';

@Riverpod(keepAlive: true)
AnalyticsRepository analyticsRepository(AnalyticsRepositoryRef ref) =>
    createRepository<AnalyticsRepository>(
      ref: ref,
      mock: () => MockAnalyticsRepository(),
      remote: (api) => RemoteAnalyticsRepository(api),
    );

@riverpod
Future<TeacherMonthlyStats> teacherMonthlyStats(
  TeacherMonthlyStatsRef ref,
  DateTime month,
) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  return repository.getTeacherMonthlyStats(month);
}
