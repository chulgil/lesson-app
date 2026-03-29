import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import 'student_detail_widgets.dart';

/// Tab content showing upcoming lessons, recent lessons, and lesson notes
class StudentLessonsTab extends StatelessWidget {
  final String studentId;

  const StudentLessonsTab({super.key, required this.studentId});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        // Upcoming lessons — teacher's primary concern
        StudentUpcomingLessonsSection(studentId: studentId),

        const SizedBox(height: AppSpacing.space6),

        // Recent lesson history
        StudentRecentLessonsSection(studentId: studentId),

        const SizedBox(height: AppSpacing.space6),

        // Lesson notes history
        StudentNotesSection(studentId: studentId),

        const SizedBox(height: AppSpacing.space8),
      ],
    );
  }
}
