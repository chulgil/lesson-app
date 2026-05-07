# Student Progress Analytics Dashboard — 종합 스펙

> 작성일: 2026-05-07
> 상태: 신규 스펙 (기존 `analytics_dashboard_spec.md` Phase 3 확장 + 학생/학부모 뷰 + 수입 분석 + 리텐션)
> 기반 스펙: [analytics_dashboard_spec.md](analytics_dashboard_spec.md) (Phase 1+2 완료 상태에서 확장)
> 이슈: 신규 (미생성)

---

## 1. 개요

### 1.1 목적

음악 레슨의 ROI(투자 대비 효과)를 데이터로 증명하는 통합 분석 대시보드.
선생님은 레슨 운영 전반을 숫자로 파악하고, 학생/학부모는 성장 궤적을 시각적으로 확인한다.

### 1.2 핵심 가치

| 사용자 | 핵심 Pain Point | 이 스펙의 해결책 |
|--------|----------------|----------------|
| 선생님 | "내가 잘 가르치고 있는 건지 데이터가 없다" | 월간 요약 + 학생별 성장 차트 |
| 선생님 | "수강권 갱신을 어떻게 설득하지?" | 성장 기록 학부모 공유 기능 |
| 학부모 | "돈이 아깝지 않은지 모르겠다" | 연습 달성률 + 레퍼토리 진도 리포트 |
| 학생 | "내가 얼마나 성장했는지 체감이 안 된다" | 스트릭 + 레퍼토리 완료 타임라인 |

### 1.3 경쟁사 벤치마크

#### 기능 매트릭스

| 기능 | Tonara | StudioMate | Modacity | Simply Piano | **Lessonaza** |
|------|:------:|:----------:|:--------:|:------------:|:-------------:|
| 연습 시간 추이 | O | X | O | O | **O** |
| 주간 목표 달성률 | O | X | O | O | **O** |
| 출석률 | X | O | X | X | **O** |
| 레슨 완료율 | X | O | X | X | **O** |
| 연습 스트릭 | O | X | O | O | **O** |
| 수입 리포트 | X | O | X | X | **O** |
| 학생 리텐션 분석 | X | X | X | X | **O** |
| 레퍼토리 진도율 | X | X | O | O | **O** |
| 녹음 비교 타임라인 | X | X | O | X | **O** |
| 학부모 리포트 공유 | O | X | X | X | **O** |
| 이탈 예측 | X | X | X | X | **O** (신규) |

#### 경쟁사 상세 분석

**Tonara**
- 핵심: 연습 시간 추적(타이머) + 교사 피드백 + 주간 목표
- 시각화: 주간 목표 달성률 도넛 차트, 연습 히스토리 바 차트
- 학부모 뷰: 실시간 연습 알림, 주간 요약 이메일
- 한계: 레슨 관리/수입 추적 없음. 악기별 커스텀 없음.

**StudioMate**
- 핵심: 스튜디오 운영 관리(출석, 수입, 청구)
- 시각화: 월별 매출 바 차트, 학생 증감 라인 차트
- 한계: 연습 데이터 없음. 학생 성장 지표 없음. 차트 커스텀 불가.

**Modacity**
- 핵심: 연습 구간 반복 + 녹음 비교
- 시각화: GitHub 스타일 연간 히트맵, 구간별 마스터리 레벨
- 한계: 레슨 관리 없음. 독립 연습 앱. 선생님-학생 연결 약함.

**Simply Piano**
- 핵심: 게임형 진행(곡 잠금 해제), 데일리 스트릭
- 시각화: 스트릭 불꽃 애니메이션, 레벨 프로그레스 바
- 한계: 자기주도 학습 전용. 선생님 없음. 클래식/피아노 외 미지원.

#### Lessonaza 차별점

1. **레슨 + 연습 + 수입 통합**: 경쟁사는 레슨 관리(StudioMate)와 연습 관리(Modacity)를 별도 앱으로 운영. Lessonaza는 단일 화면에서 통합 조회.
2. **이탈 예측**: 만료 임박 + 연습 감소 패턴으로 리텐션 위험 학생 사전 감지. 업계 최초.
3. **Notebook × Score 디자인**: 종이/잉크 팔레트 기반 차트 — 경쟁사의 무채색 SaaS UI와 시각적 차별화.

---

## 2. 화면 구조

### 2.1 화면 맵

```
Analytics Domain
├── AnalyticsDashboardScreen        (선생님 전용)
│   ├── [Tab] 월간 요약
│   ├── [Tab] 학생별 성장
│   └── [Tab] 수입 분석
│
├── StudentProgressDetailScreen     (선생님 → 학생 선택)
│   ├── 연습 시간 차트
│   ├── 출석 히트맵
│   ├── 레퍼토리 진도
│   └── 녹음 비교 타임라인
│
├── TeacherRetentionScreen          (선생님 전용)
│   ├── 수강권 갱신율 요약
│   └── 이탈 위험 학생 리스트
│
└── StudentAnalyticsTab             (학생/학부모 전용 — 학생 홈 탭 내 섹션)
    ├── 주간 연습 목표 달성률
    ├── 연습 스트릭
    ├── 레슨 요약
    └── 성장 타임라인
```

### 2.2 AnalyticsDashboardScreen — ASCII 와이어프레임

#### Tab 1: 월간 요약

```
┌──────────────────────────────────────────────────────────┐
│ ←  통계                              [2026년 5월 ▼]      │
├──────────────────────────────────────────────────────────┤
│ [월간 요약]  [학생별 성장]  [수입 분석]                    │
├──────────────────────────────────────────────────────────┤
│                                                          │
│  ┌────────────┐ ┌────────────┐ ┌────────────┐           │
│  │ 총 레슨    │ │ 완료율     │ │ 취소율     │           │
│  │   42회     │ │  90.5%     │ │   9.5%    │           │
│  │ ↑+3 vs 전월│ │ ↑+2.1%    │ │ ↓-1.2%   │           │
│  └────────────┘ └────────────┘ └────────────┘           │
│                                                          │
│  ┌────────────┐ ┌────────────┐ ┌────────────┐           │
│  │ 수강료 수입│ │ 활성 학생  │ │ 이동시간   │           │
│  │ 2,850,000 │ │   12명     │ │  8시간 20분│           │
│  │ ↑+5.2%    │ │ 신규 2 만료1│ │ 월 합산   │           │
│  └────────────┘ └────────────┘ └────────────┘           │
│                                                          │
│  레슨 추이 (최근 6개월)                                    │
│  50 ┤                     ●                             │
│  45 ┤              ●    ╱                               │
│  40 ┤        ●   ╱   ╲╱                                │
│  35 ┤  ●   ╱   ╲╱                                      │
│  30 ┤╱                                                  │
│     └──────────────────────────────                     │
│       12월  1월  2월  3월  4월  5월                      │
│                                                          │
│  연습률 TOP 5 (이번 달)                                   │
│  ① 김민수  ████████░░  85%   120분/주                   │
│  ② 이서연  ███████░░░  72%    98분/주                   │
│  ③ 박지호  ██████░░░░  65%    85분/주                   │
│  ④ 최예린  █████░░░░░  58%    72분/주                   │
│  ⑤ 정하준  ████░░░░░░  52%    65분/주                   │
│                              [전체 보기 →]               │
└──────────────────────────────────────────────────────────┘
```

#### Tab 2: 학생별 성장

