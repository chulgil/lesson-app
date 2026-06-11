import 'package:json_annotation/json_annotation.dart';

part 'practice_evidence.g.dart';

/// 연습 evidence 5경로 (= DailyPractice 5필드).
enum PracticeSource { metronome, tuner, youtube, recording, manual }

/// [PracticeRecordingService] 입력 value object.
///
/// 스펙 §6.0 + §6.3 / 플랜 Job 3 Task 3.1. 4 경로 wiring 의 단일 페이로드.
/// [videoId] 는 [PracticeSource.youtube] 일 때만 의미.
@JsonSerializable()
class PracticeEvidence {
  final PracticeSource source;
  final int durationMinutes;
  final String? videoId;
  final Map<String, dynamic> metadata;
  final DateTime occurredAt;

  const PracticeEvidence({
    required this.source,
    required this.durationMinutes,
    required this.occurredAt,
    this.metadata = const {},
    this.videoId,
  });

  PracticeEvidence copyWith({
    PracticeSource? source,
    int? durationMinutes,
    DateTime? occurredAt,
    Map<String, dynamic>? metadata,
    String? videoId,
  }) => PracticeEvidence(
    source: source ?? this.source,
    durationMinutes: durationMinutes ?? this.durationMinutes,
    occurredAt: occurredAt ?? this.occurredAt,
    metadata: metadata ?? this.metadata,
    videoId: videoId ?? this.videoId,
  );

  factory PracticeEvidence.fromJson(Map<String, dynamic> json) =>
      _$PracticeEvidenceFromJson(json);

  Map<String, dynamic> toJson() => _$PracticeEvidenceToJson(this);
}
