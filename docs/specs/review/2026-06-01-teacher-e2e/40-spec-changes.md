# 스펙 보완 매핑 (40-spec-changes)

> 작성일: 2026-06-01
> 입력: 30-gap-catalog.md (Top 10)
> 목적: 각 항목을 **기존 스펙 어디** 또는 **신규 스펙 어디** 에 반영할지 매핑. 이 파일을 그대로 따라가면 다음 세션에서 스펙 작업 가능.

각 항목은 다음 4가지 메타데이터를 가짐.

- **변경 유형**: 신규 작성 / 기존 수정 / archive 이동
- **타깃 파일**: 절대 경로
- **변경 요지**: 무엇을 어떻게
- **글로서리 영향**: 신규 용어 (있다면 `.harness/knowledge/glossary.md` 갱신 필요)

---

## G1: 온보딩 정렬 (#1·#8·#10)

### #1 AB-C1 — 가용시간 온보딩 필수 퀘스트화

| 메타 | 값 |
|---|---|
| 변경 유형 | 기존 수정 |
| 타깃 파일 | `docs/specs/onboarding/teacher_onboarding_v3_spec.md` |
| 변경 섹션 | §3 Phase B, §4 (신규 — 간소 가용시간 UX) |
| 신규 파일 | `docs/specs/onboarding/teacher_first_availability_setup.md` (간소 UI 스펙) |
| 글로서리 영향 | "첫 가용시간 (Initial Availability)" 추가 |

**변경 요지:**

- §3 Phase B 퀘스트 보드 정의에서 "필수 퀘스트 1: 레슨 가능 시간 설정" 을 **블로커**로 명시 (다른 퀘스트 잠금)
- 가용시간 0개 상태에서 홈 진입 시 인터스티셜 모달 표시
- 신규 파일에 "간소 가용시간 UI" 정의: 요일 다중선택 + 시작/종료시각 1쌍 + 기본값 (50분 / 10분 쉬는 시간)

**연계 파일 수정:**
- `docs/specs/schedule/teacher_availability_spec.md` 에 "간소 진입" 경로 명시 (풀 설정은 기존 화면 유지)

---

### #8 AB-H3 — v1/v2/v3 SSOT 통합

| 메타 | 값 |
|---|---|
| 변경 유형 | archive 이동 + 인덱스 갱신 |
| 타깃 파일 | `docs/specs/onboarding/onboarding_master.md` → `docs/specs/_archive/onboarding_master_v1.md` |
|  | `docs/specs/onboarding/onboarding_quest_v2.md` → `docs/specs/_archive/onboarding_quest_v2.md` |
|  | `docs/specs/feature_hub.md` (10·10-b 라인 통합) |
| 신규 파일 | 없음 |
| 글로서리 영향 | 없음 |

**변경 요지:**

- `teacher_onboarding_v3_spec.md` 를 **공식 SSOT** 로 명시 (파일 헤더에 추가)
- v1·v2 중 가치 있는 내용 (퀘스트 보드 10단계 등)을 v3 에 머지 후 archive 이동
- `feature_hub.md` §1 마스터 인덱스에서 "10" 과 "10-b" 두 줄을 한 줄로 통합
- `canBeSearched` 60% 임계값을 v3 §4 (신규 — 프로필 완성도 게이지) 에 시각화 정의

---

### #10 A-C2 — 전화인증을 퀘스트로 이동

| 메타 | 값 |
|---|---|
| 변경 유형 | 기존 수정 + 신규 파일 |
| 타깃 파일 | `docs/specs/user/user_master.md` §2 |
|  | `docs/specs/onboarding/teacher_onboarding_v3_spec.md` §3 Phase C |
| 신규 파일 | `docs/specs/user/phone_verification_policy.md` (전화인증 시점·필수성 정책) |
| 글로서리 영향 | "인증 선생님 배지 (Verified Teacher Badge)" 추가 |

**변경 요지:**

- `user_master.md §2` 가입 흐름에서 전화인증을 SSO 직후 **분리**: SSO → 약관 → 이름·악기 → 홈
- v3 §3 Phase C (보상 퀘스트) 에 "전화번호 인증 → 인증 선생님 배지" 명시
- 신규 파일 `phone_verification_policy.md`:
  - 진입 시점: 가입 직후가 아닌 첫 수강권 발급 전 (E3 진입 직전)
  - 보상: 인증 배지 + 학부모 측 표시
  - 미인증 시 제약: 첫 수강권 발급 차단 (단, 가입~D 단계는 자유)

---

## G2: 입금 자동화 (#2·#3·#6)

### #2 E2-C2 — 카카오 알림톡 LNZ_INVOICE / LNZ_PAYMENT_CONFIRM

