# 유비쿼터스 언어 (Ubiquitous Language)

> 최종 업데이트: 2026-05-10
> 원본: `docs/specs/glossary.md` (관계/역할/UX 용어)
> 본 문서: 전 도메인 통합 + FE-BE 명칭 매핑 + 코드 심볼 기준

## 원칙

- **하나의 개념 = 하나의 이름**: 코드·스펙·UI·대화에서 같은 단어를 사용한다.
- **FE-BE 동일 원칙**: 프론트/백엔드 클래스명이 다르면 이 문서에 매핑을 명시하고, 신규 엔티티는 동일 이름을 사용한다.
- **스펙에서 코드로**: 스펙 작성 시 이 glossary의 용어를 사용한다. glossary에 없는 용어가 필요하면 먼저 이 문서에 추가한 후 스펙/코드에 사용한다.

---

## 1. 역할 (Roles)

| 한글 | 영문 | FE 클래스 | BE 클래스 | 설명 |
|------|------|-----------|-----------|------|
| 선생님 | Teacher | `Teacher` | `Teacher` | 레슨 제공자 |
| 학생 | Student | `Student` | `Student` | 레슨 수강자 |
| 학부모 | Parent | `Parent` | `Parent` | 자녀(학생) 대리 관리자 |
| 사용자 | User | `AuthUser` | `User` | ⚠️ FE-BE 불일치. 인증된 사용자 엔티티 |

---

## 2. 레슨 (Lesson)

| 한글 | 영문 | FE 클래스 | BE 클래스 | 설명 |
|------|------|-----------|-----------|------|
| 레슨 | Lesson | `Lesson` | `Lesson` | 1회 수업 기록 |
| 체험 레슨 | Trial Lesson | `LessonBooking(type: trial)` | `LessonBooking(lesson_type: trial)` | 정규 등록 전 시험 레슨. **수강권 필수** (유료 기본, 선생님 설정으로 무료 전환 가능). 변경/취소 정책 동일 적용 |
| 정기 레슨 | Regular Lesson | `LessonBooking(type: regular)` | `LessonBooking(lesson_type: regular)` | 수강권 기반 정기 수업 |
| 보강 레슨 | Makeup Lesson | `LessonBooking(type: makeup)` | `LessonBooking(lesson_type: makeup)` | 노쇼/취소 보충 |
| 레슨 노트 | Lesson Note | `Lesson.teacherNotes` | `Lesson.teacher_notes` | 선생님 수업 기록 |
| 곡 | Piece | `LessonPiece` | `LessonPiece` | 레슨에서 다루는 곡 |

---

## 3. 스케줄 (Schedule)

| 한글 | 영문 | FE 클래스 | BE 클래스 | 설명 |
|------|------|-----------|-----------|------|
| 레슨 요청 | Lesson Request | `UnifiedLessonRequest` | `LessonRequest` | ⚠️ FE-BE 불일치. 학생→선생님 레슨 신청 |
| 요청 상태 | Request Status | `UnifiedRequestStatus` | `RequestStatus` | ⚠️ FE-BE 불일치. 요청 라이프사이클 상태 |
| 요청 이벤트 | Request Event | `RequestEvent` | `RequestEvent` | 요청 히스토리 (챗 메시지) |
| 예약 | Booking | `LessonBooking` | `LessonBooking` | 확정된 레슨 일정 |
| 예약 상태 | Booking Status | `BookingStatus` | `BookingStatus` | pending/confirmed/cancelled 등 7값 |
| 가용시간 | Availability | `TeacherAvailability` | `TeacherAvailability` | 선생님 예약 가능 시간대 |
| 스케줄 예외 | Schedule Exception | `TimeException` | `ScheduleException` | ⚠️ FE-BE 불일치. 휴무/휴가/추가 슬롯 |
| 스케줄 변경 | Schedule Change | `ScheduleChange` | `LessonScheduleChange` | 레슨 일정 변경 요청 |
| 스케줄 확정 카드 | Confirmation Card | `ScheduleConfirmationCard` | `ScheduleConfirmationCard` | 수강권 발급 후 스케줄 확정 UI |
| 휴가 모드 | Vacation Mode | `TeacherAvailability.vacationPeriods` | `vacation_periods` | 선생님 휴가 기간 일괄 등록 → 영향 레슨 일괄 처리 (취소·보강·이월) |
| 레슨 1회 시간 | Lesson Duration | `slotDurationMinutes` | `slot_duration_minutes` | 사용자 표시명. 한국 음악 레슨 표준 50분 |
| 쉬는 시간 | Break Time | `breakTimeBetweenLessons` | `break_time_between_lessons` | 사용자 표시명. 표준 10분 |

