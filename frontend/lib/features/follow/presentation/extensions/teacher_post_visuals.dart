import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../domain/entities/teacher_post.dart';

extension PostTypeVisualX on PostType {
  IconData get icon {
    switch (this) {
      case PostType.performance:
        return Icons.music_note;
      case PostType.event:
        return Icons.celebration;
      case PostType.notice:
        return Icons.campaign;
    }
  }

  String get label {
    switch (this) {
      case PostType.performance:
        return AppStrings.postTypePerformance;
      case PostType.event:
        return AppStrings.postTypeEvent;
      case PostType.notice:
        return AppStrings.postTypeNotice;
    }
  }
}
