import 'package:flutter/material.dart';

import '../../domain/entities/teaching_resource.dart';

extension TeachingResourceTypeVisuals on TeachingResourceType {
  String get label {
    switch (this) {
      case TeachingResourceType.teacherRecording:
        return '녹음';
      case TeachingResourceType.youtube:
        return '유튜브';
      case TeachingResourceType.externalLink:
        return '링크';
    }
  }

  IconData get icon {
    switch (this) {
      case TeachingResourceType.teacherRecording:
        return Icons.music_note;
      case TeachingResourceType.youtube:
        return Icons.smart_display;
      case TeachingResourceType.externalLink:
        return Icons.link;
    }
  }
}