---

## 4. 수강권 (Subscription)

| 한글 | 영문 | FE 클래스 | BE 클래스 | 설명 |
|------|------|-----------|-----------|------|
| 수강권 | Subscription | `Subscription` | `Subscription` | 레슨 횟수/기간 권리 |
| 수강권 제안 | Proposal | `SubscriptionProposal` | `SubscriptionProposal` | 선생님→학생 수강권 제안 |
| 수강권 템플릿 | Template | `SubscriptionTemplate` | `SubscriptionTemplate` | 미리 설정한 수강권 상품 |
| 수강권 상태 | Subscription Status | `SubscriptionStatus` | `SubscriptionStatus` | active/expiringSoon/expired/paused |
| 입금 상태 | Payment Status | `paymentConfirmed` | `payment_confirmed` | 외부 입금 확인 여부 (앱 내 결제 아님) |
| 입금 대기 | Payment Pending | `PaymentPendingCard` | (집계) | 입금 확인 전 수강권 제안 상태 (`paymentRequested`) 집계. 선생님 홈 상단 카드로 노출 |
| 입금 추적 | Payment Tracking | `PaymentTrackingService` | `PaymentTrackingService` | D+1/3/7 자동 리마인드 시스템. 학생·선생님 양측 발송 |
| 입금 확인 되돌리기 | Confirm Payment Undo | `undoConfirmPayment` | `undo_confirm_payment` | 입금 확인 후 24시간 내 취소 가능. 첫 레슨 차감 발생 시 불가 |
| 수강권 자동 연장 | Auto-Extension | `Subscription.autoExtendedDays` | `auto_extended_days` | 선생님 휴가 모드 등록 시 휴가 일수만큼 만료일 자동 연장 |
| 스케줄된 회차 | Scheduled Lessons | `Subscription.scheduledLessons` | `scheduled_lessons` | 실제 잡힌 레슨 수. `remainingLessons` 와 별개 트랙 |
| 보강 크레딧 | Makeup Credit | `MakeupCredit` | `MakeupCredit` | 별도 엔티티. 휴가·노쇼 면제·일괄변경 손실 회차 적립. 30일 만료 |

---

## 5. 연습 (Practice)

| 한글 | 영문 | FE 클래스 | BE 클래스 | 설명 |
|------|------|-----------|-----------|------|
| 연습 로그 | Practice Log | `PracticeLog` | `PracticeLog` | 일별 연습 기록 |
| 레퍼토리 | Repertoire | `PracticeRepertoire` | — | 연습 곡 목록 (FE Hive only) |
| 녹음 | Recording | `Recording` | `Recording` | 연습 녹음 파일 |

---

## 6. 관계/연결 (Relationship)

| 한글 | 영문 | FE 클래스 | BE 클래스 | 설명 |
|------|------|-----------|-----------|------|
| 연결 | Connection | `Relationship` | `Relationship` | 선생님-학생 관계 |
| 관계 상태 | Relationship Status | `RelationshipStatus` | `RelationStatus` | ⚠️ FE-BE 불일치. **레슨 관계 SSOT**. ConnectionStatus는 deprecate 예정 |
| 초대 코드 | Invite Code | `InviteCode` | `InviteCode` | 학생 초대용 6자리 코드 + QR + URL. 만료 7일 |
| 초대 대기 | Invite Pending | `RelationshipStatus.invitePending` | `invite_pending` | 초대 전송 후 학생 미진입 상태. 학생 리스트에서 별도 그룹 표시 |
| 팔로우 | Follow | `Follow` | `Follow` | 소식 구독 (레슨 무관) |
| 학급 | Class | `LessonClass` | `LessonClass` | 선생님의 레슨 그룹 |
| 소속 | Membership | `ClassMembership` | `ClassMembership` | 학생의 학급 소속 |

---

## 7. 알림 (Notification)

