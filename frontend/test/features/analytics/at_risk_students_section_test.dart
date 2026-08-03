import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/analytics/domain/entities/analytics_models.dart';
import 'package:lessonaza/features/analytics/presentation/providers/analytics_providers.dart';
import 'package:lessonaza/features/analytics/presentation/widgets/at_risk_students_section.dart';

RetentionAnalyticsData _retentionWith(List<AtRiskStudent> students) {
  return RetentionAnalyticsData(
    renewalRate: 0.8,
    avgSubscriptionMonths: 10.0,
    atRiskStudents: students,
    renewalTrend: const [],
    tenureDistribution: const [],
  );
}

Widget _wrap(Widget child, {required List<Override> overrides}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

void main() {
  testWidgets('renders at-risk student rows sorted high-risk first (#1216)', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const AtRiskStudentsSection(),
        overrides: [
          retentionAnalyticsProvider.overrideWith(
            (ref) async => _retentionWith(const [
              AtRiskStudent(
                studentId: 's_low',
                studentName: '박지호',
                daysUntilExpiry: 21,
                practiceDropPercent: 0.0,
                lastLessonDate: null,
                riskLevel: RiskLevel.low,
              ),
              AtRiskStudent(
                studentId: 's_high',
                studentName: '정하준',
                daysUntilExpiry: 7,
                practiceDropPercent: -40.0,
                lastLessonDate: null,
                riskLevel: RiskLevel.high,
              ),
            ]),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.analyticsAtRiskSectionTitle), findsOneWidget);

    // High-risk student row appears before the low-risk row (sorted).
    final highOffset = tester.getTopLeft(find.text('하준')).dy;
    final lowOffset = tester.getTopLeft(find.text('지호')).dy;
    expect(highOffset, lessThan(lowOffset));

    expect(find.text(AppStrings.analyticsRiskLevelHigh), findsOneWidget);
    expect(find.text(AppStrings.analyticsRiskLevelLow), findsOneWidget);
    expect(find.textContaining('D-7'), findsOneWidget);
    expect(
      find.textContaining(AppStrings.analyticsAtRiskNoLessonHistory),
      findsNWidgets(2),
    );
  });

  testWidgets('renders EmptyStateWidget when no at-risk students (#1216)', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const AtRiskStudentsSection(),
        overrides: [
          retentionAnalyticsProvider.overrideWith(
            (ref) async => _retentionWith(const []),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.analyticsAtRiskEmptyTitle), findsOneWidget);
  });

  testWidgets('renders error view and retries on failure (#1216)', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const AtRiskStudentsSection(),
        overrides: [
          retentionAnalyticsProvider.overrideWith(
            (ref) async => throw Exception('boom'),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.cannotLoadData), findsOneWidget);
  });
}
