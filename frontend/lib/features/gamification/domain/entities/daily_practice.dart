import 'package:json_annotation/json_annotation.dart';

part 'daily_practice.g.dart';

/// 일일 연습 evidence — 메트로놈/튜너/YouTube/녹음/수동 5경로 통합.
///
/// 스펙 §6.3 / 플랜 Job 1 Task 1.3. GrowthHeatmap 단일 cell 의 페이로드.
/// `totalMinutes` 는 분 단위 4 필드만 합산 — `recordingCount` 는 횟수이므로 제외.
@JsonSerializable()
class DailyPractice {
  final int metronomeMinutes;
  final int tunerMinutes;
  final int youtubeMinutes;
  final int recordingCount;
  final int manualMinutes;

  const DailyPractice({
    this.metronomeMinutes = 0,
    this.tunerMinutes = 0,
    this.youtubeMinutes = 0,
    this.recordingCount = 0,
    this.manualMinutes = 0,
  });

  int get totalMinutes =>
      metronomeMinutes + tunerMinutes + youtubeMinutes + manualMinutes;

  DailyPractice copyWith({
    int? metronomeMinutes,
    int? tunerMinutes,
    int? youtubeMinutes,
    int? recordingCount,
    int? manualMinutes,
  }) => DailyPractice(
    metronomeMinutes: metronomeMinutes ?? this.metronomeMinutes,
    tunerMinutes: tunerMinutes ?? this.tunerMinutes,
    youtubeMinutes: youtubeMinutes ?? this.youtubeMinutes,
    recordingCount: recordingCount ?? this.recordingCount,
    manualMinutes: manualMinutes ?? this.manualMinutes,
  );

  factory DailyPractice.fromJson(Map<String, dynamic> json) =>
      _$DailyPracticeFromJson(json);

  Map<String, dynamic> toJson() => _$DailyPracticeToJson(this);
}
