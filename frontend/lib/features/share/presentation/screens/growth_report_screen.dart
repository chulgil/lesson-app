import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../core/config/environment.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';

typedef PublicGrowthReportLoader =
    Future<PublicGrowthReportViewData> Function(String token);

/// #1217 — 공개 자녀 성장 리포트 뷰 데이터. 서버가 반환하는 최소 필드만 보유
/// (연락처·주소·결제·상세 레슨노트는 백엔드가 애초에 응답에 포함하지 않는다).
class PublicGrowthReportViewData {
  const PublicGrowthReportViewData({
    required this.givenName,
    required this.instrument,
    required this.practiceStreakDays,
    required this.recentLessonCount,
    required this.progressSummary,
  });

  final String givenName;
  final String instrument;
  final int practiceStreakDays;
  final int recentLessonCount;
  final String progressSummary;

  factory PublicGrowthReportViewData.fromJson(Map<String, dynamic> json) {
    final child = json['child'] as Map<String, dynamic>? ?? const {};
    final metrics = json['metrics'] as Map<String, dynamic>? ?? const {};
    return PublicGrowthReportViewData(
      givenName: child['given_name'] as String? ?? '',
      instrument: child['instrument'] as String? ?? '',
      practiceStreakDays:
          (metrics['practice_streak_days'] as num?)?.toInt() ?? 0,
      recentLessonCount: (metrics['recent_lesson_count'] as num?)?.toInt() ?? 0,
      progressSummary: metrics['progress_summary'] as String? ?? '',
    );
  }
}

/// 공개 공유 토큰으로 진입하는 읽기 전용 자녀 성장 리포트 화면.
///
/// 로그인 없이 접근 가능 — 방식 B(무가입 리포트 프리뷰). 서버가 반환하는
/// 필드만 표시하므로(이름+성장지표) 화면 레벨에서 추가 PII 노출 위험이 없다.
class GrowthReportScreen extends StatefulWidget {
  const GrowthReportScreen({super.key, required this.token, this.loader});

  final String token;
  final PublicGrowthReportLoader? loader;

  @override
  State<GrowthReportScreen> createState() => _GrowthReportScreenState();
}

class _GrowthReportScreenState extends State<GrowthReportScreen> {
  late final Future<PublicGrowthReportViewData>? _reportFuture;

  @override
  void initState() {
    super.initState();
    _reportFuture = widget.token.isEmpty
        ? null
        : (widget.loader ?? _loadPublicGrowthReport)(widget.token);
  }

  @override
  Widget build(BuildContext context) {
    return NotebookScreenScaffold(
      appBar: const NotebookDetailAppBar(
        title: AppStrings.growthReportAppBarTitle,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: _reportFuture == null
              ? const _EmptyTokenState()
              : FutureBuilder<PublicGrowthReportViewData>(
                  future: _reportFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError || snapshot.data == null) {
                      return const _EmptyTokenState();
                    }
                    return _GrowthReportContent(report: snapshot.data!);
                  },
                ),
        ),
      ),
    );
  }
}

Future<PublicGrowthReportViewData> _loadPublicGrowthReport(String token) async {
  final dio = Dio(
    BaseOptions(
      baseUrl: EnvironmentConfig.apiBaseUrl,
      connectTimeout: Duration(
        seconds: EnvironmentConfig.requestTimeoutSeconds,
      ),
      receiveTimeout: Duration(
        seconds: EnvironmentConfig.requestTimeoutSeconds,
      ),
      headers: const {'Accept': 'application/json'},
    ),
  );
  final response = await dio.get<Map<String, dynamic>>(
    '/public/growth-reports/${Uri.encodeComponent(token)}',
  );
  return PublicGrowthReportViewData.fromJson(response.data ?? const {});
}

class _GrowthReportContent extends StatelessWidget {
  const _GrowthReportContent({required this.report});

  final PublicGrowthReportViewData report;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Text(
          report.givenName,
          style: AppTypography.headingLarge.copyWith(color: AppColors.ink),
        ),
        const SizedBox(height: AppSpacing.space1),
        Text(
          report.instrument,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.inkTertiary,
          ),
        ),
        const SizedBox(height: AppSpacing.space6),
        NotebookCard(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MetricRow(
                  label: AppStrings.growthReportStreakLabel,
                  value: '${report.practiceStreakDays}일',
                ),
                _MetricRow(
                  label: AppStrings.growthReportRecentLessonsLabel,
                  value: '${report.recentLessonCount}회',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.space4),
        Text(
          report.progressSummary,
          style: AppTypography.bodyMedium.copyWith(color: AppColors.ink),
        ),
      ],
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.inkTertiary,
              ),
            ),
          ),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.ink),
          ),
        ],
      ),
    );
  }
}

class _EmptyTokenState extends StatelessWidget {
  const _EmptyTokenState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        AppStrings.errorOccurredRetryAgain,
        style: TextStyle(color: AppColors.inkSecondary),
        textAlign: TextAlign.center,
      ),
    );
  }
}
