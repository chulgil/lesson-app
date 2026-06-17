# 용어 정의 (Glossary)

> 최종 업데이트: 2026-05-04
> SSOT: `.harness/knowledge/glossary.md` — 이 파일은 동기화 대상 (사용자 열람용)

lesson-app에서 사용하는 핵심 용어와 개념을 정의합니다.

---

## 1. 관계 시스템 용어

### 1.1 연결 (Connection)

> **정의**: QR 스캔/URL 클릭을 통해 선생님-학생 관계가 생성되는 것

| 항목 | 설명 |
|------|------|
| **발생 시점** | QR 스캔 또는 초대 URL 클릭 시 |
| **결과** | `TeacherStudentRelation` 레코드 생성 |
| **초기 상태** | `trialBooked` (체험 예약) |
| **특징** | 버튼 탭 없이 **자동 연결** (제로 탭) |

```
연결 = QR 스캔 → TeacherStudentRelation 생성 (trialBooked)
```

#### 연결 vs 팔로우

| 구분 | 연결 (Connection) | 팔로우 (Follow) |
|------|------------------|----------------|
| **목적** | 레슨 관계 형성 | 소식 구독 |
| **엔티티** | `TeacherStudentRelation` | `Follow` |
| **수강권 필요** | ✅ 관계 유지에 필요 | ❌ 불필요 |
| **상태 전환** | 수강권 기반 자동 전환 | 없음 (팔로우/언팔로우만) |

---

### 1.2 팔로우 (Follow) / 소식 구독

> **정의**: 선생님/학원의 소식(공연, 이벤트, 뉴스)을 받아보기 위한 구독

| 항목 | 설명 |
|------|------|
| **성격** | 인스타그램 스타일 일방향 팔로우 |
| **수강권 필요** | ❌ 불필요 |
| **레슨 관계** | ❌ 무관 |
| **용도** | 공연 소식, 이벤트, 뉴스 알림 |

```
팔로우 = 소식 구독 (레슨과 무관)
       = 누구나 가능 (수강권 없이도)
```

#### 팔로우 시나리오

| 시나리오 | 설명 |
|----------|------|
| 공연 팬 | 연주자 선생님 공연 소식 받기 |
| 관심 학원 | 학원 이벤트/모집 소식 받기 |
| 과거 학생 | 이전 선생님 소식 계속 받기 |

---

### 1.3 수강권 중심 관계 (Subscription-Based Relationship)

> **정의**: 선생님-학생 관계를 수강권 상태로 정의하는 모델

#### 관계 상태 (RelationshipStatus)

| 상태 | 코드 | 조건 | 설명 |
|------|------|------|------|
| 체험 예정 | `trialBooked` | 체험 예약 완료 | 잠재 학생 |
| 수강 중 | `active` | 유효 수강권 존재 | 정규 레슨 진행 |
| 수강권 만료 | `expired` | 만료 후 30일 이내 | 일시적 휴식 |
| 이전 레슨 | `past` | 만료 후 30일 초과 | 과거 학생 |

#### 상태 전이

```
[QR 스캔] → trialBooked → [수강권 발급] → active
                                            ↓
                                    [수강권 만료]
                                            ↓
                                        expired
                                            ↓
                                      [30일 경과]
                                            ↓
                                          past ←→ [레슨 요청] → active
```

---

### 1.4 ~~맞팔 (Mutual Follow)~~ - 폐기됨

> ⚠️ **폐기된 용어**: 더 이상 사용하지 않습니다.

| 항목 | 기존 (맞팔) | 현재 |
|------|-----------|------|
| **선생님-학생 관계** | 상호 팔로우 | **수강권 기반 관계** |
| **소식 구독** | 해당 없음 | **팔로우 (일방향)** |

#### 변경 이유

1. **개념 불일치**: "맞팔"은 SNS 용어로 레슨 관계와 맞지 않음
2. **상태 불명확**: 수강권 없이 연결만 된 상태의 의미 모호
3. **자동 전환 불가**: 수강권 만료 시 관계 상태 변경이 어려움

#### 대체 용어

| 기존 | 대체 |
|------|------|
| 맞팔 성립 | **연결 완료** (QR 스캔 = 자동 연결) |
| 맞팔 상태 | **수강 중** (active) |
| 맞팔 해제 | **팔로우 해제** (소식 구독 취소) |

