// Analytics providers for teacher dashboard and student progress views.

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/repository_provider.dart';
import '../../data/repositories/mock_analytics_repository.dart';
import '../../data/repositories/remote_analytics_repository.dart';
import '../../data/services/mock_analytics_service.dart';
import '../../domain/entities/analytics_data.dart';
import '../../domain/entities/analytics_models.dart';
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

// analyticsService provides legacy summary aggregations (teacher monthly
// summary, student analytics summary) that do not yet have backend endpoints.
// It always returns mock data regardless of mode — the assert that previously
// crashed debug builds in real mode has been removed because the crash was
// unhelpful: the missing BE endpoints are tracked separately, not via asserts.
@Riverpod(keepAlive: true)
MockAnalyticsService analyticsService(AnalyticsServiceRef ref) =>
    MockAnalyticsService();

@riverpod
Future<TeacherMonthlyStats> teacherMonthlyStats(
  TeacherMonthlyStatsRef ref,
  DateTime month,
) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  return repository.getTeacherMonthlyStats(month);
}

@riverpod
Future<TeacherMonthlySummary> teacherMonthlySummary(
  TeacherMonthlySummaryRef ref, {
  required int year,
  required int month,
}) async {
  final service = ref.watch(analyticsServiceProvider);
  return service.getTeacherMonthlySummary(year: year, month: month);
}

// New repo-based provider: replaces the service-based studentProgress
@riverpod
Future<StudentProgressData> studentProgressData(
  StudentProgressDataRef ref,
  String studentId,
  AnalyticsPeriod period,
) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  return repository.getStudentProgress(studentId, period: period);
}

// Legacy service-based provider kept for existing consumers
@riverpod
Future<StudentProgress> studentProgress(
  StudentProgressRef ref, {
  required String studentId,
  required int months,
}) async {
  final service = ref.watch(analyticsServiceProvider);
  return service.getStudentProgress(studentId: studentId, months: months);
}

@riverpod
Future<RevenueAnalyticsData> revenueAnalyticsData(
  RevenueAnalyticsDataRef ref,
  int periodMonths,
) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  return repository.getRevenueAnalytics(periodMonths: periodMonths);
}

// Legacy service-based revenue analytics
@riverpod
Future<RevenueAnalytics> revenueAnalytics(
  RevenueAnalyticsRef ref, {
  required int months,
}) async {
  final service = ref.watch(analyticsServiceProvider);
  return service.getRevenueAnalytics(months: months);
}

@riverpod
Future<RetentionAnalyticsData> retentionAnalytics(
  RetentionAnalyticsRef ref,
) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  return repository.getRetentionAnalytics();
}

@riverpod
Future<List<StudentSummaryItem>> studentSummaryList(
  StudentSummaryListRef ref,
  DateTime month,
) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  return repository.getStudentSummaryList(month);
}

@riverpod
Future<StudentAnalyticsSummary> studentAnalyticsSummary(
  StudentAnalyticsSummaryRef ref, {
  required String studentId,
}) async {
  final service = ref.watch(analyticsServiceProvider);
  return service.getStudentAnalyticsSummary(studentId: studentId);
}
