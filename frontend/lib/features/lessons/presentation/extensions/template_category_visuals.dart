import '../../domain/entities/feedback_template.dart';
import '../../domain/entities/tip_template.dart';

extension FeedbackCategoryVisuals on FeedbackCategory {
  String get label {
    switch (this) {
      case FeedbackCategory.technique:
        return '테크닉';
      case FeedbackCategory.musicality:
        return '음악성';
      case FeedbackCategory.practice:
        return '연습';
      case FeedbackCategory.attitude:
        return '태도';
      case FeedbackCategory.general:
        return '일반';
    }
  }
}

extension TipCategoryVisuals on TipCategory {
  String get label {
    switch (this) {
      case TipCategory.technique:
        return '테크닉';
      case TipCategory.musicality:
        return '음악성';
      case TipCategory.practice:
        return '연습법';
      case TipCategory.mindset:
        return '마인드셋';
      case TipCategory.general:
        return '일반';
    }
  }

  String get icon {
    switch (this) {
      case TipCategory.technique:
        return 'build';
      case TipCategory.musicality:
        return 'music_note';
      case TipCategory.practice:
        return 'repeat';
      case TipCategory.mindset:
        return 'psychology';
      case TipCategory.general:
        return 'lightbulb';
    }
  }
}
