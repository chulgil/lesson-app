/// YouTube search result entity for the search sheet
class YoutubeSearchResult {
  final String videoId;
  final String title;
  final String channel;
  final String thumbnail;
  final int? durationSeconds;
  final String? durationText;

  const YoutubeSearchResult({
    required this.videoId,
    required this.title,
    required this.channel,
    required this.thumbnail,
    this.durationSeconds,
    this.durationText,
  });

  /// Full YouTube URL for this video
  String get youtubeUrl => 'https://www.youtube.com/watch?v=$videoId';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is YoutubeSearchResult &&
          runtimeType == other.runtimeType &&
          videoId == other.videoId;

  @override
  int get hashCode => videoId.hashCode;

  @override
  String toString() =>
      'YoutubeSearchResult(videoId: $videoId, title: $title)';
}