---

## 2. 연결 방식 용어

### 2.1 QR 연결

> **정의**: 대면 상황에서 선생님 QR 코드를 스캔하여 연결

| 항목 | 설명 |
|------|------|
| **사용 상황** | 체험 레슨 후 대면 |
| **연결 방식** | 스캔 즉시 자동 연결 |
| **버튼 탭** | 불필요 (제로 탭) |

### 2.2 URL 연결

> **정의**: 초대 링크를 통해 연결

| 항목 | 설명 |
|------|------|
| **사용 상황** | 카카오톡 등으로 링크 공유 |
| **연결 방식** | 링크 클릭 → 가입 → 자동 연결 |

### 2.3 코드 연결

> **정의**: 6자리 초대 코드 입력으로 연결

| 항목 | 설명 |
|------|------|
| **사용 상황** | QR/URL이 어려운 경우 |
| **연결 방식** | 코드 입력 → 자동 연결 |

### 2.4 초대 코드 라이프사이클 (Invite Code Lifecycle)

> **정의**: 초대 코드의 발급·전송·만료·재발송 흐름. SSOT: `docs/specs/user/invite_lifecycle_spec.md`

| 상태 | 의미 |
|------|------|
| created | 코드 생성됨, 미전송 |
| sent | 학생에게 전송됨 |
| opened | 학생이 링크/QR 접근함 |
| joined | 학생 가입·연결 완료 (`RelationshipStatus.trialBooked` 또는 `active`) |
| expired | 7일 경과로 자동 만료 |
| revoked | 선생님이 명시적으로 회수 |

#### 재발송 정책

- 만료 임박(D-1, D-3) 시 선생님에게 알림 + 1탭 재발송 버튼
- 재발송 = 같은 코드 만료 갱신 (새 코드 생성 X)
- 회수(revoked) 후에는 새 코드 발급 필요

#### 초대 대기 (Invite Pending)

- `RelationshipStatus.invitePending`: 학생 리스트에서 별도 그룹으로 표시
- 기존 `ConnectionStatus.inviteSent` 와 통합 (ConnectionStatus deprecate 예정)

---

## 3. 레슨 관련 용어

### 3.1 체험 레슨 (Trial Lesson)

> **정의**: 정규 등록 전 1회 진행하는 시험 레슨

| 항목 | 설명 |
|------|------|
| **목적** | 선생님-학생 적합성 확인 |
| **수강권** | **필수** — 체험 1회 수강권 발급 (유료가 기본, 선생님 설정으로 무료 전환 가능) |
| **무료/유료** | 선생님 설정 > 레슨 운영 > "체험레슨 무료 여부" 토글 (기본: 유료) |
| **유료 시** | 일반 수강권과 동일 — 입금 안내 → 입금 확인 → 수강권 발급. 변경/취소 정책도 동일 적용 |
| **무료 시** | 시간 확정 즉시 수강권 발급 (입금 단계 스킵) |
| **관계 상태** | `trialBooked` |

### 3.2 정기 레슨 (Regular Lesson)

> **정의**: 수강권을 기반으로 정기적으로 진행하는 레슨

| 항목 | 설명 |
|------|------|
| **수강권** | 필수 |
| **관계 상태** | `active` |
| **스케줄** | 자동 생성 (주 N회) |

### 3.3 수강권 (Subscription)

> **정의**: 레슨 횟수/기간을 정의하는 권리

| 유형 | 설명 |
|------|------|
| **회차권** | N회 레슨 권리 (예: 4회권, 8회권) |
| **기간권** | N개월 무제한 (예: 1개월권) |

---

## 4. 역할 용어

### 4.1 선생님 (Teacher)

레슨을 제공하는 사용자

| 권한 | 설명 |
|------|------|
| 학생 관리 | 학생 목록, 상태 확인 |
| 수강권 발급 | 수강권 생성 및 발급 |
| 레슨 기록 | 레슨 노트, 과제 배정 |
| 가용시간 설정 | 예약 가능 시간 관리 |

#### 인증 선생님 배지 (Verified Teacher Badge)

