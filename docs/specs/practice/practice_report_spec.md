# 연습 통계 리포트 스펙

> 작성일: 2026-01-03
> 상태: 설계 완료
> 브레인스토밍: [practice_repertoire_enhancement.md](../../proposal/practice_repertoire_enhancement.md)

## 1. 개요

### 1.1 목적
학생의 연습 현황을 주간/월간 단위로 시각화하여 진행 상황 파악 및 동기부여

### 1.2 핵심 결정사항
| 항목 | 결정 |
|------|------|
| 주간 리포트 | 연습 시간, 완료율, 일별 그래프 |
| 월간 리포트 | 주간 비교, 트렌드 그래프, 성취 요약 |
| 선생님 공유 | Phase 2 (현재는 학생 전용) |

---

## 2. 데이터 모델

### 2.1 DailyPracticeStat
```dart
/// 일별 연습 통계
class DailyPracticeStat {
  final DateTime date;
  final int practiceTimeSeconds;    // 연습 시간 (초)
  final int completedSectionCount;  // 완료한 섹션 수
  final int totalSectionCount;      // 전체 섹션 수
  final bool hasGoal;               // 목표 설정 여부
  final bool goalAchieved;          // 목표 달성 여부

  DailyPracticeStat({
    required this.date,
    required this.practiceTimeSeconds,
    required this.completedSectionCount,
    required this.totalSectionCount,
    required this.hasGoal,
    required this.goalAchieved,
  });

  /// 연습 시간 (분)
  int get practiceTimeMinutes => practiceTimeSeconds ~/ 60;

  /// 완료율 (0.0 ~ 1.0)
  double get completionRate {
    if (totalSectionCount == 0) return 0.0;
    return completedSectionCount / totalSectionCount;
  }

  /// 연습 여부
  bool get hasPracticed => practiceTimeSeconds > 0;
}
```

### 2.2 WeeklyReport
```dart
/// 주간 리포트
class WeeklyReport {
  final DateTime weekStart;         // 주 시작일 (월요일)
  final DateTime weekEnd;           // 주 종료일 (일요일)
  final List<DailyPracticeStat> dailyStats;  // 일별 통계
  final int streakDays;             // 현재 스트릭

  WeeklyReport({
    required this.weekStart,
    required this.weekEnd,
    required this.dailyStats,
    required this.streakDays,
  });

  /// 총 연습 시간 (초)
  int get totalTimeSeconds =>
      dailyStats.fold(0, (sum, s) => sum + s.practiceTimeSeconds);

  /// 총 연습 시간 (분)
  int get totalTimeMinutes => totalTimeSeconds ~/ 60;

  /// 총 연습 시간 포맷 (예: "2시간 30분")
  String get formattedTotalTime {
    final hours = totalTimeMinutes ~/ 60;
    final minutes = totalTimeMinutes % 60;
    if (hours > 0) {
      return '$hours시간 $minutes분';
    }
    return '$minutes분';
  }

  /// 연습한 일수
  int get practicedDayCount =>
      dailyStats.where((s) => s.hasPracticed).length;

  /// 평균 일일 연습 시간 (분)
  double get averageDailyMinutes {
    if (practicedDayCount == 0) return 0.0;
    return totalTimeMinutes / practicedDayCount;
  }

  /// 목표 달성 일수
  int get goalAchievedDayCount =>
      dailyStats.where((s) => s.goalAchieved).length;

  /// 가장 많이 연습한 날
  DailyPracticeStat? get mostPracticedDay {
    if (dailyStats.isEmpty) return null;
    return dailyStats.reduce((a, b) =>
        a.practiceTimeSeconds > b.practiceTimeSeconds ? a : b);
  }
}
```

### 2.3 MonthlyReport
```dart
/// 월간 리포트
class MonthlyReport {
  final int year;
  final int month;
  final List<WeeklyReport> weeklyReports;  // 주간 리포트들
  final List<DailyPracticeStat> dailyStats;  // 일별 통계 (캘린더용)

  MonthlyReport({
    required this.year,
    required this.month,
    required this.weeklyReports,
    required this.dailyStats,
  });

  /// 총 연습 시간 (분)
  int get totalTimeMinutes =>
      weeklyReports.fold(0, (sum, w) => sum + w.totalTimeMinutes);

  /// 총 연습 시간 포맷
  String get formattedTotalTime {
    final hours = totalTimeMinutes ~/ 60;
    final minutes = totalTimeMinutes % 60;
    if (hours > 0) {
      return '$hours시간 $minutes분';
    }
    return '$minutes분';
  }

  /// 연습한 총 일수
  int get practicedDayCount =>
      dailyStats.where((s) => s.hasPracticed).length;

  /// 이번 달 일수
  int get totalDaysInMonth =>
      DateTime(year, month + 1, 0).day;

  /// 연습 일수 비율
  double get practiceDayRate {
    final now = DateTime.now();
    final daysToCount = (now.year == year && now.month == month)
        ? now.day  // 이번 달이면 오늘까지만
        : totalDaysInMonth;
    return practicedDayCount / daysToCount;
  }

  /// 주간 평균 연습 시간 (분)
  double get weeklyAverageMinutes {
    if (weeklyReports.isEmpty) return 0.0;
    return totalTimeMinutes / weeklyReports.length;
  }

  /// 지난 달 대비 변화율 (별도 계산 필요)
  double? comparedToPreviousMonth;
}
```