```
┌──────────────────────────────────────────────────────────┐
│ [월간 요약]  [학생별 성장]  [수입 분석]                    │
├──────────────────────────────────────────────────────────┤
│                                                          │
│  학생 선택: [김민수 ▼]        기간: [3개월 ▼]            │
│                                                          │
│  ┌─────────────────────────────────────────────────┐    │
│  │ 연습 시간 추이 (주간)                            │    │
│  │  3h ┤    ●                    ●                 │    │
│  │  2h ┤  ╱   ╲         ●     ╱   ╲               │    │
│  │  1h ┤╱       ╲     ╱   ╲ ╱       ╲             │    │
│  │  0h └──────────────────────────────             │    │
│  │      W1 W2 W3 W4 W5 W6 W7 W8 W9 W10 W11 W12   │    │
│  └─────────────────────────────────────────────────┘    │
│                                                          │
│  출석 히트맵 (3개월)                                      │
│  월  ■  □  ■  ■  ■  ■  ■  ■  ■  ■  ■  ■  □           │
│  화  □  ■  ■  ■  □  ■  ■  ■  ■  ■  □  ■  ■           │
│  수  ■  ■  □  ■  ■  ■  □  ■  ■  □  ■  ■  ■           │
│  [■=레슨있음 □=결석/취소 빈칸=레슨없음]                   │
│                                                          │
│  레퍼토리 진도                                            │
│  Suzuki Vol.3                                            │
│  ✓ Gavotte          완료   2026.01.15                   │
│  ▶ Minuet           진행중 2026.02.01~                  │
│  ○ Bourrée          예정                                 │
│  ○ Gavotte in D     예정                                 │
│                                                          │
│  녹음 비교                               [모두 보기 →]   │
│  ● 2026.03.15  Minuet - 2절 (1:24)      [▶]            │
│  ● 2026.02.01  Minuet - 1절 (1:10)      [▶]            │
│  ● 2026.01.08  Gavotte 완곡 (1:48)      [▶]            │
│                                                          │
│                           [학부모 리포트 공유 →]         │
└──────────────────────────────────────────────────────────┘
```

#### Tab 3: 수입 분석

```
┌──────────────────────────────────────────────────────────┐
│ [월간 요약]  [학생별 성장]  [수입 분석]                    │
├──────────────────────────────────────────────────────────┤
│                                                          │
│  ┌────────────────────┐ ┌─────────────────────┐         │
│  │ 이번 달 수입       │ │ 미수금              │         │
│  │  2,850,000원       │ │  450,000원          │         │
│  │ ↑+5.2% (전월 대비) │ │ 2명 대기            │         │
│  └────────────────────┘ └─────────────────────┘         │
│                                                          │
│  ┌─────────────────────────────────────────────────┐    │
│  │ 월별 수입 추이 (6개월)                           │    │
│  │ 3.0M ┤                               ██         │    │
│  │ 2.5M ┤  ██  ██        ██  ██       ██           │    │
│  │ 2.0M ┤                                           │    │
│  │       └───────────────────────────────           │    │
│  │        12   1   2   3   4   5 (월)               │    │
│  └─────────────────────────────────────────────────┘    │
│                                                          │
│  학생별 수입 비중 (이번 달)                               │
│  ┌──────────────────────────────────────────┐           │
│  │      ╭────────╮                          │           │
│  │  김민  │  25%  │  이서연 18%              │           │
│  │       ╰────────╯  박지호 14%             │           │
│  │         (파이 차트 — paperOk/paperTrial/  │           │
│  │          paperAccent 3색 + inkTertiary)  │           │
│  └──────────────────────────────────────────┘           │
│                                                          │
│  예상 월수입 (활성 수강권 기준)                           │
│  ┌─────────────────────────────────────────┐            │
│  │ 확정 예정: 2,700,000원                  │            │
│  │ (활성 수강권 10개 × 평균 270,000원)     │            │
│  │ ⚠ 만료 임박 수강권: 3개 (이번 달 만료)  │            │
│  └─────────────────────────────────────────┘            │
└──────────────────────────────────────────────────────────┘
```

### 2.3 StudentProgressDetailScreen — ASCII 와이어프레임

```
┌──────────────────────────────────────────────────────────┐
│ ←  김민수 상세 분석                 [3개월 ▼]  [공유]    │
├──────────────────────────────────────────────────────────┤
│                                                          │
│  핵심 지표                                               │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐  │
│  │ 출석률   │ │ 연습 달성│ │ 레슨 수  │ │ 연습 일수│  │
│  │  92%     │ │  78%     │ │  24회    │ │  58일    │  │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘  │
│                                                          │
│  연습 시간 추이                                          │
│  ┌──────────────────────────────────────────────────┐   │
│  │  목표선 -------                                  │   │
│  │ 3h ┤        ●    ●               ●              │   │
│  │ 2h ┤  ●   ╱   ╲╱   ╲      ●  ╱   ╲            │   │
│  │ 1h ┤╱               ╲   ╱   ╲╱                 │   │
│  │ 0h └─────────────────────────────              │   │
│  │     W1  W2  W3  W4  W5  W6  W7  W8  W9 W10 W11 W12  │
│  └──────────────────────────────────────────────────┘   │
│                                                          │
│  출석 캘린더 히트맵                                       │
│  3월  ■ ■ □ ■ ■ ■ □ ■ ■ ■ ■ ■ □ ■ ■ ■ □ ■ ■ ■      │
│  4월  ■ ■ ■ □ ■ ■ ■ ■ □ ■ ■ ■ ■ ■ □ ■ ■ ■ ■ □      │
│  5월  ■ ■ □ ■ ■ ■ ■ □ ■ ■                            │
│                                                          │
│  레퍼토리 완료 타임라인                                   │
│  2025.12 ──●── Gavotte (시작)                           │
│  2026.01 ──●── Gavotte 완료 ✓                           │
│  2026.02 ──●── Minuet (시작)                            │
│  2026.03 ──●── Minuet 2절 진입                          │
│  2026.05 ─ ○ ─ (예정) Minuet 완료                       │
│                                                          │
│  녹음 진행 비교                                          │
│  ┌──────────────────────────────────────────────────┐   │
│  │ Minuet                                           │   │
│  │ 2026.02.01 ████░░░░░░░░  초견 (40%)  [▶]        │   │
│  │ 2026.03.01 ███████░░░░░  2절 진입 (65%)  [▶]    │   │
│  │ 2026.04.15 ██████████░░  마무리 (85%)  [▶]      │   │
│  └──────────────────────────────────────────────────┘   │
│                                                          │
│  선생님 피드백 요약                                       │
│  2026.03.20  "활쏘기 자세가 크게 개선됐어요"            │
│  2026.02.28  "비브라토 기초 도입 — 매일 5분 연습"        │
│  2026.01.31  "3포지션 안정화. 다음 목표: 비브라토"       │
│                            [더 보기 →]                  │
└──────────────────────────────────────────────────────────┘
```

### 2.4 TeacherRetentionScreen — ASCII 와이어프레임

