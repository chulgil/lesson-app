import '../../../../core/l10n/app_strings.dart';
import '../../domain/entities/teacher_post.dart';

extension PostTypeVisualX on PostType {
  String get emoji {
    switch (this) {
      case PostType.performance:
        return '🎵';
      case PostType.event:
        return '🎉';
      case PostType.notice:
        return '📢';
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
