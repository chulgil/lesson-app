# Student Journey 전수 감사 (2026-06-09)

> 범위: 학생 가입 → 수강권 발급 → 스케줄 조정 (4 채널 × 3 단계)
> 방법: 4 병렬 sub-agent (Explore, read-only) → 통합
> 시선: 20년차 UX/기획 전문가
> 작업 디렉토리: `/private/tmp/lesson-app-worktrees/student-journey-audit` (branch `audit/student-journey-2026-06-09`)
> 직전 PR: #619 "학생 가입→스케줄 조절 FE contract 정합 (5건)" — BE contract 5건 surgical fix 완료 (BookingResponse enrich, refresh_token non-null, duration_minutes alias, scheduled_date NOT NULL, change_requested 마킹). **본 감사는 FE/UX 갭에 집중.**

---

## 0. 결론 한 줄

> **학생이 가입은 했지만 "다음에 뭘 할지 모르는" 화면이 4채널 모두에 존재.** 코드/스펙 정합성은 비교적 양호하나, "발급 후 단계 단절"과 "상태 가시성 부족"이 채널 공통 이탈 패턴.

---

## 1. 채널 × 단계 매트릭스

| 채널 | 단계1 가입 | 단계2 수강권 발급 | 단계3 스케줄 조정 |
|---|---|---|---|
| **C1**. 자체 소셜로그인 → 학생 | 🔴 **P0 차단** (PASS 본인인증 미완) | ⚠️ 선생님 검색 라우트 미와이어드 | — (P0 차단으로 도달 불가) |
| **C2**. 학생 초대코드 | ✅ 양호 | ⚠️ 입금 대기 상태 가시성 부족 | 🔴 **P1 단절** (발급 후 첫 레슨 CTA 없음) |
| **C3**. 학원 초대 (G1-G10) | 🔴 **P0** (G1 발행 화면 전무) | ⚠️ G7 수강권 발급 후 /home 직진 | — (G7 단절로 G8 도달 모호) |
| **C4**. 학부모 → 14세 미만 자녀 | ⚠️ 빈 홈에서 자녀 등록 유도 약함 | 🔴 **스펙 drift** (입금 대상/열람 권한 UI 누락) | ✅ 프로필 전환 양호 |

🔴 = 흐름 차단/명백한 P0~P1 시급 / ⚠️ = 진행은 되지만 이탈 위험 / ✅ = 양호

---

## 2. 채널 공통 패턴 (3대 이탈 원인)

### 패턴 A — "발급 후 단계 단절" (Cross-channel)
- C1: 학생 직접 가입은 차단, 차단 화면에서 "초대코드 입력" 외에 다음 액션 모호
- C2: `ProposalDetailScreen` → 수강권 발급 → 그 후 첫 레슨 일정 잡기 CTA 없음
- C3: `AcademyInviteAcceptScreen._handleAccept()` → `context.go(home)` 직진. 학원 수강권 보여주는 화면 없음
- C4: 학부모 자녀 등록 후 → 수강권 받아도 → "자녀 첫 레슨 일정 합의" 안내 부재
- **공통 결론**: 발급 직후 "다음으로 갈 곳"이 라우트로 정의되어 있지 않거나 라우트만 있고 화면이 없음

### 패턴 B — "상태 가시성 부족" (학생/학부모 측)
- C2: 입금 완료 → 선생님 확인 대기 구간 상태 표시 없음 (`paymentConfirmed=false && paidAt!=null`)
- C2: 학부모 대시보드 수강권 카드가 여전히 Mock 데이터
- C4: 학부모가 입금 확인 액션을 어디서 하는지 UI 없음
- C4 (스펙 drift): "입금 대상이 학부모인지 학생인지" 설정 UI가 스펙엔 있는데 코드엔 없음
- C4 (스펙 drift): 학부모 열람 권한 설정 UI 미구현 (`ParentVisibilitySettings` 엔티티만 존재)