```
┌──────────────────────────────────────────────────────────┐
│ ←  학생 리텐션 분석                                       │
├──────────────────────────────────────────────────────────┤
│                                                          │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐     │
│  │ 수강권 갱신율│ │ 평균 수강기간│ │ 이탈 위험    │     │
│  │    76%       │ │  14.2개월    │ │  3명         │     │
│  └──────────────┘ └──────────────┘ └──────────────┘     │
│                                                          │
│  이탈 위험 학생 (조치 필요)          [기준: ⚠ 위험도]   │
│  ┌──────────────────────────────────────────────────┐   │
│  │ ⚠ 정하준  수강권 7일 후 만료 + 연습 40% 감소     │   │
│  │           마지막 레슨: 2026.04.28                 │   │
│  │           [갱신 제안 발송 →]                      │   │
│  ├──────────────────────────────────────────────────┤   │
│  │ ⚠ 최예린  수강권 12일 후 만료                    │   │
│  │           연습률: 이번달 45% (전달 68%)           │   │
│  │           [갱신 제안 발송 →]                      │   │
│  ├──────────────────────────────────────────────────┤   │
│  │ ℹ 박지호  수강권 21일 후 만료                    │   │
│  │           연습률: 정상 (65%)                      │   │
│  │           [미리 알림 보내기 →]                    │   │
│  └──────────────────────────────────────────────────┘   │
│                                                          │
│  월별 갱신율 추이                                         │
│  100% ┤                                                  │
│   80% ┤  ████  ████        ████  ████  ████             │
│   60% ┤                ████                             │
│   40% ┤                                                 │
│        └──────────────────────────────                  │
│         12월  1월  2월  3월  4월  5월                   │
│                                                          │
│  평균 수강 기간 분포                                      │
│  0-3개월  ██  (2명)                                      │
│  3-6개월  ████  (4명)                                    │
│  6-12개월 ███  (3명)                                     │
│  12개월+  ███  (3명)                                     │
└──────────────────────────────────────────────────────────┘
```

### 2.5 StudentAnalyticsTab — ASCII 와이어프레임

```
┌──────────────────────────────────────────────────────────┐
│ 내 성장 기록                                              │
├──────────────────────────────────────────────────────────┤
│                                                          │
│  이번 주 목표                                            │
│  ┌──────────────────────────────────────────────────┐   │
│  │  [■■■■■■■░░░]  70%  (7일 중 5일 연습)           │   │
│  │  목표: 주 5일 연습 · 달성까지 2일 더!            │   │
│  └──────────────────────────────────────────────────┘   │
│                                                          │
│  연속 연습 스트릭                                        │
│  ┌──────────────────────────────────────────────────┐   │
│  │   🔥 12일 연속 연습 중!                          │   │
│  │   월  화  수  목  금  토  일                      │   │
│  │   ●  ●  ●  ●  ●  ○  ●                          │   │
│  └──────────────────────────────────────────────────┘   │
│                                                          │
│  이번 달 레슨                                            │
│  ┌──────────────────────────────────────────────────┐   │
│  │  완료 8회  ·  예정 2회  ·  취소 0회              │   │
│  │  선생님 피드백: 3건 새 메모                       │   │
│  └──────────────────────────────────────────────────┘   │
│                                                          │
│  레퍼토리 진도                                           │
│  ┌──────────────────────────────────────────────────┐   │
│  │ Suzuki Vol.3                  4곡 중 1곡 완료    │   │
│  │ [████░░░░░░]  25%                               │   │
│  │                                                  │   │
│  │ ✓ Gavotte      완료  2026.01.15                 │   │
│  │ ▶ Minuet       진행중 (시작: 2026.02.01)         │   │
│  └──────────────────────────────────────────────────┘   │
│                                                          │
│  성장 타임라인                                           │
│  ● 2026.04.15  Minuet 2절 마무리 단계                  │
│  ● 2026.03.20  활쏘기 자세 개선 완료                   │
│  ● 2026.02.01  Minuet 시작                             │
│  ● 2026.01.15  Gavotte 완곡 🎉                        │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

---

## 3. 데이터 모델

### 3.1 집계 기준 정의

| 지표 | 소스 테이블 | 집계 방식 | 필터 |
|------|------------|----------|------|
| 레슨 횟수 | `lessons` | COUNT(id) | status별 분류 |
| 완료율 | `lessons` | completed / (completed + noShow + studentAbsent) | 기간 필터 |
| 취소율 | `lessons` | (cancelled + teacherCancelled) / total | 기간 필터 |
| 수강료 수입 | `payments` | SUM(amount) WHERE status='confirmed' | 기간 필터 |
| 미수금 | `payments` | SUM(amount) WHERE status='pending' | 현재 기준 |
| 연습 달성률 | `practice_items` | completed_count / total_count | 학생, 주 필터 |
| 연습 분수 | `practice_sessions` | SUM(duration_minutes) | 학생, 기간 필터 |
| 출석 히트맵 | `lessons` | GROUP BY date, status | 학생, 기간 필터 |
| 레퍼토리 진도율 | `repertoire_pieces` | completed / total per book | 학생 필터 |
| 녹음 타임라인 | `recordings` | ORDER BY created_at | 학생, 곡 필터 |
| 이동시간 합계 | `lessons` | SUM(travel_minutes) | 선생님, 기간 필터 |
| 갱신율 | `subscriptions` | renewed / expired | 기간 필터 |
| 수강 기간 | `subscriptions` | MIN(created_at) → 현재 | 학생별 |

### 3.2 신규 엔티티 (Dart)

```dart
// features/analytics/domain/entities/student_progress.dart

/// 학생 성장 분석 종합 모델
@freezed
class StudentProgress with _$StudentProgress {
  const factory StudentProgress({
    required String studentId,
    required String studentName,
    required String? instrumentType,
    required double attendanceRate,          // 0.0 ~ 1.0
    required int attendedLessons,
    required int totalLessons,
    required double practiceAchievementRate, // 0.0 ~ 1.0 (목표 대비)
    required int totalPracticeMinutes,       // 기간 내 총 연습 분
    required int practiceStreakDays,         // 현재 연속 연습일
    required List<WeeklyPracticeSummary> weeklyPractice,
    required List<LessonAttendanceDay> attendanceCalendar,
    required List<RepertoireProgressItem> repertoire,
    required List<RecordingEntry> recordings,
    required List<FeedbackSummary> feedbackHighlights,
  }) = _StudentProgress;

  factory StudentProgress.fromJson(Map<String, dynamic> json) =>
      _$StudentProgressFromJson(json);
}

/// 주간 연습 요약
@freezed
class WeeklyPracticeSummary with _$WeeklyPracticeSummary {
  const factory WeeklyPracticeSummary({
    required DateTime weekStart,   // Monday of the week
    required int totalMinutes,
    required double achievementRate, // 0.0 ~ 1.0 vs goal
    required int activeDays,         // 1~7
  }) = _WeeklyPracticeSummary;

  factory WeeklyPracticeSummary.fromJson(Map<String, dynamic> json) =>
      _$WeeklyPracticeSummaryFromJson(json);
}

/// 출석 캘린더 데이터포인트
@freezed
class LessonAttendanceDay with _$LessonAttendanceDay {
  const factory LessonAttendanceDay({
    required DateTime date,
    required AttendanceStatus status, // present, absent, cancelled, noLesson
  }) = _LessonAttendanceDay;

  factory LessonAttendanceDay.fromJson(Map<String, dynamic> json) =>
      _$LessonAttendanceDayFromJson(json);
}

enum AttendanceStatus { present, absent, cancelled, noLesson }

/// 레퍼토리 진도 항목
@freezed
class RepertoireProgressItem with _$RepertoireProgressItem {
  const factory RepertoireProgressItem({
    required String pieceId,
    required String title,
    required String? bookTitle,       // e.g. "Suzuki Vol.3"
    required RepertoireStatus status, // planned, inProgress, completed
    required DateTime? startedAt,
    required DateTime? completedAt,
    required int? masteryPercent,     // 0~100, null if not started
  }) = _RepertoireProgressItem;

