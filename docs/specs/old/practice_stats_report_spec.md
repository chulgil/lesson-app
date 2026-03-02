# 연습 통계 리포트 스펙

> 작성일: 2026-01-03
> 상태: 설계 완료
> 브레인스토밍: [practice_repertoire_enhancement.md](../../proposal/practice_repertoire_enhancement.md)

## 1. 개요

### 1.1 목적
학생의 연습 활동을 주간/월간 단위로 분석하여 시각적 리포트를 제공하는 시스템

### 1.2 핵심 결정사항
| 항목 | 결정 |
|------|------|
| 리포트 범위 | 주간 + 월간 |
| 시각화 | 막대그래프 + 라인차트 |
| 지표 | 연습시간, 연습일수, 완료율, 레퍼토리별 분석 |

---

## 2. 데이터 모델

### 2.1 PracticeStatsReport (계산용)
```dart
/// 연습 통계 리포트 (저장 안함, 실시간 계산)
class PracticeStatsReport {
  final DateTime startDate;
  final DateTime endDate;
  final ReportType type;  // weekly, monthly

  // 요약 통계
  final int totalPracticeSeconds;
  final int practiceDayCount;
  final int completedSectionCount;
  final int totalSectionCount;

  // 일별 상세
  final List<DailyStats> dailyStats;

  // 레퍼토리별 상세
  final List<RepertoireStats> repertoireStats;

  /// 총 연습 시간 (분)
  int get totalMinutes => totalPracticeSeconds ~/ 60;

  /// 완료율 (%)
  double get completionRate {
    if (totalSectionCount == 0) return 0.0;
    return completedSectionCount / totalSectionCount * 100;
  }

  /// 일평균 연습 시간 (분)
  int get avgDailyMinutes {
    if (practiceDayCount == 0) return 0;
    return totalMinutes ~/ practiceDayCount;
  }
}

/// 리포트 유형
enum ReportType { weekly, monthly }

/// 일별 통계
class DailyStats {
  final DateTime date;
  final int practiceSeconds;
  final int completedSections;
  final bool hasPracticed;

  int get practiceMinutes => practiceSeconds ~/ 60;
}

/// 레퍼토리별 통계
class RepertoireStats {
  final String repertoireId;
  final String repertoireName;
  final int practiceSeconds;
  final int completedSections;
  final int totalSections;

  int get practiceMinutes => practiceSeconds ~/ 60;
  double get completionRate =>
    totalSections == 0 ? 0.0 : completedSections / totalSections * 100;
}
```

---

## 3. UI 설계

### 3.1 통계 탭 화면
```
┌─────────────────────────────────────────┐
│ ← 연습 통계                              │
├─────────────────────────────────────────┤
│ [  주간  ] [  월간  ]          ← 탭     │
├─────────────────────────────────────────┤
│                                         │
│   < 2026년 1월 1주차 >        ← 날짜    │
│                                         │
├─────────────────────────────────────────┤
│ 📊 요약                                  │
│ ┌─────────┬─────────┬─────────┐        │
│ │ 연습시간 │ 연습일  │ 완료율  │        │
│ │ 3시간    │  5일   │  85%   │        │
│ └─────────┴─────────┴─────────┘        │
├─────────────────────────────────────────┤
│ 📈 일별 연습 시간                        │
│ [막대 그래프]                            │
│  ▓▓▓▓                                   │
│  ▓▓▓▓  ▓▓▓                              │
│  ▓▓▓▓  ▓▓▓  ▓▓                          │
│  월   화   수   목   금   토   일        │
├─────────────────────────────────────────┤
│ 🎵 레퍼토리별 연습                       │
│ ┌───────────────────────────────────┐   │
│ │ 바흐 파르티타                      │   │
│ │ 1시간 30분  │  ████████░░ 80%    │   │
│ └───────────────────────────────────┘   │
│ ┌───────────────────────────────────┐   │
│ │ 모차르트 소나타                    │   │
│ │ 45분       │  ██████░░░░ 60%    │   │
│ └───────────────────────────────────┘   │
└─────────────────────────────────────────┘
```

### 3.2 월간 리포트 추가 요소
```
├─────────────────────────────────────────┤
│ 📅 주간 트렌드                           │
│ [라인 차트]                              │
│     ╱╲                                  │
│    ╱  ╲   ╱╲                           │
│   ╱    ╲_╱  ╲                          │
│  1주   2주   3주   4주                   │
├─────────────────────────────────────────┤
│ 🔥 스트릭 기록                           │
│ 최대 스트릭: 12일                        │
│ 현재 스트릭: 5일                         │
└─────────────────────────────────────────┘
```

---

## 4. Repository 인터페이스

```dart
abstract class PracticeStatsRepository {
  /// 주간 리포트 조회
  Future<PracticeStatsReport> getWeeklyReport(
    String studentId,
    DateTime weekStart,
  );

  /// 월간 리포트 조회
  Future<PracticeStatsReport> getMonthlyReport(
    String studentId,
    int year,
    int month,
  );

  /// 특정 기간 일별 통계
  Future<List<DailyStats>> getDailyStats(
    String studentId,
    DateTime startDate,
    DateTime endDate,
  );
}
```

---

## 5. Provider 설계

```dart
/// 주간 리포트 Provider
final weeklyReportProvider = FutureProvider.family<
  PracticeStatsReport,
  ({String studentId, DateTime weekStart})
>((ref, params) async {
  final repository = ref.watch(practiceStatsRepositoryProvider);
  return repository.getWeeklyReport(params.studentId, params.weekStart);
});

/// 월간 리포트 Provider
final monthlyReportProvider = FutureProvider.family<
  PracticeStatsReport,
  ({String studentId, int year, int month})
>((ref, params) async {
  final repository = ref.watch(practiceStatsRepositoryProvider);
  return repository.getMonthlyReport(
    params.studentId,
    params.year,
    params.month,
  );
});
```

---

## 6. 파일 구조

```
lib/features/practice/
├── domain/
│   └── entities/
│       └── practice_stats_report.dart   # 리포트 모델
├── data/
│   └── repositories/
│       └── practice_stats_repository.dart
├── presentation/
│   ├── providers/
│   │   └── practice_stats_provider.dart
│   ├── screens/
│   │   └── practice_stats_screen.dart   # 통계 메인 화면
│   └── widgets/
│       └── stats/
│           ├── stats_summary_card.dart      # 요약 카드
│           ├── daily_bar_chart.dart         # 일별 막대그래프
│           ├── weekly_line_chart.dart       # 주간 라인차트
│           └── repertoire_stats_list.dart   # 레퍼토리별 목록
```

---

## 7. 구현 체크리스트

- [ ] 리포트 모델 생성 (PracticeStatsReport, DailyStats, RepertoireStats)
- [ ] PracticeStatsRepository 인터페이스 및 Mock 구현
- [ ] Provider 구현
- [ ] 요약 카드 위젯
- [ ] 일별 막대그래프 위젯 (fl_chart 활용)
- [ ] 주간 라인차트 위젯
- [ ] 레퍼토리별 통계 위젯
- [ ] 통계 메인 화면 (주간/월간 탭)
- [ ] 날짜 네비게이션 (이전/다음 주/월)
- [ ] 라우트 추가

---

## 8. 차트 라이브러리

`fl_chart` 패키지 사용:
- 막대그래프: `BarChart`
- 라인차트: `LineChart`
- 반응형 터치 지원
- 애니메이션 효과
