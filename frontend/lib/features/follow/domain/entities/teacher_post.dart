import 'package:json_annotation/json_annotation.dart';

part 'teacher_post.g.dart';

/// Type of post in the follow feed.
enum PostType {
  /// Performance or recital announcement
  performance,

  /// Event (discount, campaign, etc.)
  event,

  /// General notice
  notice,
}

/// A post/announcement from a teacher or academy.
///
/// Displayed in FollowFeedScreen for followers.
@JsonSerializable()
class TeacherPost {
  final String id;

  /// Author ID (teacher or academy)
  final String authorId;

  /// Author display name
  final String authorName;

  final PostType postType;

  /// Post title
  final String title;

  /// Post body content
  final String content;

  final DateTime createdAt;

  TeacherPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.postType,
    required this.title,
    required this.content,
    required this.createdAt,
  });

  factory TeacherPost.fromJson(Map<String, dynamic> json) =>
      _$TeacherPostFromJson(json);

  Map<String, dynamic> toJson() => _$TeacherPostToJson(this);

  /// Icon for this post type.
  String get typeEmoji {
    switch (postType) {
      case PostType.performance:
        return '🎵';
      case PostType.event:
        return '🎉';
      case PostType.notice:
        return '📢';
    }
  }

  /// Display label for this post type.
  String get typeLabel {
    switch (postType) {
      case PostType.performance:
        return '발표회';
      case PostType.event:
        return '이벤트';
      case PostType.notice:
        return '공지사항';
    }
  }
}