  factory RepertoireProgressItem.fromJson(Map<String, dynamic> json) =>
      _$RepertoireProgressItemFromJson(json);
}

enum RepertoireStatus { planned, inProgress, completed }

/// 녹음 타임라인 항목
@freezed
class RecordingEntry with _$RecordingEntry {
  const factory RecordingEntry({
    required String recordingId,
    required String? pieceTitle,
    required DateTime recordedAt,
    required int durationSeconds,
    required String? teacherNote,     // 선생님 코멘트
    required String? audioUrl,
  }) = _RecordingEntry;

  factory RecordingEntry.fromJson(Map<String, dynamic> json) =>
      _$RecordingEntryFromJson(json);
}

/// 피드백 요약 (레슨 노트 하이라이트)
@freezed
class FeedbackSummary with _$FeedbackSummary {
  const factory FeedbackSummary({
    required String lessonId,
    required DateTime lessonDate,
    required String summaryText,      // 선생님이 작성한 레슨 노트 첫 줄
  }) = _FeedbackSummary;

  factory FeedbackSummary.fromJson(Map<String, dynamic> json) =>
      _$FeedbackSummaryFromJson(json);
}
```

```dart
// features/analytics/domain/entities/revenue_analytics.dart

/// 수입 분석 종합 모델
@freezed
class RevenueAnalytics with _$RevenueAnalytics {
  const factory RevenueAnalytics({
    required int currentMonthRevenue,       // 원
    required double revenueChangePercent,   // 전월 대비 %
    required int pendingAmount,             // 미수금 총액
    required int pendingCount,              // 미수금 학생 수
    required int expectedMonthlyRevenue,    // 예상 수입 (활성 수강권 기준)
    required int expiringSubscriptionCount, // 이번 달 만료 수강권 수
    required List<MonthlyRevenueTrend> trend,
    required List<StudentRevenuePortion> breakdown, // 학생별 비중
  }) = _RevenueAnalytics;

  factory RevenueAnalytics.fromJson(Map<String, dynamic> json) =>
      _$RevenueAnalyticsFromJson(json);
}

@freezed
class MonthlyRevenueTrend with _$MonthlyRevenueTrend {
  const factory MonthlyRevenueTrend({
    required DateTime month,
    required int confirmedRevenue,
    required int pendingRevenue,
  }) = _MonthlyRevenueTrend;

  factory MonthlyRevenueTrend.fromJson(Map<String, dynamic> json) =>
      _$MonthlyRevenueTrendFromJson(json);
}

@freezed
class StudentRevenuePortion with _$StudentRevenuePortion {
  const factory StudentRevenuePortion({
    required String studentId,
    required String studentName,
    required int amount,
    required double percent,         // 0.0 ~ 1.0
  }) = _StudentRevenuePortion;

  factory StudentRevenuePortion.fromJson(Map<String, dynamic> json) =>
      _$StudentRevenuePortionFromJson(json);
}
```

```dart
// features/analytics/domain/entities/retention_analytics.dart

/// 리텐션 분석 종합 모델
@freezed
class RetentionAnalytics with _$RetentionAnalytics {
  const factory RetentionAnalytics({
    required double renewalRate,              // 0.0 ~ 1.0 (최근 6개월)
    required double avgSubscriptionMonths,    // 평균 수강 기간
    required List<AtRiskStudent> atRiskStudents,
    required List<MonthlyRenewalTrend> renewalTrend,
    required List<TenureDistribution> tenureDistribution,
  }) = _RetentionAnalytics;

  factory RetentionAnalytics.fromJson(Map<String, dynamic> json) =>
      _$RetentionAnalyticsFromJson(json);
}

/// 이탈 위험 학생
@freezed
class AtRiskStudent with _$AtRiskStudent {
  const factory AtRiskStudent({
    required String studentId,
    required String studentName,
    required int daysUntilExpiry,            // 수강권 만료까지 남은 일수
    required double practiceDropPercent,     // 연습 감소율 (음수=감소)
    required DateTime lastLessonDate,
    required RiskLevel riskLevel,            // high, medium, low
  }) = _AtRiskStudent;

  factory AtRiskStudent.fromJson(Map<String, dynamic> json) =>
      _$AtRiskStudentFromJson(json);
}

enum RiskLevel { high, medium, low }

@freezed
class MonthlyRenewalTrend with _$MonthlyRenewalTrend {
  const factory MonthlyRenewalTrend({
    required DateTime month,
    required int expired,
    required int renewed,
  }) = _MonthlyRenewalTrend;

  factory MonthlyRenewalTrend.fromJson(Map<String, dynamic> json) =>
      _$MonthlyRenewalTrendFromJson(json);
}

@freezed
class TenureDistribution with _$TenureDistribution {
  const factory TenureDistribution({
    required String label,   // e.g. "0-3개월"
    required int count,
  }) = _TenureDistribution;

  factory TenureDistribution.fromJson(Map<String, dynamic> json) =>
      _$TenureDistributionFromJson(json);
}
```

```dart
// features/analytics/domain/entities/student_analytics_summary.dart
// 학생 본인용 요약 (StudentAnalyticsTab)

@freezed
class StudentAnalyticsSummary with _$StudentAnalyticsSummary {
  const factory StudentAnalyticsSummary({
    required int weeklyGoalDays,              // 목표 연습 일수 (수강권 설정값)
    required int weeklyAchievedDays,          // 이번 주 달성 일수
    required double weeklyAchievementRate,    // 0.0 ~ 1.0
    required int currentStreakDays,           // 현재 연속 연습일
    required int longestStreakDays,           // 역대 최장 스트릭
    required List<bool> weekdayPracticed,     // 7개 — 이번 주 요일별 연습 여부
    required int monthlyCompletedLessons,
    required int monthlyScheduledLessons,
    required int monthlyNewFeedbacks,         // 새 선생님 피드백 수
    required List<RepertoireProgressItem> activeRepertoire,
    required List<GrowthMilestone> timeline,  // 성장 타임라인
  }) = _StudentAnalyticsSummary;

  factory StudentAnalyticsSummary.fromJson(Map<String, dynamic> json) =>
      _$StudentAnalyticsSummaryFromJson(json);
}

/// 성장 마일스톤 (타임라인 아이템)
@freezed
class GrowthMilestone with _$GrowthMilestone {
  const factory GrowthMilestone({
    required DateTime date,
    required MilestoneType type,  // pieceStarted, pieceCompleted, feedbackHighlight, practiceStreak
    required String description,
    required String? emoji,       // 선택적 시각 강조 (NotebookGlyph 대신 사용 시)
  }) = _GrowthMilestone;

  factory GrowthMilestone.fromJson(Map<String, dynamic> json) =>
      _$GrowthMilestoneFromJson(json);
}

enum MilestoneType { pieceStarted, pieceCompleted, feedbackHighlight, practiceStreak }
```

### 3.3 Repository 인터페이스 확장

```dart
// features/analytics/domain/repositories/analytics_repository.dart

abstract class AnalyticsRepository {
  // 기존 (Phase 1+2)
  Future<TeacherMonthlyStats> getTeacherMonthlyStats(DateTime month);

  // 신규: 학생 성장
  Future<StudentProgress> getStudentProgress(
    String studentId, {
    required AnalyticsPeriod period,
  });

  // 신규: 수입 분석
  Future<RevenueAnalytics> getRevenueAnalytics({
    required int periodMonths, // 1, 3, 6, 12
  });