| 한글 | 영문 | FE 클래스 | BE 클래스 | 설명 |
|------|------|-----------|-----------|------|
| 알림 | Notification | `AppNotification` | `Notification` | ⚠️ FE-BE 불일치. 인앱/푸시 알림 |
| 알림톡 | AlimTalk | `AlimTalkService` | `AlimTalkService` | 카카오톡 비즈 알림 메시지. LNZ_INVOICE / LNZ_PAYMENT_REMINDER_D1/D3/D7 / LNZ_PAYMENT_CONFIRM / LNZ_TEACHER_VACATION |
| 발신 프로필 | Sender Profile | `AlimTalkSenderProfile` | `sender_profile` | 카카오 알림톡 발신 식별자. 본 앱 단일 프로필 사용 |
| 만료 알림 설정 | Expiry Reminder Settings | `SubscriptionExpiryReminderSettings` | `SubscriptionSettings.renewal_alert_days_set` | D-14/D-7/D-1/D-0 토글 |
| 선생님 휴강 이벤트 | Lesson Cancelled By Teacher | `RequestEventType.lessonCancelledByTeacher` | `lessonCancelledByTeacher` | 선생님 사유 휴강 → 수강권 챗에 이벤트 기록 (변경권 미차감) |
| 선생님 공지 이벤트 | Teacher Announcement | `RequestEventType.teacherAnnouncement` | `teacherAnnouncement` | 선생님 일괄 메시지 → 수강권 챗에 공지 기록 |
| 이동시간 | Travel Time | `ClassMembership.travelTimeMinutes` | `travel_time_minutes` | 선생님→학생 이동 소요시간 (분). 스케줄 버퍼 계산에 사용 |
| 이동시간 자동 측정 | Travel Time Estimate | `TravelTimeApi.estimate()` | `GET /travel-time/estimate` | 카카오/네이버/구글 API 기반 출발지-도착지 이동시간 자동 측정. 실패 시 수기 입력 |
| 이동 추가금 | Travel Surcharge | `Subscription.travelSurcharge` | `travel_surcharge` | 이동시간 기반 참고용 추가금. 최종 금액은 선생님이 결정 |

---

## 8. UX 용어

| 한글 | 영문 | 설명 |
|------|------|------|
| 제로 탭 | Zero Tap | 추가 버튼 없이 동작 완료 (QR 스캔 = 연결) |
| 원클릭 | One Click | 한 번 탭으로 동작 완료 |
| 원샷 UX | One-Shot UX | 한 번 탭으로 모든 연관 작업 완료 |
| 노트북 | Notebook | 디자인 시스템 메타포 (종이+잉크+연필) |
| 퀘스트 | Quest | 온보딩 미션. 실제 앱 사용 행동을 유도하는 진행형 과제 |
| 퀘스트 보드 | Quest Board | 홈 화면의 퀘스트 진행 카드 (Getting Started Card v2) |
| 코치마크 | Coach Mark | 화면 오버레이로 특정 UI 요소를 하이라이트하며 안내하는 UI 패턴 |
| 워크스루 | Walkthrough | 인터랙티브 온보딩 — 실제 화면에서 직접 탭하며 배우는 체험 |
| 셀레브레이션 | Celebration | 퀘스트 완료 시 축하 피드백 (애니메이션 + 메시지) |
| 프로필 완성도 | Profile Completeness | 프로필 입력 항목 기반 0-100% 게이지. `canBeSearched` 60% 임계값 게이지에 표시 |
| 첫 가용시간 | Initial Availability | 온보딩 중 강제 설정하는 최소 가용시간 (요일 다중선택 + 시작/종료시각 1쌍, 50분 기본). 풀 설정은 나중에 |
| 인증 선생님 배지 | Verified Teacher Badge | 전화번호 인증 완료 시 부여. 학부모 측 신뢰 표시. 첫 수강권 발급 전 인증 필요 |

---

## 9. FE-BE 불일치 요약

> 아래는 역사적 이유로 이름이 다른 것. **신규 엔티티는 반드시 동일 이름 사용.**

