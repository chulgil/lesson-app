import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../subscription/subscription_ui_facade.dart';
import '../../../../students/domain/entities/student.dart';
import 'student_contact_card.dart';
import 'student_detail_widgets.dart';

/// Tab content showing student profile info, stats, and subscription status
class StudentInfoTab extends StatelessWidget {
  final Student student;
  final String? membershipId;

  const StudentInfoTab({super.key, required this.student, this.membershipId});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        // Contact / memo card (#24/#25) — 연락처/메모 최상단
        StudentContactCard(student: student),

        const SizedBox(height: AppSpacing.space6),

        // Stats cards (neutral tone, no icons)
        StudentStatsCards(student: student),

        const SizedBox(height: AppSpacing.space6),

        // Subscription status (filtered by membershipId if provided)
        StudentSubscriptionSection(
          studentId: student.id,
          membershipId: membershipId,
        ),

        const SizedBox(height: AppSpacing.space6),

        // 보강 크레딧 관리 (#1165 진입점) — 발급/회수 인라인.
        TeacherMakeupCreditSection(studentId: student.id),

        const SizedBox(height: AppSpacing.space8),
      ],
    );
  }
}