  // 신규: 리텐션
  Future<RetentionAnalytics> getRetentionAnalytics();

  // 신규: 학생 본인용
  Future<StudentAnalyticsSummary> getStudentAnalyticsSummary(String studentId);
}

enum AnalyticsPeriod { oneMonth, threeMonths, sixMonths, oneYear }
```

---

## 4. API 계약

### 4.1 Base URL

```
/api/v1/analytics
```

공통 헤더:
```
Authorization: Bearer {token}
Content-Type: application/json
```

### 4.2 선생님 월간 요약

```
GET /api/v1/analytics/teacher/monthly?year=2026&month=5
```

**Query Params**

| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| year | int | O | 4자리 연도 |
| month | int | O | 1~12 |

**Response 200**

```json
{
  "month": "2026-05",
  "lessons": {
    "total": 42,
    "completed": 38,
    "cancelled": 2,
    "teacher_cancelled": 1,
    "no_show": 1,
    "completion_rate": 0.905,
    "cancellation_rate": 0.095
  },
  "revenue": {
    "confirmed_amount": 2850000,
    "pending_amount": 450000,
    "change_percent": 5.2
  },
  "students": {
    "total_active": 12,
    "new": 2,
    "expired": 1,
    "trial": 1
  },
  "travel": {
    "total_minutes": 500
  },
  "lesson_trend": [
    {"month": "2025-12", "lesson_count": 32, "revenue": 2300000},
    {"month": "2026-01", "lesson_count": 38, "revenue": 2600000},
    {"month": "2026-02", "lesson_count": 41, "revenue": 2710000},
    {"month": "2026-03", "lesson_count": 39, "revenue": 2650000},
    {"month": "2026-04", "lesson_count": 40, "revenue": 2710000},
    {"month": "2026-05", "lesson_count": 42, "revenue": 2850000}
  ],
  "practice_ranking": [
    {
      "student_id": "s001",
      "student_name": "김민수",
      "instrument": "violin",
      "practice_rate": 0.85,
      "practice_minutes": 480
    }
  ]
}
```

### 4.3 학생 성장 분석

```
GET /api/v1/analytics/student/{student_id}/progress?period=3months
```

**Path Params**

| 파라미터 | 타입 | 설명 |
|---------|------|------|
| student_id | string | 학생 UUID |

**Query Params**

| 파라미터 | 타입 | 기본값 | 설명 |
|---------|------|-------|------|
| period | enum | 3months | 1month, 3months, 6months, 12months |

**Response 200**

```json
{
  "student_id": "s001",
  "student_name": "김민수",
  "instrument": "violin",
  "period": "3months",
  "summary": {
    "attendance_rate": 0.92,
    "attended_lessons": 22,
    "total_lessons": 24,
    "practice_achievement_rate": 0.78,
    "total_practice_minutes": 2040,
    "practice_streak_days": 12
  },
  "weekly_practice": [
    {
      "week_start": "2026-03-04",
      "total_minutes": 165,
      "achievement_rate": 0.85,
      "active_days": 5
    }
  ],
  "attendance_calendar": [
    {
      "date": "2026-03-05",
      "status": "present"
    },
    {
      "date": "2026-03-12",
      "status": "absent"
    }
  ],
  "repertoire": [
    {
      "piece_id": "p001",
      "title": "Gavotte",
      "book_title": "Suzuki Vol.3",
      "status": "completed",
      "started_at": "2025-12-01",
      "completed_at": "2026-01-15",
      "mastery_percent": 100
    },
    {
      "piece_id": "p002",
      "title": "Minuet",
      "book_title": "Suzuki Vol.3",
      "status": "in_progress",
      "started_at": "2026-02-01",
      "completed_at": null,
      "mastery_percent": 65
    }
  ],
  "recordings": [
    {
      "recording_id": "r001",
      "piece_title": "Minuet",
      "recorded_at": "2026-03-15T14:30:00Z",
      "duration_seconds": 84,
      "teacher_note": "2절 진입. 활쏘기 자세 크게 개선됨.",
      "audio_url": "/recordings/r001.m4a"
    }
  ],
  "feedback_highlights": [
    {
      "lesson_id": "l042",
      "lesson_date": "2026-03-20",
      "summary_text": "활쏘기 자세가 크게 개선됐어요"
    }
  ]
}
```

### 4.4 연습 요약 (학생 본인용)

```
GET /api/v1/analytics/student/{student_id}/practice-summary?period=1month
```

**Response 200**

```json
{
  "student_id": "s001",
  "period": "1month",
  "weekly_goal_days": 5,
  "weekly_achieved_days": 4,
  "weekly_achievement_rate": 0.80,
  "current_streak_days": 12,
  "longest_streak_days": 21,
  "weekday_practiced": [true, true, true, true, true, false, true],
  "monthly_completed_lessons": 8,
  "monthly_scheduled_lessons": 10,
  "monthly_new_feedbacks": 3,
  "active_repertoire": [
    {
      "piece_id": "p002",
      "title": "Minuet",
      "book_title": "Suzuki Vol.3",
      "status": "in_progress",
      "started_at": "2026-02-01",
      "mastery_percent": 65
    }
  ],
  "growth_timeline": [
    {
      "date": "2026-04-15",
      "type": "feedback_highlight",
      "description": "Minuet 2절 마무리 단계",
      "emoji": null
    },
    {
      "date": "2026-01-15",
      "type": "piece_completed",
      "description": "Gavotte 완곡",
      "emoji": null
    }
  ]
}
```

### 4.5 수입 분석

```
GET /api/v1/analytics/teacher/revenue?period=6months
```

**Query Params**

| 파라미터 | 타입 | 기본값 | 설명 |
|---------|------|-------|------|
| period | int | 6 | 조회 월 수 (1, 3, 6, 12) |

**Response 200**

```json
{
  "current_month_revenue": 2850000,
  "revenue_change_percent": 5.2,
  "pending_amount": 450000,
  "pending_count": 2,
  "expected_monthly_revenue": 2700000,
  "expiring_subscription_count": 3,
  "trend": [
    {
      "month": "2025-12",
      "confirmed_revenue": 2300000,
      "pending_revenue": 0
    },
    {
      "month": "2026-01",
      "confirmed_revenue": 2600000,
      "pending_revenue": 150000
    }
  ],
  "breakdown": [
    {
      "student_id": "s001",
      "student_name": "김민수",
      "amount": 712500,
      "percent": 0.25
    }
  ]
}
```

### 4.6 리텐션 분석

```
GET /api/v1/analytics/teacher/retention
```

**Response 200**

```json
{
  "renewal_rate": 0.76,
  "avg_subscription_months": 14.2,
  "at_risk_students": [
    {
      "student_id": "s005",
      "student_name": "정하준",
      "days_until_expiry": 7,
      "practice_drop_percent": -40.0,
      "last_lesson_date": "2026-04-28",
      "risk_level": "high"
    },
    {
      "student_id": "s004",
      "student_name": "최예린",
      "days_until_expiry": 12,
      "practice_drop_percent": -25.0,
      "last_lesson_date": "2026-05-01",
      "risk_level": "medium"
    }
  ],
  "renewal_trend": [
    {
      "month": "2025-12",
      "expired": 2,
      "renewed": 2
    },
    {
      "month": "2026-01",
      "expired": 3,
      "renewed": 2
    }
  ],
  "tenure_distribution": [
    {"label": "0-3개월", "count": 2},
    {"label": "3-6개월", "count": 4},
    {"label": "6-12개월", "count": 3},
    {"label": "12개월+", "count": 3}
  ]
}
```

### 4.7 에러 응답

| HTTP Status | code | 사유 |
|-------------|------|------|
| 400 | INVALID_PERIOD | period 값이 허용 범위 밖 |
| 403 | FORBIDDEN | 본인 데이터 외 접근 시도 |
| 404 | STUDENT_NOT_FOUND | student_id 없음 |
| 422 | VALIDATION_ERROR | 쿼리 파라미터 타입 오류 |

```json
{
  "error": {
    "code": "INVALID_PERIOD",
    "message": "period must be one of: 1month, 3months, 6months, 12months"
  }
}
```

---

## 5. Frontend 구조

### 5.1 파일 레이아웃

```
features/analytics/
├── domain/
│   ├── entities/
│   │   ├── teacher_stats.dart              (기존 — 유지)
│   │   ├── teacher_stats.g.dart            (generated)
│   │   ├── student_progress.dart           (신규)
│   │   ├── student_progress.g.dart         (generated)
│   │   ├── revenue_analytics.dart          (신규)
│   │   ├── revenue_analytics.g.dart        (generated)
│   │   ├── retention_analytics.dart        (신규)
│   │   ├── retention_analytics.g.dart      (generated)
│   │   ├── student_analytics_summary.dart  (신규)
│   │   └── student_analytics_summary.g.dart (generated)
│   └── repositories/
│       └── analytics_repository.dart       (기존 확장)
├── data/
│   └── repositories/
│       ├── mock_analytics_repository.dart  (기존 확장)
│       └── remote_analytics_repository.dart (기존 확장)
└── presentation/
    ├── providers/
    │   ├── analytics_providers.dart        (기존 확장)
    │   └── analytics_providers.g.dart      (generated)
    ├── screens/
    │   ├── analytics_dashboard_screen.dart (신규 — 탭 컨테이너)
    │   ├── student_progress_detail_screen.dart (신규)
    │   └── teacher_retention_screen.dart   (신규)
    └── widgets/
        ├── (기존)
        │   ├── monthly_trend_chart.dart
        │   └── practice_ranking_list.dart
        ├── (신규 — 선생님)
        │   ├── analytics_summary_tab.dart      # Tab 1 월간 요약
        │   ├── student_growth_tab.dart         # Tab 2 학생별 성장
        │   ├── revenue_analytics_tab.dart      # Tab 3 수입 분석
        │   ├── revenue_bar_chart.dart          # 월별 수입 바 차트
        │   ├── revenue_pie_chart.dart          # 학생별 비중 파이 차트
        │   ├── at_risk_student_card.dart       # 이탈 위험 카드
        │   ├── tenure_distribution_chart.dart  # 수강 기간 분포 가로 바
        │   └── renewal_trend_chart.dart        # 갱신율 추이
        ├── (신규 — 학생 상세)
        │   ├── practice_weekly_line_chart.dart # 주간 연습 라인 차트
        │   ├── attendance_heatmap.dart         # 출석 캘린더 히트맵
        │   ├── repertoire_timeline.dart        # 레퍼토리 완료 타임라인
        │   └── recording_comparison_list.dart  # 녹음 타임라인
        └── (신규 — 학생/학부모)
            ├── practice_goal_ring.dart         # 주간 목표 링
            ├── streak_display.dart             # 연속 연습 스트릭
            └── growth_milestone_timeline.dart  # 성장 타임라인
