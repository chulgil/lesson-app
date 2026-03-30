import '../../domain/entities/teacher_post.dart';
import '../../domain/repositories/post_repository.dart';

/// Mock implementation of [PostRepository] with sample feed data.
class MockPostRepository implements PostRepository {
  static final List<TeacherPost> _posts = [
    TeacherPost(
      id: 'post_1',
      authorId: 'teacher_1',
      authorName: '김선영',
      postType: PostType.performance,
      title: '3월 정기 발표회 안내',
      content: '3월 정기 발표회를 진행합니다.\n일시: 3/15 토 14:00\n장소: 음악나라홀\n\n참가 신청은 레슨 시간에 말씀해 주세요.',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    TeacherPost(
      id: 'post_2',
      authorId: 'teacher_2',
      authorName: '박지훈',
      postType: PostType.notice,
      title: '4월 레슨 일정 변경 안내',
      content: '4월 첫째 주는 개인 사정으로 휴강합니다.\n보강은 4월 둘째 주에 진행됩니다.',
      createdAt: DateTime.now().subtract(const Duration(hours: 8)),
    ),
    TeacherPost(
      id: 'post_3',
      authorId: 'academy_1',
      authorName: '음악나라학원',
      postType: PostType.event,
      title: '신규 등록 할인 이벤트',
      content: '3월 신규 등록 시 첫 달 수강료 50% 할인!\n기간: 3/1 ~ 3/31\n\n문의: 02-1234-5678',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    TeacherPost(
      id: 'post_4',
      authorId: 'teacher_1',
      authorName: '김선영',
      postType: PostType.notice,
      title: '연습실 이용 안내',
      content: '레슨생은 평일 오전 10시~12시 무료로 연습실을 이용할 수 있습니다.',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    TeacherPost(
      id: 'post_5',
      authorId: 'teacher_1',
      authorName: '김선영',
      postType: PostType.performance,
      title: '학생 연주 영상 공유',
      content: '지난 주 레슨에서 멋진 연주를 보여준 학생들의 영상을 공유합니다. 모두 열심히 연습한 결과입니다!',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];

  @override
  Future<List<TeacherPost>> getByAuthor(String authorId) async {
    return _posts
        .where((p) => p.authorId == authorId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<List<TeacherPost>> getByAuthors(List<String> authorIds) async {
    if (authorIds.isEmpty) return [];
    final authorSet = authorIds.toSet();
    return _posts
        .where((p) => authorSet.contains(p.authorId))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
}
