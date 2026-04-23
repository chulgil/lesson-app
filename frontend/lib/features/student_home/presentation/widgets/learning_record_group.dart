import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/notebook/thin_rule.dart';
import 'dashboard/dashboard_widgets.dart';
import 'trial_bookings_section.dart';

/// 학습 기록 그룹 — 선생님 피드백 + 연습 요약 + 체험 레슨을 시각적으로 묶음.
///
/// 학생 홈 섹션 수를 10 → 8 로 축약(Miller 7±2 부합).
/// 데이터 통합 X, 시각적 묶음만. 각 섹션의 자체 빈 상태 로직은 그대로 유지.
class LearningRecordGroup extends StatelessWidget {
  const LearningRecordGroup({super.key, required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TeacherFeedbackSection(studentId: studentId),
        const SizedBox(height: AppSpacing.space3),
        const ThinRule(),
        const SizedBox(height: AppSpacing.space3),
        PracticeSummarySection(studentId: studentId),
        const SizedBox(height: AppSpacing.space3),
        const ThinRule(),
        const SizedBox(height: AppSpacing.space3),
        TrialBookingsSection(studentId: studentId),
      ],
    );
  }
}