```

### 5.2 Provider 정의

```dart
// analytics_providers.dart (기존 파일 확장)

// ---- 기존 유지 ----
@Riverpod(keepAlive: true)
AnalyticsRepository analyticsRepository(AnalyticsRepositoryRef ref) { ... }

@riverpod
Future<TeacherMonthlyStats> teacherMonthlyStats(
  TeacherMonthlyStatsRef ref, DateTime month) async { ... }

// ---- 신규 추가 ----
@riverpod
Future<StudentProgress> studentProgress(
  StudentProgressRef ref,
  String studentId,
  AnalyticsPeriod period,
) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  return repository.getStudentProgress(studentId, period: period);
}

@riverpod
Future<RevenueAnalytics> revenueAnalytics(
  RevenueAnalyticsRef ref,
  int periodMonths,
) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  return repository.getRevenueAnalytics(periodMonths: periodMonths);
}

@riverpod
Future<RetentionAnalytics> retentionAnalytics(
  RetentionAnalyticsRef ref,
) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  return repository.getRetentionAnalytics();
}

@riverpod
Future<StudentAnalyticsSummary> studentAnalyticsSummary(
  StudentAnalyticsSummaryRef ref,
  String studentId,
) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  return repository.getStudentAnalyticsSummary(studentId);
}
```

### 5.3 라우팅 정의

```dart
// 기존 route에 추가할 경로
// core/router/routes/analytics_routes.dart

const _analyticsDashboard = '/analytics';
const _studentProgressDetail = '/analytics/student/:studentId';
const _teacherRetention = '/analytics/retention';

