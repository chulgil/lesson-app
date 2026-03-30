import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'teacher_post.g.dart';

/// Type of post in the follow feed.
@HiveType(typeId: 140)
enum PostType {
  /// Performance or recital announcement
  @HiveField(0)
  performance,

  /// Event (discount, campaign, etc.)
  @HiveField(1)
  event,

  /// General notice
  @HiveField(2)
  notice,
}

/// A post/announcement from a teacher or academy.
///
/// Displayed in FollowFeedScreen for followers.
@HiveType(typeId: 141)
@JsonSerializable()
class TeacherPost extends HiveObject {
  @HiveField(0)
  final String id;

  /// Author ID (teacher or academy)
  @HiveField(1)
  final String authorId;

  /// Author display name
  @HiveField(2)
  final String authorName;

  @HiveField(3)
  final PostType postType;

  /// Post title
  @HiveField(4)
  final String title;

  /// Post body content
  @HiveField(5)
  final String content;

  @HiveField(6)
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