| 메타 | 값 |
|---|---|
| 변경 유형 | 기존 수정 |
| 타깃 파일 | `docs/specs/notification/kakao_alimtalk_spec.md` |
|  | `docs/specs/subscription/subscription_master.md` §3 (제안 송신 시 알림톡 트리거) §4 (입금 확인 시 알림톡) |
| 신규 파일 | `docs/specs/notification/alimtalk_templates.md` (템플릿 본문 + 변수 정의) |
| 글로서리 영향 | "알림톡 (AlimTalk)", "발신 프로필 (Sender Profile)" 추가 |

**변경 요지:**

- `kakao_alimtalk_spec.md` 에 LNZ_INVOICE, LNZ_PAYMENT_CONFIRM, LNZ_PAYMENT_REMINDER_D1/D3/D7 5종 템플릿 정의
- 발송 트리거 명시:
  - E1 송신 직후 → LNZ_INVOICE
  - D+1, D+3, D+7 → LNZ_PAYMENT_REMINDER_*
  - E3 입금 확인 시 → LNZ_PAYMENT_CONFIRM
- `subscription_master.md` §3·§4 에 "알림톡 자동 발송" 항목 추가
- 신규 파일 `alimtalk_templates.md`:
  - 각 템플릿의 본문 (90자 이내, 변수 위치)
  - 비용·실패 폴백 (앱 푸시)
  - 발신 가능 시간 (08:00-20:00) 정책

---

### #3 E2-C1 — 입금 미확인 대시보드 + 자동 리마인드

| 메타 | 값 |
|---|---|
| 변경 유형 | 기존 수정 + 신규 파일 |
| 타깃 파일 | `docs/specs/home/home_master.md` (선생님 홈 대시보드 — 입금 대기 카드 추가) |
|  | `docs/specs/subscription/subscription_master.md` §4 (입금 추적) |
|  | `docs/specs/notification/notification_master.md` (선생님 측 푸시 정의 추가) |
| 신규 파일 | `docs/specs/subscription/payment_tracking_dashboard.md` |
| 글로서리 영향 | "입금 대기 (Payment Pending)", "입금 추적 (Payment Tracking)" 추가 |

**변경 요지:**

- `home_master.md` 에 선생님 홈 상단 "입금 대기 N건" 카드 정의
- `subscription_master.md §4` 에 D+1/3/7 리마인드 정책 명시 (학생 + 선생님 양측)
- `notification_master.md` 에 선생님 측 푸시 3종 추가:
  - `payment.pending_d1`
  - `payment.pending_d3`
  - `payment.pending_d7_final`
- 신규 파일 `payment_tracking_dashboard.md`:
  - 카드 디자인 (Notebook × Score 시스템 준수)
  - 리스트 화면 UI (학생별 D+N 표시)
  - 1탭 재발송 액션 (알림톡 + 앱 푸시 동시)

---

### #6 E3-H2 — 입금 확인 Undo (24h 윈도우)

| 메타 | 값 |
|---|---|
| 변경 유형 | 기존 수정 |
| 타깃 파일 | `docs/specs/subscription/subscription_master.md` §4 (입금 확인 Undo 정책) |
| 신규 파일 | 없음 (subscription_master 안에 §4.X로 추가) |
| 글로서리 영향 | "입금 확인 되돌리기 (Confirm Payment Undo)" 추가 |

**변경 요지:**

- `subscription_master.md` §4 에 신규 §4.X "입금 확인 Undo" 섹션 추가:
  - 윈도우: 입금 확인 후 24시간
  - 추가 제약: 첫 레슨 차감 발생 시 Undo 불가
  - 자동 처리: 수강권 회수, RelationshipStatus 롤백, 자동 생성된 스케줄 취소
  - 학생 측 알림: 선택적 (선생님 결정)
- UI: 입금 확인 직후 SnackBar "확인 완료. 24시간 내 되돌릴 수 있습니다 [되돌리기]"

---

## G3: 휴가·일정 (#4·#7)

### #4 H-001 — 휴가/장기휴강 모드

| 메타 | 값 |
|---|---|
| 변경 유형 | 기존 수정 + 신규 파일 |
| 타깃 파일 | `docs/specs/schedule/teacher_availability_spec.md` (방학 모드 → 휴가 모드 통합) |
|  | `docs/specs/subscription/subscription_master.md` §X (수강권 자동 연장 정책) |
| 신규 파일 | `docs/specs/schedule/teacher_vacation_mode.md` |
| 글로서리 영향 | "휴가 모드 (Vacation Mode)", "수강권 자동 연장 (Auto-Extension)" 추가 |

**변경 요지:**