List<GoRoute> get analyticsRoutes => [
  GoRoute(
    path: _analyticsDashboard,
    builder: (context, state) => const AnalyticsDashboardScreen(),
  ),
  GoRoute(
    path: _studentProgressDetail,
    builder: (context, state) {
      final studentId = state.pathParameters['studentId']!;
      final periodStr = state.uri.queryParameters['period'] ?? 'threeMonths';
      return StudentProgressDetailScreen(
        studentId: studentId,
        initialPeriod: AnalyticsPeriod.fromString(periodStr),
      );
    },
  ),
  GoRoute(
    path: _teacherRetention,
    builder: (context, state) => const TeacherRetentionScreen(),
  ),
];
```

학생 홈 탭 내 `StudentAnalyticsTab`은 별도 라우트 없이 `student_home_tab.dart`의 탭 위젯으로 진입.

---

## 6. UX 디자인 — Notebook × Score

### 6.1 색상 매핑

| UI 요소 | AppColors 토큰 | 설명 |
|---------|---------------|------|
| 차트 1차 데이터라인 | `paperAccent` (#9B1B12) | 출석, 완료, 핵심 지표 |
| 차트 2차 데이터라인 | `paperOk` (#3F5D2F) | 연습 달성, 긍정 지표 |
| 차트 3차 데이터라인 | `paperTrial` (#C4923A) | 예상/계획, 중간 지표 |
| 차트 비활성/배경 | `inkTertiary` (55% alpha) | 목표선, 보조 선 |
| 카드 배경 | `paperDark` (#E8DFC7) | StatCard 배경 |
| 카드 좌측 액센트 보더 | `paperAccent` | 핵심 액션 카드 |
| 히트맵 레벨 0 | `paper` (#F2ECDD) | 연습 없음 |
| 히트맵 레벨 1 | `inkQuaternary` blend | 1~2회 |
| 히트맵 레벨 2 | `inkTertiary` blend | 3~4회 |
| 히트맵 레벨 3 | `ink` (#14161C) | 5회+ |
| 이탈 위험 HIGH | `paperAccent` | 긴급 경고 |
| 이탈 위험 MEDIUM | `paperTrial` | 주의 |
| 이탈 위험 LOW | `inkTertiary` | 정보 |
| 스트릭 불꽃 | `amber` (#FFB800) | 연속 달성 강조 |

### 6.2 차트 라이브러리 선택

**기존**: `monthly_trend_chart.dart` — `CustomPaint` (fl_chart 미사용)
**신규 차트**: `CustomPaint` 동일 방식으로 구현. fl_chart 패키지 신규 추가 금지.

> 이유: pubspec.yaml에 fl_chart 없음. 기존 CustomPaint 패턴 일관성 유지.
> 선례: `monthly_trend_chart.dart`의 `_TrendChartPainter` 참조하여 동일 스타일로 구현.

**구현할 차트 종류**

| 차트 | 구현 방식 |
|------|---------|
| 라인 차트 (연습 시간 추이) | `CustomPaint` — 베지어 곡선, 데이터 포인트 원형 |
| 바 차트 (수입 추이) | `CustomPaint` — 직사각형 + paperDark 배경 |
| 파이 차트 (학생별 수입 비중) | `CustomPaint` — 아크 + 범례 텍스트 |
| 히트맵 캘린더 (출석) | `GridView` + `Container` — 7열 고정 그리드 |
| 가로 바 분포 (수강 기간) | `LinearProgressIndicator` 커스텀 |
| 타임라인 (레퍼토리) | `Column` + 연결선 `CustomPaint` |

### 6.3 StatCard 패턴

기존 `core/widgets/stat_card.dart`를 재사용. 신규 variant 필요 시 기존 파일에 named constructor 추가.

```dart
// 표준 StatCard — 기존 core/widgets/stat_card.dart 재사용
StatCard(
  label: '완료율',
  value: '90.5%',
  subtitle: '↑+2.1% 전월 대비',
  subtitleColor: AppColors.paperOk,
  leftBorderColor: AppColors.paperOk,
)
```

### 6.4 텍스트 규칙

| 요소 | Typography 토큰 |
|------|----------------|
| 섹션 헤더 | `NotebookTypography.sectionTitle` |
| 차트 수치 레이블 | `AppTypography.captionMono` (IBM Plex Mono) |
| 카드 큰 숫자 | `AppTypography.displaySmall` |
| 카드 라벨 | `AppTypography.labelMedium` |
| 타임라인 날짜 | `AppTypography.captionMono` |

### 6.5 학생 뷰 스트릭 디자인

스트릭은 Modacity/Simply Piano의 불꽃 애니메이션 대신 Notebook 스타일로:
- 연속 7일+: `paperHighlight` (#F7D755) 배경의 원형 배지 + `amber` 수치
- 연속 3-6일: `paperTrial` 배경
- 연속 1-2일: `paperDark` 배경

---

## 7. 구현 단계

### Phase A: 데이터 모델 + Mock 집계 서비스

**범위**: 신규 엔티티 4개 + Mock Repository 확장 + Provider 정의
**산출물**:
- `student_progress.dart` + `.g.dart`
- `revenue_analytics.dart` + `.g.dart`
- `retention_analytics.dart` + `.g.dart`
- `student_analytics_summary.dart` + `.g.dart`
- `mock_analytics_repository.dart` 확장 (메서드 4개 추가)
- `analytics_providers.dart` 확장 (provider 4개 추가)

**완료 기준**: `flutter analyze` 0 에러, mock 데이터 모든 provider에서 반환

### Phase B: 선생님 월간 요약 카드 (AnalyticsDashboardScreen Tab 1)

**범위**: 기존 `teacher_dashboard_screen.dart`를 탭 구조 컨테이너로 리팩토링
**산출물**:
- `analytics_dashboard_screen.dart` (신규 — DefaultTabController 탭 3개)
- `analytics_summary_tab.dart` (기존 `teacher_dashboard_screen.dart` 내용 이동)
- 라우팅 등록

**완료 기준**: Tab 1에서 6개 StatCard + 레슨 추이 차트 + 연습률 TOP 5 표시

### Phase C: 학생별 성장 차트 (Tab 2 + StudentProgressDetailScreen)

**범위**: 학생 선택 드롭다운 + 연습 라인 차트 + 출석 히트맵 + 레퍼토리 진도
**산출물**:
- `student_growth_tab.dart`
- `student_progress_detail_screen.dart`
- `practice_weekly_line_chart.dart` (CustomPaint)
- `attendance_heatmap.dart` (GridView)
- `repertoire_timeline.dart`
- `recording_comparison_list.dart`

**완료 기준**: 학생 선택 → 기간 변경 → 각 차트 데이터 갱신 정상 동작

### Phase D: 수입 분석 (Tab 3)

**범위**: 수입 바 차트 + 학생별 파이 차트 + 미수금 카드 + 예상 수입
**산출물**:
- `revenue_analytics_tab.dart`
- `revenue_bar_chart.dart` (CustomPaint)
- `revenue_pie_chart.dart` (CustomPaint)

**완료 기준**: 6개월 바 차트 + 파이 차트 + 미수금/예상수입 카드 표시

### Phase E: 학생/학부모 분석 뷰 (StudentAnalyticsTab)

**범위**: 학생 홈 내 분석 탭 섹션 신규 추가
**산출물**:
- `practice_goal_ring.dart`
- `streak_display.dart`
- `growth_milestone_timeline.dart`
- `student_home_tab.dart` 또는 `student_analytics_screen.dart`에 섹션 추가

**완료 기준**: 학생 계정으로 로그인 시 주간 목표 달성률 + 스트릭 + 레퍼토리 진도 표시

### Phase F: 리텐션 분석 (TeacherRetentionScreen)

**범위**: 이탈 예측 로직 + 갱신율 추이 + AtRiskStudent 카드
**산출물**:
- `teacher_retention_screen.dart`
- `at_risk_student_card.dart`
- `renewal_trend_chart.dart`
- `tenure_distribution_chart.dart`

**완료 기준**: 이탈 위험 학생 조건(만료 임박 OR 연습 감소) 올바르게 분류, 갱신 제안 발송 버튼 → 기존 ProposalScreen 연결

### Phase G: 백엔드 API 구현

**범위**: FastAPI 엔드포인트 5개 + PostgreSQL 집계 쿼리
**산출물**:
- `backend/app/api/v1/analytics.py`
- `backend/app/schemas/analytics.py`
- `backend/app/services/analytics_service.py`

**완료 기준**: `test_analytics.py` 시나리오 테스트 통과, SQL 집계 결과 mock 데이터와 일치

---

## 8. 백엔드 구현 가이드

### 8.1 파일 위치

```
backend/app/
├── api/v1/analytics.py          # 라우터 (5 엔드포인트)
├── schemas/analytics.py         # Pydantic 요청/응답 스키마
└── services/analytics_service.py  # 비즈니스 로직 + SQL 쿼리
```

### 8.2 이탈 위험 판정 로직

```python
def classify_risk_level(
    days_until_expiry: int,
    practice_drop_percent: float,
) -> RiskLevel:
    """
    이탈 위험 판정 기준:
    - HIGH: 만료 7일 이내 AND 연습 30%+ 감소
    - HIGH: 만료 7일 이내 (연습 무관)
    - MEDIUM: 만료 14일 이내 OR 연습 20%+ 감소
    - LOW: 만료 30일 이내
    """
    if days_until_expiry <= 7:
        return RiskLevel.HIGH
    if days_until_expiry <= 14 or practice_drop_percent <= -20:
        return RiskLevel.MEDIUM
    if days_until_expiry <= 30:
        return RiskLevel.LOW
    return None  # 위험 없음, 목록에 미포함
