import 'daily_practice.dart';

/// 성장 히트맵 — 1년 캘린더, 일별 연습 evidence 통합.
///
/// 스펙 §6.3 / 플랜 Job 1 Task 1.4. P1 Foundation 의 핵심 시각화 데이터.
/// `days` key 는 UTC 자정 [DateTime] — 동일 날짜는 단일 key 로 유지.
///
/// 직렬화는 수동 구현 (json_serializable 은 [Map] key 가 [DateTime] 일 때
/// 자동 변환 미지원 — ISO8601 string 으로 인코딩).
class GrowthHeatmap {
  final String studentId;
  final Map<DateTime, DailyPractice> days;

  const GrowthHeatmap({required this.studentId, required this.days});

  /// [weekStart] 부터 7일간의 `totalMinutes` 합산. 빠진 날은 0.
  int weekTotal(DateTime weekStart) {
    var sum = 0;
    for (var i = 0; i < 7; i++) {
      final key = weekStart.add(Duration(days: i));
      sum += days[key]?.totalMinutes ?? 0;
    }
    return sum;
  }

  /// [asOf] 부터 거꾸로 연속해서 `totalMinutes > 0` 인 날 카운트.
  /// 한 날이라도 빠지거나 0 분이면 즉시 종료.
  int streakDays(DateTime asOf) {
    var count = 0;
    var cursor = asOf;
    while (true) {
      final entry = days[cursor];
      if (entry == null || entry.totalMinutes <= 0) {
        return count;
      }
      count++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
  }

  GrowthHeatmap copyWith({Map<DateTime, DailyPractice>? days}) =>
      GrowthHeatmap(studentId: studentId, days: days ?? this.days);

  Map<String, dynamic> toJson() => {
    'studentId': studentId,
    'days': {
      for (final entry in days.entries)
        entry.key.toIso8601String(): entry.value.toJson(),
    },
  };

  factory GrowthHeatmap.fromJson(Map<String, dynamic> json) {
    final raw = (json['days'] as Map<String, dynamic>? ?? const {});
    final parsed = <DateTime, DailyPractice>{
      for (final entry in raw.entries)
        DateTime.parse(entry.key): DailyPractice.fromJson(
          entry.value as Map<String, dynamic>,
        ),
    };
    return GrowthHeatmap(studentId: json['studentId'] as String, days: parsed);
  }
}
