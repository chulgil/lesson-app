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

  String get icon {
    switch (this) {
      case TeachingResourceType.teacherRecording:
        return '🎵';
      case TeachingResourceType.youtube:
        return '🎬';
      case TeachingResourceType.externalLink:
        return '🔗';
    }
  }
}
