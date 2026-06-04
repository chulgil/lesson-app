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
| 입금 상태 | Payment Status | 외부 입금 확인 여부 (앱 내 결제 아님) |
| 입금 대기 | Payment Pending | 입금 확인 전 수강권 제안 상태 집계. 선생님 홈 상단 카드로 노출 |
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
| 휴가 모드 | Vacation Mode | 선생님 휴가 기간 일괄 등록 → 영향 레슨 일괄 처리 (취소·보강·이월) + 수강권 자동 연장 |
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

## 용어 변경 이력

| 날짜 | 기존 용어 | 신규 용어 | 이유 |
|------|----------|----------|------|
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
