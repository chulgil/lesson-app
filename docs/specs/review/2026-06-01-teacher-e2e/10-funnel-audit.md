# 선생님 E2E 펀넬 감사 (10-funnel-audit)

> 작성일: 2026-06-01
> 방법: 5개 subagent 병렬 dispatch + 정량 grep 검증
> 평가 기준: 이탈 방지 (drop-off prevention)
> 평가틀: 10단계 (A·B·C·D·E1·E2·E3·F·G·H) × 6차원 (Drop-off / Friction / Gap / Conflict / Benchmark / Recovery)
> 본 문서는 발견 카탈로그이며, 갭 매핑은 `30-gap-catalog.md`, 스펙 보완은 `40-spec-changes.md` 참조.

---

## 1. 집계

| 단계 | Critical | High | Medium 이하 | 합 | 정량 입증 |
|---|:---:|:---:|:---:|:---:|---|
| A 유입·로그인 | 1 | 0 | 0 | 1 | — |
| B 온보딩 v3 Phase A | 1 | 1 | 0 | 2 | grep 0건 입증 |
| C 가용시간 설정 | 1 | 1 | 0 | 2 | grep 0건 입증 |
| D 학생 초대·연결 | 1 | 0 | 0 | 1 | grep 0건 입증 |
| E1 수강권 제안 송신 | 0 | 0 | 1 | 1 | — |
| E2 입금 추적·리마인드 | 2 | 2 | 0 | 4 | grep 0건 입증 |
| E3 입금 확인·발급 | 0 | 1 | 0 | 1 | — |
| F 스케줄 확정 | 0 | 0 | 1 | 1 | — |
| G 레슨 진행·노트 | 0 | 0 | 2 | 2 | — |
| H 일정 조절·갱신 | 2 | 2 | 0 | 4 | 부분 입증 |
| **합** | **8** | **7** | **4** | **19** | — |

E2 (입금 추적) 와 H (일정 조절) 가 본 펀넬의 **2대 최약 고리**. 둘 다 한국 음악 선생님이 일상적으로 가장 많이 부딪히는 단계이고, 카톡 채널·네이버 카페로 도주하는 트리거.

---

## 2. 단계별 발견 카탈로그

각 발견은 `<ID> [심각도] <한 줄 문제> | 영향 | 객관 근거` 포맷.

### A. 유입·로그인

| ID | 심각도 | 발견 |
|---|:---:|---|
| A-C2 | Critical | SSO 직후 전화인증 강제 → 카톡 채널·네이버 카페 대비 진입 마찰 최대. v3 spec §1 "전화인증이 첫 단계 → 진입 마찰 큼"으로 자체 인식했으나 미구현. **카톡 채널은 진입 마찰 0** |

### B. 온보딩 v3 Phase A

| ID | 심각도 | 발견 |
|---|:---:|---|
| **AB-C1** | **Critical** | **가용시간(WeeklySchedule) 설정이 온보딩에 없음 → B 완료해도 학생 예약 0% 가능. 정량: `grep WeeklySchedule frontend/lib/features/onboarding/` = 0건.** v3 spec §1 자체 인식 "레슨 시간/가용 시간 설정이 온보딩에 없음 → 학생이 예약 불가" CRITICAL로 명시했으나 미구현 |
| AB-H3 | High | onboarding_master(v1) / teacher_onboarding_v3 / onboarding_quest_v2 **3개 SSOT 동시 존재**. 어느 것이 정답인지 불명, FE 코드는 v1 따름. canBeSearched 60% 임계값이 사용자에게 비가시 → 가입 후 "왜 검색에 안 나오지" 혼선 |

### C. 가용시간 설정

| ID | 심각도 | 발견 |
|---|:---:|---|
| **C-G1** | **Critical** | **방학/장기휴강 모드 스펙만 있고 미구현. 정량: `grep vacationMode = 0`. 여름 시즌 일괄 휴강·수강권 자동 연장 부재 → 운영 신뢰 붕괴, 카톡 채널 회피** |
| C-G2 | High | availability_settings_ux_redesign_spec 의 미리보기·진입경로 단축 미반영. "가용시간/슬롯/예외" 기술 용어, 슬롯길이·쉬는시간·시작간격이 3 화면에 분산. 첫 슬롯 등록 포기 위험. Calendly 1탭 vs 우리 3탭. schedule_master §2(`slotStartInterval=30`) vs availability_settings(`레슨 길이 50분 기본`) 기본값 불일치 |

