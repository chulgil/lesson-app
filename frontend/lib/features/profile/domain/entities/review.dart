// Review domain entity
// Moved from lib/models/review.dart for Clean Architecture

/// Review author type - who wrote the review
/// TeacherReview.authorType 필드 타입 + copyWith/displayAuthorName/isParentReview에 배선됨.
/// 리뷰 작성 UI 미구현 — 학생/학부모 리뷰 플로우 구현 시 활용.
// ignore: unused-enum
enum ReviewAuthorType {
  student, // Student wrote the review
  parent, // Parent wrote the review
}

/// Review visibility - who can see the review
/// TeacherReview.visibility 필드 타입. 리뷰 작성 폼 미구현 — 공개 범위 선택 UI 구현 시 활용.
// ignore: unused-enum
enum ReviewVisibility {
  public, // Anyone can see
  teacherOnly, // Only the teacher can see
}

/// Teacher review model
/// Both students and parents can write reviews based on Q9:C decision
class TeacherReview {
  final String id;
  final String teacherId;
  final String teacherName;
  final String studentId; // The student being taught
  final String studentName;

  // Author info
  final ReviewAuthorType authorType;
  final String authorId; // Student ID or Parent ID
  final String authorName;

  // Review content
  final int rating; // 1-5 stars
  final String? content;
  final List<String> tags; // e.g., ['친절함', '설명 잘함', '열정적']

  // Visibility and status
  final ReviewVisibility visibility;
  final bool isAnonymous; // Display as anonymous
  final bool isVerified; // Verified student/parent relationship
  final bool isActive; // Soft delete support

  final DateTime createdAt;
  final DateTime? updatedAt;

  const TeacherReview({
    required this.id,
    required this.teacherId,
    required this.teacherName,
    required this.studentId,
    required this.studentName,
    required this.authorType,
    required this.authorId,
    required this.authorName,
    required this.rating,
    this.content,
    this.tags = const [],
    this.visibility = ReviewVisibility.public,
    this.isAnonymous = false,
    this.isVerified = true,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  /// Check if author is a parent
  bool get isParentReview => authorType == ReviewAuthorType.parent;

  /// Check if author is a student
  bool get isStudentReview => authorType == ReviewAuthorType.student;

  TeacherReview copyWith({
    String? id,
    String? teacherId,
    String? teacherName,
    String? studentId,
    String? studentName,
    ReviewAuthorType? authorType,
    String? authorId,
    String? authorName,
    int? rating,
    String? content,
    List<String>? tags,
    ReviewVisibility? visibility,
    bool? isAnonymous,
    bool? isVerified,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TeacherReview(
      id: id ?? this.id,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      authorType: authorType ?? this.authorType,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      rating: rating ?? this.rating,
      content: content ?? this.content,
      tags: tags ?? this.tags,
      visibility: visibility ?? this.visibility,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TeacherReview &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Review permission checker
/// Based on Q9:C - both parents and students can write reviews
class ReviewPermission {
  /// Check if a user can write a review for a teacher
  static bool canWriteReview({
    required String userId,
    required String userType, // 'student' or 'parent'
    required String studentId,
    String? parentId,
    required bool hasActiveRelation,
  }) {
    // Students can always review their teachers
    if (userType == 'student' && userId == studentId) {
      return true;
    }

    // Parents can review if they have active relation with the student
    if (userType == 'parent' && parentId != null && hasActiveRelation) {
      return true;
    }

    return false;
  }

  /// Check if a user can edit a review
  static bool canEditReview({
    required String userId,
    required TeacherReview review,
  }) {
    // Only the author can edit their review
    return review.authorId == userId;
  }

  /// Check if a user can delete a review
  static bool canDeleteReview({
    required String userId,
    required String userType,
    required TeacherReview review,
  }) {
    // Author can delete their review
    if (review.authorId == userId) {
      return true;
    }

    // TODO: Add admin/teacher delete permission if needed
    return false;
  }
}

/// Review summary statistics for a teacher
class TeacherReviewSummary {
  final String teacherId;
  final double averageRating;
  final int totalReviews;
  final int studentReviews;
  final int parentReviews;
  final Map<int, int> ratingDistribution; // rating -> count

  const TeacherReviewSummary({
    required this.teacherId,
    this.averageRating = 0.0,
    this.totalReviews = 0,
    this.studentReviews = 0,
    this.parentReviews = 0,
    this.ratingDistribution = const {},
  });

  /// Get percentage of 5-star reviews
  double get fiveStarPercentage {
    if (totalReviews == 0) return 0.0;
    return (ratingDistribution[5] ?? 0) / totalReviews * 100;
  }

  /// Get formatted average rating
  String get formattedRating {
    return averageRating.toStringAsFixed(1);
  }
}
