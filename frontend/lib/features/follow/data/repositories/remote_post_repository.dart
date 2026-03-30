import '../../../../core/network/api_client.dart';
import '../../domain/entities/teacher_post.dart';
import '../../domain/repositories/post_repository.dart';

/// Remote implementation of [PostRepository] using FastAPI backend.
class RemotePostRepository implements PostRepository {
  final ApiClient _apiClient;

  RemotePostRepository(this._apiClient);

  @override
  Future<List<TeacherPost>> getByAuthor(String authorId) async {
    final response = await _apiClient.get(
      '/posts',
      queryParameters: {'author_id': authorId},
    );
    return _parsePostList(response.data);
  }

  @override
  Future<List<TeacherPost>> getByAuthors(List<String> authorIds) async {
    if (authorIds.isEmpty) return [];
    final response = await _apiClient.get(
      '/posts',
      queryParameters: {'author_ids': authorIds.join(',')},
    );
    return _parsePostList(response.data);
  }

  List<TeacherPost> _parsePostList(dynamic data) {
    List<dynamic> items;
    if (data is Map<String, dynamic> && data.containsKey('items')) {
      items = data['items'] as List<dynamic>;
    } else if (data is List<dynamic>) {
      items = data;
    } else {
      return [];
    }
    final posts = items
        .map((e) => _postFromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return posts;
  }

  TeacherPost _postFromJson(Map<String, dynamic> json) {
    return TeacherPost(
      id: json['id'] as String,
      authorId: json['author_id'] as String,
      authorName: json['author_name'] as String? ?? '',
      postType: _parsePostType(json['post_type'] as String?),
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  PostType _parsePostType(String? value) {
    if (value == null) return PostType.notice;
    try {
      return PostType.values.firstWhere((e) => e.name == value);
    } catch (_) {
      return PostType.notice;
    }
  }
}
