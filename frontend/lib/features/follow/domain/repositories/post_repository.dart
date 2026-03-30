import '../entities/teacher_post.dart';

/// Repository interface for teacher/academy posts.
abstract class PostRepository {
  /// Get posts by a specific author.
  Future<List<TeacherPost>> getByAuthor(String authorId);

  /// Get posts by multiple authors (for feed aggregation).
  Future<List<TeacherPost>> getByAuthors(List<String> authorIds);
}
