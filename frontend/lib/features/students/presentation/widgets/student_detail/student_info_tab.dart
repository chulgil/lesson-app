import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../students/domain/entities/student.dart';
import 'student_detail_widgets.dart';

/// Tab content showing student profile info, stats, and subscription status
class StudentInfoTab extends StatelessWidget {
  final Student student;

  const StudentInfoTab({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        // Stats cards (neutral tone, no icons)
        StudentStatsCards(student: student),

        const SizedBox(height: AppSpacing.space6),

        // Subscription status
        StudentSubscriptionSection(studentId: student.id),

        const SizedBox(height: AppSpacing.space8),
      ],
    );
  }
}
