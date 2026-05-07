import '../../domain/entities/teaching_resource.dart';
import '../../domain/entities/youtube_search_result.dart';

/// Mock YouTube search API — supports both keyword search and URL parsing.
///
/// URL 입력 시: 해당 videoId로 단일 결과 반환.
/// 키워드 입력 시: 키워드 필터링된 mock 결과 반환.
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
    YoutubeSearchResult(
      videoId: 'dQw4w9WgXcQ',
      title: '기타 코드 전환 속도 올리기 — 초보자용',
      channel: '기타 레슨 채널',
      thumbnail: 'https://img.youtube.com/vi/dQw4w9WgXcQ/mqdefault.jpg',
      durationSeconds: 480,
      durationText: '8:00',
    ),
    YoutubeSearchResult(
      videoId: 'abc123violin',
      title: '바이올린 스케일 G장조 연습',
      channel: '바이올린 클래스',
      thumbnail: 'https://img.youtube.com/vi/abc123violin/mqdefault.jpg',
      durationSeconds: 290,
      durationText: '4:50',
    ),
    YoutubeSearchResult(
      videoId: 'piano_scale_01',
      title: '피아노 하논 1번 연습',
      channel: '피아노 마스터',
      thumbnail: 'https://img.youtube.com/vi/piano_scale_01/mqdefault.jpg',
      durationSeconds: 195,
      durationText: '3:15',
    ),
  ];

  /// Search by keyword or parse YouTube URL.
  /// URL 감지: youtu.be/ 또는 youtube.com 포함 시 URL 파싱.
  /// 키워드: 제목/채널에 포함된 결과만 필터.
  Future<List<YoutubeSearchResult>> search(String query) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];

    // URL 감지 → 단일 결과 반환
    final parsed = TeachingResource.parseYoutubeUrl(trimmed);
    if (parsed.videoId != null) {
      final videoId = parsed.videoId!;
      // mock에서 찾기, 없으면 가상 결과 생성
      final found = _mockResults.where((r) => r.videoId == videoId).toList();
      if (found.isNotEmpty) return found;
      return [
        YoutubeSearchResult(
          videoId: videoId,
          title: '유튜브 동영상',
          channel: '',
          thumbnail: 'https://img.youtube.com/vi/$videoId/mqdefault.jpg',
          durationSeconds: 300,
          durationText: '5:00',
        ),
      ];
    }

    // 키워드 검색 — 제목/채널에 포함된 결과 필터
    final lower = trimmed.toLowerCase();
    final filtered = _mockResults.where((r) {
      return r.title.toLowerCase().contains(lower) ||
          r.channel.toLowerCase().contains(lower);
    }).toList();

    // 필터 결과가 없으면 전체 반환 (mock이라 항상 결과 보여줌)
    return filtered.isNotEmpty ? filtered : _mockResults;
  }
}