- `teacher_availability_spec.md` 의 "방학 모드" 미구현 섹션을 "휴가 모드" 로 이름 변경 + 강화
- 신규 파일 `teacher_vacation_mode.md`:
  - `TeacherAvailability.vacationPeriods: List<DateRange>` 엔티티 확장
  - 진입 UI: 기간 선택 → 영향 받는 레슨 N건 표시 → 일괄 처리 옵션
  - 처리 옵션: (a) 보강 자동 등록 (#7 MakeupCredit 연동) (b) 무료 처리 (c) 다음 회차 이월
  - 수강권 만료일 자동 연장 (휴가일 수만큼)
- `subscription_master.md` 에 "수강권 자동 연장" 정책 명시 (휴가 모드 트리거 시)
- 알림: 학생/학부모에게 알림톡 (#2 와 연계 — LNZ_TEACHER_VACATION 신규 템플릿)

---

### #7 H-002 — 일괄변경 후 회차 재계산 + Make-up bank

| 메타 | 값 |
|---|---|
| 변경 유형 | 기존 수정 + 신규 파일 |
| 타깃 파일 | `docs/specs/subscription/subscription_master.md` §2 (모델 확장) |
|  | `docs/specs/schedule/subscription_schedule_change_spec.md` (일괄변경 시 재계산) |
| 신규 파일 | `docs/specs/subscription/makeup_credit_spec.md` (보강 크레딧 별도 엔티티) |
| 글로서리 영향 | "스케줄된 회차 (Scheduled Lessons)", "보강 크레딧 (Makeup Credit)", "Make-up Bank" 추가 |

**변경 요지:**

- `subscription_master.md` 에 `Subscription` 모델 확장:
  - 기존: `remainingLessons`
  - 추가: `scheduledLessons` (실제 잡힌 레슨 수)
  - 추가: 5주차 보너스 정책 (`bonusCount`) 과 일괄변경 우선순위
- `subscription_schedule_change_spec.md` 에 일괄변경 시 재계산 로직 명시:
  - 기존 `scheduledLessons` 취소 → 새 시간으로 재생성
  - `remainingLessons` 조정 (취소된 회차는 복원, 새 회차는 차감 예약)
- 신규 파일 `makeup_credit_spec.md`:
  - `MakeupCredit` 엔티티 (학생별 보강 회차 적립)
  - 적립 트리거: 선생님 휴가 (#4), 학생 노쇼 면제, 일괄변경 중 손실 회차
  - 사용: 차시 예약 시 정규 차감 대신 크레딧 사용 가능
  - 만료: 30일 (기존 정책 준용)

---

## G4: 학생 연결 (#5)

### #5 D-G3 — 초대 재발송·만료·이중 상태 통합

| 메타 | 값 |
|---|---|
| 변경 유형 | 기존 수정 + 신규 파일 |
| 타깃 파일 | `docs/specs/user/user_master.md` §초대 시스템 (재발송·만료 흐름 추가) |
|  | `docs/specs/lesson/invite/` (디렉토리 내 invite_system 스펙) |
|  | `docs/specs/glossary.md` (RelationshipStatus vs ConnectionStatus 명시) |
| 신규 파일 | `docs/specs/user/invite_lifecycle_spec.md` |
| 글로서리 영향 | "초대 코드 (Invite Code)", "초대 대기 (Invite Pending)" 명시. ConnectionStatus deprecate 명시 |

**변경 요지:**

- 신규 파일 `invite_lifecycle_spec.md`:
  - 상태 전이: created → sent → opened → joined / expired / revoked
  - 만료 정책: 7일 (기존) + D+1·D+3 만료 임박 알림
  - 재발송 정책: 같은 코드 만료 갱신 vs 새 코드 생성 (UX 선택)
  - 학생 리스트에 "초대 대기" 그룹 정의
- `user_master.md` 초대 섹션 업데이트 (재발송·만료 추가)
- 이중 상태 통합:
  - `RelationshipStatus` 를 **공식 SSOT** 로 확정
  - `ConnectionStatus.inviteSent` 같은 상태는 `RelationshipStatus.invitePending` 으로 통합
  - glossary.md 에 매핑 명시 (FE-BE 일관성)

---

## G5: 가용시간 UX (#9)

### #9 C-G2 — 가용시간 redesign 실행

| 메타 | 값 |
|---|---|
| 변경 유형 | 기존 수정 |
| 타깃 파일 | `docs/specs/schedule/availability_settings_ux_redesign_spec.md` (실행 우선순위 끌어올림, 누락 부분 보강) |
|  | `docs/specs/schedule/teacher_availability_spec.md` (기본값 통일) |
|  | `docs/specs/schedule/schedule_master.md` §2 (기본값 통일) |
| 신규 파일 | 없음 |
| 글로서리 영향 | "레슨 1회 시간 (Lesson Duration)", "쉬는 시간 (Break Time)" 사용자 친숙 용어 추가 |

**변경 요지:**

- `availability_settings_ux_redesign_spec.md` 에 다음 보강:
  - 좌측 설정 + 우측 미리보기 split 레이아웃 (Calendly 패턴)
  - 첫 슬롯 등록까지 ≤ 3탭 목표
  - 사용자 친숙 용어 매핑 표 (내부 용어 ↔ 표시 용어)
- 기본값 통일 (3개 파일):
  - 레슨 1회 시간 (slotDurationMinutes): **50분**
  - 쉬는 시간 (breakTimeBetweenLessons): **10분**
  - 슬롯 시작 간격 (slotStartInterval): **60분** (레슨+쉬는시간 = effectiveSlotDuration)
- 한국 음악 레슨 표준 (50분 + 10분 = 1시간 1교시) 근거 명시

---

## 글로서리 신규 용어 (요약)

`.harness/knowledge/glossary.md` 와 `docs/specs/glossary.md` 양쪽에 추가.

| 용어 (한글 / 영문) | 정의 | 출처 항목 |
|---|---|---|
| 첫 가용시간 / Initial Availability | 온보딩 중 강제 설정하는 최소 가용시간 | #1 |
| 인증 선생님 배지 / Verified Teacher Badge | 전화인증 완료 시 부여 | #10 |
| 알림톡 / AlimTalk | 카카오톡 비즈 알림 메시지 | #2 |
| 발신 프로필 / Sender Profile | 카카오 알림톡 발신 식별자 | #2 |
| 입금 대기 / Payment Pending | 입금 확인 전 수강권 제안 상태 집계 | #3 |
| 입금 추적 / Payment Tracking | D+1/3/7 자동 리마인드 시스템 | #3 |
| 입금 확인 되돌리기 / Confirm Payment Undo | 24h 윈도우 내 입금 확인 취소 | #6 |
| 휴가 모드 / Vacation Mode | 기간 선택 + 영향 레슨 일괄 처리 | #4 |
| 수강권 자동 연장 / Auto-Extension | 휴가 일수만큼 만료일 자동 연장 | #4 |
| 스케줄된 회차 / Scheduled Lessons | 실제 잡힌 레슨 수 (remaining 과 별개) | #7 |
| 보강 크레딧 / Makeup Credit | 별도 엔티티로 적립된 보강 회차 | #7 |
| 초대 코드 / Invite Code | 학생 초대용 코드 (만료·재발송) | #5 |
| 초대 대기 / Invite Pending | 학생 미진입 상태 그룹 라벨 | #5 |
| 레슨 1회 시간 / Lesson Duration | slotDurationMinutes 사용자 표시명 | #9 |
| 쉬는 시간 / Break Time | breakTimeBetweenLessons 사용자 표시명 | #9 |

---

## PR 그룹별 예상 일정

| 그룹 | 항목 | 스펙 작업 | 코드 작업 | 합 |
|---|---|---|---|---|
| G1 온보딩 정렬 | #1·#8·#10 | 2-3일 | 1-2주 | 2-3주 |
| G2 입금 자동화 | #2·#3·#6 | 2-3일 | 2-3주 | 3-4주 |
| G3 휴가·일정 | #4·#7 | 3-4일 | 3-4주 | 4-5주 |
| G4 학생 연결 | #5 | 1일 | 3-5일 | 1주 |
| G5 가용시간 UX | #9 | 1일 | 1-2주 | 2주 |
| **합** | 10건 | ~2주 | ~3개월 | ~3.5개월 |

스펙 작업만 먼저 끝내면 외주·신규 개발자에게 코드 작업 위임 가능. 본 감사의 핵심 산출물은 **스펙 보완** 이며, 코드 실행은 다음 단계.

---

## 다음 세션 진입 방법

다음 세션에서 본 작업을 이어가려면:

```
"docs/specs/review/2026-06-01-teacher-e2e/ 의 40-spec-changes.md 의 G1 부터 순차 실행해주세요"
```

또는 그룹별 분할:

```
"40-spec-changes.md G2 (입금 자동화) 만 스펙 작업해주세요"
```

각 그룹은 독립적이므로 평행 진행 가능 (worktree 사용 권장).

---

## 변경 이력

| 버전 | 날짜 | 내용 |
|---|---|---|
| 1.0 | 2026-06-01 | Top 10 → 5 그룹 × 12 파일 매핑 + 15 글로서리 용어 정리 |