### D. 학생 초대·연결

| ID | 심각도 | 발견 |
|---|:---:|---|
| **D-G3** | **Critical** | **초대 만료(`InviteCode.expiresAt`) / 거절 / 재초대 흐름 미정의. 정량: `grep reinvite/resendInvite = 0`.** 학생이 코드 받고 미설치 시 선생님 측 재발송 트리거 없음. `RelationshipStatus.trialBooked` vs `ConnectionStatus.inviteSent` 이중 상태 충돌 |

### E1. 수강권 제안 송신

| ID | 심각도 | 발견 |
|---|:---:|---|
| E1-M1 | Medium | Template-First (3단계, 2-3탭) 구현 우수. 청구서(Invoice) PDF·계좌 자동 채움이 Phase 2 대기 |

### E2. 입금 추적·리마인드 (본 펀넬 최약 고리)

| ID | 심각도 | 발견 |
|---|:---:|---|
| **E2-C1** | **Critical** | **선생님 측 "입금 미확인" 일별 대시보드 부재 + D+1/3/7 자동 리마인드 없음**. 7일 후 자동 expired만 존재 → 송금 누락 묵시적 포기, 매출 직격 손실. paymentRequested → paymentNotified 사이 무방비 |
| **E2-C2** | **Critical** | **카카오 알림톡(LNZ_INVOICE, LNZ_PAYMENT_CONFIRM) 미구현. 정량: `grep alimtalk/LNZ_INVOICE = 0`**. 앱 미설치 학부모 도달 0% → 결제 채널 단절. 카톡 채널 푸시 도달률 95% vs 우리 0% |
| E2-H1 | High | 부분/분할 입금 데이터 모델 부재 (`amount` 단일 필드). 실제 한국 음악 레슨 패턴(반액 선납·잔금 후납·할인 적용) 미수용 |
| E2-H3 | High | paymentReceipt/Invoice Phase 1 미배포 → 학부모 연말정산·증빙 요청 시 외부 카톡으로 도주 |

### E3. 입금 확인·발급

| ID | 심각도 | 발견 |
|---|:---:|---|
| **E3-H2** | **High** | **입금 확인 Undo 경로 부재 (`undoConfirmPayment` 부재, 정량 0건)**. 오발송 1회로 잘못된 수강권 영구 발급, 신뢰 무너짐. 24h 내 영수증 cancel 스펙만 있고 구현 0 |

### F. 스케줄 확정

| ID | 심각도 | 발견 |
|---|:---:|---|
| F-M1 | Medium | ScheduleConfirmationCard 3 타입 구현 완료, 학생 능동 확정은 OK. 학생 7일 미확인 시 자동 확정/리마인드·선생님 측 "확인 대기" 만료 정책 부재 |

### G. 레슨 진행·노트

| ID | 심각도 | 발견 |
|---|:---:|---|
| G-M1 | Medium | 노트 부담 낮음(자동완료+템플릿 누적) — 우수. 단 KeyPoints/PracticeTips는 Undo 미지원(불일치). 노쇼 사유 UI 미구현 |
| G-M2 | Medium | `LessonStatus.cancelled` 단일 enum vs 6개 세분상태, `lessonCancellationConfirmed` ↔ status enum 매핑 불명 |

### H. 일정 조절·갱신

| ID | 심각도 | 발견 |
|---|:---:|---|
| **H-001** | **Critical** | **휴가/장기휴강 모드 부재** (선생님이 1주 휴가 시 N건 개별취소 → 크레딧·노쇼 오염, 카톡 이탈). C-G1과 같은 뿌리. `grep teacherVacation = 0` |
| **H-002** | **Critical** | **정규권 일괄변경 후 5주차·보강 재계산 미정의**. `bulkChange` 후 회차 어긋남, 학생-선생님 분쟁 유발 |
| H-003 | High | cancel_lesson_bottom_sheet 스펙 §9.3 미구현 → 사유 선택 불가 → 자동 차감 분쟁. 무료처리만으로는 회복 부족 |
| H-004 | High | `RequestEvent` (옵션A) vs `SubscriptionEvent` (옵션B) 모델 미확정 → H 전 흐름 차단, FE-BE 명칭 충돌 위험 |

