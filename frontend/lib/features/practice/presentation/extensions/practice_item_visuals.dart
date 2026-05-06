import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/practice_item.dart';

extension PracticePriorityVisuals on PracticePriority {
  Color get color {
    return switch (this) {
      PracticePriority.must => AppColors.paperAccent,
      PracticePriority.should => AppColors.practiceNormal,
      PracticePriority.could => AppColors.paperOk,
    };
  }
}

extension PracticeTypeVisuals on PracticeType {
  IconData get icon {
    return switch (this) {
      PracticeType.repertoire => Icons.music_note,
      PracticeType.technique => Icons.piano,
      PracticeType.theory => Icons.menu_book,
      PracticeType.custom => Icons.edit_note,
    };
  }
}