> 전화번호 인증 완료 시 부여. 학부모 측 신뢰 표시. **첫 수강권 발급 전 인증 필요** (가입~D 단계는 미인증으로 자유 진행)

### 4.2 학생 (Student)

레슨을 받는 사용자

| 권한 | 설명 |
|------|------|
| 레슨 예약 | 가용시간에서 선택 |
| 연습 기록 | 연습 시간, 녹음 저장 |
| 수강권 확인 | 잔여 횟수 확인 |

### 4.3 학부모 (Parent)

자녀(학생)를 대신 관리하는 사용자

| 권한 | 설명 |
|------|------|
| 자녀 연습 확인 | 연습 현황 조회 |
| 입금 상태 관리 | 앱 밖 무통장입금/현금 수강료의 수강권 입금 확인 상태 |
| 레슨 확인 | 레슨 스케줄, 노트 확인 |

---

## 5. 네트워크/연결 상태 용어

### 5.1 ConnectionStatus (네트워크 상태) — **Deprecate 예정**

> ⚠️ **2026-06-01 결정**: ConnectionStatus는 점진적으로 deprecate. 초대·연결 상태는 `RelationshipStatus.invitePending` 으로 통합. 신규 코드는 RelationshipStatus 사용.

| 기존 상태 | 코드 | 통합 후 |
|------|------|------|
| 오프라인 | `offline` | (네트워크 영역으로 분리, 레슨 관계와 무관) |
| 초대 발송 | `inviteSent` | → `RelationshipStatus.invitePending` |
| 초대 수락 | `inviteAccepted` | → `RelationshipStatus.trialBooked` (체험 예약) |
| 연결됨 | `connected` | → `RelationshipStatus.active` 또는 팔로우 영역 |

### 5.2 RelationshipStatus (레슨 관계 상태) — **공식 SSOT**

> 레슨 관계의 단일 SSOT. 초대~수강 완료까지 모든 상태를 포괄.

| 상태 | 코드 | 조건 |
|------|------|------|
| 초대 대기 | `invitePending` | 학생에게 초대 코드 전송됨, 미진입 (신규 — 2026-06-01) |
| 체험 예정 | `trialBooked` | 체험 예약 완료 |
| 수강 중 | `active` | 유효 수강권 존재 |
| 수강권 만료 | `expired` | 만료 후 30일 이내 |
| 이전 레슨 | `past` | 만료 후 30일 초과 |

