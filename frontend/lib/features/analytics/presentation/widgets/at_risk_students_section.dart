// At-risk students section — read-only surfacing of retention_service output.
// Refs #1216 (BE detection + retentionAnalytics provider already wired).
//
// This is pure wiring: the risk detection already runs server-side and the
// FE provider already fetches it — no screen displayed it until now. This
// section is intentionally read-only: no nudge/message/re-engage action is
// included here (channel + copy is a separate, still-undecided product
// decision).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/utils/name_utils.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../domain/entities/analytics_models.dart';
import '../extensions/risk_level_visuals.dart';
import '../providers/analytics_providers.dart';
import 'analytics_error_view.dart';

/// Read-only "이탈 위험 학생" section for the 월간요약 tab.
///
/// Watches [retentionAnalyticsProvider] and lists
/// [RetentionAnalyticsData.atRiskStudents] sorted high-risk first (declared
/// [RiskLevel] enum order already is high -> medium -> low).
class AtRiskStudentsSection extends ConsumerWidget {
  const AtRiskStudentsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final retentionAsync = ref.watch(retentionAnalyticsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.analyticsAtRiskSectionTitle,
          style: NotebookTypography.sectionTitle,
        ),
        const SizedBox(height: AppSpacing.space3),
        retentionAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error:
              (_, _) => AnalyticsErrorView(
                onRetry: () => ref.invalidate(retentionAnalyticsProvider),
              ),
          data: (data) => _AtRiskStudentList(students: data.atRiskStudents),
        ),
      ],
    );
  }
}

class _AtRiskStudentList extends StatelessWidget {
  const _AtRiskStudentList({required this.students});

  final List<AtRiskStudent> students;

  @override
  Widget build(BuildContext context) {
    if (students.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.check_circle_outline,
        title: AppStrings.analyticsAtRiskEmptyTitle,
      );
    }

    final sorted = [...students]
      ..sort((a, b) => a.riskLevel.index.compareTo(b.riskLevel.index));

    return Column(
      children:
          sorted.map((student) => _AtRiskStudentRow(student: student)).toList(),
    );
  }
}

class _AtRiskStudentRow extends StatelessWidget {
  const _AtRiskStudentRow({required this.student});

  final AtRiskStudent student;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.space3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            NameUtils.givenName(student.studentName),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.space2),
                        _RiskLevelBadge(riskLevel: student.riskLevel),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.space1),
                    Text(
                      _signalsLine(student),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.inkSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(height: 1, color: AppColors.inkQuaternary),
      ],
    );
  }

  /// Composes the compact signal line: D-day / no-expiry, practice drop,
  /// last lesson / no-history — joined in a single subtitle row.
  String _signalsLine(AtRiskStudent s) {
    final parts = <String>[
      s.daysUntilExpiry != null
          ? AppStrings.subscriptionBadgeDday(s.daysUntilExpiry!)
          : AppStrings.analyticsAtRiskNoExpiry,
      AppStrings.analyticsAtRiskPracticeDropFormat(s.practiceDropPercent),
      s.lastLessonDate != null
          ? AppStrings.lastLessonOn(
            s.lastLessonDate!.month,
            s.lastLessonDate!.day,
          )
          : AppStrings.analyticsAtRiskNoLessonHistory,
    ];
    return parts.join(' · ');
  }
}

class _RiskLevelBadge extends StatelessWidget {
  const _RiskLevelBadge({required this.riskLevel});

  final RiskLevel riskLevel;

  @override
  Widget build(BuildContext context) {
    final color = riskLevel.color;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space2,
        vertical: 2,
      ),
      decoration: BoxDecoration(border: Border.all(color: color, width: 1)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(riskLevel.icon, size: 11, color: color),
          const SizedBox(width: AppSpacing.space1),
          Text(
            riskLevel.label,
            style: AppTypography.captionSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
