import '../../../../core/l10n/app_strings.dart';
import '../../domain/entities/review.dart';

extension ReviewAuthorTypeVisuals on ReviewAuthorType {
  String get label {
    switch (this) {
      case ReviewAuthorType.student:
        return AppStrings.reviewAuthorStudent;
      case ReviewAuthorType.parent:
        return AppStrings.reviewAuthorParent;
    }
  }
}

extension ReviewVisibilityVisuals on ReviewVisibility {
  String get label {
    switch (this) {
      case ReviewVisibility.public:
        return AppStrings.reviewVisibilityPublic;
      case ReviewVisibility.teacherOnly:
        return AppStrings.reviewVisibilityTeacherOnly;
    }
  }
}

extension TeacherReviewVisuals on TeacherReview {
  String get displayAuthorName {
    if (isAnonymous) {
      return authorType.label;
    }
    return authorName;
  }

  String get authorBadge {
    final badge = authorType.label;
    if (isVerified) {
      return '$badge ✓';
    }
    return badge;
  }
}