### 패턴 C — "에지 케이스 처리 약함"
- C2: 만료된 초대코드 = "올바르지 않은 초대 코드" (만료 vs 회수 vs 오타 미구분)
- C3: G9 에러 분류가 `error.toString().contains()` 문자열 매칭 (BE 메시지 바뀌면 깨짐)
- C3: G9 거절 사유 `reason` 파라미터는 받는데 mock/remote 둘 다 저장 안 함
- C3: 학생이 이미 개인 선생님 소속인데 학원 초대 수락 시 충돌 가드 없음

---

## 3. 발견 사항 전체 목록 (28건)

> ID 규칙: `채널-Fnn` / 우선순위 P0(차단) > P1(이탈 위험) > P2(다듬기)
> 위치는 sub-agent 보고 그대로 보존. 필요 시 fix 단계에서 line 재검증.

### 3.1 P0 — 흐름 차단 (3건)

| ID | 카테고리 | 발견 | 위치 |
|---|---|---|---|
| **C1-F01** | 가입 차단 | 학생 직접 가입이 PASS 본인인증 미완성으로 차단됨. 사용자 입장에서 "학생" 선택지가 사실상 죽음 (Hick's Law 위반) | `frontend/lib/features/auth/presentation/screens/student_signup_blocked_screen.dart` |
| **C3-F01** | G1 미구현 | 학원 대표/매니저가 초대 발행하는 화면이 전무. academy 도메인에 BulkClosureDetailScreen, AcademyActivityTimelineScreen 2개 화면만 존재. 전체 C3 루프가 막힘 | `frontend/lib/features/academy/presentation/screens/` |
| **C2-F02** | 발급 후 단절 | 수강권 발급 후 "첫 레슨 일정 잡기" CTA 없음. 학생이 수강권 받고 무엇을 해야 할지 모름. `student_direct_booking_spec.md §8` "수강권 발급 완료" 진입점 미구현 | `frontend/lib/features/subscription/presentation/screens/proposal_detail_screen.dart` |

### 3.2 P1 — 이탈 유발 (12건)

| ID | 카테고리 | 발견 | 위치 |
|---|---|---|---|
| **C1-F02** | 미와이어드 진입점 | `selectTeacher` 라우트 — Getting Started 카드의 "선생님과 연결하기" 탭 시 화면 구현 미확인 | `student_dashboard_tab.dart:94`, `student_getting_started_card.dart:94` |
| **C1-F03** | 빈 상태 가이드 | Getting Started 카드가 완료 시 자동 숨김(`SizedBox.shrink()`). 이후 빈 홈에서 다음 액션 가이드 없음. `home_master.md §2.1`은 QuestBoardCard가 담당이라 했으나 QuestBoard는 온보딩 Phase B-C 진행 시만 표시 | `student_getting_started_card.dart:44-45` |
| **C1-F09** | 권한 검증 | 학생 역할 진입 후 `authState is AuthAuthenticated` 조건에 `role == student` 체크 없음. 역할 전환 후 라우팅 의존성에 race 가능성 | `features/auth/` route guard |
| **C2-F01** | 상태 가시성 | 입금 확인 전 구간(`paymentConfirmed=false && paidAt!=null`)에서 학생에게 "선생님이 아직 확인 안 함" 상태 피드백 없음. proposal_detail_screen에서 제안 상태 표시만 있고 입금 중간 상태 별도 UI 없음 | `features/subscription/presentation/screens/proposal_detail_screen.dart:99-100` |
| **C2-F03** | 학부모 동기 | 자녀의 선생님이 수강권 제안했을 때 학부모 화면에서 그 제안/입금 상태가 표시되지 않음. 학부모 대시보드 "수강권 입금 상태 카드" Mock 상태 | `features/parent_home/.../parent_dashboard_tab.dart`, `user_master.md §5.2:1198` |
| **C3-F02** | G9 정합성 | (참고) 만료/거절 화면 wiring 완료 + smoke test 통과. 라우트 `/academy/expired` 등록됨 ✅ 이 항목은 **이미 닫힌 상태 확인용**으로만 기록 | `academy_invite_expired_screen.dart`, `academy_invite_accept_screen_test.dart:105-163` |
| **C3-F03** | 에러 분류 | G9 에러 분류가 `error.toString().contains()` 문자열 매칭. BE 메시지 변경 시 깨질 위험 | `AcademyInviteAcceptScreen._errorCodeFor():117-123` |
| **C3-F04** | 거절 사유 | `rejectInvite(token, {reason?})` 시그니처는 reason 받는데 mock/remote 모두 저장 안 함 (단순 log) | `RemoteAcademyInviteRepository:60`, mock:67 |
| **C3-F05** | 3자 관계 충돌 | 학생이 이미 개인 선생님 소속인데 학원 초대 수락 시 충돌 처리/안내 없음. 단순 `acceptInvite()` 호출만 | `AcademyInviteAcceptScreen:46-50` |
| **C3-F08** | 발급 후 단절 | G7 학원 수강권 발급 후 화면 전환이 `context.go(home)` 직진. 학원 수강권을 보여주는 화면 없음 | `AcademyInviteAcceptScreen._handleAccept():55` |
| **C4-F03** | 빈 홈 유도 | 학부모가 "코드 없어도 괜찮아요" 클릭 시 빈 홈만 표시. 자녀 추가 진입점이 프로필 탭 → 자녀 관리 메뉴에 숨겨짐 (발견성 낮음). `ChildProfileFormScreen` 존재함 | `child_profile_form_screen.dart:17` |
| **C4-F04** | 입금 액션 | 학부모 결제 화면에 "입금 확인 알림" 액션 버튼 코드 미발견. 열람만 가능 | `parent_payments_tab.dart:100-104` |

### 3.3 P1 — 스펙 Drift (3건)

| ID | 카테고리 | 발견 | 위치 |
|---|---|---|---|
| **C4-F07** | 스펙 ↔ 코드 | `user_master.md §5.2`에 "입금 안내 대상(학부모 vs 학생) 선생님이 설정" 명시. 코드/BE 모두 미구현 | spec `user_master.md §5.2`, code `parent_payments_tab.dart` |
| **C4-F08** | 스펙 ↔ 코드 | `parent_system.md §6.1`에 학부모 열람 권한 설정 명시(레슨/과제/연습기록/노트/녹음/피드백/채팅 7항목). `ParentVisibilitySettings` 엔티티는 정의되어 있고 provider 호출도 있으나 학부모 화면에 권한 확인 UI 없음 | spec `parent_system.md:643-666`, entity exists |
| **C2-F03 (drift측면)** | 스펙 ↔ 코드 | `user_master.md §5.2` ParentDashboardTab 구현 상태 = "Mock", subscription 입금 상태 = "❌ hardcoding" | `user_master.md §5.2:1183-1198` |

### 3.4 P2 — 마감 (10건, fix 대상에서 제외)

| ID | 카테고리 | 발견 |
|---|---|---|
| C1-F04 | 빈 상태 | 수강권 0개 상태에서 `StudentSubscriptionSummary` CTA 검증 미완 |
| C1-F05 | 빈 상태 | 선생님 없을 때 `NextLessonCard` 렌더 결과 미검증 |
| C1-F06 | 프로필 게이트 | 가입 직후 프로필 입력 강제 없음 (수동 입력만) |
| C1-F07 | 에러 fallback | 선생님 검색 실패 시 fallback 미정의 |
| C1-F08 | 중복 가입 | 로그아웃 → 재가입 시 기존 계정 처리 미확인 |
| C1-F10 | 초대 경로 | 학생 초대 경로가 "선생님 없는 상태" vs "이미 있는 상태" 미구분 |
| C2-F04 | 에러 메시지 | 만료/회수/오타 초대코드 일괄 "올바르지 않은 코드" |
| C2-F05 | 선생님 명시 | 다중 초대 시 ProposalDetail에 선생님명 헤더 강조 부족 |
| C2-F06 | 복구 경로 | 학생 14세 게이트 거절 후 복구 버튼 없음 |
| C2-F07 | 재제안 | 수강권 거절 후 학생이 재요청할 버튼 없음 (외부 문자만) |
| C2-F08 | 악기 하드코딩 | `InviteConfirmScreen` 라우팅 시 instrument='악기' 하드코딩 |
| C2-F09 | 중복 초대 | 학원+개인 동시 초대 시 관계 중복 가능성 (FE 단) |
| C2-F10 | 자동 알림 | 학부모 자녀 등록 후 선생님에게 자동 알림 없음 |
| C3-F06 | 역할 enum | 학원 역할 코드(R-AO/R-AT) enum화 안 됨 (문자열 매칭) |
| C3-F07 | G5-G6 미노출 | 수락 후 가용시간 설정/강사 배정 화면 없음 (web 콘솔 책임이라지만 경계 불명) |
| C3-F09 | 토큰 lifecycle | 토큰 유효기간 정책 문서화 부재 |
| C3-F10 | 재발송/회수 | 초대 재발송/회수 기능 전무 (spec `user_master §3.2` 2026-06-01에 명시) |
| C4-F05 | 프로필 전환 | (양호 확인용) ProfileSwitcher 잘 구현됨 ✅ |
| C4-F06 | 미연결 자녀 제약 | (양호 확인용) UnconnectedChildDashboard 스펙 준수 ✅ |
| C4-F09 | 14세 도달 전환 | 자녀 → 학생 계정 전환 플로우/화면 미구현 |

---

## 4. 권장 Fix 순서 (P0/P1 대상)

### 4.1 즉시 (P0, 3건)

| 순서 | 발견 ID | 작업 | 영향 |
|---|---|---|---|
| 1 | **C2-F02** | `ProposalDetailScreen`에 수강권 발급 후 "첫 레슨 일정 잡기" CTA 추가. `student_direct_booking_spec §8` "수강권 발급 완료" 진입점 wiring | C2 채널이 끝까지 흐름 완성 |
| 2 | **C1-F01** | "학생 직접 가입 차단" 화면에 명확한 우회 경로(=초대코드 입력) 강조 + "선생님께 코드 요청하기" 안내. 차단 자체는 정책이므로 유지하되 다음 액션을 명확히 | C1 가입자 이탈 ↓ |
| 3 | **C3-F01** | G1 학원 초대 발행 화면 — 학원 대표/매니저 권한 가드 + 초대 발행 UI + 토큰 생성 API 호출. 라우트 `/academy/:id/invites/new` 신설 | C3 채널 진입 자체 가능해짐 |

### 4.2 같은 PR 시리즈 (P1 — 패턴 A 묶음, 3건)

| 순서 | 발견 ID | 작업 |
|---|---|---|
| 4 | **C1-F02** | `selectTeacher` 라우트의 화면 존재 확인. 없으면 빈 학생홈 "선생님 검색하기" CTA 추가 |
| 5 | **C3-F08** | G7 수락 후 학원 수강권 확인 화면으로 라우팅 (직진 `/home` 대신) |
| 6 | **C4-F03** | 학부모 빈 홈에 "자녀 등록하기" 배너 + `ChildProfileFormScreen` 바로가기 |

### 4.3 같은 PR 시리즈 (P1 — 패턴 B 상태 가시성, 3건)

| 순서 | 발견 ID | 작업 |
|---|---|---|
| 7 | **C2-F01** | 입금 확인 대기 구간 상태 표시 위젯 추가 (paymentConfirmed=false && paidAt!=null) |
| 8 | **C2-F03** | 학부모 대시보드 수강권 카드 Mock → 실제 API 연결 |
| 9 | **C4-F04** | 학부모 측 "입금 확인 알림" 액션 추가 (BE 의존 — 가능 범위만) |

### 4.4 같은 PR 시리즈 (P1 — 패턴 C 에지케이스 + 권한, 4건)

| 순서 | 발견 ID | 작업 |
|---|---|---|
| 10 | **C3-F03** | G9 에러 분류 문자열 매칭 → 명시적 error code/enum 또는 BE response code 기반으로 |
| 11 | **C3-F04** | 거절 사유 `reason` 저장 — repository에 persistence 추가 |
| 12 | **C3-F05** | 학원 초대 수락 전 3자 관계 충돌 가드 + 사용자 안내 |
| 13 | **C1-F09** | 학생 역할 진입 시 `role == student` 가드 추가 |

### 4.5 별도 BE 이슈로 분리 (다음 턴)

스펙 drift 2건 — 코드 구현 못지않게 BE 모델·API가 함께 가야 함:
- **C4-F07** 입금 안내 대상 설정 UI + `ParentPaymentRequestView` BE 모델
- **C4-F08** 학부모 열람 권한 설정 화면 (FE 단독 가능 범위만 우선)

⇒ 이 두 건은 "BE 이슈 별도 처리"로 분리하고, 이번 PR 시리즈는 **FE만** 또는 BE 의존 없는 부분만.

---

## 5. 스펙 업데이트 매핑

| 발견 | 업데이트 스펙 | 섹션 |
|---|---|---|
| C2-F02 fix | `docs/specs/schedule/student_direct_booking_spec.md` | §8 진입점 |
| C2-F02 fix | `docs/specs/subscription/subscription_master.md` | §3.2.3 발급 직후 학생 다음 액션 |
| C3-F01 신설 | `docs/specs/academy/academy_master.md` | §4 라우트 + G1 화면 |
| C3-F03/F04 | `docs/specs/user/user_master.md` | §3.2 초대 시스템 — 거절/만료 토큰 |
| C3-F05 | `docs/specs/user/user_master.md` | §3.4 3자 관계 — 충돌 가드 |
| C4-F03 fix | `docs/specs/user/user_master.md` | §2.4 학부모 가입 — 빈 홈 유도 |
| C4-F07/F08 | `docs/specs/user/user_master.md` | §5.2~5.3 학부모 대시보드 / 데이터 접근 (BE 이슈 분리 후 별도) |

---

## 6. 다음 턴 — BE 이슈 분리 후보

| ID | 작업 |
|---|---|
| C2-F01 BE측 | 입금 대기 상태 BE 응답 필드 (paymentConfirmedAt vs paidAt 구분 노출) |
| C2-F03 BE측 | 학부모-자녀 수강권 조회 API (Mock 제거) |
| C3-F03 BE측 | 학원 초대 에러 응답에 명시적 `error_code` 필드 추가 |
| C3-F04 BE측 | reject 호출 시 `reason` 컬럼 추가 + 알림 |
| C3-F05 BE측 | 학원 초대 수락 전 충돌 검사 endpoint |
| C3-F09 BE측 | 학원 초대 토큰 lifecycle 정책 명시 (만료/회수/재발송) |
| C3-F10 BE측 | 초대 재발송/회수 API |
| C4-F04 BE측 | 학부모 입금 확인 액션 endpoint |
| C4-F07 BE측 | `ParentPaymentRequestView` 모델 + 입금 대상 설정 |
| C4-F08 BE측 | 학부모 열람 권한 CRUD endpoint |
| C4-F09 BE측 | 14세 도달 자녀 → 학생 계정 전환 endpoint |

---

## 7. Open Question (사용자 확인 필요)

1. **P0 3건 중 C3-F01 (G1 학원 초대 발행 화면)** — 학원 콘솔이 web으로 분리되어 있는데(`feature_hub §1.4`) "Phase 2 web 콘솔" 책임이라면 FE 모바일에서 신설할 작업이 아닐 수도. **확인 필요**.
2. **C1-F01 (학생 직접 가입 차단)** — PASS 본인인증 도입 일정이 잡혀 있다면 fix가 아니라 "차단 화면 UX 개선"으로 수렴. 본인인증 일정이 있는지?
3. **P0 3건 + P1 13건 = 16건**을 1 PR로 가는 건 너무 큼. **3 PR (P0 묶음 / P1 패턴 A+B / P1 패턴 C)** 정도로 분할 권장.
4. P2 13건은 이번 fix 대상 제외 — 별도 이슈로 백로그?

---

## 8. 산출물 위치

- 본 리포트: `docs/specs/_audits/2026-06-09-student-journey-audit.md` (현재 파일)
- worktree: `/private/tmp/lesson-app-worktrees/student-journey-audit/`
- branch: `audit/student-journey-2026-06-09`
- tmux 세션: `student-audit` (attach: `tmux attach -t student-audit`)