```

### 8.3 연습 감소율 계산

```
이전 기간 연습률 대비 현재 기간 연습률의 변화 %
- 현재 기간: 최근 2주
- 비교 기간: 그 이전 2주
- practice_drop_percent = (current_rate - previous_rate) / previous_rate * 100
```

### 8.4 예상 월수입 계산

```
활성 수강권(status='active') 각각의 1회당 단가 × 월 레슨 예약 횟수 합산
- 회차권: price_per_session × remaining_sessions (단, 이번 달 예약분만)
- 정기권: monthly_fee (전액)
```

---

## 9. Mock 데이터 상세

### 9.1 StudentProgress (김민수, 3개월)

```dart
StudentProgress(
  studentId: 'student_001',
  studentName: '김민수',
  instrumentType: 'violin',
  attendanceRate: 0.92,
  attendedLessons: 22,
  totalLessons: 24,
  practiceAchievementRate: 0.78,
  totalPracticeMinutes: 2040,
  practiceStreakDays: 12,
  weeklyPractice: [
    WeeklyPracticeSummary(weekStart: DateTime(2026,3,4), totalMinutes: 165, achievementRate: 0.85, activeDays: 5),
    WeeklyPracticeSummary(weekStart: DateTime(2026,3,11), totalMinutes: 195, achievementRate: 1.0, activeDays: 6),
    WeeklyPracticeSummary(weekStart: DateTime(2026,3,18), totalMinutes: 120, achievementRate: 0.60, activeDays: 4),
    WeeklyPracticeSummary(weekStart: DateTime(2026,3,25), totalMinutes: 180, achievementRate: 0.92, activeDays: 5),
    WeeklyPracticeSummary(weekStart: DateTime(2026,4,1), totalMinutes: 150, achievementRate: 0.75, activeDays: 5),
    WeeklyPracticeSummary(weekStart: DateTime(2026,4,8), totalMinutes: 170, achievementRate: 0.88, activeDays: 5),
    WeeklyPracticeSummary(weekStart: DateTime(2026,4,15), totalMinutes: 115, achievementRate: 0.58, activeDays: 4),
    WeeklyPracticeSummary(weekStart: DateTime(2026,4,22), totalMinutes: 185, achievementRate: 0.95, activeDays: 6),
    WeeklyPracticeSummary(weekStart: DateTime(2026,4,29), totalMinutes: 160, achievementRate: 0.82, activeDays: 5),
    WeeklyPracticeSummary(weekStart: DateTime(2026,5,6), totalMinutes: 80, achievementRate: 0.70, activeDays: 3),
  ],
  // attendance_calendar 생략 (90일치 — 구현 시 확장)
  attendanceCalendar: [],
  repertoire: [
    RepertoireProgressItem(
      pieceId: 'piece_001',
      title: 'Gavotte',
      bookTitle: 'Suzuki Vol.3',
      status: RepertoireStatus.completed,
      startedAt: DateTime(2025,12,1),
      completedAt: DateTime(2026,1,15),
      masteryPercent: 100,
    ),
    RepertoireProgressItem(
      pieceId: 'piece_002',
      title: 'Minuet',
      bookTitle: 'Suzuki Vol.3',
      status: RepertoireStatus.inProgress,
      startedAt: DateTime(2026,2,1),
      completedAt: null,
      masteryPercent: 65,
    ),
    RepertoireProgressItem(
      pieceId: 'piece_003',
      title: 'Bourrée',
      bookTitle: 'Suzuki Vol.3',
      status: RepertoireStatus.planned,
      startedAt: null,
      completedAt: null,
      masteryPercent: null,
    ),
  ],
  recordings: [
    RecordingEntry(recordingId: 'rec_003', pieceTitle: 'Minuet', recordedAt: DateTime(2026,4,15), durationSeconds: 96, teacherNote: '마무리 단계. 활쏘기 자세 완성.', audioUrl: null),
    RecordingEntry(recordingId: 'rec_002', pieceTitle: 'Minuet', recordedAt: DateTime(2026,3,1), durationSeconds: 84, teacherNote: '2절 진입. 개선 눈에 띄어요.', audioUrl: null),
    RecordingEntry(recordingId: 'rec_001', pieceTitle: 'Minuet', recordedAt: DateTime(2026,2,1), durationSeconds: 70, teacherNote: '초견. 리듬 좋음.', audioUrl: null),
  ],
  feedbackHighlights: [
    FeedbackSummary(lessonId: 'l042', lessonDate: DateTime(2026,3,20), summaryText: '활쏘기 자세가 크게 개선됐어요'),
    FeedbackSummary(lessonId: 'l038', lessonDate: DateTime(2026,2,28), summaryText: '비브라토 기초 도입 — 매일 5분 연습'),
    FeedbackSummary(lessonId: 'l034', lessonDate: DateTime(2026,1,31), summaryText: '3포지션 안정화. 다음 목표: 비브라토'),
  ],
)
```

### 9.2 AtRiskStudents

```dart
[
  AtRiskStudent(
    studentId: 'student_005',
    studentName: '정하준',
    daysUntilExpiry: 7,
    practiceDropPercent: -40.0,
    lastLessonDate: DateTime(2026,4,28),
    riskLevel: RiskLevel.high,
  ),
  AtRiskStudent(
    studentId: 'student_004',
    studentName: '최예린',
    daysUntilExpiry: 12,
    practiceDropPercent: -25.0,
    lastLessonDate: DateTime(2026,5,1),
    riskLevel: RiskLevel.medium,
  ),
  AtRiskStudent(
    studentId: 'student_003',
    studentName: '박지호',
    daysUntilExpiry: 21,
    practiceDropPercent: 0.0,
    lastLessonDate: DateTime(2026,5,3),
    riskLevel: RiskLevel.low,
  ),
]
```

---

## 10. 테스트 체크리스트

### Unit Tests

| 테스트 | 파일 | 검증 포인트 |
|--------|------|-----------|
| 이탈 위험 판정 | `test/analytics/retention_analytics_test.dart` | 7일 이내 → HIGH, 14일 + 20% 감소 → MEDIUM 등 |
| 연습 달성률 계산 | `test/analytics/practice_rate_test.dart` | 0~100%, 목표 0인 경우 처리 |
| 수입 변화율 계산 | `test/analytics/revenue_analytics_test.dart` | 전월 0원 경우, 소수점 반올림 |

### Widget Smoke Tests

```dart
// test/features/analytics/analytics_dashboard_screen_test.dart
testWidgets('AnalyticsDashboardScreen smoke test', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [analyticsRepositoryProvider.overrideWithValue(MockAnalyticsRepository())],
      child: const MaterialApp(home: AnalyticsDashboardScreen()),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
});
```

---

## 11. 관련 문서

| 문서 | 역할 |
|------|------|
| [analytics_dashboard_spec.md](analytics_dashboard_spec.md) | Phase 1+2 완료 스펙 (이 문서의 기반) |
| [docs/specs/design/ux_guidelines.md](../design/ux_guidelines.md) | UX 원칙 |
| [docs/specs/design/notebook/README.md](../design/notebook/README.md) | Notebook × Score 팔레트 |
| [docs/specs/subscription/lesson_cancellation_policy.md](../subscription/lesson_cancellation_policy.md) | 출석/취소 판정 기준 |
| [docs/specs/practice/](../practice/) | 연습 데이터 소스 |

---

## 변경 이력

| 날짜 | 변경 내용 |
|------|----------|
| 2026-05-07 | 초안 작성 — Phase 3 학생 성장 분석 + 수입 분석 + 리텐션 + 학생/학부모 뷰 전체 스펙 |
