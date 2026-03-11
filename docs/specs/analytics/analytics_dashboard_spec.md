# 통계/리포트 화면 스펙

> 구현 상태: ✅ Phase 1+2 구현 완료 (Phase 3 미구현)
> 작성일: 2026-03-07
> 마지막 업데이트: 2026-03-11
> 상태: Phase 1+2 구현 완료
> 이슈: [#72](https://github.com/chulgil/lesson-app/issues/72), [#97](https://github.com/chulgil/lesson-app/issues/97) (closed)

---

## 1. 개요

선생님이 레슨 운영 현황을 한눈에 파악하고, 학부모에게 학생 성장 근거를 제시할 수 있는 통계/리포트 시스템.

### 1.1 핵심 가치

| 사용자 | 가치 |
|--------|------|
| 선생님 | 월별 레슨/수익 추이 파악, 학생 관리 효율화 |
| 학부모 | 자녀 성장 리포트 수신 (레슨 참여도, 연습률, 진도) |

### 1.2 경쟁사 벤치마크

| 기능 | My Music Staff | Tonara | 스튜디오메이트 | Lessonaza (목표) |
|------|:-:|:-:|:-:|:-:|
| 레슨 횟수 통계 | O | O | O | O |
| 수익 리포트 | O | X | O | O |
| 학생 연습률 | X | O | X | O |
| 학부모 리포트 공유 | X | O | X | O |
| 출석률 통계 | O | X | O | O |

#### 경쟁사 상세 분석

**StudioMate (스튜디오메이트)**
- 월별 매출 차트: 바 차트로 월간 매출 추이 제공, 레슨료/등록비/기타 수입 분리 표시
- 학생 증감 그래프: 월별 신규 등록/이탈 학생 수를 라인 차트로 시각화
- 한계: 학생의 연습 데이터를 수집하지 않아 연습률/성장 리포트 불가

**Modacity**
- 연습 시간 히트맵: GitHub Contribution 스타일의 연간 히트맵 캘린더로 연습 일수 시각화
- 주간 트렌드: 주간 연습 시간/횟수를 라인 차트로 표시, 목표 대비 달성률 포함
- 한계: 레슨 관리 기능 없음, 연습 데이터만 독립적으로 존재

**Lessonaza 차별점**
- 레슨 + 연습 + 출석 통합 리포트: 경쟁사는 레슨 관리(StudioMate)와 연습 관리(Modacity)가 분리되어 있으나, Lessonaza는 레슨 출석률 + 연습 달성률 + 레퍼토리 진도를 하나의 리포트로 통합
- 학부모 공유 기능: 선생님이 생성한 통합 리포트를 학부모에게 직접 전송하여 레슨 가치를 증명
- 실시간 연동: 레슨 완료 → 과제 → 연습 → 통계 자동 반영 (수동 입력 불필요)

---

## 2. 화면 구조

### 2.1 선생님 통계 대시보드

**진입 경로**: 홈 탭 > 통계 섹션 (또는 프로필 탭 > 통계)

```
+-----------------------------------------------+
| 통계                          [이번 달 v] [>]  |
+-----------------------------------------------+
|                                               |
| [레슨 현황]                                    |
| +-----------+-----------+-----------+         |
| | 총 레슨   | 완료      | 취소/결석  |         |
| |   42회    |   38회    |   4회     |         |
| +-----------+-----------+-----------+         |
|                                               |
| [레슨 추이] (라인 차트 - 최근 6개월)            |
| |        ___                                  |
| |   ___/    \___                              |
| |  /            \                             |
| +---+---+---+---+---+---+                    |
|   10  11  12   1   2   3                      |
|                                               |
| [수익 현황]                                    |
| +-----------+-----------+                     |
| | 이번 달   | 전월 대비  |                     |
| | 2,850,000 | +5.2%     |                     |
| +-----------+-----------+                     |
|                                               |
| [학생 현황]                                    |
| +-----------+-----------+-----------+         |
| | 총 학생   | 신규      | 이탈      |         |
| |   12명    |   2명     |   0명     |         |
| +-----------+-----------+-----------+         |
|                                               |
| [연습률 TOP 5]                                 |
| 1. 김민수  ████████░░  85%                    |
| 2. 이서연  ███████░░░  72%                    |
| 3. 박지호  ██████░░░░  65%                    |
| ...                                           |
+-----------------------------------------------+
```

### 2.2 학생별 리포트

**진입 경로**: 학생 상세 > "리포트" 섹션 또는 통계 > 학생 선택

```
+-----------------------------------------------+
| < 김민수 리포트            [3개월 v] [공유]     |
+-----------------------------------------------+
|                                               |
| [출석률]                                       |
| ████████████████████░░  92% (22/24)           |
|                                               |
| [연습률] (주간 평균)                            |
| |  _   _       _                              |
| | / \_/ \   __/ \                             |
| |/       \_/    \                             |
| +--+--+--+--+--+--+--+--+--+--+--+--+       |
|   W1 W2 W3 W4 W5 W6 W7 W8 W9 W10W11W12      |
|                                               |
| [레퍼토리 진도]                                 |
| Suzuki Vol.3                                  |
|   Gavotte ............. 완료 (1/15)           |
|   Minuet .............. 진행중 (2/01~)        |
|   Bourree ............. 예정                   |
|                                               |
| [레슨 노트 요약]                               |
| - 활쏘기 자세 개선 (2/28)                      |
| - 비브라토 도입 (2/14)                         |
| - 3포지션 안정화 (1/31)                        |
|                                               |
| [공유] 버튼 → 학부모에게 리포트 전송            |
+-----------------------------------------------+
```

### 2.3 학부모 월간 리포트

**발송 방식**: 선생님이 수동 공유 (향후 자동 발송 옵션)

```
+-----------------------------------------------+
| Lessonaza 월간 리포트                          |
| 2026년 2월 김민수                              |
+-----------------------------------------------+
|                                               |
| 이번 달 한눈에 보기                             |
| +-----------+-----------+-----------+         |
| | 레슨      | 연습      | 출석률    |         |
| |   8회     | 주 5.2일  |   100%   |         |
| +-----------+-----------+-----------+         |
|                                               |
| 선생님 코멘트                                   |
| "비브라토를 처음 도입했습니다. 매일 5분씩        |
|  연습하면 3월 말에는 자연스럽게 될 거예요."      |
|                                               |
| 이번 달 배운 곡                                 |
| - Suzuki Vol.3 Minuet (진행중)                |
| - 음계: G Major 3옥타브                        |
|                                               |
| 다음 달 목표                                    |
| - Minuet 완곡                                 |
| - 비브라토 기초 안정화                          |
+-----------------------------------------------+
```

---

## 3. 데이터 모델

### 3.1 통계 집계 기준

| 지표 | 데이터 소스 | 집계 방식 |
|------|------------|----------|
| 레슨 횟수 | `Lesson` | status별 count (기간 필터) |
| 수익 | `Subscription` | 기간 내 결제 confirmed 금액 합산 |
| 출석률 | `Lesson` | completed / (completed + noShow + studentAbsent) |
| 연습률 | `PracticeItem` | isCompleted == true / 전체 아이템 (주간 평균) |
| 학생 수 추이 | `Student` | createdAt 기준 신규, 비활성 기준 이탈 |

### 3.2 Provider 설계

```dart
// 선생님 월간 통계
@riverpod
Future<TeacherMonthlyStats> teacherMonthlyStats(
  Ref ref, {required DateTime month}
) async { ... }

// 학생별 리포트
@riverpod
Future<StudentReport> studentReport(
  Ref ref, {required String studentId, required ReportPeriod period}
) async { ... }

// 연습률 랭킹
@riverpod
Future<List<StudentPracticeRank>> practiceRanking(
  Ref ref, {required DateTime month}
) async { ... }
```

### 3.3 주요 모델

```dart
class TeacherMonthlyStats {
  final int totalLessons;
  final int completedLessons;
  final int cancelledLessons;
  final int totalRevenue;
  final double revenueChangePercent; // vs previous month
  final int totalStudents;
  final int newStudents;
  final int churnedStudents;
  final List<MonthlyTrend> lessonTrend; // 6 months
}

class StudentReport {
  final String studentId;
  final String studentName;
  final double attendanceRate;
  final List<WeeklyPracticeRate> practiceRates;
  final List<RepertoireProgress> repertoireProgress;
  final List<LessonNoteSummary> recentNotes;
}

enum ReportPeriod { oneMonth, threeMonths, sixMonths, oneYear }
```

---

## 4. 구현 계획

### Phase 1: 선생님 기본 통계 (MVP)

| 항목 | 설명 |
|------|------|
| 레슨 횟수 카드 | 총/완료/취소 카운트 |
| 학생 현황 카드 | 총/신규/이탈 카운트 |
| 연습률 TOP 5 | 리스트 (프로그레스 바) |

### Phase 2: 차트 + 수익

| 항목 | 설명 |
|------|------|
| 레슨 추이 차트 | CustomPaint 커스텀 차트 (6개월, 베지어 곡선) |
| 수익 현황 | 월간 수익 + 전월 대비 |

### Phase 3: 학생별 리포트 + 학부모 공유

| 항목 | 설명 |
|------|------|
| 학생 리포트 화면 | 출석률, 연습률 차트, 진도 |
| 학부모 공유 | 리포트 이미지/PDF 생성 + 공유 |

---

## 5. 위젯 구조

### 5.1 TeacherDashboardScreen 위젯 트리

선생님 통계 대시보드의 전체 위젯 트리. `Scaffold` > `CustomScrollView`로 구성하여 스크롤 가능한 카드 레이아웃을 사용한다.

```
TeacherDashboardScreen
├── AppBar (title: "통계", actions: [MonthSelector])
└── CustomScrollView
    ├── StatCardGrid                          ← 핵심 지표 4개
    │   ├── StatCard (월 레슨 수)
    │   ├── StatCard (월 수입)
    │   ├── StatCard (학생 수)
    │   └── StatCard (출석률)
    ├── SizedBox(height: 16)
    ├── MonthlyTrendChart                     ← 6개월 레슨 추이
    ├── SizedBox(height: 16)
    ├── RevenueBreakdownCard                  ← 수익 상세
    │   ├── 이번 달 수익 (금액)
    │   ├── 전월 대비 (% 변화)
    │   └── 수익 구성 (레슨료 / 등록비 등)
    ├── SizedBox(height: 16)
    └── PracticeRankingList                   ← 연습률 TOP 5
        └── PracticeRankingTile × N
```

#### 위젯 상세

| 위젯 | Props | 데이터 소스 (Provider) | 표시 형식 |
|------|-------|----------------------|----------|
| `StatCardGrid` | `stats: TeacherMonthlyStats` | `teacherMonthlyStatsProvider(month)` | 2×2 그리드, 각 카드에 아이콘 + 수치 + 라벨 |
| `StatCard` | `icon: IconData`, `label: String`, `value: String`, `subtitle: String?`, `onTap: VoidCallback?` | 부모에서 전달 | 라운드 카드, 아이콘 좌측, 수치 크게, 라벨 작게 |
| `MonthlyTrendChart` | `trendData: List<MonthlyTrend>` | `teacherMonthlyStatsProvider(month)` → `.lessonTrend` | CustomPaint 베지어 곡선 차트, X축: 월(6개), Y축: 레슨 수, 값 라벨 표시 |
| `RevenueBreakdownCard` | `revenue: int`, `changePercent: double` | `teacherMonthlyStatsProvider(month)` | 카드 내 금액(원 단위, 콤마 포맷) + 변화율(▲/▼ 색상 구분) |
| `PracticeRankingList` | `rankings: List<StudentPracticeRank>` | `practiceRankingProvider(month)` | ListView, 순위 + 이름 + LinearProgressIndicator + % |
| `PracticeRankingTile` | `rank: int`, `studentName: String`, `rate: double` | 부모에서 전달 | ListTile, leading: 순위 뱃지, trailing: % 텍스트 |

### 5.2 StudentReportScreen 위젯 트리

학생별 상세 리포트 화면. 기간 선택(1/3/6/12개월)에 따라 데이터 범위가 변경된다.

```
StudentReportScreen
├── AppBar (title: "{학생명} 리포트", actions: [PeriodSelector, ShareButton])
└── CustomScrollView
    ├── AttendanceRateCard                    ← 출석률
    │   ├── CircularPercentIndicator (출석률 %)
    │   └── Text ("22/24회 출석")
    ├── SizedBox(height: 16)
    ├── PracticeHeatmapCalendar               ← 연습 히트맵
    │   └── HeatmapCalendarGrid (GitHub 스타일)
    ├── SizedBox(height: 16)
    ├── PracticeWeeklyTrendChart               ← 주간 연습률 차트
    │   └── fl_chart LineChart (X: 주차, Y: 연습률)
    ├── SizedBox(height: 16)
    ├── RepertoireProgressList                ← 레퍼토리 진도
    │   └── RepertoireProgressTile × N
    │       ├── 곡명
    │       ├── 상태 (완료/진행중/예정)
    │       └── 날짜 정보
    ├── SizedBox(height: 16)
    └── RecentLessonNotesList                 ← 레슨 노트 요약
        └── LessonNoteTile × N
```

#### 위젯 상세

| 위젯 | Props | 데이터 소스 (Provider) | 표시 형식 |
|------|-------|----------------------|----------|
| `AttendanceRateCard` | `rate: double`, `attended: int`, `total: int` | `studentReportProvider(studentId, period)` → `.attendanceRate` | 원형 프로그레스 (AppColors.primary), 중앙에 % 텍스트, 하단에 "N/M회 출석" |
| `PracticeHeatmapCalendar` | `practiceData: Map<DateTime, int>`, `period: ReportPeriod` | `studentReportProvider(studentId, period)` → `.practiceRates` 변환 | 월~일 7행 격자, 연습량에 따라 색상 농도 4단계 (없음/1~2회/3~4회/5회+) |
| `PracticeWeeklyTrendChart` | `weeklyRates: List<WeeklyPracticeRate>` | `studentReportProvider(studentId, period)` → `.practiceRates` | `fl_chart` LineChart, X축: 주차(W1~W12), Y축: 연습률(0~100%), 평균선 점선 표시 |
| `RepertoireProgressList` | `items: List<RepertoireProgress>` | `studentReportProvider(studentId, period)` → `.repertoireProgress` | 교재별 섹션 > 곡 목록, 상태 칩(완료=green, 진행중=orange, 예정=grey) |
| `RepertoireProgressTile` | `title: String`, `status: ProgressStatus`, `dateInfo: String` | 부모에서 전달 | ListTile, trailing: 상태 Chip + 날짜 |
| `RecentLessonNotesList` | `notes: List<LessonNoteSummary>` | `studentReportProvider(studentId, period)` → `.recentNotes` | 카드 리스트, 날짜 + 요약 텍스트, 최대 10개 표시 |

---

## 6. 화면 플로우

### 6.1 진입점 (Entry Points)

```
[홈 탭]
  └── 통계 섹션 StatCard 그리드
       ├── "레슨" 카드 탭 → TeacherDashboardScreen (레슨 탭 포커스)
       ├── "수입" 카드 탭 → TeacherDashboardScreen (수익 섹션으로 스크롤)
       ├── "학생" 카드 탭 → TeacherDashboardScreen (학생 섹션으로 스크롤)
       └── "출석률" 카드 탭 → TeacherDashboardScreen (출석 섹션으로 스크롤)

[프로필 탭]
  └── "통계" 메뉴 항목
       └── 탭 → TeacherDashboardScreen

[학생 상세 화면]
  └── "리포트" 섹션/버튼
       └── 탭 → StudentReportScreen (해당 학생)
```

### 6.2 네비게이션 플로우

```
TeacherDashboardScreen
  │
  ├── [MonthSelector] 변경 → 동일 화면, 선택 월 데이터로 갱신
  │
  ├── [StatCard "학생 수"] 탭 → 학생 목록 (기존 StudentsTab)
  │
  ├── [PracticeRankingTile] 탭
  │   └── StudentReportScreen (해당 학생)
  │       │
  │       ├── [PeriodSelector] 변경 → 동일 화면, 기간 데이터 갱신
  │       │
  │       ├── [RepertoireProgressTile] 탭
  │       │   └── 레퍼토리 상세 화면 (기존 화면 재활용)
  │       │
  │       └── [ShareButton] 탭
  │           └── 학부모 리포트 공유 (이미지/PDF 생성 → Share Sheet)
  │
  └── [MonthlyTrendChart] 특정 월 탭
      └── 해당 월로 MonthSelector 변경 (동일 화면 내 상호작용)
```

### 6.3 라우팅 정의

```dart
// core/router/app_routes.dart에 추가
static const analyticsDashboard = '/analytics';
static const studentReport = '/analytics/student/:studentId';

// core/router/routes/analytics_routes.dart
GoRoute(
  path: AppRoutes.analyticsDashboard,
  builder: (context, state) => const TeacherDashboardScreen(),
),
GoRoute(
  path: AppRoutes.studentReport,
  builder: (context, state) {
    final studentId = state.pathParameters['studentId']!;
    final period = state.uri.queryParameters['period'] ?? 'threeMonths';
    return StudentReportScreen(
      studentId: studentId,
      initialPeriod: ReportPeriod.fromString(period),
    );
  },
),
```

---

## 7. Mock 데이터 설계

### 7.1 TeacherMonthlyStats Mock

```dart
TeacherMonthlyStats(
  totalLessons: 42,
  completedLessons: 38,
  cancelledLessons: 4,
  totalRevenue: 2850000,
  revenueChangePercent: 5.2,
  totalStudents: 12,
  newStudents: 2,
  churnedStudents: 0,
  lessonTrend: [
    MonthlyTrend(month: DateTime(2025, 10), lessonCount: 35, revenue: 2500000),
    MonthlyTrend(month: DateTime(2025, 11), lessonCount: 40, revenue: 2700000),
    MonthlyTrend(month: DateTime(2025, 12), lessonCount: 32, revenue: 2300000),
    MonthlyTrend(month: DateTime(2026, 1), lessonCount: 38, revenue: 2600000),
    MonthlyTrend(month: DateTime(2026, 2), lessonCount: 41, revenue: 2710000),
    MonthlyTrend(month: DateTime(2026, 3), lessonCount: 42, revenue: 2850000),
  ],
)
```

### 7.2 StudentReport Mock

```dart
// 김민수 학생 리포트 (3개월 기간)
StudentReport(
  studentId: 'student_001',
  studentName: '김민수',
  attendanceRate: 0.92,
  practiceRates: [
    WeeklyPracticeRate(weekStart: DateTime(2026, 1, 6), rate: 0.80),
    WeeklyPracticeRate(weekStart: DateTime(2026, 1, 13), rate: 0.85),
    WeeklyPracticeRate(weekStart: DateTime(2026, 1, 20), rate: 0.70),
    WeeklyPracticeRate(weekStart: DateTime(2026, 1, 27), rate: 0.90),
    WeeklyPracticeRate(weekStart: DateTime(2026, 2, 3), rate: 0.75),
    WeeklyPracticeRate(weekStart: DateTime(2026, 2, 10), rate: 0.88),
    WeeklyPracticeRate(weekStart: DateTime(2026, 2, 17), rate: 0.60),
    WeeklyPracticeRate(weekStart: DateTime(2026, 2, 24), rate: 0.92),
    WeeklyPracticeRate(weekStart: DateTime(2026, 3, 3), rate: 0.85),
    WeeklyPracticeRate(weekStart: DateTime(2026, 3, 10), rate: 0.78),
    WeeklyPracticeRate(weekStart: DateTime(2026, 3, 17), rate: 0.82),
    WeeklyPracticeRate(weekStart: DateTime(2026, 3, 24), rate: 0.88),
  ],
  repertoireProgress: [
    RepertoireProgress(
      title: 'Gavotte',
      book: 'Suzuki Vol.3',
      status: ProgressStatus.completed,
      startDate: DateTime(2025, 12, 1),
      completedDate: DateTime(2026, 1, 15),
    ),
    RepertoireProgress(
      title: 'Minuet',
      book: 'Suzuki Vol.3',
      status: ProgressStatus.inProgress,
      startDate: DateTime(2026, 2, 1),
      completedDate: null,
    ),
    RepertoireProgress(
      title: 'Bourrée',
      book: 'Suzuki Vol.3',
      status: ProgressStatus.planned,
      startDate: null,
      completedDate: null,
    ),
  ],
  recentNotes: [
    LessonNoteSummary(date: DateTime(2026, 2, 28), summary: '활쏘기 자세 개선'),
    LessonNoteSummary(date: DateTime(2026, 2, 14), summary: '비브라토 도입'),
    LessonNoteSummary(date: DateTime(2026, 1, 31), summary: '3포지션 안정화'),
  ],
)
```

### 7.3 PracticeRanking Mock

```dart
// 연습률 랭킹 (3월 기준)
[
  StudentPracticeRank(studentId: 'student_001', studentName: '김민수', rate: 0.85),
  StudentPracticeRank(studentId: 'student_002', studentName: '이서연', rate: 0.72),
  StudentPracticeRank(studentId: 'student_003', studentName: '박지호', rate: 0.65),
  StudentPracticeRank(studentId: 'student_004', studentName: '최예린', rate: 0.58),
  StudentPracticeRank(studentId: 'student_005', studentName: '정하준', rate: 0.52),
]
```

### 7.4 PracticeHeatmap Mock

```dart
// 히트맵용 일별 연습 데이터 (최근 3개월, 주요 샘플)
// key: DateTime(날짜), value: 연습 아이템 완료 수
{
  DateTime(2026, 1, 6): 3,
  DateTime(2026, 1, 7): 5,
  DateTime(2026, 1, 8): 2,
  DateTime(2026, 1, 9): 0,   // 미연습
  DateTime(2026, 1, 10): 4,
  // ... 이하 90일치 데이터
  // 패턴: 평일(월~금) 평균 3~5회, 주말 0~2회, 간헐적 0일
}
```

---

## 8. 구현 파일 위치

```
features/analytics/
├── domain/entities/
│   └── teacher_stats.dart              # TeacherMonthlyStats, MonthlyTrend,
│                                       # StudentPracticeRank (✅ 구현 완료)
├── data/repositories/
│   └── mock_analytics_repository.dart  # Mock 데이터 (✅ 구현 완료)
└── presentation/
    ├── screens/
    │   ├── teacher_dashboard_screen.dart   # 선생님 통계 대시보드 (✅ 구현 완료)
    │   └── student_report_screen.dart      # 학생별 상세 리포트 (❌ Phase 3)
    ├── widgets/
    │   ├── monthly_trend_chart.dart        # 6개월 레슨 추이 (CustomPaint) (✅)
    │   ├── practice_ranking_list.dart      # 연습률 TOP 5 리스트 (✅)
    │   ├── attendance_rate_card.dart       # 원형 출석률 카드 (❌ Phase 3)
    │   ├── practice_heatmap.dart           # GitHub 스타일 히트맵 (❌ Phase 3)
    │   ├── practice_weekly_trend_chart.dart # 주간 연습률 차트 (❌ Phase 3)
    │   ├── repertoire_progress_list.dart   # 레퍼토리 진도 (❌ Phase 3)
    │   └── recent_lesson_notes_list.dart   # 레슨 노트 요약 (❌ Phase 3)
    └── providers/
        └── analytics_providers.dart        # @riverpod: teacherMonthlyStats (✅)

# 구현 노트:
# - StatCard는 core/widgets/stat_card.dart 재사용 (별도 파일 불필요)
# - 수익 카드는 teacher_dashboard_screen.dart 내 _buildRevenueCard() 메서드
# - fl_chart 대신 CustomPaint + _TrendChartPainter 사용 (외부 패키지 없음)
# - 라우트: AppRoutes.analytics = '/analytics' (profile_routes.dart에 등록)
# - 진입점: 홈 대시보드 "통계" 버튼 (dashboard_tab.dart)
```

### 파일-위젯 매핑

| 파일 | 포함 위젯 | 사용 화면 |
|------|----------|----------|
| `stat_card_grid.dart` | `StatCardGrid`, `StatCard` | TeacherDashboardScreen |
| `monthly_trend_chart.dart` | `MonthlyTrendChart` | TeacherDashboardScreen |
| `revenue_breakdown_card.dart` | `RevenueBreakdownCard` | TeacherDashboardScreen |
| `practice_ranking_list.dart` | `PracticeRankingList`, `PracticeRankingTile` | TeacherDashboardScreen |
| `attendance_rate_card.dart` | `AttendanceRateCard` | StudentReportScreen |
| `practice_heatmap.dart` | `PracticeHeatmapCalendar` | StudentReportScreen |
| `practice_weekly_trend_chart.dart` | `PracticeWeeklyTrendChart` | StudentReportScreen |
| `repertoire_progress_list.dart` | `RepertoireProgressList`, `RepertoireProgressTile` | StudentReportScreen |
| `recent_lesson_notes_list.dart` | `RecentLessonNotesList`, `LessonNoteTile` | StudentReportScreen |

---

## 9. 관련 문서

| 문서 | 역할 |
|------|------|
| [teacher_ux_review.md](../design/teacher_ux_review.md) | UX 검토 (섹션 6.2 우선순위 1위) |
| [lesson_cancellation_policy.md](../subscription/lesson_cancellation_policy.md) | 출석/취소 정책 |
| [assignment_dashboard_spec.md](../lesson/assignment_dashboard_spec.md) | 과제 현황 (연습률 데이터 공유) |

---

## 변경 이력

| 날짜 | 변경 내용 |
|------|----------|
| 2026-03-11 | Phase 1+2 구현 완료 반영 (#97). fl_chart → CustomPaint 변경, 구현 파일 위치 업데이트 |
| 2026-03-07 | 위젯 구조, 화면 플로우, 경쟁사 상세 분석, Mock 데이터 설계, 구현 파일 위치 섹션 추가 |
| 2026-03-07 | 초안 작성 (이슈 #72) |
