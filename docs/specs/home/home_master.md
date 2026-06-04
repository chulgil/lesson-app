# 선생님 홈 마스터 스펙

> 마지막 업데이트: 2026-06-01 (E2E 감사 #3 E2-C1 보강)
> 구현 상태: ✅ 구현 완료 (UX 개선 진행 중)
> 관련 코드: `features/home/`
> 관련 이슈: #424

> **신규 카드 (2026-06-01)**: 상단 영역에 "입금 대기 N건" 카드 추가 — `paymentRequested` / `paymentNotified` 상태 집계. 1탭 진입 시 학생별 D+N 표시 + 1탭 재발송. 상세: [../subscription/payment_tracking_dashboard.md](../subscription/payment_tracking_dashboard.md)

---

## 1. 개요

선생님 메인 대시보드. 긴급 알림, 오늘 레슨, 대응 필요 이벤트, 과제 현황을 3초 안에 파악 가능하도록 설계.
탭 기반 네비게이션(홈/스케줄/수강관리/프로필)의 진입점.

**핵심 설계 원칙**: 정보 밀도 최소화 + Progressive Disclosure + 시간 한정 정보 우선.

---

## 2. 화면 구조 (DashboardTab)

### 2.1 섹션 순서 (상단 → 하단)

| 순서 | 섹션 | 우선순위 | 조건부 표시 |
|:---:|------|:---:|:---:|
| 1 | Header (Lessonaza + 알림 벨) | - | 항상 |
| 2 | ProgrammeTitle (오늘의 레슨 + 날짜) | - | 항상 |
| 3 | DemoDashboardOverlay | 데모 | 데모 모드 활성 시만 |
| 4 | SyncFailureBanner | **긴급** | 동기화 실패 시만 |
| 5 | PendingRequestsSection | 대응 필요 | 대기 요청 있을 때 |
| 6 | TimeContextBanner (시간대 인사) | **시간 한정** | 항상 (시간 기반 메시지 분기) |
| 7 | TodayLessons (오늘 레슨 리스트) | **시간 한정** | 항상 (빈 상태 포함) |
| 8 | PaymentPendingCard | **긴급** | 입금 대기 1+건 있을 때 (#424) |
| 9 | InvitePendingCard | **대응** | 초대 대기 1+건 있을 때 (#5 D-G3) |
| 10 | QuestBoardCard | 안내 | 온보딩 Phase B-C 진행 중일 때 (#422, #482) |
| 11 | StatsRow (오늘/이번달) | 요약 | 항상 |
| 12 | UrgentAlertZone (긴급 알림) | **긴급** | 긴급 1+건 있을 때 |
| 13 | LessonRequestSection (레슨 요청) | 대응 필요 | 요청 1+건 있을 때 |
| 14 | ScheduleChangeRequestSection (스케줄 변경) | 대응 필요 | 변경 1+건 있을 때 |
| 15 | AssignmentSummarySection (과제) | 참고 | 과제 1+건 있을 때 |
| 16 | Analytics Link | 참고 | 항상 |

> **수강권 섹션 제거** (2026-04): 수강권 관리는 "수강관리" 탭에서 수행. 홈은 오늘·이벤트 중심.
> **레이아웃 재배치** (2026-05-07): 오늘 레슨 리스트를 다음 레슨 배너 바로 아래로 이동. 입금대기 등 긴급 알림은 통계(오늘/이번달) 아래로 이동.
> **신규 카드 추가** (2026-06-04 코드→스펙 정합): PaymentPendingCard / InvitePendingCard / QuestBoardCard 가 TodayLessons 와 StatsRow 사이에 wiring 됨. GettingStartedCard 는 코드에서 사용되지 않음 — 신규 사용자 안내는 QuestBoardCard 가 담당.

---

## 3. UX 정책

### 3.1 긴급 알림 정책 (Top 1 + Expandable)

**원칙**: "가장 시급한 1건"을 배너로 표시. 나머지는 펼침(Expandable) 버튼으로 접근.

#### 긴급 알림 우선순위

| 순위 | 알림 | 색상 | 기준 |
|:---:|------|:----:|------|
| 1 | 입금대기(후불) | error (red) | 입금 기한 초과 |
| 2 | 수강권 만료 | error | 만료됨 (expired) |
| 3 | 수강권 갱신 예정 | warning | 7일 이내 만료 |
| 4 | 레슨 확인 필요 | warning | 완료 후 미확인 |
| 5 | 대기 중 예약 | info | 승인 대기 |

#### 표시 규칙

- **1건**: 단일 카드로 표시
- **2건 이상**: 최상위 1건만 표시 + "외 N건 ▼" 버튼
- 펼침 버튼 탭 → 나머지 알림 슬라이드 다운
- 각 알림 탭 → 해당 상세 화면 이동

#### 참고 벤치마크

> 토스 홈 긴급 알림 패턴 — "Top 1 + 알림함"을 차용.

---

### 3.2 오늘 레슨 Progressive Disclosure

**원칙**: 기본 5개 노출. 초과 시 "전체보기" 버튼으로 확장.

| 오늘 레슨 수 | 표시 방식 |
|:---:|------|
| 0건 | "레슨 추가" CTA (빈 상태) |
| 1~5건 | 전체 표시 |
| 6건 이상 | 최대 5건 + "전체보기 (N건 더)" |

- "전체보기" 탭 → 오늘 레슨 전체 화면으로 이동
- 카드당 정보: 시간, 학생명, 악기, [노트 →] 버튼

#### 참고 벤치마크

> 네이버 예약 "다가오는 예약" — 상단 5건 + "전체보기" 패턴.

---

### 3.3 이벤트 섹션 (레슨 요청 + 스케줄 변경)

각 섹션 최대 3건 표시. 4건 이상 시 "더보기" 버튼.

- 레슨 요청: 신규 체험/재등록 요청
- 스케줄 변경 요청: 수강권 기반 변경 요청

> 향후 Phase 2: 두 섹션 통합 검토 ("대응 필요" 단일 섹션).

---

### 3.4 StatsRow

**표시 항목**: 오늘 N건 · 이번달 N건

- 오늘 탭 → 오늘 레슨 전체
- 이번달 탭 → Analytics

> 향후 "과제 완료율" 추가 검토 (백엔드 연동 후).

---

### 3.5 시간대 인식 컨텍스트 배너 (2026-04-16)

**원칙**: 사용자의 일일 루틴(아침/낮/저녁)에 맞춰 홈 상단에 다른 메시지 표시.

> 선생님/학생 모두 동일 위젯(TimeContextBanner) 사용. viewerRole 파라미터로 메시지 분기.

**위치**: Header 바로 아래, StatsRow 위 (0번째 위치)

**표시 규칙**:

| 시간대 | 메시지 | 데이터 |
|:------:|--------|--------|
| 06~10시 (아침) | "좋은 아침이에요. 오늘 N건의 레슨이 있어요" | todayLessons 수 |
| 10~14시 (낮) | "다음 레슨: HH:MM 학생명 (X분 후)" | 다음 미완료 레슨 |
| 14~18시 (오후) | 동일 (다음 레슨 카운트다운) | 다음 미완료 레슨 |
| 18~22시 (저녁) | "오늘 N건 완료. 노트 미작성 N건" 또는 "오늘 수고하셨어요" | 완료 레슨 + 노트 상태 |
| 22~06시 (밤) | "내일 N건의 레슨이 예정되어 있어요" | 내일 레슨 수 |

**조건부 숨김**:
- 레슨 0건 + 미작성 노트 0건 → 배너 숨김 (정보 없음)
- 신규 사용자 (학생 0명) → GettingStartedCard만 표시, 배너 숨김

**구현**: `TimeContextBanner` 위젯 — 시간 기반 자동 메시지 생성

#### 학생 버전 메시지

| 시간대 | 메시지 | 데이터 |
|:------:|--------|--------|
| 06~10시 (아침) | "좋은 아침이에요. 오늘 N건의 레슨이 있어요" 또는 "오늘 연습해볼까요?" | todayLessons + streak |
| 10~14시 (낮) | "다음 레슨: HH:MM (X분 후)" | 다음 예정 레슨 |
| 14~18시 (오후) | 동일 | 다음 예정 레슨 |
| 18~22시 (저녁) | "오늘 N일째 연속 연습 중이에요!" 또는 "오늘 연습 어땠나요?" | streak 또는 연습 격려 |
| 22~06시 (밤) | "수고하셨어요. 내일도 파이팅!" | - |

#### 참고 벤치마크

> 토스 홈 — 시간대별 인사말 + 컨텍스트 카드 패턴.

---

## 4. 코드 위치

| 레이어 | 파일 |
|--------|------|
| Provider | `features/home/presentation/providers/assignment_summary_provider.dart` |
| 화면 | `features/home/presentation/screens/home_screen.dart`, `assignment_dashboard_screen.dart` |
| 위젯 | `features/home/presentation/widgets/` (dashboard_tab, urgent_alert_zone, lesson_card, lesson_request_section, schedule_change_request_section, assignment_summary_section) |

---

## 5. 구현 현황

| 기능 | 상태 | 비고 |
|------|:----:|------|
| 기본 섹션 구조 | 완료 | 2026-04 배치 순서 재정렬 |
| 긴급 알림 Top 1 + Expandable | 진행 중 | 2026-04-16 업데이트 |
| 오늘 레슨 Progressive Disclosure | 진행 중 | 2026-04-16 업데이트 |
| 과제 대시보드 (#101) | 완료 | 전체 학생 주간 현황 |
| 시간대 인식 홈 (10x Vision) | ✅ 구현 완료 (2026-06-04 정정) | `TimeContextBanner` 시간 기반 메시지 분기 — `dashboard_tab.dart` §6 위치 |
| 이벤트 섹션 통합 | 미착수 | 향후 Phase |

---

## 6. 관련 마스터 스펙

- 레슨 카드: [lesson_master.md](../lesson/lesson_master.md)
- 수강관리 (탭): [user_master.md §4.3](../user/user_master.md)
- 디자인: [notebook/README.md](../design/notebook/README.md)
- UX 원칙: [ux_guidelines.md](../design/ux_guidelines.md)

---

## 7. 변경 이력

| 날짜 | 변경 |
|------|------|
| 2026-06-04 | 코드→스펙 드리프트 반영: §2.1 섹션 순서를 코드 실측에 맞춰 11 → 16 행으로 갱신 (PaymentPendingCard/InvitePendingCard/QuestBoardCard/SyncFailureBanner/PendingRequestsSection 추가). §5 TimeContextBanner "미착수" → "구현 완료" 정정. GettingStartedCard 코드 미사용 명시 — 신규 사용자 안내는 QuestBoardCard 가 담당 |
| 2026-05-07 | 스케줄 변경 요청 리스트 아이템을 레슨 요청과 동일 형식으로 통일 — Line1: 이름·악기·레벨, Line2: 소속·타입·이벤트 |
| 2026-05-07 | 섹션 순서 재배치 — 오늘 레슨 리스트를 다음 레슨 바로 아래로 이동, 입금대기(긴급 알림)를 통계 아래로 이동 |
| 2026-04-16 | UX 개선 스펙 추가 — 긴급 알림 Top 1 정책, 오늘 레슨 Progressive Disclosure, 섹션 순서 확정, 수강권 섹션 제거 명시 |
| 2026-03-12 | 초기 스펙 작성 |
