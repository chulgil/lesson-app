# Top 10 갭 카탈로그 (30-gap-catalog)

> 작성일: 2026-06-01
> 입력: 10-funnel-audit.md + 20-competitive-benchmark.md
> 결정: G1 게이트 — 사용자 "추천대로" 승인 (Top 10 그대로 진행)
> 본 문서는 각 항목의 문제·영향·해결안·측정을 정의. 스펙 파일 매핑은 40-spec-changes.md 참조.

---

## 우선순위 매트릭스

```
                 높은 임팩트       낮은 임팩트
              ┌──────────────────┬──────────────┐
   저노력     │ #1 AB-C1          │  —           │
              │ #5 D-G3           │              │
              │ #6 E3-H2          │              │
              │ #8 AB-H3          │              │
              ├──────────────────┼──────────────┤
   고노력     │ #2 E2-C2          │  보류        │
              │ #3 E2-C1          │              │
              │ #4 H-001          │              │
              │ #7 H-002          │              │
              │ #9 C-G2           │              │
              │ #10 A-C2          │              │
              └──────────────────┴──────────────┘
```

저노력 = 스펙만 또는 1-2일 코드 변경. 고노력 = 백엔드 변경 또는 1주+ 작업.

---

## #1 AB-C1 — 가용시간 설정이 온보딩에 없음

| 항목 | 값 |
|---|---|
| 단계 | B 온보딩 v3 Phase A |
| 심각도 | Critical |
| 노력 | **저** (스펙 + UI 라우팅) |
| 객관 근거 | `grep WeeklySchedule frontend/lib/features/onboarding/` = **0건** |

### 문제

선생님이 가입 직후 홈 화면에 진입하지만 `WeeklySchedule`이 비어 있어 학생이 예약할 슬롯이 0개. 학생 초대해도 "예약 가능 시간 없음" → 첫 인상 실패 → 이탈.

`teacher_onboarding_v3_spec.md §1` 자체에서 "레슨 시간/가용 시간 설정이 온보딩에 없음 → 학생이 예약 불가" 를 **CRITICAL** 로 명시했으나 미구현.

### 영향

- B → C 단계 전이 게이트 깨짐: 가용시간 없이 D(학생초대)까지 진행되면 학생도 함께 이탈
- D·E 단계 전체 차단 가능성: "예약 못 함" 한 줄 경험으로 학생까지 도주

### 해결안

1. `teacher_onboarding_v3` Phase B 필수 퀘스트 1번을 "가용시간 설정" 으로 확정
2. 홈 진입 직후 가용시간 0개 상태에서 **퀘스트 보드 최상단에 강제 노출** + 다른 퀘스트 잠금
3. 가용시간 설정 화면을 **간소화 버전** 으로 분리 (요일 다중선택 + 시작/종료시각 1쌍 + "더 추가" 옵션). 풀 설정은 나중에.

### 측정

- After: `grep WeeklySchedule frontend/lib/features/onboarding/` ≥ 1
- After: 신규 선생님 가입 후 24h 내 `WeeklySchedule.isActive=true` 비율 (백엔드 메트릭)

---

## #2 E2-C2 — 카카오 알림톡(LNZ_INVOICE / LNZ_PAYMENT_CONFIRM) 미구현

| 항목 | 값 |
|---|---|
| 단계 | E2 입금 추적 |
| 심각도 | Critical |
| 노력 | 중 (백엔드 1-2주) |
| 객관 근거 | `grep alimtalk\|LNZ_INVOICE = 0건` |

### 문제

수강권 제안 후 입금 안내가 **앱 내부 알림에만 의존**. 학생이 앱 미설치 또는 알림 차단이면 도달률 0%. 학부모는 앱 미설치 비율이 매우 높음 → 입금 안내가 학부모에게 도달 못 함 → 입금 누락 → E3 단계 도달 실패.

카톡 채널 푸시 도달률은 ~95%. 우리는 0%.

### 영향

- E2 → E3 전이 게이트 깨짐: 학부모 미도달 → 7일 후 자동 expired → 수강권 발급 실패
- 매출 직격: 가입했는데 첫 결제가 안 일어남
- 카톡 채널 대안으로 도주

### 해결안

1. `notification/kakao_alimtalk_spec.md` 의 LNZ_INVOICE 템플릿을 백엔드 알림톡 발신 큐에 연결
2. 발송 트리거: E1 종료 직후 (제안 송신 = 알림톡 발송)
3. LNZ_PAYMENT_CONFIRM: 선생님이 입금 확인 누르면 학생·학부모에게 발송
4. 비용 / 발신 가능 상태 / 실패 폴백 (앱 푸시) 정의

### 측정