---

## 3. UI 설계

### 3.1 주간 리포트 화면

```
┌─────────────────────────────────────────┐
│ ← 주간 리포트                           │
│   12월 30일 ~ 1월 5일                   │
├─────────────────────────────────────────┤
│ 📊 이번 주 요약                         │
│ ┌─────────────────────────────────────┐ │
│ │ ⏱️ 총 연습 시간                     │ │
│ │        3시간 45분                   │ │
│ │                                     │ │
│ │ 📅 연습 일수      🎯 목표 달성      │ │
│ │    5일 / 7일        4일            │ │
│ │                                     │ │
│ │ 🔥 현재 스트릭                      │ │
│ │        12일                         │ │
│ └─────────────────────────────────────┘ │
├─────────────────────────────────────────┤
│ 📈 일별 연습 시간                       │
│ ┌─────────────────────────────────────┐ │
│ │    45                               │ │
│ │    ██                               │ │
│ │ 30 ██ ██    ██                      │ │
│ │    ██ ██    ██ ██                   │ │
│ │ 15 ██ ██    ██ ██ ██                │ │
│ │    ██ ██ ░░ ██ ██ ██ ░░             │ │
│ │    월 화 수 목 금 토 일             │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ █ 연습함  ░ 연습 안함  ✓ 목표 달성     │
├─────────────────────────────────────────┤
│ 🏆 이번 주 하이라이트                   │
│ • 화요일에 가장 많이 연습 (45분)        │
│ • 평균 일일 연습 시간: 32분             │
│ • 목표 달성률: 80%                      │
└─────────────────────────────────────────┘
```

### 3.2 월간 리포트 화면

```
┌─────────────────────────────────────────┐
│ ← 월간 리포트              [◀] 1월 [▶] │
├─────────────────────────────────────────┤
│ 📊 이번 달 요약                         │
│ ┌─────────────────────────────────────┐ │
│ │ ⏱️ 총 연습 시간    📅 연습 일수    │ │
│ │   12시간 30분        18일          │ │
│ │   ▲ 15% 증가         ▲ 3일 증가   │ │
│ └─────────────────────────────────────┘ │
├─────────────────────────────────────────┤
│ 📅 연습 캘린더                          │
│ ┌─────────────────────────────────────┐ │
│ │    월  화  수  목  금  토  일       │ │
│ │         1   2   3   4   5          │ │
│ │        ●   ●   ○   ●   ○          │ │
│ │    6   7   8   9  10  11  12       │ │
│ │    ●   ●   ●   ○   ●   ●   ○      │ │
│ │   ...                               │ │
│ └─────────────────────────────────────┘ │
│ ● 연습함  ○ 연습 안함  ◉ 목표 달성     │
├─────────────────────────────────────────┤
│ 📈 주간 비교                            │
│ ┌─────────────────────────────────────┐ │
│ │ 4h                                  │ │
│ │    ████                             │ │
│ │ 3h ████ ████      ████              │ │
│ │    ████ ████ ████ ████ ████         │ │
│ │ 2h ████ ████ ████ ████ ████         │ │
│ │    1주  2주  3주  4주  5주          │ │
│ └─────────────────────────────────────┘ │
├─────────────────────────────────────────┤
│ 🏆 이번 달 성취                         │
│ • 총 18일 연습 완료                     │
│ • 새로운 뱃지: "꾸준한 연습가" 획득     │
│ • 최장 스트릭: 8일                      │
└─────────────────────────────────────────┘
```

### 3.3 접근 경로

```
[학생 홈 화면]
├── 연습 탭
│   └── 상단 통계 영역 터치 → 주간 리포트
└── 더보기/설정
    └── 연습 통계 → 주간/월간 선택
```

---

## 4. Repository 인터페이스

```dart
abstract class PracticeReportRepository {
  /// 일별 통계 조회
  Future<DailyPracticeStat> getDailyStat(String studentId, DateTime date);

  /// 주간 리포트 조회
  Future<WeeklyReport> getWeeklyReport(String studentId, DateTime weekStart);

  /// 월간 리포트 조회
  Future<MonthlyReport> getMonthlyReport(String studentId, int year, int month);

  /// 이전 달 대비 변화율 계산
  Future<double?> getMonthlyComparison(String studentId, int year, int month);
}
```

---

## 5. Provider 설계

