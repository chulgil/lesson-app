// Lesson assignments section — practice items list for the lesson detail
// single-scroll layout (doc 41 §6.1: 2탭→단일 스크롤 통합).

import 'package:flutter/material.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../practice_items_section.dart';
import 'lesson_notes_widgets.dart';

/// Assignments section for the lesson detail single-scroll layout.
///
/// Extracted from `LessonDetailScreen._buildAssignmentsTab` — same content,
/// no behavior change. Section header kept in-scroll so the content stays
/// labeled without a tab.
class LessonAssignmentsSection extends StatelessWidget {
  final String lessonId;
  final String studentId;
  final bool isTeacher;

  const LessonAssignmentsSection({
    super.key,
    required this.lessonId,
    required this.studentId,
    required this.isTeacher,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LessonDetailSectionHeader(
          title: AppStrings.assignmentsTab,
          icon: Icons.assignment_outlined,
        ),
        const SizedBox(height: AppSpacing.space3),
        PracticeItemsSection(
          lessonId: lessonId,
          studentId: studentId,
          isTeacher: isTeacher,
        ),
      ],
    );
  }
}
