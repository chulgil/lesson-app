# Audit — analytics 도메인 (2026-04-30)

> 점검자: Claude Phase 3-2 격리 에이전트  
> 범위: `docs/specs/analytics/analytics_dashboard_spec.md` 전체  
> 기준: 프론트 Phase 1+2 구현 완료 vs 백엔드 endpoint/model 0개

## 1. 프론트 요구 인벤토리

| 기능 | Spec § | Mock 데이터 | 프론트 구현 파일 | 상태 |
|------|--------|-----------|-----------------|------|
| 월간 통계 (레슨/수익/학생) | 2.1, 3.1 | TeacherMonthlyStats | `teacher_dashboard_screen.dart` | ✅ Phase 1+2 |
| 레슨 추이 차트 (6개월) | 2.1, 5.1 | `MonthlyTrend[]` | `monthly_trend_chart.dart` | ✅ CustomPaint |
| 연습률 TOP 5 랭킹 | 2.1, 5.1 | `StudentPracticeRank[]` | `practice_ranking_list.dart` | ✅ Phase 1+2 |
| 학생별 상세 리포트 | 2.2, 5.2 | `StudentReport` (mock 스펙만) | student_report_screen.dart | ❌ Phase 3 |
| 출석률 카드 | 2.2, 5.2 | — | attendance_rate_card.dart | ❌ Phase 3 |
| 연습률 히트맵 | 2.2, 5.2 | `practiceData: Map<DateTime, int>` | practice_heatmap.dart | ❌ Phase 3 |
| 주간 연습률 차트 | 2.2, 5.2 | `WeeklyPracticeRate[]` | practice_weekly_trend_chart.dart | ❌ Phase 3 |
| 레퍼토리 진도 | 2.2, 5.2 | `RepertoireProgress[]` | repertoire_progress_list.dart | ❌ Phase 3 |
| 레슨 노트 요약 | 2.2, 5.2 | `LessonNoteSummary[]` | recent_lesson_notes_list.dart | ❌ Phase 3 |

## 2. 백엔드 현황

| 항목 | 확인 결과 |
|------|---------|
| analytics 라우터 (`api/v1/analytics.py`) | **0개** — 파일 부재 |
| analytics 모델 (`models/analytics.py` 등) | **0개** — 모델 부재 |
| 통계 서비스 | **0개** — 서비스 부재 |
| `/analytics/monthly-stats` endpoint | **MISSING** — `RemoteAnalyticsRepository` 호출 명시, 구현 0 |
| 데이터 소스 (Lesson/Subscription/Student) | ✅ 존재 — 집계 기반 제공 가능 |

**결론**: 백엔드는 **완전 미구현** 상태. 프론트는 Mock 데이터로 UI/UX만 검증 중.

## 3. 갭 매트릭스

| # | 항목 | 프론트 출처 | 백엔드 상태 | 판정 | 우선 |
|---|------|-----------|-----------|:---:|:---:|
| 1 | 월간 통계 조회 (레슨/수익/학생/출석률) | spec §2.1, 3.1 | MISSING | MISSING | **P0** |
| 2 | 레슨 추이 (6개월 trend 데이터) | spec §2.1, 7.1 | MISSING | MISSING | **P0** |
| 3 | 연습률 TOP 5 랭킹 | spec §2.1, 7.3 | MISSING | MISSING | **P0** |
| 4 | TeacherMonthlyStats 응답 스키마 | mock §7.1 | MISSING | MISSING | **P0** |
| 5 | StudentPracticeRank 응답 스키마 | mock §7.3 | MISSING | MISSING | **P0** |
| 6 | 학생 리포트 조회 (출석/연습/진도/노트) | spec §2.2, 3.1 | MISSING | MISSING | **P1** |
| 7 | StudentReport 응답 스키마 | spec §3.3 | MISSING | MISSING | **P1** |
| 8 | 연습 데이터 조회 (PracticeItem) | spec §3.1 | 부분 (practice.py 라우터 존재) | STALE | **P1** |
| 9 | 레퍼토리 진도 조회 | spec §2.2, 3.1 | 부분 (repertoire?) | STALE | **P1** |
| 10 | 레슨 노트 조회 (학생별 시간순) | spec §2.2, 3.1 | 부분 (lessons.py에 포함?) | STALE | **P1** |

## 4. 권장 조치

### P0 (즉시 차단 — 월간 통계 API 신설)

**신설 라우터**: `backend/app/api/v1/analytics.py`

```python
# GET /analytics/monthly-stats?month=2026-04
#   → TeacherMonthlyStats JSON
#   집계 로직: 
#   - totalLessons = count(Lesson where month, teacher_id)
#   - completedLessons = count(Lesson where status='completed')
#   - cancelledLessons = count(where status in ['cancelled*'])
#   - noShowLessons = count(where status in ['noShow', 'studentAbsent'])
#   - totalRevenue = sum(Subscription.price where status='confirmed', month)
#   - revenueChangePercent = (current - prev) / prev * 100
#   - totalStudents = count(Student where teacher_id, active)
#   - newStudents = count(created_at in month)
#   - churnedStudents = count(inactive in month)
#   - attendanceRate = completedLessons / (completedLessons + cancelledLessons + noShow) * 100
#   - lessonTrend = [6개월 월별 {month, lessonCount, revenue}]

# GET /analytics/practice-ranking?month=2026-04
#   → List[StudentPracticeRank] JSON
#   집계 로직:
#   - practiceRate = count(PracticeItem where isCompleted=true, student, month) / total * 100
#   - practiceMinutes = sum(PracticeItem.duration where completed, month)
```

### P1 (기능 차단 — 학생 리포트 API)

**신설 라우터**: 동일 `analytics.py`

```python
# GET /analytics/students/{studentId}/report?period=3months
#   → StudentReport JSON
#   필요 통합:
#   - attendanceRate (Lesson 기반)
#   - practiceRates[] (PracticeItem 주간 집계)
#   - repertoireProgress[] (Repertoire + LessonNote 통합)
#   - recentNotes[] (LessonNote 조회)
```

**신설 모델** (선택사항 — 응답만 정의):
- `analytics.py`: `TeacherMonthlyStats`, `StudentPracticeRank`, `StudentReport`, `MonthlyTrend` 스키마

## 5. 평가

| 기준 | 점수 | 근거 |
|------|:---:|------|
| SSOT 명확도 | 60/100 | 스펙은 데이터 소스 명시 (Lesson/Subscription/Student), 백엔드 구현 부재로 명확성 0 |
| 프론트↔백엔드 일치 | 0/100 | Mock 데이터 구현만 존재, 백엔드 endpoint 0개 |
| 데이터 모델 정합성 | N/A | 백엔드 미구현 |
| 우선순위 정렬 | 70/100 | Phase 1+2 프론트 완료, Phase 3 명시 (학부모 공유 제외) — 백엔드는 Phase 1+2 누락 |

**종합**: **FAIL** — 백엔드 완전 미구현. P0 3항 (월간 통계 API, 스키마, 랭킹 조회) 즉시 추가 필수.
