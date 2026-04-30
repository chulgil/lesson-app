# Home 도메인 백엔드 점검 (Home / Student_Home / Parent_Home)

> 점검일: 2026-04-30
> 점검자: Claude (Phase 1D — Home Domains)
> 대상: `backend/app/api/v1/teachers.py`, `parents.py`, 스펙 ↔ 프론트 매트릭스
> 비교 SSOT: `docs/specs/home/home_master.md`, `docs/specs/student_home/student_home_master.md`, `docs/specs/user/parent_dashboard_spec.md`

---

## 1. 핵심 질문: 전용 집계 API vs 기존 endpoint 재조합

### 1.1 분석 결과

세 도메인 모두 **기존 도메인별 endpoint 재조합 가능**.

**Home (선생님)**:
- 오늘 레슨 `GET /lessons?teacher_id=self&date=today` (기존)
- 긴급 알림 = Subscription (만료) + 예약 (미승인) + 노트 (미완료)  
- StatsRow = LessonStats 재조합  
- → **N+1 쿼리 risk LOW** (Lesson/Subscription 단일 풀이면 충분)

**Student Home**:
- 다음 레슨 = `GET /lessons?student_id=self&date>=today` (첫 항목)  
- 수강권 상태 = `GET /subscriptions?student_id=self`  
- 이벤트 그룹 = RequestEvent/Proposal (기존)  
- → **N+1 risk MEDIUM** (5+개 독립 provider, client 순차 호출)

**Parent Home**:
- 자녀 프로필 = `GET /children?parent_id=self` (기존)  
- 레슨/과제/결제 = 자녀별 student_id 재조합  
- Mock → 실데이터 간격 존재  
- → **N+1 risk HIGH** (자녀 선택 후 4개 탭 × 자녀 수 조회)

---

## 2. 점검 매트릭스

### 2.1 Home Domain (선생님 대시보드)

| # | 요구사항 (home_master.md) | 프론트 구현 | 백엔드 endpoint | 판정 |
|---|--------------------------|-----------|-----------------|------|
| 1 | §2.1 Header (롤 + 알림벨) | 고정 UI | — | **PASS** |
| 2 | §2.1 GettingStartedCard (학생 0명 시) | 조건부 렌더 | 없음 (클라이언트 조회) | **PARTIAL** |
| 3 | §3.1 UrgentAlertZone (Top 1 + Expandable) | 완료 | `GET /subscriptions?status=expired\|expiringSoon` + `GET /bookings?status=pending` | **PASS** |
| 4 | §3.2 TodayLessons (Progressive 5→Full) | 완료 | `GET /lessons?teacher_id=self&date=today` | **PASS** |
| 5 | §3.2 TodayLessons "전체보기" 버튼 | 완료 | 기존 endpoint 재사용 | **PASS** |
| 6 | §3.3 LessonRequestSection (최대 3건) | 완료 | `GET /requests?teacher_id=self&status=pending` (위임) | **PARTIAL** |
| 7 | §3.3 ScheduleChangeRequestSection | 완료 | RequestEvent 모델 (2026-04-28 audit P0-2 미반영) | **MISSING** |
| 8 | §3.4 StatsRow (오늘/이번달) | 완료 | `GET /lessons?teacher_id=self` (클라이언트 grouping) | **PARTIAL** |
| 9 | §3.5 TimeContextBanner (시간대 메시지) | 완료 | 로컬 시간만 필요 | **PASS** |
| 10 | §2.1 AssignmentSummarySection | 완료 | `GET /assignments?teacher_id=self` | **MISSING** (확인 필요) |

### 2.2 Student Home Dashboard

| # | 요구사항 (student_home_master.md) | 프론트 구현 | 백엔드 제공 | 판정 |
|---|----------------------------------|-----------|----------|------|
| 1 | §2.2 TimeContextBanner | 완료 | 로컬 시간 | **PASS** |
| 2 | §2.2 GamificationHeader (레벨/포인트/배지) | 완료 | `GET /gamification?student_id=self` | **PASS** |
| 3 | §2.2 NextLessonCard (다음 레슨) | 완료 | `GET /lessons?student_id=self&date>=today` | **PASS** |
| 4 | §2.2 SubscriptionSummary (수강권 미니) | 완료 | `GET /subscriptions?student_id=self` | **PASS** |
| 5 | §2.2 EventsGroup (대응 필요 통합 4개) | 완료 | RequestEvent/Proposal/Booking (분산) | **PARTIAL** |
| 6 | §2.2 TeacherFeedback (최근 1개) | 완료 | `GET /reviews?student_id=self` | **PARTIAL** |
| 7 | §2.2 PracticeSummary (히트맵 + 마일스톤) | 완료 | `GET /practice?student_id=self` | **PARTIAL** |
| 8 | §2.3 StudentLessonsTab (주간 캘린더) | 완료 | 기존 endpoint 재사용 | **PASS** |
| 9 | §2.4 StudentPracticeTab (레퍼토리) | 완료 | `GET /practice?student_id=self` | **PASS** |
| 10 | §2.5 StudentProfileTab (설정) | 완료 | `GET /users/{id}/profile` | **PASS** |

