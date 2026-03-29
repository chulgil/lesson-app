import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import 'student_detail_widgets.dart';

/// Tab content showing practice progress and statistics
class StudentPracticeTab extends StatelessWidget {
  final String studentId;

  const StudentPracticeTab({super.key, required this.studentId});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        // Practice progress this week
        StudentPracticeSection(studentId: studentId),

        const SizedBox(height: AppSpacing.space8),
      ],
    );
  }
}
