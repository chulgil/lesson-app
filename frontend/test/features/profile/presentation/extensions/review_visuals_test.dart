import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/profile/domain/entities/review.dart';
import 'package:lessonaza/features/profile/presentation/extensions/review_visuals.dart';

void main() {
  group('ReviewVisuals', () {
    test('provides centralized labels for author and visibility', () {
      expect(ReviewAuthorType.student.label, '학생');
      expect(ReviewAuthorType.parent.label, '학부모');
      expect(ReviewVisibility.public.label, '공개');
      expect(ReviewVisibility.teacherOnly.label, '선생님만');
    });

    test('formats anonymous author and verified badge for presentation', () {
      final review = TeacherReview(
        id: 'review-1',
        teacherId: 'teacher-1',
        teacherName: 'Teacher',
        studentId: 'student-1',
        studentName: 'Student',
        authorType: ReviewAuthorType.parent,
        authorId: 'parent-1',
        authorName: 'Parent',
        rating: 5,
        isAnonymous: true,
        createdAt: DateTime(2026),
      );

      expect(review.displayAuthorName, '학부모');
      expect(review.authorBadge, '학부모 ✓');
    });
  });
}
