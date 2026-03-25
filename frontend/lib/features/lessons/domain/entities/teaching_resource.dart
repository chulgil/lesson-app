// Teaching resource entity for sharing learning materials with students
import 'package:json_annotation/json_annotation.dart';
part 'teaching_resource.g.dart';

/// Types of teaching resources
enum TeachingResourceType {
  teacherRecording, // Teacher's model performance recording
  youtube, // YouTube video link with timestamp support
  externalLink; // External link (sheet music PDF, theory sites, etc.)

  String get label {
    switch (this) {
      case TeachingResourceType.teacherRecording:
        return '녹음';
      case TeachingResourceType.youtube:
        return '유튜브';
      case TeachingResourceType.externalLink:
        return '링크';
    }
  }

  String get icon {
    switch (this) {
      case TeachingResourceType.teacherRecording:
        return '🎵';
      case TeachingResourceType.youtube:
        return '🎬';
      case TeachingResourceType.externalLink:
        return '🔗';
    }
  }
}

/// Teaching resource model - learning materials shared by teachers
@JsonSerializable()
class TeachingResource {
  final String id;
  final String teacherId;
  final TeachingResourceType type;
  final String title;
  final String? description; // Memo shown to students

  // YouTube-specific fields
  final String? youtubeUrl; // Full YouTube URL
  final String? youtubeVideoId; // Extracted video ID
  final String? youtubeThumbnail; // Thumbnail URL (auto-generated)
  final int? youtubeStartSeconds; // Start timestamp
  final int? youtubeEndSeconds; // End timestamp

  // Teacher recording fields (Phase 2)
  final String? audioUrl; // Server URL for uploaded audio
  final int? audioDurationSeconds;

  // External link fields (Phase 3)
  final String? externalUrl;

  // Metadata
  final String? instrument; // Instrument tag
  final List<String> tags; // Free-form tags
  final DateTime createdAt;
  final DateTime? updatedAt;

  const TeachingResource({
    required this.id,
    required this.teacherId,
    required this.type,
    required this.title,
    this.description,
    this.youtubeUrl,
    this.youtubeVideoId,
    this.youtubeThumbnail,
    this.youtubeStartSeconds,
    this.youtubeEndSeconds,
    this.audioUrl,
    this.audioDurationSeconds,
    this.externalUrl,
    this.instrument,
    this.tags = const [],
    required this.createdAt,
    this.updatedAt,
  });

  factory TeachingResource.fromJson(Map<String, dynamic> json) =>
      _$TeachingResourceFromJson(json);

  Map<String, dynamic> toJson() => _$TeachingResourceToJson(this);

  /// Get the launch URL for this resource (with timestamp if applicable)
  String? get launchUrl {
    switch (type) {
      case TeachingResourceType.youtube:
        if (youtubeUrl == null) return null;
        if (youtubeStartSeconds != null && youtubeStartSeconds! > 0) {
          final videoId = youtubeVideoId ?? _extractVideoId(youtubeUrl!);
          if (videoId != null) {
            return 'https://www.youtube.com/watch?v=$videoId&t=${youtubeStartSeconds}s';
          }
        }
        return youtubeUrl;
      case TeachingResourceType.externalLink:
        return externalUrl;
      case TeachingResourceType.teacherRecording:
        return null; // Handled by in-app player
    }
  }

  /// Get formatted duration string for YouTube segment
  String? get segmentDurationText {
    if (type != TeachingResourceType.youtube) return null;
    if (youtubeStartSeconds == null) return null;

    final start = _formatSeconds(youtubeStartSeconds!);
    if (youtubeEndSeconds != null) {
      final end = _formatSeconds(youtubeEndSeconds!);
      return '$start~$end';
    }
    return '$start~';
  }

  /// Get formatted timestamp for display
  String? get timestampText {
    if (youtubeStartSeconds == null) return null;
    final start = _formatSeconds(youtubeStartSeconds!);
    if (youtubeEndSeconds != null) {
      final end = _formatSeconds(youtubeEndSeconds!);
      return '$start ~ $end';
    }
    return '$start부터';
  }

  TeachingResource copyWith({
    String? id,
    String? teacherId,
    TeachingResourceType? type,
    String? title,
    String? description,
    String? youtubeUrl,
    String? youtubeVideoId,
    String? youtubeThumbnail,
    int? youtubeStartSeconds,
    int? youtubeEndSeconds,
    String? audioUrl,
    int? audioDurationSeconds,
    String? externalUrl,
    String? instrument,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TeachingResource(
      id: id ?? this.id,
      teacherId: teacherId ?? this.teacherId,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      youtubeUrl: youtubeUrl ?? this.youtubeUrl,
      youtubeVideoId: youtubeVideoId ?? this.youtubeVideoId,
      youtubeThumbnail: youtubeThumbnail ?? this.youtubeThumbnail,
      youtubeStartSeconds: youtubeStartSeconds ?? this.youtubeStartSeconds,
      youtubeEndSeconds: youtubeEndSeconds ?? this.youtubeEndSeconds,
      audioUrl: audioUrl ?? this.audioUrl,
      audioDurationSeconds: audioDurationSeconds ?? this.audioDurationSeconds,
      externalUrl: externalUrl ?? this.externalUrl,
      instrument: instrument ?? this.instrument,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TeachingResource &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'TeachingResource(id: $id, type: $type, title: $title)';

  // --- Utility methods ---

  static String _formatSeconds(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return s > 0 ? '$m:${s.toString().padLeft(2, '0')}' : '$m:00';
  }

  static String? _extractVideoId(String url) {
    // Handle youtu.be/VIDEO_ID
    final shortMatch = RegExp(r'youtu\.be/([a-zA-Z0-9_-]{11})').firstMatch(url);
    if (shortMatch != null) return shortMatch.group(1);

    // Handle youtube.com/watch?v=VIDEO_ID
    final longMatch =
        RegExp(r'[?&]v=([a-zA-Z0-9_-]{11})').firstMatch(url);
    if (longMatch != null) return longMatch.group(1);

    return null;
  }

  /// Parse YouTube URL and extract video ID + timestamp
  static ({String? videoId, int? startSeconds}) parseYoutubeUrl(String url) {
    final videoId = _extractVideoId(url);
    int? startSeconds;

    // Parse t= parameter (supports ?t=92 or &t=1m32s or &t=92s)
    final tMatch = RegExp(r'[?&]t=(\d+)').firstMatch(url);
    if (tMatch != null) {
      startSeconds = int.tryParse(tMatch.group(1)!);
    }

    return (videoId: videoId, startSeconds: startSeconds);
  }

  /// Generate YouTube thumbnail URL from video ID
  static String? thumbnailUrl(String? videoId) {
    if (videoId == null) return null;
    return 'https://img.youtube.com/vi/$videoId/mqdefault.jpg';
  }
}