| 개념 | Frontend | Backend | 통일 방향 |
|------|----------|---------|----------|
| 사용자 | `AuthUser` | `User` | FE 사정 (Flutter Auth 충돌 회피) — 유지 |
| 알림 | `AppNotification` | `Notification` | FE 사정 (dart:html 충돌 회피) — 유지 |
| 관계 상태 | `RelationshipStatus` | `RelationStatus` | BE rename 권장 → `RelationshipStatus`. 본 SSOT는 FE `RelationshipStatus` |
| ConnectionStatus | (deprecate 예정) | (deprecate 예정) | 초대·연결 상태는 `RelationshipStatus.invitePending` 으로 통합. 점진적 제거 |
| 레슨 요청 | `UnifiedLessonRequest` | `LessonRequest` | FE가 여러 소스 통합 — 유지 |
| 요청 상태 | `UnifiedRequestStatus` | `RequestStatus` | 동일 사유 — 유지 |
| 스케줄 예외 | `TimeException` | `ScheduleException` | BE 이름이 정확 — FE rename 권장 |

---

## 10. 앱 릴리즈 / 신뢰 구축 (App Release / Trust)

| 한글 | 영문 | FE 클래스 | BE 클래스 | 설명 |
|------|------|-----------|-----------|------|
| 앱 버전 스냅샷 | AppVersionSnapshot | `AppVersionSnapshot` | — | 현재/최신/빌드 버전 정보 |
| 새 소식 | AppNewsItem | `AppNewsItem` | `AppNewsItem` | 변경 로그 항목 |
| 로드맵 항목 | AppRoadmapItem | `AppRoadmapItem` | `AppRoadmapItem` | 개발 예정/진행중/완료 기능 |
| 릴리즈 스냅샷 | AppReleaseSnapshot | `AppReleaseSnapshot` | — | 버전 + 뉴스 + 로드맵 통합 응답 |
| 리뷰 상태 | AppReviewState | `AppReviewState` | — | 리뷰 프롬프트 이력 (Hive 로컬 저장) |
| 로드맵 상태 | AppRoadmapStatus | `AppRoadmapStatus` | — | planned / inProgress / shipped |

---

## 11. 코드 반영 신규 용어 (2026-06-03)

> 코드↔스펙 드리프트 동기화에서 식별된, 코드에는 존재하나 glossary에 미등록이던 FE 엔티티/enum. 각 도메인 마스터 스펙에 본문 반영 완료. (BE 매핑은 백엔드 구현 시 확정)

### 수강권/결제 (Subscription/Billing)
| 용어 | 영문(FE) | 값 / 구성 |
|------|----------|-----------|
| 앱 빌링 스냅샷 | `AppBillingSnapshot` | 현재 플랜·상태 집계 |
| 빌링 플랜 | `BillingPlan` | free / pro / studio / lifetime |
| 빌링 상태 | `BillingStatus` | active / trial / expired / cancelled |
| 빌링 가드 | `BillingGuard` | 학생 한도/만료 차단 판정 (`StudentLimitDecision`, `LimitReason`) |
| IAP 서비스 | `IapService` / `StoreKitIapService` | 인앱결제 래퍼 (`IapPurchaseOutcome` sealed) |
| IAP 검증 결과 | `IapValidationResult` | 영수증 검증 결과 |
| 체험 활성화 결과 | `TrialActivationResult` | 14일 Pro 체험 시작 결과 |
| 보강 크레딧 잔액 | `MakeupCreditBalance` | 사용 가능 크레딧 집계 (만료순 정렬) |

### 스케줄 (Schedule)
| 용어 | 영문(FE) | 값 / 구성 |
|------|----------|-----------|
| 휴가 처리 방식 | `VacationDisposition` | makeupCredit / freeCancel / rollForward |
| 휴가 영향 미리보기 | `VacationImpactPreview` | 영향 레슨/학생 집계 (`VacationImpactedStudent`) |
| 요청 필터 | `RequestFilter` | 요청 목록 필터/정렬 (FE 전용) |
| 요청 단계 | `RequestPhase` | request / subscription / lessons / completed / terminal |
| 요청 상태 그룹 | `RequestStatusGroup` | 상태 묶음 (목록 그룹핑) |

### 레슨/관계 (Lesson/Relationship)
| 용어 | 영문(FE) | 값 / 구성 |
|------|----------|-----------|
| 레슨 공개 범위 | `LessonVisibility` | academyFull / academyBusyOnly |
| 일정 편성 방식 | `ScheduleType` | fixed / flexible |
| 학습 목표 | `LessonGoal` | hobby / exam / major |
| 경험 수준 | `ExperienceLevel` | none / beginner / some / experienced |
| 피드백 프리셋 | `FeedbackPreset` | 일괄 피드백 템플릿 (활성) |
| 관계 상태 | `RelationshipStatus` | trialBooked / active / expired / past (기존 본문 pending/active/inactive/blocked 오기재 정정) |