- After: 알림톡 발송 건수 / E1 송신 건수 ≥ 90% (운영 메트릭)
- After: 입금 회수율 (E1 송신 → E3 paymentConfirmed) 추정 +20-30%

---

## #3 E2-C1 — 선생님 측 입금 미확인 대시보드 + 자동 리마인드 부재

| 항목 | 값 |
|---|---|
| 단계 | E2 입금 추적 |
| 심각도 | Critical |
| 노력 | 중 (FE + BE 1-2주) |
| 객관 근거 | grep + subscription_master §4 정성 확인 |

### 문제

학생 측 D+1/3/7 리마인드는 부분 존재하나, **선생님은 입금 안 됨을 능동적으로 알 수 없음**. 7일 후 자동 expired 까지 침묵. 선생님이 "어, 입금 안 됐네" 인지 못 함 → 묵시적 포기.

### 영향

- 선생님 측 매출 누락 인지 실패
- 7일 자동 expired 후 재제안 마찰 (학생도 의지 약해짐)
- 카톡 채널은 선생님이 단톡방에서 매일 확인 → 우리 앱은 일별 대시보드 0

### 해결안

1. 선생님 홈 대시보드 상단에 **"입금 대기 N건"** 카드 추가 (paymentRequested 상태 집계)
2. 카드 탭 → 입금 미확인 리스트 (학생별 D+N 표시, 1탭 재발송)
3. 선생님 측 푸시: D+1, D+3, D+7 "○○○ 학생 입금 대기 N일" (선생님 본인에게)
4. 카톡 알림톡 #2 와 결합: 학부모 측 자동 알림 + 선생님 측 가시화

### 측정

- After: 선생님 홈에 `paymentRequested` 카운트 위젯 존재 (UI grep)
- After: 선생님 측 푸시 정의 (notification_master 추가)

---

## #4 H-001 — 휴가/장기휴강 모드 부재

| 항목 | 값 |
|---|---|
| 단계 | H 일정 조절·갱신 (C 가용시간과 같은 뿌리) |
| 심각도 | Critical |
| 노력 | 중 (스펙 + FE/BE) |
| 객관 근거 | `grep teacherVacation\|VacationMode = 0건` |

### 문제

선생님이 1주 휴가 → 해당 기간 레슨 N건을 **개별 취소**해야 함. 크레딧·노쇼 카운터 오염, 수강권 자동 연장 부재 → 학생도 수강권 만료 임박으로 혼선.

`teacher_availability_spec.md` 의 방학 모드는 스펙만 존재하고 미구현. C-G1 과 동일 문제.

### 영향

- 여름·겨울 시즌마다 운영 신뢰 붕괴
- N건 취소 작업이 카톡 단톡방 "이번 주 휴강합니다" 1줄 대비 압도적 마찰
- 카톡 채널 회피

### 해결안

1. `TeacherAvailability` 에 `vacationPeriods: List<DateRange>` 필드 추가
2. 휴가 모드 진입 UI: "기간 선택 → 영향 받는 레슨 N건 표시 → 일괄 처리"
3. 처리 옵션: (a) 보강 자동 등록 (b) 무료 처리 (c) 다음 회차로 이월
4. 수강권 만료일 자동 연장 (휴가일 수만큼)
5. 학생/학부모에게 알림톡 자동 발송

### 측정

- After: `grep VacationPeriod\|vacationMode backend/app/models/` ≥ 1
- After: 운영 메트릭 — 휴가 등록 후 수동 취소 건수 / 휴가 등록 건수 < 10%

---

## #5 D-G3 — 초대 만료·거절·재초대 흐름 미정의

| 항목 | 값 |
|---|---|
| 단계 | D 학생 초대·연결 |
| 심각도 | Critical |
| 노력 | **저** (스펙 + 화면 1-2개) |
| 객관 근거 | `grep reinvite\|resendInvite = 0건` |

### 문제

- 학생이 초대 코드/QR 받고 미설치 시 선생님 측 재발송 트리거 없음
- `InviteCode.expiresAt` 후 자동 만료되지만 선생님은 인지 못 함
- `RelationshipStatus.trialBooked` vs `ConnectionStatus.inviteSent` **이중 상태 충돌**: UI에서 어느 게 보여야 하는지 모름

### 영향

- D → E1 전이 게이트 깨짐
- 학생 미진입 시 선생님 손쓸 방법 없음 → 학생을 영영 잃음

### 해결안

1. 학생 리스트에 `inviteSent` 상태인 학생을 **별도 그룹 "초대 대기"** 로 표시
2. 각 학생에 D+1, D+3 만료 임박 표시 + 1탭 재발송 버튼
3. 재발송 시 같은 코드 만료 갱신 또는 새 코드 생성 (정책 결정 필요)
4. 이중 상태 통합: `RelationshipStatus` SSOT 로, `ConnectionStatus` deprecate 또는 internal 화