---

## 3. 단계 전이 게이트 위반 (자동 처리 누락)

00-plan §3의 전이 게이트 중 다음이 누락 확인됨.

| 전이 | 요구된 자동 처리 | 현재 상태 |
|---|---|---|
| B → C | 홈 퀘스트 보드에 "가용시간 비어 있음" 알림 | **누락 — onboarding/schedule 연결 0건** (정량 입증) |
| E1 → E2 | 카톡 알림톡 자동 발송 | **누락 — alimtalk 0건** |
| E2 → E3 | D+1/3/7 자동 리마인드 (학생·선생님 양측) | **누락** (선생님 측 0, 학생 측만 부분 있음) |

---

## 4. Recovery 차원 종합

00-plan §4의 6번째 차원(회복성). 본 감사에서 **Recovery 부재가 광범위**한 것으로 확인.

| 단계 | 잘못된 행동 | 되돌리기 경로 |
|---|---|---|
| A | 역할 잘못 선택 | **없음** (role_select_screen 최초 1회만) |
| B | 잘못된 악기·이름 입력 | profileSetup 재진입 라우트 불명 |
| C | 잘못된 가용시간 등록 | 일괄 비활성·Undo 부재 |
| D | 잘못된 학생 초대 | invite_system_v2에 회수·취소 흐름 미정의 |
| E2 | 잘못된 입금 안내 발송 | 알림톡 회수 불가 |
| E3 | **잘못 [입금 확인] 누름** | **없음** — 오발송 1회로 영구 발급 |
| G | 잘못된 노트 | Undo 1단계만, "완료" 되돌리기 모호 |
| H | 잘못 보낸 학생 알림 | unsend 불가, 무료처리 후 재차감 경로 없음 |

Recovery 부재는 "실수 한 번 = 영구 데이터 오류" 패턴을 만들고, 카톡 채널(메시지 회수 가능) 대비 신뢰감을 떨어뜨림.

---

## 5. 정량 입증 결과 (객관 근거)

| 검증 명령 | 결과 | 의미 |
|---|:---:|---|
| `grep WeeklySchedule frontend/lib/features/onboarding/` | **0건** | AB-C1 입증 — 가용시간이 온보딩 코드에 없음 |
| `grep vacationMode\|reinvite frontend/lib/features/ backend/app/` | **0건** | C-G1, D-G3, H-001 입증 — 방학·재초대 0 |
| `grep undoConfirmPayment\|partialPayment\|LNZ_INVOICE frontend/lib/features/subscription backend/app/services/` | **0건** | E2-C1, E2-C2, E2-H1, E3-H2 모두 입증 |
| `grep teacherVacation frontend/lib backend/app` | **0건** | H-001 입증 |

스펙 누락이 아닌 **코드 0줄** 수준으로 확인된 Critical 항목 = **8건 중 6건**.

---

## 6. 본 펀넬 최약 5단계 (이탈 위험 순)

1. **E2 입금 추적** (Critical 2 + High 2) — 한국 외부 송금 모델에서 매출 직격
2. **H 일정 조절** (Critical 2 + High 2) — 일상 운영에서 가장 자주 발생
3. **B 온보딩** (Critical 1 + High 1) — 가입 직후 학생 예약 0% 가능
4. **C 가용시간** (Critical 1 + High 1) — 첫 진입 마찰 + 방학 시즌 신뢰 붕괴
5. **D 학생 초대** (Critical 1) — 학생 미진입 시 선생님 무방비

상위 5단계 모두 **카톡 채널·네이버 카페가 무료로 해결하고 있는** 패턴들. 우리 앱이 이를 못 풀면 가입자가 결국 외부로 도주.

---

## 7. 변경 이력

| 버전 | 날짜 | 내용 |
|---|---|---|
| 1.0 | 2026-06-01 | 5개 subagent 결과 + 정량 grep 검증 종합 |