```dart
/// 이번 주 리포트
final currentWeekReportProvider =
    FutureProvider.family<WeeklyReport, String>(
  (ref, studentId) async {
    final repository = ref.watch(practiceReportRepositoryProvider);
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    return repository.getWeeklyReport(studentId, weekStart);
  },
);

/// 특정 주 리포트
final weeklyReportProvider =
    FutureProvider.family<WeeklyReport, WeeklyReportParams>(
  (ref, params) async {
    final repository = ref.watch(practiceReportRepositoryProvider);
    return repository.getWeeklyReport(params.studentId, params.weekStart);
  },
);

class WeeklyReportParams {
  final String studentId;
  final DateTime weekStart;

  const WeeklyReportParams({
    required this.studentId,
    required this.weekStart,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeeklyReportParams &&
          studentId == other.studentId &&
          weekStart.year == other.weekStart.year &&
          weekStart.month == other.weekStart.month &&
          weekStart.day == other.weekStart.day;

  @override
  int get hashCode => studentId.hashCode ^ weekStart.hashCode;
}

/// 월간 리포트
final monthlyReportProvider =
    FutureProvider.family<MonthlyReport, MonthlyReportParams>(
  (ref, params) async {
    final repository = ref.watch(practiceReportRepositoryProvider);
    return repository.getMonthlyReport(
      params.studentId,
      params.year,
      params.month,
    );
  },
);

class MonthlyReportParams {
  final String studentId;
  final int year;
  final int month;

  const MonthlyReportParams({
    required this.studentId,
    required this.year,
    required this.month,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonthlyReportParams &&
          studentId == other.studentId &&
          year == other.year &&
          month == other.month;

  @override
  int get hashCode => studentId.hashCode ^ year ^ month;
}
```

---

## 6. 그래프 라이브러리

### 6.1 추천 패키지
```yaml
dependencies:
  fl_chart: ^0.68.0  # 바 차트, 라인 차트
```

### 6.2 차트 위젯 예시

```dart
/// 일별 연습 시간 바 차트
class DailyPracticeBarChart extends StatelessWidget {
  final List<DailyPracticeStat> stats;

  const DailyPracticeBarChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        barGroups: stats.asMap().entries.map((entry) {
          final index = entry.key;
          final stat = entry.value;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: stat.practiceTimeMinutes.toDouble(),
                color: stat.goalAchieved
                    ? AppColors.success
                    : AppColors.primary,
                width: 20,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }).toList(),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final days = ['월', '화', '수', '목', '금', '토', '일'];
                return Text(days[value.toInt()]);
              },
            ),
          ),
        ),
      ),
    );
  }
}
```

---

## 7. 라우팅

```dart
GoRoute(
  path: 'practice/report/weekly',
  name: 'weeklyReport',
  builder: (context, state) {
    final studentId = state.uri.queryParameters['studentId']!;
    final weekStartStr = state.uri.queryParameters['weekStart'];
    final weekStart = weekStartStr != null
        ? DateTime.parse(weekStartStr)
        : null;
    return WeeklyReportScreen(
      studentId: studentId,
      weekStart: weekStart,
    );
  },
),
GoRoute(
  path: 'practice/report/monthly',
  name: 'monthlyReport',
  builder: (context, state) {
    final studentId = state.uri.queryParameters['studentId']!;
    final year = int.tryParse(state.uri.queryParameters['year'] ?? '');
    final month = int.tryParse(state.uri.queryParameters['month'] ?? '');
    return MonthlyReportScreen(
      studentId: studentId,
      year: year,
      month: month,
    );
  },
),
```

---

## 8. 파일 구조

```
lib/features/practice/
├── domain/
│   └── entities/
│       ├── daily_practice_stat.dart
│       ├── weekly_report.dart
│       └── monthly_report.dart
├── data/
│   └── repositories/
│       └── practice_report_repository.dart
├── presentation/
│   ├── providers/
│   │   └── practice_report_provider.dart
│   ├── screens/
│   │   ├── weekly_report_screen.dart
│   │   └── monthly_report_screen.dart
│   └── widgets/
│       ├── report_summary_card.dart
│       ├── daily_practice_bar_chart.dart
│       ├── weekly_comparison_chart.dart
│       ├── practice_calendar_heatmap.dart
│       └── achievement_highlight.dart
```

---

## 9. 구현 체크리스트

### Phase 4: 주간 리포트
- [ ] DailyPracticeStat, WeeklyReport 모델
- [ ] PracticeReportRepository 구현
- [ ] 주간 리포트 화면 UI
- [ ] 일별 바 차트 구현
- [ ] Provider 구현

### Phase 4: 월간 리포트
- [ ] MonthlyReport 모델
- [ ] 월간 리포트 화면 UI
- [ ] 연습 캘린더 히트맵
- [ ] 주간 비교 차트
- [ ] 이전 달 대비 계산

---

## 10. 향후 확장

| 기능 | Phase | 설명 |
|------|:-----:|------|
| 선생님 공유 | 2 | 학생 리포트를 선생님에게 자동/수동 공유 |
| PDF 내보내기 | 2 | 리포트를 PDF로 저장/공유 |
| 연간 리포트 | 2 | 연간 통계 및 성장 그래프 |
| 비교 기능 | 2 | 다른 학생/평균과 비교 (익명) |