### 측정

- After: `grep resendInvite frontend/lib/features/user\|student/` ≥ 1
- After: `InviteCode.expiresAt` 후 재발송 비율 (운영 메트릭)

---

## #6 E3-H2 — 입금 확인 Undo 경로 부재

| 항목 | 값 |
|---|---|
| 단계 | E3 입금 확인·발급 |
| 심각도 | High |
| 노력 | **저** (백엔드 + UI 1-2일) |
| 객관 근거 | `grep undoConfirmPayment = 0건` |

### 문제

선생님이 잘못 [입금 확인] 누르면 `paymentConfirmed=true` 되어 **수강권이 영구 발급**. 관계가 active 로 전환되고 스케줄도 자동 생성됨. 되돌리기 경로 없음 → 신뢰 무너짐.

### 영향

- 한 번 실수 = 영구 데이터 오류
- 선생님이 "이 앱은 위험하네" 인식 → 일상 사용 회피 → 카톡 회피

### 해결안

1. 입금 확인 후 **24시간 윈도우** 내 Undo 가능
2. UI: 입금 확인 직후 SnackBar "확인 완료. 24시간 내 되돌릴 수 있습니다 [되돌리기]"
3. Undo 시 자동 처리: 수강권 회수, 관계 상태 롤백, 자동 생성된 스케줄 취소, 학생에게 알림 (선택)
4. 24시간 후 또는 첫 레슨 차감 후에는 Undo 불가, 환불은 외부 처리

### 측정

- After: `grep undoConfirmPayment backend/app/services/` ≥ 1
- After: Undo 사용률 (운영 메트릭, 정상 범위 1-5%)

---

## #7 H-002 — 정규권 일괄변경 후 5주차/보강 재계산 미정의

| 항목 | 값 |
|---|---|
| 단계 | H 일정 조절·갱신 |
| 심각도 | Critical |
| 노력 | **고** (모델·계산 로직, 2-3주) |
| 객관 근거 | `bulkChange` 호출처 정성 확인 |

### 문제

정규 수강권 일괄 변경(요일·시간 변경) 후 5주차·보강·이월 회차 자동 재계산 로직 부재. `bulkChange` 후 학생 측 회차 표시와 실제 차감이 어긋남 → 학생-선생님 분쟁.

### 영향

- H 단계 일상 운영의 가장 큰 분쟁 원인
- "이번 달 5주차인데 수강권은 4회만 차감됨" → 한 달 단위 다툼 → 갱신 거부

### 해결안

1. `Subscription` 에 `remainingLessons` 외에 `scheduledLessons` 별도 트랙
2. 일괄변경 시 `scheduledLessons` 재계산 + `remainingLessons` 조정
3. 5주차 보너스 정책 명시 (`bonusCount`) + 일괄변경과 결합 시 우선순위 정의
4. 보강 크레딧을 별도 엔티티(`MakeupCredit`) 로 분리 — Teachworks "Make-up bank" 패턴 차용

### 측정

- After: `MakeupCredit` 엔티티 정의 + repository
- After: 일괄변경 후 학생 측·선생님 측 회차 표시 일치 (테스트 케이스)

---

## #8 AB-H3 — v1/v2/v3 SSOT 3중 충돌

| 항목 | 값 |
|---|---|
| 단계 | A·B (온보딩) |
| 심각도 | High |
| 노력 | **저** (스펙 정리만) |
| 객관 근거 | feature_hub.md 와 spec 디렉토리 교차 확인 |

### 문제

- `onboarding_master.md` (v1, 코드 역공학)
- `teacher_onboarding_v3_spec.md` (v3, 신규)
- `onboarding_quest_v2.md` (v2, 미구현)

3개 동시 존재. FE 코드는 v1 따름. 어느 게 정답인지 불명. 새 작업자(또는 다음 세션의 AI)가 어느 스펙을 읽어야 할지 모름.

`canBeSearched` 60% 임계값이 사용자에게 비가시 — 가입 후 "왜 검색에 안 나오지" 혼선.

### 영향

- 스펙·코드 drift 가속
- 새 기능 추가 시 어느 스펙에 반영할지 일관성 깨짐
- AI 세션이 잘못된 스펙 따라 잘못된 코드 생성 위험

### 해결안