### 연습/게이미피케이션/소식 (Practice/Gamification/Follow)
| 용어 | 영문(FE) | 값 / 구성 |
|------|----------|-----------|
| 노트 열람 요청 | `NoteAccessRequest` / `NoteAccessStatus` | requested / consented / rejected / revoked |
| 피치 분석 결과 | `PitchAnalysisResult` | 음정 분석 (S~D 등급) |
| 도전 과제 유형/주기 | `ChallengeType` / `ChallengePeriod` | 챌린지 분류 |
| 랭킹 티어 | `RankingTier` | 주간 랭킹 등급 |
| 콤보 티어 | `ComboTier` | 튜너 콤보 5단계 (`ComboState`) |
| 판정 결과 | `JudgementResult` | 튜너 음정 판정 |
| 선생님 게시물 | `TeacherPost` / `PostType` | performance / event / notice (소식 피드) |

---

## 12. 학원 (Academy) — AC-M1 그룹 A (2026-06-04)

> 코드: `backend/app/models/academy.py` + `frontend/lib/features/academy/`
> 스펙 SSOT: `docs/specs/web/academy/` (콘솔/정책) + `docs/specs/academy/academy_master.md` (앱 FE)

### 핵심 엔티티 (BE ↔ FE 동일 클래스명)

| 용어 (한글) | 클래스 (BE+FE) | 정의 |
|------|----------|------|
| 학원 | `Academy` | 학원 1개 (slug, name, owner_user_id, business_number). 1 학원 = 1 행 |
| 학원 소속 | `AcademyMember` | 학원장 또는 강사. (academy_id, user_id, role) 조합. 한 user 가 같은 학원에서 owner+teacher 겸직 시 행 2개 |
| 학원 학생 | `AcademyStudent` | 학원이 등록한 학생. lesson-app User 와 연결 nullable (학원만 등록한 학생 케이스 지원) |
| 강사 초대 | `AcademyInvite` | 토큰 기반 강사 초대. `token_hash` 저장 (raw 발급 시 1회만 노출) |

### Enum

| 용어 | Enum 클래스 | 값 |
|------|-----------|-----|
| 학원 멤버 역할 | `AcademyMemberRole` | `owner` (학원장), `teacher` (강사) |
| 학원 학생 상태 | `AcademyStudentStatus` | `waiting` 등록대기 / `matched` 강사매칭 / `active` 정규수업 / `paused` 일시중단 / `alumni` 퇴원 |
| 초대 상태 | `AcademyInviteState` | `pending` / `accepted` / `declined` / `expired` / `revoked` |

### 정책 용어

| 용어 | 의미 |
|---|---|
| 공개 페이지 노출 동의 | `AcademyMember.public_page_consent` — 강사가 본인 학원 공개 페이지 노출 동의. 기본 false |
| 수습 강사 onboarding | `AcademyMember.onboarding_until` — 기한 동안 학생 매칭 제한 + activity 추가 표식 |
| 강사 권한 차단 | `AcademyMember.access_revoked_at` — 퇴직 처리. 행 삭제 X, audit 보존 |
| 신뢰 위임자 (매니저) | `AcademyMember.delegate_role` — `trusted_substitute` 패턴 (영구 위임 옵션) |
| 학원 슬러그 | `Academy.slug` — 공개 페이지 URL 식별자 (`academy.lessonaza.app/{slug}`) |
| 입금자 매칭 메모 코드 | `AcademyStudent.deposit_code` — 무통장입금 fuzzy 매칭 보조 신호 (payment_matching_spec §3.5) |

### UX 1탭 onboarding

`AcademyCreate.also_register_as_teacher=true` — 학원장이 학원 생성 시 본인을 강사로도 자동 등록 (소규모 음악학원 흔한 패턴). 두 멤버 행 자동 생성 (owner + teacher).

### 권한 계층 (AC-M1 그룹 B, 2026-06-04)

