# Practice Streak — Single Source of Truth (SSOT) 정합 스펙

> 작성: 2026-06-29 (G3 streak 3중 소스 정합). 결정권자 승인: 범위 = FE+BE 정합(Phase 1+2),
> 정의 = 달력일 엄격(주말도 끊김) + KST 경계, 권위 소스 = BE 재계산(self-healing).
> 근거(발산 실측 지도): 워크플로 `streak-source-map` (6+ 독립 소스 / 7+ 표시 화면).

## 0. 문제 (왜 이 작업을 하는가)

스트릭("연속 연습 일수")이 **6개 이상 독립 계산**으로 흩어져 한 학생에게 **동시에 서로 다른 숫자**를 보인다.

- 인라인 계산 2벌(손복사): `practice_summary_section`, `student_dashboard_tab`
- `practiceStreakProvider`(엔티티) — mock 은 0 반환, remote 는 BE counter
- `PracticeStatsReport`(별도 repo, /practice/stats) — mock 하드코딩(student_1→5/12)
- analytics `practiceStreakDays` — mock 하드코딩 12, remote 는 로그 재계산
- `GrowthHeatmap.streakDays` — 별도 Hive, **UTC 일경계**
- 뱃지 `badge_point_bridge` — 포인트내역 설명 정규식 `(\d+)일`
- `effectiveStreakProvider`(freeze 적용, 의도된 SSOT) — ~~표시 소비처 0 = dead~~ → Phase 3(#1214)에서 표시 SSOT 로 배선 완료. §7 참조

BE 도 3중: ① `practice_streaks` counter(비자가치유) ② AnalyticsService 로그 재계산 ③ `/students/{id}/stats` 하드코딩 0.

**실제 버그**: 동일 학생 → 성장탭 12 / 통계카드 5 / 학부모 0 / 학생홈 로그계산값. 한 화면 두 store(remote 로그 vs local Hive UTC). UTC/local off-by-one.

## 1. 정규 스트릭 사양 (이 값이 단일 진실)

| 항목 | 규칙 |
|---|---|
| 일 단위 | **KST(UTC+9) 달력일**. BE 의 naive `date.today()` 금지 → KST 기준 날짜 |
| 연습일 정의 | 해당 KST 날짜에 `PracticeLog.total_minutes > 0` 가 1건 이상. (task-completed-only 는 카운트 제외 — 아웃라이어 제거) |
| current_streak | 최근 연습일에서 **연속 달력일** 역방향 카운트, 첫 공백에서 정지. 오늘(KST) 미연습이어도 어제 연습했으면 유지(grace); 어제도 공백이면 0 |
| 엄격성 | **주말 브리지 없음**. 평일/주말 무관, 하루라도 빠지면 끊김 |
| longest_streak | 전체 이력에서 최대 연속 run 길이 |
| last_practice_date | 가장 최근 연습일(KST date) |
| total_practice_days | distinct 연습일 수 |
| freeze(동결) | **Phase 3 적용됨(#1214)** — 위 current_streak 을 계산한 뒤, 차감된 결석일이 공백을 **이어준다**. 상세 §7 |

### 알고리즘 (의사코드)

```
days = { kst_date(log.date_or_created) : True for log in logs if log.total_minutes > 0 }  # set of practiced KST dates
today = now_kst().date()
if not days: return (current=0, longest=0, last=None, total=0)
last = max(days)
# current: 오늘 또는 어제까지 이어졌는가
if last < today - 1day: current = 0
else:
    current = 0; d = last
    while d in days: current += 1; d -= 1day
# longest: 전체 최대 run
sorted_days = sorted(days); longest = run = 1
for i in 1..len: run = (sorted_days[i]-sorted_days[i-1]==1day) ? run+1 : 1; longest = max(longest, run)
total = len(days); last_date = last
```

## 2. 권위 소스 (Authoritative)

**BE 단일 함수** `compute_streak(student_id) -> StreakSummary{current, longest, last_date, total_days}`
가 `practice_logs` 에서 **매 읽기 재계산**(self-healing). 아래 4개 출력 전부 이 함수 사용:

| 출력 | 현재 | 목표 |
|---|---|---|
| `GET /practice/streak` | counter 테이블 읽기(stale 가능) | `compute_streak` |
| `GET /practice/stats` (current/longest_streak) | counter 읽기 | `compute_streak` |
| `GET /analytics/students/{id}/progress` (`practice_streak_days`) | 자체 로그 재계산(window 제한) | `compute_streak`(window 무관 전체) |
| `GET /students/{id}/stats` (`practice_streak`) | **하드코딩 0** | `compute_streak` |

- `practice_streaks` counter 테이블: **읽기 권위 박탈**. 쓰기는 당분간 유지 가능하나 어떤 읽기도 의존 금지. (PR-D 에서 제거 검토)
- 시간대: 단일 KST 헬퍼(예: `app/core/time` 또는 기존 util) 사용. naive `date.today()` 호출부 전부 교체.

## 3. FE 정합

- **단일 provider** `currentStreakProvider`(기존 `practiceStreakProvider` 재활용) 만 스트릭 진실. FE 는 **계산하지 않음**, BE 값 표시만.
- mock 패리티: mock 도 §1 알고리즘 1벌로 로그에서 계산. 하드코딩 상수(stats mock 5/12, analytics mock 12) 제거.
- 7개 표시 화면 전부 SSOT 위임. 삭제 대상: 인라인 계산 2벌, heatmap-스트릭(표시용), 뱃지 정규식.

## 4. 구현 DAG (PR 단위)

- **PR-A (BE foundation)** — `compute_streak` 신설(엄격 달력+KST), 4개 엔드포인트 배선, `/students/{id}/stats` 스텁 제거. pytest(KST 경계·공백 리셋·longest·empty·minutes 게이트). **beta 배포**. prod 는 별도 윈도우(숫자 변동 가시).
- **PR-B (FE mock+provider)** — mock 단일 알고리즘, `currentStreakProvider` SSOT, 하드코딩 mock 제거. 단위 테스트.
- **PR-C (FE consumers)** — 7 화면 SSOT 위임, 인라인/heatmap/정규식 제거. 위젯 회귀 "동일 학생=동일 숫자".
- **PR-D (cleanup)** — counter 테이블 비활성/제거. ~~freeze(Phase 3)는 분리 보류.~~ → Phase 3 완료(#1214), §7 참조.

## 5. 검증

- BE: pytest red-green. 케이스 — (a) 오늘 연습 N일 연속 → current=N (b) 어제까지 N, 오늘 미연습 → current=N(grace) (c) 그제까지만 → current=0 (d) 주말 공백 포함 → 끊김(브리지 없음) (e) longest > current (f) 0분 로그만 → 0 (g) KST 자정 경계(UTC 23:30 = KST 익일 08:30) off-by-one 고정.
- FE: "동일 학생 → 전 화면 동일 스트릭" 위젯 테스트 먼저 FAIL 확인 후 GREEN.
- prod 영향: 재계산이 기존 counter 와 다를 수 있음 → 배포 윈도우·백업·plan-first.

## 6. 리스크

- prod 숫자 변동(재계산 vs stale counter) — 사용자 가시. prod 배포는 승인·윈도우 필수.
- KST off-by-one — BE naive date.today() 전수 교체가 핵심.
- offline(SyncAware getStreak online-only) — Phase 1 범위 밖, 현행 유지.
- mock-BE 알고리즘 패리티 — 테스트로 의도 고정(에이전트 self-test Oracle 주의: 소비자 계약으로 검증).

## 7. Phase 3 — freeze(동결) 표시 적용 (#1214, 2026-07-28)

§1 의 정규 스트릭은 공백 하루에 0 으로 끊긴다(guilt-based). Phase 3 은 그 위에
**동결(freeze)** 을 얹어 표시값을 보정한다. 근거 시맨틱 = `.harness/spec/2026-06-11-student-gamification.md` §14.1/§14.2/§14.3.

### 7.1 표시 SSOT 이동

**표시 스트릭의 SSOT 는 `effectiveStreakProvider` 다.** 학생 화면은 `practiceStreakProvider`
(정규값)를 직접 표시하지 않는다. 배선된 표시 지점:

`PracticeStartCard`(홈 카드) · `PracticeSummarySection`(연습 요약) · 학생 홈 시간대 배너 ·
`PracticeCelebrationOverlay`(연습 직후). 같은 화면에 서로 다른 숫자가 뜨지 않게 **일괄** 이동.

### 7.2 규칙

| 항목 | 규칙 |
|---|---|
| 발급 | 일요일 00:00 KST 기준 주 1회 +2, 최대 보유 4 (§14.1). `lastGrantedAt` 게이트로 멱등 |
| 차감 | 결석일 1일당 freeze 1개 (§14.2). 오늘은 아직 끝나지 않았으므로 결석 판정 제외 |
| 커버 판정 | **미차감 결석일 수 <= 잔여 balance** 일 때만 유지. 초과하면 끊김 + 차감 안 함(낭비 방지) |
| 표시값 | 마지막 연습일에서 역방향 카운트. 차감된 결석일은 체인을 **잇되 일수에 더하지 않는다** ("유지" ≠ "증가") |
| 시험 모드 | 활성 중 차감 0 + 스트릭 동결 (§14.3) |
| 멱등 | 같은 날짜 재차감 금지 (`usedAt` 가드) — 화면 재빌드가 잔량을 갉아먹지 않는다 |

### 7.3 BE 와의 관계

freeze 는 **표시 계층 보정**이다. §1~§2 의 BE `compute_streak` 는 변경 없이 정규값을 계속
반환하며, freeze 상태는 현재 **기기 로컬(Hive)** 이다 → 기기 변경 시 소멸. 서버 영속은
범위 밖(후속). 따라서 BE 가 돌려주는 숫자와 앱 표시값이 다를 수 있고, **표시값이 우선**이다.