1. `teacher_onboarding_v3_spec.md` 를 **공식 SSOT** 로 확정 (이미 #1 AB-C1 에서 v3 채택)
2. `onboarding_master.md` 를 v1 archive 로 이동 (`_archive/` 디렉토리)
3. `onboarding_quest_v2.md` 의 가치 있는 내용은 v3 에 머지 후 archive
4. `canBeSearched` 임계값 (60%) 을 프로필 완성도 게이지 UI 에 명시 (#9 와 연결)
5. `feature_hub.md` 의 온보딩 라인을 v3 단일로 정리

### 측정

- After: `ls docs/specs/onboarding/` = teacher_onboarding_v3_spec.md (+ 기타 보조)
- After: `_archive/onboarding/` 에 v1·v2 이동 확인

---

## #9 C-G2 — 가용시간 UX redesign 미반영

| 항목 | 값 |
|---|---|
| 단계 | C 가용시간 설정 |
| 심각도 | High |
| 노력 | 중 (UI 작업 1-2주) |
| 객관 근거 | availability_settings_ux_redesign_spec.md vs 현재 코드 비교 |

### 문제

- 용어 마찰: "가용시간 / 슬롯 / 예외" 기술 용어 그대로 노출
- 미리보기 부재: 슬롯 등록 후 학생이 보게 될 화면 안 보임
- 3 화면 분산: 슬롯길이·쉬는시간·시작간격이 별도 화면
- Calendly 1탭 vs 우리 3탭
- 기본값 충돌: `slotStartInterval=30` (schedule_master) vs `레슨 길이 50분 기본` (availability_settings)

### 영향

- 첫 슬롯 등록 포기 → C 단계 이탈
- AB-C1 (가용시간 온보딩 누락) 과 결합 시 효과 누적

### 해결안

1. `availability_settings_ux_redesign_spec.md` 의 redesign 안 실행 우선순위 끌어올림
2. "레슨 1회 시간"·"쉬는 시간" 같은 사용자 친숙 용어로 통일
3. 좌측 설정 + 우측 미리보기 split 레이아웃 — Calendly 패턴
4. 기본값 정의: 레슨 50분 / 쉬는 시간 10분 / 시작 간격 = 레슨+쉬는 시간 = 60분 (한국 음악 레슨 표준)

### 측정

- After: 첫 슬롯 등록까지 탭 수 ≤ 3 (UX 테스트)
- After: 기본값 일관성 확인 (schedule_master·availability spec 동일 수치)

---

## #10 A-C2 — 전화인증을 SSO 직후 첫 단계에서 분리

| 항목 | 값 |
|---|---|
| 단계 | A 유입·로그인 |
| 심각도 | Critical |
| 노력 | **고** (인증 흐름 + 정책, 2-3주) |
| 객관 근거 | 기존 가입 흐름 + `teacher_onboarding_v3_spec.md §1` 자체 인식 |

### 문제

SSO 직후 전화인증 강제. SMS 인증번호 입력 3분 타이머 마찰. 카톡 채널(이미 가입됨)·네이버 카페·숨고(약관만) 대비 진입 마찰 최대.

v3 spec 자체에서 "전화인증이 첫 단계 → 진입 마찰 큼" 으로 인식하고 "퀘스트 보드로 이동" 권고했으나 미구현.

### 영향

- A 단계 이탈 1순위 (가입 직후 3분 내)
- "한 번 보고 그만" 마찰

### 해결안

1. SSO 직후 즉시 B 단계(이름·악기) 진입 — 전화인증 스킵
2. 전화인증을 **선택 퀘스트**로 이동 (보상: "인증 선생님 배지", "학부모 신뢰 강화")
3. 단, 첫 수강권 발급 시점에는 전화인증 필수 (학부모 측 신뢰 보호)
4. 약관 동의는 SSO 단계에서 1탭 처리 (별도 화면 X)

### 측정

- After: SSO → 홈 진입까지 평균 시간 < 60초 (운영 메트릭)
- After: 가입 후 24h 내 이탈률 (운영 메트릭)

---

## 그룹핑 (PR·세션 단위)

40-spec-changes 에서 다음 그룹으로 묶일 예정.

| 그룹 | 항목 | 도메인 | 예상 노력 |
|---|---|---|---|
| G1: 온보딩 정렬 | #1, #8, #10 | onboarding | 2-3주 |
| G2: 입금 자동화 | #2, #3, #6 | subscription + notification | 2-3주 |
| G3: 휴가·일정 | #4, #7 | schedule | 3-4주 |
| G4: 학생 연결 | #5 | user (invite) | 1주 |
| G5: 가용시간 UX | #9 | schedule (UX) | 1-2주 |

---

## 변경 이력

| 버전 | 날짜 | 내용 |
|---|---|---|
| 1.0 | 2026-06-01 | G1 게이트 "추천대로" 승인 후 Top 10 상세화 |