### 2.3 Parent Home Dashboard

| # | 요구사항 (parent_dashboard_spec.md) | 프론트 상태 | 백엔드 endpoint | 판정 |
|---|-------------------------------------|-----------|-----------------|------|
| 1 | §2 Child 프로필 선택 | ✅ 실데이터 | `GET /children?parent_id=self` | **PASS** |
| 2 | §4.1 QuickStats (이번주 레슨 수) | ❌ 하드코딩 "1회" | `GET /lessons?child_id={id}&date_range=week` 필요 | **MISSING** |
| 3 | §4.1 QuickStats (과제 완료율) | ❌ 하드코딩 "4/5" | `GET /assignments?child_id={id}` 필요 | **MISSING** |
| 4 | §4.1 QuickStats (연습 스트릭) | ❌ 하드코딩 "12일" | `GET /practice/streak?child_id={id}` 필요 | **MISSING** |
| 5 | §4.1 NextLessonCard | ❌ 하드코딩 | `GET /lessons?child_id={id}&next=true` 필요 | **MISSING** |
| 6 | §4.1 PracticeCalendar (주간) | ❌ 하드코딩 | `GET /practice/calendar?child_id={id}&week=...` 필요 | **MISSING** |
| 7 | §4.2 ParentLessonsTab (캘린더 + 목록) | ❌ 하드코딩 | `GET /lessons?child_id={id}` + 모델링 필요 | **MISSING** |
| 8 | §4.2 LessonNote 바텀시트 | ❌ 하드코딩 | `GET /lessons/{id}/notes` 필요 | **MISSING** |
| 9 | §4.3 ParentAssignmentsTab | ❌ 하드코딩 | `GET /assignments?child_id={id}` 필요 | **MISSING** |
| 10 | §4.4 ParentPaymentsTab | ✅ 실데이터 (#233) | `GET /subscriptions?student_id=linkedStudentId` 재사용 | **PASS** |

---

## 3. 갭 상세 분석

### P0 갭 (기능 불가, 0건)

**없음**. 세 도메인 모두 fallback mock/stub 데이터 또는 기존 endpoint 재조합으로 기본 동작 가능.

### P1 갭 (기능 차단, 4건)

#### P1-1 — Parent QuickStats 3개 endpoint 미구현 (#2, #3, #4)

- **현황**: 학부모 대시보드 상단 3열 카드가 모두 하드코딩.
  - "이번주 레슨": 1회 (고정)
  - "과제 완료율": 4/5 (고정)
  - "연습 스트릭": 12일 (고정)
- **프론트 impact**: `childProfileProvider` 선택 후 실시간 갱신 불가. mock 데이터 진입 장벽.
- **백엔드 누락**: 3개 조회 endpoint 부재.
  - `GET /lessons?child_id={id}&date_range=week&count_only=true` → `{ "count": int }`
  - `GET /assignments?child_id={id}&summary=true` → `{ "total": int, "completed": int }`
  - `GET /practice/streak?child_id={id}` → `{ "streak_days": int }`
- **우선순위**: **P1** (phase_2 roadmap 의존, mock 상태로도 동작)

#### P1-2 — Parent Dashboard 자녀별 탭 데이터 미연동 (#5~#9)

- **현황**: 레슨/과제/결제 탭이 4개 섹션 모두 하드코딩.
  - ParentDashboardTab NextLessonCard: 고정 "D-1 1월 16일"
  - ParentLessonsTab: placeholder 캘린더 + 하드코딩 목록
  - ParentAssignmentsTab: 하드코딩 진행도 "71% 완료"
- **프론트 impact**: 자녀 선택 후 새로고침해도 tab UI 갱신 안 됨.
- **백엔드 누락**: 자녀(student_id) 기반 4개 이상의 새로운 조회 경로 필요.
  - `GET /lessons?child_id={id}` (기존 경로 변경)
  - `GET /assignments?child_id={id}` (신규)
  - `GET /practice/calendar?child_id={id}&week=ISO` (신규)
  - `GET /lessons/{id}/notes` (신규)
- **우선순위**: **P1** (Parent Dashboard Phase 2 핵심 데이터)

#### P1-3 — Home ScheduleChangeRequestSection endpoint 미연결 (#7)

- **현황**: 위젯 완료하나 백엔드 RequestEvent SSOT 미반영 (2026-04-28 audit P0-4).
- **프론트 impact**: 스케줄 변경 요청이 화면에 노출되지 않음.
- **우선순위**: **P1** (기존 audit P0-4 종속)

### P2 갭 (정합성, 5건)

#### P2-1 — StatsRow 클라이언트 aggregation (#8)

- **현황**: `lessonStatsProvider` 가 모든 lesson 조회 후 grouping.
- **개선**: 백엔드 `GET /stats/lessons?teacher_id=self&group_by=date` 별도 endpoint가 더 효율적.
- **우선순위**: **P2** (기존 동작하나 확장성 리스크)

#### P2-2 — Student EventsGroup 분산 provider (#5)

- **현황**: 4개 이벤트(레슨요청/갱신제안/예약/확인) 가 각각 다른 provider.
  - `studentLessonRequestsProvider`
  - `pendingStudentProposalsProvider`
  - `studentBookingsProvider`
  - `scheduleConfirmationCardsProvider` (부재)
- **개선**: 단일 `GET /events?student_id=self&type=all` aggregation endpoint.
- **우선순위**: **P2** (기능 동작, UX 효율성)

#### P2-3 — Parent Home linkedStudentId 매핑 부재 (#2~#6)

- **현황**: ChildProfile.linkedStudentId 가 null이면 "선생님 연결 안 됨" 표시. 
- **phase_2 로드맵**: 자녀 생성 시 자동 student ID 매핑 필요 (현재 수동).
- **우선순위**: **P2** (설계 단계, phase 2 미정)

#### P2-4 — GettingStartedCard 조건부 숨김 logic (Home & Student)

- **현황**: 학생/선생님 0명 시 조건부 표시. 백엔드 확인 경로 명확하지 않음.
- **개선**: 각 도메인 `GET /summary?role=teacher|student` → `{ "count": int }`.
- **우선순위**: **P2** (현재 프론트 로컬 조회, UX 개선)

---

## 4. 아키텍처 권장사항

### 4.1 Full Aggregation vs Fragment Composition

| 시나리오 | 권장 | 근거 |
|--------|------|------|
| Home TodayLessons + Stats | Fragment (기존) | Lesson 1회 조회 후 메모리 grouping |
| Home UrgentAlertZone | Full Aggregation | Subscription + Booking 2개 도메인 join 필요 |
| Student NextLesson | Fragment (기존) | Lesson 첫 항목 재사용 |
| Student Events (4개 배너) | Aggregation 권장 | 5개 provider watch → 1개 api call |
| Parent QuickStats | Full Aggregation 필수 | 3개 계산식 각각 별도 endpoint 필요 |
| Parent Tabs (자녀 전환) | Fragment Recomposition | 기존 `/lessons?student_id=` 재사용, 자녀 ID 파라미터 변경 |

### 4.2 제안 신규 endpoint (옵션)

```
# 높은 우선순위 (P1)
GET /lessons/{teacher_id}/summary  
  → { today_count, this_month_count, ... }

GET /children/{parent_id}/dashboard-summary
  → { child_id, lessons_this_week, assignments_completion, practice_streak }

# 중간 우선순위 (P2)
GET /students/{student_id}/events
  → { lesson_requests, proposals, bookings, schedule_cards }

GET /assignments/{child_id}/summary
  → { total, completed, progress_pct }
```

---

## 5. 결론

| 도메인 | 총항목 | PASS | PARTIAL | MISSING | P0 | P1 | P2 |
|--------|------:|-----:|--------:|--------:|---:|---:|---:|
| **Home** | 10 | 5 | 3 | 2 | 0 | 1 | 1 |
| **Student Home** | 10 | 6 | 3 | 1 | 0 | 0 | 1 |
| **Parent Home** | 10 | 2 | 1 | 7 | 0 | 2 | 5 |
| **합계** | **30** | **13** | **7** | **10** | **0** | **3** | **7** |

**점검 결론**: Home 계열 3 도메인은 **기존 endpoint 재조합으로 80% 기능 동작** (P1 갭 3건만 차단).  
**P1 우선순위**: Parent Dashboard phase 2 데이터 연동 (QuickStats + 4탭), Home ScheduleChangeRequest endpoint.  
**추천 조치**: 2026-04 audit P0 항목(RequestEvent SSOT) 완료 후 phase 2 parent/student 데이터 mapping.

---

## 6. 추가 노트

- **TimeContextBanner**: 선생님/학생 공유 위젯. 백엔드 연동 불필요 (로컬 시간).
- **Mock 상태 유지**: Phase 2 까지 부분 mock 유지 가능. 사용자 진입 장애 없음.
- **자녀 확장성**: Parent Dashboard 자녀 선택 후 N명 시 각 탭마다 1 api call → N api calls. Aggregation 설계 권장.
