import 'package:flutter/material.dart';

import '../../../../../core/theme/notebook_typography.dart';

/// Student info for lesson selection
class LessonStudentInfo {
  final String id;
  final String name;
  final String instrument;
  final String currentPiece;
  final Color color;

  const LessonStudentInfo({
    required this.id,
    required this.name,
    required this.instrument,
    required this.currentPiece,
    required this.color,
  });
}

/// Section title widget
class LessonFormSectionTitle extends StatelessWidget {
  final String title;

  const LessonFormSectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    // Notebook × Score: 레슨 폼 섹션 제목도 Playfair sectionTitle(17) 로 통일.
    return Text(title, style: NotebookTypography.sectionTitle);
  }
}
