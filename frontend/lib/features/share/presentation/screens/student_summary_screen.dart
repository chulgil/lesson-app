import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../core/config/environment.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';

typedef PublicLessonSummaryLoader =
    Future<PublicLessonSummaryViewData> Function(String token);

class PublicLessonSummaryViewData {
  const PublicLessonSummaryViewData({
    required this.studentName,
    required this.instrument,
    required this.teacherName,
    required this.lessonDate,
    required this.startTime,
    required this.durationMinutes,
    this.feedback,
    this.practiceTips,
    this.studentNote,
    this.keyPoints = const [],
  });

  final String studentName;
  final String instrument;
  final String? teacherName;
  final String lessonDate;
  final String startTime;
  final int durationMinutes;
  final String? feedback;
  final String? practiceTips;
  final String? studentNote;
  final List<String> keyPoints;

  factory PublicLessonSummaryViewData.fromJson(Map<String, dynamic> json) {
    final lesson = json['lesson'] as Map<String, dynamic>? ?? const {};
    final teacher = json['teacher'] as Map<String, dynamic>? ?? const {};
    final student = json['student'] as Map<String, dynamic>? ?? const {};
    final summary = json['summary'] as Map<String, dynamic>? ?? const {};
    return PublicLessonSummaryViewData(
      studentName: student['name'] as String? ?? '',
      instrument: student['instrument'] as String? ?? '',
      teacherName: teacher['name'] as String?,
      lessonDate: lesson['date'] as String? ?? '',
      startTime: lesson['start_time'] as String? ?? '',
      durationMinutes: (lesson['duration_minutes'] as num?)?.toInt() ?? 0,
      feedback: summary['feedback'] as String?,
      practiceTips: summary['practice_tips'] as String?,
      studentNote: summary['student_note'] as String?,
      keyPoints: _keyPointsFromJson(summary['key_points']),
    );
  }

  static List<String> _keyPointsFromJson(Object? value) {
    if (value is List) {
      return value.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }
    if (value is Map) {
      return value.values
          .expand((e) => e is List ? e : [e])
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return const [];
  }
}

/// 공개 공유 토큰으로 진입하는 읽기 전용 레슨 요약 화면.
class StudentSummaryScreen extends StatefulWidget {
  const StudentSummaryScreen({super.key, required this.token, this.loader});

  final String token;
  final PublicLessonSummaryLoader? loader;

  @override
  State<StudentSummaryScreen> createState() => _StudentSummaryScreenState();
}

class _StudentSummaryScreenState extends State<StudentSummaryScreen> {
  late final Future<PublicLessonSummaryViewData>? _summaryFuture;

  @override
  void initState() {
    super.initState();
    _summaryFuture =
        widget.token.isEmpty
            ? null
            : (widget.loader ?? _loadPublicLessonSummary)(widget.token);
  }

  @override
  Widget build(BuildContext context) {
    return NotebookScreenScaffold(
      appBar: const NotebookDetailAppBar(
        title: AppStrings.studentSummaryAppBarTitle,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child:
              _summaryFuture == null
                  ? _EmptyTokenState(token: widget.token)
                  : FutureBuilder<PublicLessonSummaryViewData>(
                    future: _summaryFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError || snapshot.data == null) {
                        return _SummaryErrorState(token: widget.token);
                      }
                      return _SummaryContent(summary: snapshot.data!);
                    },
                  ),
        ),
      ),
    );
  }
}

Future<PublicLessonSummaryViewData> _loadPublicLessonSummary(
  String token,
) async {
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
    '/public/student-summaries/${Uri.encodeComponent(token)}',
  );
  return PublicLessonSummaryViewData.fromJson(response.data ?? const {});
}

class _SummaryContent extends StatelessWidget {
  const _SummaryContent({required this.summary});

  final PublicLessonSummaryViewData summary;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Text(
          summary.studentName,
          style: AppTypography.headingLarge.copyWith(color: AppColors.ink),
        ),
        const SizedBox(height: AppSpacing.space1),
        Text(
          summary.instrument,
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
                _LabelValue(label: '수업일', value: summary.lessonDate),
                _LabelValue(label: '시작 시간', value: summary.startTime),
                _LabelValue(
                  label: '수업 시간',
                  value: '${summary.durationMinutes}분',
                ),
                if (summary.teacherName?.isNotEmpty == true)
                  _LabelValue(label: '선생님', value: summary.teacherName!),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.space4),
        if (summary.feedback?.isNotEmpty == true)
          _Section(title: '피드백', body: summary.feedback!),
        if (summary.practiceTips?.isNotEmpty == true)
          _Section(title: '연습 팁', body: summary.practiceTips!),
        if (summary.studentNote?.isNotEmpty == true)
          _Section(title: '학생 메모', body: summary.studentNote!),
        if (summary.keyPoints.isNotEmpty)
          _Section(title: '핵심 포인트', items: summary.keyPoints),
      ],
    );
  }
}

class _LabelValue extends StatelessWidget {
  const _LabelValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space2),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.inkTertiary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, this.body, this.items = const []});

  final String title;
  final String? body;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.headingSmall.copyWith(color: AppColors.ink),
          ),
          const SizedBox(height: AppSpacing.space2),
          if (body != null)
            Text(
              body!,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.ink),
            ),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.space1),
              child: Text(
                item,
                style: AppTypography.bodyMedium.copyWith(color: AppColors.ink),
              ),
            ),
        ],
      ),
    );
  }
}

class _SummaryErrorState extends StatelessWidget {
  const _SummaryErrorState({required this.token});

  final String token;

  @override
  Widget build(BuildContext context) {
    return _CenteredMessage(
      title: AppStrings.errorOccurredRetryAgain,
      token: token,
    );
  }
}

class _EmptyTokenState extends StatelessWidget {
  const _EmptyTokenState({required this.token});

  final String token;

  @override
  Widget build(BuildContext context) {
    return _CenteredMessage(
      title: AppStrings.studentSummaryComingSoon,
      token: token,
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({required this.title, required this.token});

  final String title;
  final String token;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: AppTypography.headingMedium.copyWith(
              color: AppColors.inkSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (token.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.space6),
            Text(
              AppStrings.studentSummaryTokenLabel,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.inkTertiary,
              ),
            ),
            const SizedBox(height: AppSpacing.space1),
            SelectableText(
              token,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.inkSecondary,
                fontFamily: 'monospace',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