| 용어 (한글) | 클래스 (BE) | 정의 |
|------|----------|------|
| 컨텍스트 토글 감사 | `ContextSwitchLog` | 학원장↔강사 모드 전환 1건 = 1 행. 영구 보존 (분쟁 증거 + 노트 일시 접근 사전 검증) |
| 임시 권한 위임 | `AcademyDelegation` | 학원장 부재 시 부분 권한 위임. ends_at 필수 (영구 권한 금지). 한 학원당 동시 1개만 |
| 위임 액션 감사 | `AcademyDelegationAction` | 위임 활성 기간 동안 delegatee 가 수행한 액션 1건 = 1 행. 학원장 사후 검토 owner_reviewed_at |
| 학원 활동 타임라인 | `AcademyActivityLog` | 강사 액션 사후 가시성 (NFR-A-5). actor_name 직접 저장 (퇴직 후에도 audit 보존) |

| Enum 클래스 | 값 |
|-----------|-----|
| `AcademyContext` | `academy_owner` / `teacher` |
| `ContextSwitchTrigger` | `user` (명시 토글) / `session_resume` (4h 만료 후 복원) |
| `DelegationReason` | `trip` / `sick` / `vacation` / `event` / `other` |
| `DelegationState` | `scheduled` / `active` / `expired` / `revoked` / `auto_ended` |
| `DelegationRevokeReason` | `owner_returned` (자동 감지) / `owner_manual` / `expired` / `delegatee_declined` |

### 정책 용어 (그룹 B 추가)

| 용어 | 의미 |
|---|---|
| 학원장 자동 복귀 감지 | 학원장이 콘솔 로그인 시 활성 위임 자동 종료 (`revoked_reason=owner_returned`) |
| 명시 confirmation | 비밀번호 직접 검증 미지원(OAuth 기반) → `confirmation=true` 토글로 대체. 향후 PIN/SMS 도입 |
| 전체 승인 검토 | 학원장이 audit 행을 1탭으로 일괄 승인. 30일 후 자동 승인 (delegatee 보호) |
| 사후 가시성 | 강사 액션을 사전 승인 없이 진행 + 학원장이 timeline 으로 사후 확인 (무조건 위임 모델) |

---

## 변경 이력

| 날짜 | 변경 |
|------|------|
| 2026-06-04 | §12 학원(Academy) 권한 계층 (AC-M1 그룹 B) 추가 — ContextSwitchLog + AcademyDelegation + AcademyDelegationAction + AcademyActivityLog 4 엔티티 + 5 enum (AcademyContext/ContextSwitchTrigger/DelegationReason/DelegationState/DelegationRevokeReason) |
| 2026-06-04 | §12 학원(Academy) 도메인 신설 — AC-M1 그룹 A 4 엔티티 + 3 enum + 정책 용어 6종. 마일스톤: AC-M1 |
| 2026-06-03 | §11 코드 반영 신규 용어 — 코드↔스펙 드리프트 동기화로 식별된 FE 엔티티/enum 30여종 등록 (billing/schedule/lesson/relationship/practice/gamification/follow) |
| 2026-06-01 | E2E 감사 Top 10 반영 — 15용어 추가: 휴가 모드, 알림톡, 입금 대기/추적/되돌리기, 수강권 자동 연장, 스케줄된 회차, 보강 크레딧, 초대 코드/대기, 첫 가용시간, 인증 선생님 배지, 레슨 1회 시간, 쉬는 시간, 발신 프로필. ConnectionStatus deprecate 명시 |
| 2026-05-10 | §10 앱 릴리즈/신뢰 구축: AppVersionSnapshot, AppNewsItem, AppRoadmapItem, AppReleaseSnapshot, AppReviewState 추가 (R6) |
| 2026-05-07 | §7 알림: lessonCancelledByTeacher, teacherAnnouncement 이벤트 타입 추가 (일괄 작업 v2) |
| 2026-05-07 | §2 체험레슨: 수강권 필수 명시 (유료 기본, 무료 선택), 변경/취소 정책 동일 적용 |
| 2026-05-07 | §8 UX 용어: 퀘스트/코치마크/워크스루/셀레브레이션/프로필완성도 추가 (온보딩 v2) |
| 2026-05-04 | 초판 작성 — `docs/specs/glossary.md` 기반 + 전 도메인 확장 + FE-BE 매핑 |
