import '../../domain/entities/youtube_search_result.dart';

/// Mock YouTube search API — returns hardcoded music-lesson results with a
/// simulated network delay. Swap this for the real YouTube Data API v3 later.
class MockYoutubeSearchApi {
  const MockYoutubeSearchApi();

  static const _mockResults = [
    YoutubeSearchResult(
      videoId: 'GdqyRFGlNKM',
      title: '바이올린 보잉 기초 — 활 잡는 법부터',
      channel: '바이올린 클래스',
      thumbnail: 'https://img.youtube.com/vi/GdqyRFGlNKM/mqdefault.jpg',
      durationSeconds: 542,
      durationText: '9:02',
    ),
    YoutubeSearchResult(
      videoId: 'Q9Qw9gLKJ4E',
      title: '피아노 체르니 30번 연습 포인트',
      channel: '피아노 마스터',
      thumbnail: 'https://img.youtube.com/vi/Q9Qw9gLKJ4E/mqdefault.jpg',
      durationSeconds: 380,
      durationText: '6:20',
    ),
    YoutubeSearchResult(
      videoId: 'Xt_wMNB1hxY',
      title: '첼로 비브라토 연습 — 왼손 손가락 훈련',
      channel: '첼로 아카데미',
      thumbnail: 'https://img.youtube.com/vi/Xt_wMNB1hxY/mqdefault.jpg',
      durationSeconds: 623,
      durationText: '10:23',
    ),
    YoutubeSearchResult(
      videoId: 'dQw4w9WgXcQ',
      title: '기타 코드 전환 속도 올리기 — 초보자용',
      channel: '기타 레슨 채널',
      thumbnail: 'https://img.youtube.com/vi/dQw4w9WgXcQ/mqdefault.jpg',
      durationSeconds: 480,
      durationText: '8:00',
    ),
    YoutubeSearchResult(
      videoId: 'kXYiU_JCYtU',
      title: '드럼 기초 박자 — 4/4박자 기본 패턴',
      channel: '드럼 스쿨',
      thumbnail: 'https://img.youtube.com/vi/kXYiU_JCYtU/mqdefault.jpg',
      durationSeconds: 314,
      durationText: '5:14',
    ),
    YoutubeSearchResult(
      videoId: 'VB8WbznxaAQ',
      title: '플루트 음정 안정화 연습법',
      channel: '관악기 스튜디오',
      thumbnail: 'https://img.youtube.com/vi/VB8WbznxaAQ/mqdefault.jpg',
      durationSeconds: 445,
      durationText: '7:25',
    ),
  ];

  /// Returns mock results for any [query] after a simulated 500ms delay.
  Future<List<YoutubeSearchResult>> search(String query) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (query.trim().isEmpty) return const [];
    return _mockResults;
  }
}