> 상세: [섹션 1.3 수강권 중심 관계](#13-수강권-중심-관계-subscription-based-relationship)

---

## 6. 시스템 용어

### 5.1 제로 탭 (Zero Tap)

> **정의**: 추가 버튼 탭 없이 동작이 완료되는 UX 패턴

| 적용 | 설명 |
|------|------|
| QR 연결 | 스캔만으로 연결 (연결하기 버튼 없음) |
| 시간 선택 | 칩 탭 = 선택 완료 (확인 버튼 없음) |

### 5.2 원클릭 (One Click)

> **정의**: 한 번의 탭으로 동작이 완료되는 UX 패턴

| 적용 | 설명 |
|------|------|
| 시간 선택 | 시간 칩 탭 = 선택 |
| 템플릿 선택 | 템플릿 탭 = 적용 |

### 5.3 온보딩 퀘스트 용어 (v2)

| 한글 | 영문 | 설명 |
|------|------|------|
| 퀘스트 | Quest | 온보딩 미션. 실제 앱 사용 행동을 유도하는 진행형 과제 |
| 퀘스트 보드 | Quest Board | 홈 화면의 퀘스트 진행 카드 |
| 코치마크 | Coach Mark | 화면 오버레이로 특정 UI 요소를 하이라이트하며 안내 |
| 워크스루 | Walkthrough | 인터랙티브 온보딩 — 실제 화면에서 직접 탭하며 배움 |
| 셀레브레이션 | Celebration | 퀘스트 완료 시 축하 피드백 (애니메이션 + 메시지) |
| 프로필 완성도 | Profile Completeness | 프로필 입력 항목 기반 0-100% 게이지 |

> 상세: [온보딩 퀘스트 v2 스펙](onboarding/onboarding_quest_v2.md)

---

## 7. 수강권 (Subscription)

| 한글 | 영문 | 설명 |
|------|------|------|
| 수강권 | Subscription | 레슨 횟수/기간 권리 |
| 수강권 제안 | Proposal | 선생님→학생 수강권 제안 |
| 수강권 템플릿 | Template | 미리 설정한 수강권 상품 |
| 판매가 | Sale Price | 실제 결제 금액 |
| 정가 | Regular Price | 할인 표시용 원가(선택). 판매가보다 크면 정가에 취소선 + 할인가 + 할인율 표시. 작성 시 악기·레벨 가격표에서 자동 산출 |
| 입금 상태 | Payment Status | 외부 입금 확인 여부 (앱 내 결제 아님) |
| 미수금 | Outstanding Payment | **후불** 수강권 중 입금 완료 기록 없는 상태 = 선생님 미수 채권. 배지·정산·프로필 통일 표시명. 사용하지 않는 표현: 입금대기(후불), 입금대기 |
| 입금 확인 대기 | Payment Confirmation Pending | **선불**(입금 안내 후) 입금 확인 전 수강권 제안 상태 집계. 선생님 홈 상단 카드. 사용하지 않는 표현: 입금 대기 |
| 입금 추적 | Payment Tracking | D+1/3/7 자동 리마인드 시스템 (학생·선생님 양측) |
| 입금 확인 되돌리기 | Confirm Payment Undo | 입금 확인 후 24시간 내 취소 가능. 첫 레슨 차감 발생 시 불가 |
| 수강권 자동 연장 | Auto-Extension | 선생님 휴가 일수만큼 만료일 자동 연장 |
| 스케줄된 회차 | Scheduled Lessons | 실제 잡힌 레슨 수. 잔여 회차와 별개 트랙 (5주차·일괄변경 후 재계산용) |
| 보강 크레딧 | Makeup Credit | 별도 엔티티로 적립된 보강 회차. 30일 만료 |

## 8. 스케줄 (Schedule)

| 한글 | 영문 | 설명 |
|------|------|------|
| 레슨 요청 | Lesson Request | 학생→선생님 레슨 신청 |
| 예약 | Booking | 확정된 레슨 일정 |
| 가용시간 | Availability | 선생님 예약 가능 시간대 |
| 첫 가용시간 | Initial Availability | 온보딩 중 강제 설정하는 최소 가용시간 (요일 + 시작/종료 시각, 50분 기본) |
| **휴무** | Day Off | 선생님 비근무일 (1일 단위, 레슨 없음). 스케줄 예외로 표현. 사용하지 않는 표현: 쉬는날 |
| **휴가** | Vacation | 기간형 휴무 (다중일). 휴가 기간 일괄 등록 → 영향 레슨 일괄 처리 (취소·보강·이월) + 수강권 자동 연장. 사용하지 않는 표현: 휴가 모드, 방학 중 |
| **휴강** | Lesson Cancellation | 잡힌 레슨을 안 함 + 보상 발생 (보강 크레딧/무료/이월). 변경권 미차감. |
| 스케줄 예외 | Schedule Exception | 휴무/휴가/추가 슬롯 |
| 레슨 1회 시간 | Lesson Duration | 슬롯 길이 사용자 표시명. 한국 음악 레슨 표준 50분 |
| 쉬는 시간 | Break Time | 레슨 간 쉬는 시간 사용자 표시명. 표준 10분 |

## 9. 연습 (Practice)

| 한글 | 영문 | 설명 |
|------|------|------|
| 연습 로그 | Practice Log | 일별 연습 기록 |
| 레퍼토리 | Repertoire | 연습 곡 목록 |
| 녹음 | Recording | 연습 녹음 파일 |

## 10. 알림 (Notification)

| 한글 | 영문 | 설명 |
|------|------|------|
| 알림 | Notification | 인앱/푸시 알림 |
| 알림톡 | AlimTalk | 카카오톡 비즈 알림 메시지. LNZ_INVOICE / LNZ_PAYMENT_REMINDER_D1/D3/D7 / LNZ_PAYMENT_CONFIRM / LNZ_TEACHER_VACATION |
| 만료 알림 설정 | Expiry Reminder Settings | D-14/D-7/D-1/D-0 토글 |

---

## 11. 학원 (Academy) — AC-M1 그룹 A (2026-06-04)

> 상세: `.harness/knowledge/glossary.md §12`. 본 섹션은 관계/역할 중심 요약.

| 용어 (한글) | 영문 | 정의 |
|------|------|------|
| 학원 | Academy | 학원 1개 (slug + 이름 + 사업자번호 + 학원장). 공개 페이지 URL `academy.lessonaza.app/{slug}` |
| 학원장 | Academy Owner | 학원 소유자. role=owner. 학원 전체 운영 권한 |
| 학원 강사 | Academy Teacher | 학원 소속 강사. role=teacher. 본인 담당 학생만 |
| 학원 학생 | Academy Student | 학원이 등록한 학생. 5상태 (등록대기/매칭/정규/일시중단/퇴원) |
| 강사 초대 | Academy Invite | 학원장이 강사를 부르는 토큰 (이메일/카톡으로 공유). 만료 + 일회용 |
| 학원 슬러그 | Academy Slug | URL 식별자 (예: `jaepark-music`) |
| 학원장 겸직 강사 | Owner-Teacher | 학원장 본인이 학생도 가르치는 경우. 같은 user 가 owner+teacher 행 2개 |
| 수습 강사 | Onboarding Teacher | onboarding_until 기한 동안 학생 매칭 제한 + 학원장 사전 감독 |
| 신뢰 위임자 (매니저) | Trusted Substitute | 학원장 부재 시 영구 위임 패턴 가능한 강사 |
| 학원 멤버 권한 차단 | Member Access Revoked | 퇴직/해고 처리. 행 보존 + 접근만 차단 |
| 컨텍스트 토글 | Context Switch | 학원장 ↔ 강사 모드 전환. ContextSwitchLog 영구 audit |
| 임시 권한 위임 | Temporary Delegation | 학원장 부재 시 부분 권한 위임. 시간 제한 + 동시 1개 |
| 위임 액션 감사 | Delegation Action Audit | 위임 기간 동안 delegatee 액션 1건 = 1 행. 학원장 사후 검토 |
| 학원 활동 타임라인 | Academy Activity Log | 강사 액션 사후 가시성. actor_name 스냅샷 (퇴직 후 보존) |
| 학원장 자동 복귀 감지 | Owner Auto Return | 학원장 콘솔 로그인 → 활성 위임 자동 종료 |

---

## 12. 퀘스트 시스템 (Quest System) — 2026-06-08

선생님 학습 가이드 + 단축 진입점. **의무 아님** — 점수가 아닌 행동 격려.

| 한글 | 영문 | 설명 |
|------|------|------|
| 퀘스트 | Quest | 선생님 학습 가이드 + 단축 진입점. 11 항목 (Q1~Q11) |
| 프로필 설정 그룹 | Profile Setup Group | Q1~Q5 (가용시간/사진/소개/레슨비/계좌) |
| 운영 시작 그룹 | Operation Group | Q6~Q10 (학생/수강권/레슨/노트/숙제) |
| 선택 보너스 그룹 | Bonus Group | Q11 (전화인증) — `[선택]` 라벨 + 점선 카드 |
| 자동 완료 트리거 | Auto-Complete Trigger | 입력 즉시 퀘스트 완료 감지 + 카드 즉시 소거 |
| 퀘스트 축하 카드 | Quest Celebration Card | 11/11 완료 시 1회 표시. `User.questCelebratedAt` 으로 1회성 보장 |
| 가입 직후 첫 도착 | Signup First Arrival | 가입 직후 1회만 카드 2초 표시 (5분 윈도우, SharedPreferences) |
| Lock 매트릭스 | Lock Matrix | Q6(학생 등록) → {Q7, Q8, Q9, Q10} 잠금 해제 트리거 |

**SSOT 정렬**: 가용시간은 `TeacherAvailability` (schedule 도메인) 단일.

---

## 13. 학생 게이미피케이션 (자가 연습) — 2026-06-11

학생 자가 연습 80% 비중을 가시화. **선생님 퀘스트(§12)와 별 시스템** — 학생용은 자가 결정 목표 추적.

| 한글 | 영문 | 설명 |
|------|------|------|
| 학생 자가 quest | StudentQuest | 학생이 작성/채택한 연습 목표 (선생님 quest 와 별도) |
| Quest 출처 | QuestOrigin | 자가 quest 출처 6종 — 자작/시스템 루틴/레슨 추출/선생님 추천/시즌 이벤트/주변 |
| 성장 히트맵 | GrowthHeatmap | 1년 캘린더 연습 시각화 (Strava 모델) |
| 일일 연습 기록 | DailyPractice | 메트로놈/튜너/YouTube/녹음/수동 5경로 통합 분 단위 |
| [연습 시작] 1버튼 | Practice Start | 학생 홈의 단일 진입점 — 1탭으로 연습 모드 진입 |
| 1.5초 축하 | Celebration Overlay | 연습 종료 후 비방해 축하 피드백 |
| 자가 연습 전용 모드 | Self-Only Mode | 14세 미만 부모 동의 미수신 학생 — 비교 보기·리더보드 차단 |
| 스트릭 동결 | StreakFreeze | 결석일에 자동 적용되어 streak 유지. Sunday 00:00 KST 자동 +2 (max 4). 시험 모드 활성 시 차감 0 |
| 1년 히트맵 | Year Heatmap | GitHub contribution graph 스타일 7×52 그리드. 5단계 색 농도 + 색맹 친화 패턴 |
| 트로피 모음 | Trophy Collection | 학생 성장 마커 단일 카드 (badge 재사용). 카테고리 분류 노출 X |
| 휴식 권고 | Rest Recommendation | 단일 세션 30분 / 일일 누적 3시간 / 14세 미만 15분 도달 시 푸시 X 토스트 1회 (SC-11) |
| 시험 모드 | Exam Mode | 학부모·선생님 발급. 모드 활성 동안 freeze 차감 0 + 스트릭 동결 |
| 복귀 보너스 | Comeback Bonus | 7일+ 미사용 후 복귀 시 첫 세션 보너스 P. FOMO 메시지 X |
| 스포트라이트 프롬프트 | SpotlightPrompt | 학생에게 가끔 보여지는 권유 1슬롯. 축하 overlay 안 1슬롯 (스펙 §6.2) |
| 스포트라이트 종류 | SpotlightType | 3종 — 선생님 추천(teacherRec) / 시즌·명절(seasonEvent) / 자가 routine 30일+(routineSuggestion) |
| 스포트라이트 슬롯 | SpotlightSlot | 축하 overlay 내부 1슬롯 UI. "지금 볼래" / "다음에" 동일 비중 (스펙 §7.4) |
| 노출 조건 | Spotlight Eligibility | 6 조건 (5분 세션 + 오늘 첫 prompt + 주간 ≤ 2 + 큐 promptable + 14세 미만 동의) 모두 통과 시 노출 (스펙 §7.1) |
| 큐 우선순위 | Spotlight Queue Priority | 4단계 — 선생님 필수 → 일반 추천 → 시즌 → routine. 같은 type oldest queuedAt 우선 (스펙 §7.2) |
| 거절 학습 | Decline Learning | "다음에" 1회 → 7일 cooldown. 5회 누적 → 8주 hide. 8주 후 1회 재시도 또 거절 → 영구 hide (스펙 §7.3 / SC-9) |

> 상세: [학생 게이미피케이션 스펙](../../.harness/spec/2026-06-11-student-gamification.md) (P1+P2 머지 + P3 진행)

---

## 14. 프로필 5묶음 IA (Teacher Settings Redesign) — 2026-06-12

선생님 프로필 탭 11개 메뉴를 5묶음 카테고리 IA 로 통합. **`profile_master.md §2.1` 채택**.

| 한글 | 영문 | 정의 | 사용 금지 표현 |
|------|------|------|---------------|
| 운영시간 | Operating Hours | 선생님이 가르치는 요일별 시간대 + 쉬는시간 + 휴무 + 휴가. `TeacherAvailability` 엔티티 단일 SSOT | 가용시간, 가용 슬롯, available slot, 레슨 시간 설정 |
| 수업방식 | Lesson Style | 레슨 1회 시간 + 사전예약 규칙 + 학생 안내 메시지. `TeacherSettings.lesson*` 필드 | 수업설정, 레슨방식, 수업 옵션 |
| 수강권·정산 | Subscription & Billing | 수강권 템플릿 + 가격표 + 시험레슨 정책 + 계좌. 5묶음 §8 BottomSheet 진입 | 결제 (개별 용어는 OK), 빌링 |
| lessonDurationMinutes | — | 레슨 1회 시간 (분). 기본값 50. `TeacherSettings` 필드 | defaultLessonDuration, slotDurationMinutes |
| 카테고리 미리보기 | Category Preview | 가입 직후 Step 2.5 (`OnboardingCategoryPreviewScreen`) — 5묶음 인지 1회 화면. W6 에서 기존 가입자 마이그레이션 overlay 로 재활용 | 카테고리 가이드, 5묶음 가이드 |
| 퀘스트 졸업 | Quest Graduation | Q1~Q10 100% 완료 시점 (`User.quest_celebrated_at`) + 7일 grace (`kQuestGraduationGrace`) 후 메인에서 hide. "⚙️ 정책·알림·지원 → 가이드 다시 보기" 로 재노출 | 퀘스트 완료 (개별 quest 완료와 구분), 퀘스트 dismiss |

**관련 스펙**: [profile_master.md §2.1](profile/profile_master.md), [availability_settings_ux_redesign_spec.md](schedule/availability_settings_ux_redesign_spec.md), [teacher_quest_audit_2026-06-08.md §6~§7](design/teacher_quest_audit_2026-06-08.md), [teacher_first_availability_setup.md §3.3](onboarding/teacher_first_availability_setup.md).

> 상세 (FE 클래스 매핑 포함): `.harness/knowledge/glossary.md §14`.

---

## UX 용어 통일 — 2026/06/17 검토 반영

> 사용자 검토 기반 화면 라벨 통일. 도메인 개념은 그대로, 표시 라벨만 정규화.

| 개념 | 정규 라벨 | 사용하지 않는 표현 |
|------|-----------|--------------------|
| 일정 협상 상태 | 시간 조율 중 / 시간 조율 중 (N회차) | 시간협상, 시간조율 |
| 다른 시간 제안 | 다른 시간 제안하기 | 일정 비교, 다른 일정 제안, 다른 시간 제안 |
| 레슨 보관 | 보관함으로 이동 | 보관, 레슨 보관 |
| 레슨 편집 | 전체 수정(수기) / 곡·메모 수정(수강권) | 편집 (수기), 내용 수정 |
| 수업방식 카드 | 레슨·예약 규칙 | 수업방식 |
| 알림 카테고리(시간 변경) | 시간 변경 요청 | 스케줄 변경(알림 한정) |
| 운영시간 | 운영시간 | 레슨 운영 시간 |
| 앱 공지 | 앱 업데이트 안내 | 새 소식과 로드맵 |

## 용어 변경 이력

| 날짜 | 기존 용어 | 신규 용어 | 이유 |
|------|----------|----------|------|
| 2026-06-17 | 입금대기(후불) / 입금 대기 | 미수금 (후불) / 입금 확인 대기 (선불) | 검토 #50 입금 용어 분리 — 후불 미수 채권 vs 선불 입금 안내 후 확인 대기 혼동 해소 + 미수금 금액 반올림 제거(만/원 정확). 표시명·glossary만, enum 불변 (.harness/knowledge/glossary.md SSOT 동기화) |
| 2026-06-17 | 학생 정규 / 연습 휴강 | 학생 수강중 / 연습 기록없음 | 검토 #26 상태 어휘 SSOT — '휴강' overload(학생 paused vs 연습 무기록) 분리. 표시명만, enum 값·Membership/학생 휴강 불변 (.harness/knowledge/glossary.md 동기화) |
| 2026-06-17 | 쉬는날 / 방학 중 / 휴가 모드 | 휴무 / 휴가 / 휴강 (3 SSOT) | 검토 #14 "안 하는 날" 6용어 혼용 해소 — 표시명·glossary만, 코드 식별자 불변 (.harness/knowledge/glossary.md SSOT 동기화) |
| 2026-06-12 | — | §13 학생 게이미피케이션 P3 — 스포트라이트 프롬프트 / 스포트라이트 종류 (3) / 스포트라이트 슬롯 / 노출 조건 / 큐 우선순위 / 거절 학습 | P3 Spotlight 진입 — SC-9 거절 5회 → 8주 hide 충족 + SpotlightPrompt 신규 엔티티 (.harness/knowledge/glossary.md §15 P3 동기화) |
| 2026-06-12 | — | §13 학생 게이미피케이션 P2 — 스트릭 동결 / 1년 히트맵 / 트로피 모음 / 휴식 권고 / 시험 모드 / 복귀 보너스 | P2 Visual Growth 진입 — SC-10/SC-11 충족 + GrowthHeatmap 1년 캐시 (.harness/knowledge/glossary.md §15 P2 동기화) |
| 2026-06-12 | 가용시간 (메뉴 라벨), 레슨 시간 설정 (메뉴 라벨) | §14 프로필 5묶음 IA — 운영시간 / 수업방식 / 수강권·정산 / lessonDurationMinutes / 카테고리 미리보기 / 퀘스트 졸업 | teacher-settings-redesign 머지 — 11개 메뉴 → 5묶음 IA 통합 + 졸업 메커니즘 (.harness glossary §14 동기화) |
| 2026-06-11 | — | §13 학생 게이미피케이션 — StudentQuest / QuestOrigin / GrowthHeatmap / DailyPractice + [연습 시작] 1버튼 / 1.5초 축하 / 자가 연습 전용 모드 (14세 미만) | 학생 자가 연습 80% 가시화 (.harness/knowledge/glossary.md §15 동기화) |
| 2026-06-08 | — | §12 퀘스트 시스템 — 3 그룹 (profile/operation/bonus) + Lock 매트릭스 + 자동 완료 + 축하 카드 (1회성) + 가입 직후 첫 도착 | 선생님 퀘스트 재정의 (.harness/knowledge/glossary.md §13 동기화) |
| 2026-06-04 | — | ContextSwitchLog / AcademyDelegation / AcademyDelegationAction / AcademyActivityLog + 5 enum + 권한 계층 정책 5종 | AC-M1 그룹 B BE 권한 계층 (.harness glossary §12 동기화) |
| 2026-06-04 | — | Academy / AcademyMember / AcademyStudent / AcademyInvite + 3 enum + 정책 용어 | AC-M1 그룹 A BE 도메인 모델링 (.harness glossary §12 동기화) |
| 2026-06-01 | ConnectionStatus | RelationshipStatus.invitePending 통합 | E2E 감사: 초대·관계 이중 상태 충돌 해소 (D-G3) |
| 2026-06-01 | — | 휴가 모드, 알림톡, 입금 대기/추적/되돌리기, 수강권 자동 연장, 스케줄된 회차, 보강 크레딧, 초대 코드, 첫 가용시간, 인증 선생님 배지, 레슨 1회 시간, 쉬는 시간 | E2E 감사 Top 10 반영 (.harness/knowledge/glossary.md SSOT 동기화) |
| 2026-05-07 | 체험레슨 수강권 "불필요" | 체험레슨 수강권 **"필수"** (유료 기본, 무료 선택) | 실제 운영: 체험도 유료가 대부분이므로 수강권+변경권 정책 동일 적용 |
| 2026-05-07 | — | 온보딩 퀘스트 v2 용어 6개 추가 | .harness glossary 동기화 |
| 2026-05-04 | — | 수강권/스케줄/연습/알림 도메인 추가 | .harness glossary 동기화 |
| 2026-01-30 | 맞팔 | 수강권 기반 관계 | 레슨 도메인에 맞는 용어로 변경 |
| 2026-01-30 | 맞팔 (소식용) | 팔로우/소식 구독 | 기능 명확화 |
| 2026-01-30 | 연결하기 버튼 | 자동 연결 | 제로 탭 UX 반영 |

---

## 관련 문서

| 문서 | 설명 |
|------|------|
| [.harness/knowledge/glossary.md](../../.harness/knowledge/glossary.md) | **SSOT** — 전 도메인 용어 + FE-BE 클래스 매핑 |
| [subscription_based_relationship.md](./lesson/invite/subscription_based_relationship.md) | 수강권 중심 관계 모델 상세 |
| [invite_system_v2.md](./lesson/invite/invite_system_v2.md) | 초대/연결 시스템 |
| [ux_guidelines.md](./design/ux_guidelines.md) | UX 가이드라인 |
