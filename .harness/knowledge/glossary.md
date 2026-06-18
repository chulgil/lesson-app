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
| 레슨 요약 공유 | Lesson Summary Share | `LessonSummaryShare` / `lessonSummaryShareRepositoryProvider` | `ShareTokenService.issue_lesson_summary_share` | 교사가 레슨 상세에서 공개 요약 공유 토큰 발급(`POST /lesson-summaries/{id}/share`) → 학생 요약 랜딩(`StudentSummaryScreen`, `/student/summary/:token`) 연결. 서버가 URL·공유텍스트 생성, FE는 복사/공유만. #808 |

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
| **휴무** | Day Off | (표시명) | — | 선생님 비근무일 (1일 단위, 레슨 없음). `스케줄 예외`(`TimeException`/`ScheduleException`)로 표현. 사용하지 않는 표현: 쉬는날 |
| **휴가** | Vacation | `TeacherAvailability.vacationPeriods` | `vacation_periods` | 기간형 휴무 (다중일). 휴가 기간 일괄 등록 → 영향 레슨 일괄 처리 (취소·보강·이월) + 수강권 자동 연장. 사용하지 않는 표현: 휴가 모드, 방학 중 |
| **휴강** | Lesson Cancellation (by teacher) | `RequestEventType.lessonCancelledByTeacher` | `lessonCancelledByTeacher` | 잡힌 레슨을 안 함 + 보상 발생 (보강 크레딧/무료/이월). 변경권 미차감. cf. `선생님 휴강 이벤트` |
| 레슨 1회 시간 | Lesson Duration | `slotDurationMinutes` | `slot_duration_minutes` | 사용자 표시명. 한국 음악 레슨 표준 50분 |
| 쉬는 시간 | Break Time | `breakTimeBetweenLessons` | `break_time_between_lessons` | 사용자 표시명. 표준 10분 |

---

## 4. 수강권 (Subscription)

| 한글 | 영문 | FE 클래스 | BE 클래스 | 설명 |
|------|------|-----------|-----------|------|
| 수강권 | Subscription | `Subscription` | `Subscription` | 레슨 횟수/기간 권리 |
| 수강권 제안 | Proposal | `SubscriptionProposal` | `SubscriptionProposal` | 선생님→학생 수강권 제안 |
| 수강권 템플릿 | Template | `SubscriptionTemplate` | `SubscriptionTemplate` | 미리 설정한 수강권 상품 |
| 판매가 | Sale Price | `SubscriptionTemplate.price` | `amount` | 실제 결제 금액 (proposal/instance 기준) |
| 정가 | Regular Price | `SubscriptionTemplate.regularPrice` | `regular_price` | 할인 표시용 원가(선택). 판매가보다 크면 카드/시트에 취소선+할인율 표시. 작성 시 `TeacherSettings.lessonPriceTable`(악기×레벨 회당가)에서 자동 산출 |
| 수강권 상태 | Subscription Status | `SubscriptionStatus` | `SubscriptionStatus` | active/expiringSoon/expired/paused |
| 입금 상태 | Payment Status | `paymentConfirmed` | `payment_confirmed` | 외부 입금 확인 여부 (앱 내 결제 아님) |
| 미수금 | Outstanding Payment | `Subscription.isUnpaid` (표시명 `subscriptionBadgeUnpaid`) | `payment_confirmed = false` | **후불** 수강권 중 입금 완료 기록 없는 상태 = 선생님 미수 채권. 배지·정산·프로필 면 통일 표시명. 사용하지 않는 표현: 입금대기(후불), 입금대기 |
| 입금 확인 대기 | Payment Confirmation Pending | `PaymentPendingCard` | (집계) | **선불**(입금 안내 후) 입금 확인 전 수강권 제안 상태 (`paymentRequested`) 집계. 선생님 홈 상단 카드로 노출. 사용하지 않는 표현: 입금 대기 |
| 입금 추적 | Payment Tracking | `PaymentTrackingService` | `PaymentTrackingService` | D+1/3/7 자동 리마인드 시스템. 학생·선생님 양측 발송 |
| 입금 확인 되돌리기 | Confirm Payment Undo | `undoConfirmPayment` | `undo_confirm_payment` | 입금 확인 후 24시간 내 취소 가능. 첫 레슨 차감 발생 시 불가 |
| 수강권 자동 연장 | Auto-Extension | `Subscription.autoExtendedDays` | `auto_extended_days` | 선생님 휴가 등록 시 휴가 일수만큼 만료일 자동 연장 |
| 스케줄된 회차 | Scheduled Lessons | `Subscription.scheduledLessons` | `scheduled_lessons` | 실제 잡힌 레슨 수. `remainingLessons` 와 별개 트랙 |
| 보강 크레딧 | Makeup Credit | `MakeupCredit` | `MakeupCredit` | 별도 엔티티. 휴가·노쇼 면제·일괄변경 손실 회차 적립. 30일 만료 |
| 갱신 제안 | Renewal Propose | (만료임박 카드 `onRenew` CTA → issueSubscription `renewFromSubscriptionId`) | — | 만료임박 수강권을 이전 값(회차·금액·유효기간·변경허용) 프리필 발급 화면으로 바로 발급. 교사 수동 갱신. "연장"(자동 만료연장)과 구분 — 갱신=새 수강권 발급(폼 프리필만, 발급은 교사 확인). #806 |

---

## 5. 연습 (Practice)

| 한글 | 영문 | FE 클래스 | BE 클래스 | 설명 |
|------|------|-----------|-----------|------|
| 연습 로그 | Practice Log | `PracticeLog` | `PracticeLog` | 일별 연습 기록 |
| 레퍼토리 | Repertoire | `PracticeRepertoire` | — | 연습 곡 목록 (FE Hive only) |
| 녹음 | Recording | `Recording` | `Recording` | 연습 녹음 파일 |
| 구간 반복 연습 오버라이드 | Practice Loop Override | `PracticeLoopOverride` | — | §3.5 학생이 선생님 디폴트 영상 구간을 로컬에서 조정한 값 (Hive scoped) |
| 오디오 믹스 모드 | Audio Mix Mode | `AudioMixMode` | — | §3.5 영상/메트로놈/녹음 6 모드 조합 (videoOnly/recordOnly/mixed/videoMuted/headphoneOnly/metronomeMixed) |
| 재생 루퍼 | Playback Looper | `PlaybackLooper` | — | §3.5 순수 루프 알고리즘 (seek-back / count-in / target-reached 판정) |
| 오디오 라우팅 서비스 | Audio Routing Service | `AudioRoutingService` | — | §3.5 헤드폰 감지 — `audio_session` 기반 |
| 카운트인 오버레이 | Count-In Overlay | `CountInOverlay` | — | §3.5 3-2-1 카운트인 오버레이 (Playfair 60-72pt) |
| 구간 반복 북마크 | Loop Bookmark | `LoopBookmark` | — | §3.5 #511 학생이 영상에 마킹한 N구간 (도입/전개/엔딩 등). 최대 5개, 색 슬롯 자동 할당 |
| 북마크 관리 시트 | Bookmark Manager Sheet | `BookmarkManagerSheet` | — | §3.5 #511 북마크 추가/수정/삭제/선택 바텀시트 |
| 구간 반복 통계 | Practice Loop Stats | `PracticeLoopStats` | `PracticeLoopStats` | §3.5 #512 (학생, 섹션) 누적 반복 횟수 — 선생님 통계 + 학생 동기화 SSOT |
| 학생 반복 통계 | Student Repeat Stats | `StudentRepeatStats` | `PracticeLoopStatsStudentSummary` | §3.5 #512 학생 단위 roll-up (대시보드 카드) |
| 루프 통계 동기화 서비스 | Loop Stats Sync Service | `LoopStatsSyncService` | — | §3.5 #512 오프라인 큐 + 세션 종료 배치 동기화 |
| 학생 반복 차트 | Student Repeat Chart | `StudentRepeatChart` | — | §3.5 #512 구간별 반복 횟수 막대 차트 (fl_chart BarChart) |
| 학생 루프 히트맵 | Student Loop Heatmap | `StudentLoopHeatmap` | — | §3.5 #512 어려운 구간 시각화 — 반복 횟수 비례 음영 |

---

## 6. 관계/연결 (Relationship)

| 한글 | 영문 | FE 클래스 | BE 클래스 | 설명 |
|------|------|-----------|-----------|------|
| 연결 | Connection | `Relationship` | `Relationship` | 선생님-학생 관계 |
| 관계 상태 | Relationship Status | `RelationshipStatus` | `RelationStatus` | ⚠️ FE-BE 불일치. **레슨 관계 SSOT**. ConnectionStatus는 deprecate 예정 |
| 초대 코드 (학생·동료) | Invite Code | `InviteCode` | `InviteCode` | 학생/동료 초대용 6자리 코드 + QR + URL. **유효기간 7일** (#799 명시) |
| 학부모 초대 코드 | Parent Invite Code | `ParentInvitation` | `ParentInvitation` | 자녀-학부모 연결용 6자리 코드 (교사: 학생 상세 / 학생: 프로필에서 생성). **유효기간 24시간** — 학생/동료(7일)와 차등 유지. 모든 초대 생성·공유·입력 면에 유효기간 병기 (#799) |
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

### 수강권/청구/정산 (AC-M1 그룹 C, 2026-06-04)

| 용어 (한글) | 클래스 (BE+FE) | 정의 |
|------|----------|------|
| 학원 청구·배분 규칙 | `AcademyBillingRule` | 학원당 1행. 청구일/납부기한/계좌/배분 모드/세금 정책 |
| 강사 배분 모드 override | `AcademyTeacherPayoutOverride` | 강사별 다른 정산 모드. effective_from/until 히스토리 |
| 학원 귀속 수강권 정책 | `AcademySubscription` | subscriptions 본체 1:1. ownership + 12h 정책 + 학생보상 정책 (FE 1:1) |
| 학원 청구서 | `AcademyInvoice` | 월간 학생별 청구서. period(year,month) 유니크. status: draft→sent→paid→overdue→cancelled |
| 학원 수금 | `AcademyPayment` | 청구서 × 1 + N 수금 (부분 수금 지원). source: manual/csv_import/fuzzy_match |
| 강사 배분 명세 | `AcademySettlement` | 월간 강사 페이 산출 + 학원장 확정 + 송금 마킹. adjustment_log audit 영구 보존 |

| Enum (그룹 C) | 값 |
|---|---|
| `TeacherDistributionType` | hourly / revenue_share / per_student |
| `SubscriptionOwnership` | academy / teacher (수강권 귀속) |
| `SettlementBase` | attendance / invoiced / completed_invoice |
| `InvoiceStatus` | draft / sent / paid / overdue / cancelled |
| `PaymentMethod` | transfer / cash / card |
| `PaymentSource` | manual / csv_import / fuzzy_match |
| `SettlementStatus` | draft / confirmed / transferred |
| `LessonVisibility` | academyFull / academyBusyOnly (academy_schedule_authority §2.3) |

### 그룹 C UX 1탭 흐름

- POST /billing/invoices (월간 청구서 자동 또는 수기 생성) — 학원장 1탭
- POST /billing/invoices/bulk-send (전체 발송) — 학원장 1탭
- POST /billing/payments (수금 1탭 마킹)
- POST /billing/settlements/calculate (강사 배분 자동 산출, 수금 80% 시점)
- POST /billing/settlements/{id}/confirm → /transfer (송금 완료 1탭)

### 그룹 C 정합 결정 (2026-06-04)

- AcademySubscription 신규 테이블 채택 (이전 결정 "academy_subscriptions 안 만듦" 변경) — spec §2.2 + FE 1:1 매핑 우선
- subscriptions.academy_id 컬럼 추가 (빠른 조회 denormalization)
- lessons.academy_id + visibility 컬럼 추가 (학원 컨텍스트 가시성)
- AcademyInvitePreview 응답 FE 호환 변경 (token + 중첩 academy + owner_name)
- FE 갭 (Type C 6 영역) → GitHub Issue #513

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

## 13. 퀘스트 시스템 (Quest System) — 2026-06-08

선생님 학습 가이드 + 단축 진입점. **의무 아님** — 점수가 아닌 행동 격려.

| 한글 | 영문 | FE 클래스 | BE 클래스 | 설명 |
|------|------|-----------|-----------|------|
| 퀘스트 | Quest | `_Quest` | — | 선생님 학습 가이드 + 단축 진입점 (의무 아님). 11개 항목 (Q1~Q11) |
| 프로필 설정 그룹 | Profile Setup Group | `QuestGroup.profile` | — | Q1~Q5 (가용시간/사진/소개/레슨비/계좌) |
| 운영 시작 그룹 | Operation Group | `QuestGroup.operation` | — | Q6~Q10 (학생/수강권/레슨/노트/숙제) |
| 선택 보너스 그룹 | Bonus Group | `QuestGroup.bonus` | — | Q11 (전화인증) — `[선택]` 라벨 + 점선 카드 |
| 자동 완료 트리거 | Auto-Complete Trigger | (reactive provider) | — | 입력 즉시 퀘스트 완료 감지 + 카드 즉시 소거 |
| 퀘스트 축하 카드 | Quest Celebration Card | `QuestCelebrationCard` | — | **Q1~Q10 (필수) 100% 완료 = 졸업 시점** 1회 표시 (`User.questCelebratedAt` 으로 1회성 보장). 2026-06-11 의미 재정의 — 기존 "11/11 완료" → "10/10 졸업" + Q11 보너스 분리 (`quest_bonus_shown_provider` FE Hive flag) |
| 가입 직후 첫 도착 | Signup First Arrival | `questFirstShownProvider` | — | SharedPreferences 기반 — 가입 직후 1회만 카드 2초 표시 (5분 윈도우) |
| Lock 매트릭스 | Lock Matrix | `_QuestLockMatrix` | — | Q6(학생) → {Q7, Q8, Q9, Q10} 잠금 해제 트리거 (학생 등록 전 운영 행동 불가) |
| Q11 보너스 표시 | Quest Bonus Shown | `quest_bonus_shown_provider` (FE Hive) | — | Q11 (전화인증) 완료 시 1회 보너스 배지 표시. **BE 컬럼 신설 없음** — 게이지 100% 미포함 (Q1~Q10 별도 졸업 트리거와 분리). 2026-06-11 architect 검토 반영 |
| dual-write 마이그레이션 | Dual-Write Migration | — | `teacher_availability_diff.py` | 단계 1~4: dual-write → reader 교체 → deprecate → 필드 제거 (in-flight 데이터 손실 방지) |

**SSOT 정렬**: 가용시간은 `TeacherAvailability` (schedule 도메인) 단일 — `TeacherSettings.availableSlots` 는 dual-write 단계 후 deprecate.

---

## 14. 선생님 설정 정보 아키텍처 (5묶음) — 2026-06-11

> 선생님 설정의 1차 분류는 다음 5묶음으로 고정. 코드·스펙·UI·대화에서 동일 사용.
> 입력 자료: `.harness/spec/2026-06-11-teacher-settings-redesign.md`
> 기존 "레슨 시간 설정" 메뉴 폐기 — 카테고리 어긋남 해소.

### 5묶음 카테고리

| 한글 | 영문 | 주요 엔티티/필드 | 의미 |
|------|------|------------------|------|
| 운영시간 묶음 | Operating Hours Group | `TeacherAvailability` (schedule) | "언제 가르치는가" — 주간 운영시간 + 쉬는시간 + 휴무 + 휴가 |
| 수업방식 묶음 | Lesson Style Group | `TeacherSettings.lessonDurationMinutes` / `minBookingHours` / `studentGuideMessage` (profile) | "어떻게 가르치는가" — 레슨 1회 시간 + 최소 사전예약 + 학생 안내 메시지 |
| 수강권·정산 묶음 | Subscription & Billing Group | `TeacherSettings.priceTable` + `trialLessonPolicy` + `cancellationDefaults` + `SubscriptionTemplate` + `BankAccount` + `OutstandingPayment` | "어떻게 받는가" |
| 내 프로필 묶음 | My Profile Group | `TeacherProfile` / `Instrument` / `Credential` / `Repertoire` | "나는 누구인가" |
| 알림·소식·지원 묶음 | Notification/News/Support Group | `NotificationSettings` / `FeedbackTemplate` / `Following`/`News` 등 | 가끔 보는 것. #805: 시트 3 섹션(템플릿 / 알림·소식 / 지원·계정)으로 청킹, 라벨 "정책·알림·지원"→"알림·소식·지원"(정책 항목은 수강권·정산 소관이라 제거). 묶음 enum `policyNotifications` 불변 |

### 신규 용어

| 한글 | 영문 | FE 클래스/필드 | 설명 |
|------|------|----------------|------|
| 카테고리 미리보기 | Category Preview | `OnboardingCategoryPreviewScreen` + `onboardingCategoryShownProvider` | 가입 직후 Step 2.5 5묶음 인지 화면. 1회 노출, 스킵 가능 |
| 카테고리 카드 | Category Card | (DashboardTab 5묶음 카드 그리드) | 미설정 시 노란 점 affordance + 진행 상태 라벨 |
| 퀘스트 졸업 | Quest Graduation | `questCelebrationProvider` + 7일 dismiss | Q1~Q10 100% 완료 후 메인에서 자동 hide. 졸업 카드 1주일 노출 후 dismiss |
| 가이드 다시 보기 | Guide Re-show | (알림·소식·지원 메뉴) | 졸업 후 퀘스트 보드 + 카테고리 미리보기 재실행 fallback |
| 메뉴 NEW 배지 | NEW Badge | (5묶음 카테고리 카드) | 새 카테고리 7일간 NEW 점 표시. 한 번 진입 시 해당 카드만 dismiss |
| 다음 미션 spotlight | Next Mission Spotlight | (메인 첫 진입 오버레이) | 메인 첫 진입 1회 — 화면 어둡게 + 다음 quest 카드 1개만 highlight |

### Deprecated 표현 (사용 금지)

| 폐기 표현 | 대신 사용 |
|---|---|
| "레슨 시간 설정" (메뉴) | 5묶음으로 흩어짐 — 1:1 매핑 없음 |
| "가용 요일/시간" (메뉴 라벨) | "운영시간" (단일 라벨) |
| "가용시간" (사용자 노출 표현) | "운영시간" — 코드의 `TeacherAvailability` 클래스명은 SSOT 유지 |
| `TeacherSettings.availableSlots` | `TeacherAvailability.weeklySchedules` (SSOT) |
| `TeacherSettings.breakTimeBetweenLessons` | `TeacherAvailability.breakTimeBetweenLessons` (운영시간 묶음) |
| `defaultLessonDuration` (profile) | `lessonDurationMinutes` (TeacherSettings) |
| `slotDurationMinutes` (schedule, 필드명) | `lessonDurationMinutes` (TeacherSettings, 수업방식 묶음 SSOT) |
| `TeacherAvailability.minBookingHours` (schedule 중복본) | `TeacherSettings.minBookingHours` (profile 단일 — 수업방식 묶음 SSOT). **반대 방향 주의** — `breakTimeBetweenLessons` 는 schedule SSOT 이고 `minBookingHours` 는 profile SSOT (마이그레이션 충돌 시 우선 방향 다름) |

### 마이그레이션 (앱 부팅 시 1회)

`.harness/spec/2026-06-11-teacher-settings-redesign.md` §5.4 참조 — `availableSlots` → `weeklySchedules` 복사 + 충돌 시 schedule 우선. `breakTimeBetweenLessons` / `minBookingHours` 도 동일 정책.

---

## 15. 학생 게이미피케이션 (자가 연습) — 2026-06-11

> 스펙: `.harness/spec/2026-06-11-student-gamification.md` (locked at commit 6262f03d)
> 플랜: `.harness/decomposition/2026-06-11-student-gamification-p1-foundation.md`
> 범위: P1 Foundation (StudentQuest + GrowthHeatmap + PracticeRecordingService). P2~P4 별도.

학생 자가 연습 80% 비중을 가시화하는 1년 retention 시스템. **선생님 quest(§13)와는 별 시스템** — 학생용은 자가 결정 목표 추적, 선생님용은 학습 가이드.

### 핵심 엔티티 (BE ↔ FE 동일 클래스명)

| 한글 | 영문 (FE/BE) | 정의 |
|---|---|---|
| 학생 자가 quest | `StudentQuest` | 학생이 작성/채택한 연습 목표. 6 origin 중 하나로 분류 |
| 성장 히트맵 | `GrowthHeatmap` | 1년(365일) 캘린더. 일별 연습 evidence 통합. Hive 30일 chunk × 13 box (스펙 §17 P95<500ms) |

### Value Object / Service

| 한글 | 영문 (FE) | 정의 |
|---|---|---|
| 일일 연습 evidence | `DailyPractice` | 메트로놈/튜너/YouTube/녹음/수동 5경로 분 단위 통합. GrowthHeatmap 단일 cell 의 페이로드 |
| 연습 기록 서비스 | `PracticeRecordingService` | 모든 연습 evidence 단일 진입점. 위치: `features/practice/domain/services/`. 4 경로 wiring 의 hub |
| 연습 evidence (입력) | `PracticeEvidence` | PracticeRecordingService 입력 value object (source/durationMinutes/timestamp) |

### Enum

| 한글 | 영문 (FE) | 값 (6종) |
|---|---|---|
| Quest 출처 | `QuestOrigin` | `ambient` (주변/배경에서 자연 발생) / `selfCreated` (학생 직접 작성) / `systemRoutine` (스케일·웜업 등 시스템 추천) / `lessonDerived` (레슨 메모에서 추출) / `teacherRec` (선생님 추천) / `seasonEvent` (시즌 이벤트) |

### 정책 용어 (P1 범위)

| 용어 | 정의 |
|---|---|
| [연습 시작] 1버튼 | 학생 홈 `StudentDashboardTab` GamificationHeader 자리의 단일 진입점 (스펙 §6 / 플랜 O6). PracticeStartCard 위젯 |
| 1.5초 축하 | 연습 종료 후 CelebrationOverlay — 즉시성·비방해 원칙 (스펙 §9) |
| 4 경로 wiring | 메트로놈/튜너/YouTube/녹음/수동 → 모두 PracticeRecordingService 단일 진입 (스펙 §11) |
| 자동 트리거 | 학생 첫 로그인 + StudentQuest 0개 시 onboarding 1화면 자동 진입 (플랜 O7) |
| Hive 30일 chunk × 13 box | GrowthHeatmap 1년 캐시 전략 (플랜 O2). 메모리 효율 + P95<500ms 달성 |

### 14세 미만 처리 (스펙 §16)

| 한글 | 영문 (FE) | 정의 |
|---|---|---|
| 부모 동의 시각 | `Student.parentConsentAt` (nullable) | 14세 미만 학생의 부모 동의 timestamp. null 이면 자가 연습만 허용 (비교 보기·리더보드 차단) |
| 자가 연습 전용 모드 | self-only mode | 14세 미만 + parentConsentAt=null 학생의 P1 기본 모드 — 비교 보기 없음, 부모 동의 불필요 |

### Deprecated 표현 (사용 금지)

| 폐기 표현 | 대신 사용 |
|---|---|
| "학생 quest" (선생님 quest 와 혼동) | "학생 자가 quest" 또는 `StudentQuest` (선생님 quest 는 §13 `Quest`) |
| "연습 evidence" (혼란스러운 약칭) | `DailyPractice` (저장 단위) 또는 `PracticeEvidence` (입력 value object) |

### P2 Visual Growth 추가 용어 (2026-06-12)

> 플랜: `.harness/decomposition/2026-06-11-student-gamification-p2-visual-growth.md`
> 범위: 1년 히트맵 UI + StreakFreeze 시스템 + 휴식 권고. SC-10, SC-11.

#### 핵심 엔티티 (BE ↔ FE 동일 클래스명)

| 한글 | 영문 (FE/BE) | 정의 |
|---|---|---|
| 스트릭 동결 | `StreakFreeze` | 결석일에 자동 적용되어 streak 유지하는 학생별 record. 4 필드: studentId / balance (0-4) / usedAt / examModeUntil |

#### 정책 용어 (P2 범위)

| 용어 | 정의 |
|---|---|
| 동결 잔액 | `StreakFreeze.balance` 의 별칭. Sunday 00:00 KST 자동 +2, max 4 (스펙 §6.5 / §14.1) |
| 시험 모드 | `StreakFreeze.examModeUntil` 활성 동안 freeze 차감 0. 학부모/선생님 발급 (스펙 §14.3) |
| 복귀 보너스 | 7일+ 미사용 후 복귀 시 첫 세션 보너스 P + "다시 만나서 반가워요" 환영. FOMO 메시지 X (스펙 §14.4) |
| 1년 히트맵 | `YearHeatmap` UI — GitHub contribution graph 스타일 7×52 그리드. 5단계 색 농도 (0/1-15/16-30/31-60/61+ 분) + 색맹 친화 패턴 |
| 트로피 모음 | `TrophyCollection` UI — 기존 `badge_award_provider` 재사용. 카테고리 분류 노출 X — 단일 "모음" 카드 (스펙 §16) |
| 30일 chunk | `HeatmapChunk` — Hive 13 box × 30일 = 390일 분량 캐시 단위. key=`heatmap_chunk_{studentId}_{chunkIndex}`. 단일 chunk 만 invalidate (플랜 O2) |
| D-day 마이그레이션 | P2 배포 시점 1회 — 기존 `practice_streak_provider` → `StreakFreeze.balance = 2` + KST timezone 정렬 + 학생에게 "스트릭 동결 시스템 시작" 안내 토스트 1회 (스펙 §18.3 / 플랜 O7) |
| 휴식 권고 | `RestRecommendationToast` — 단일 세션 30분 / 일일 누적 3시간 / 14세 미만 15분 도달 시 푸시 X 토스트 1회 (스펙 §9.4 SC-11) |

#### 데이터 단위

| 한글 | 영문 (FE) | 정의 |
|---|---|---|
| 자동 발급 | `StreakFreezeService.weeklyGrantIfDue()` | KST `Asia/Seoul` 고정 — 학생 디바이스 timezone 무관. Sunday 00:00 이후 마지막 grant 가 이번 주 외이면 balance +2 (clamp 4) |
| 자동 적용 | `StreakFreezeService.applyOnAbsence()` | 학생 결석일 발생 시 balance -1 + usedAt 추가. examMode 활성 시 no-op. balance=0 시 no-op (streak 끊김은 `practice_streak_provider` 책임) |

#### Deprecated 표현 (P2 추가)

| 폐기 표현 | 대신 사용 |
|---|---|
| "freeze 보상" / "스트릭 보호" | "스트릭 동결" 또는 `StreakFreeze` — "보상" 단어는 외부 보상 의존 메시징 회피 (스펙 §3) |
| "트로피 카테고리" / "트로피 분류" | "트로피 모음" 또는 `TrophyCollection` — 단일 카드, 카테고리 노출 X (스펙 §16) |

### P3 Spotlight 추가 용어 (2026-06-12)

> 플랜: `.harness/decomposition/2026-06-12-student-gamification-p3-spotlight.md`
> 범위: SpotlightPrompt 큐 + 거절 학습 + 축하 후 1슬롯 prompt. SC-9.

#### 핵심 엔티티 (BE ↔ FE 동일 클래스명)

| 한글 | 영문 (FE/BE) | 정의 |
|---|---|---|
| 스포트라이트 프롬프트 | `SpotlightPrompt` | 학생에게 가끔 보여지는 권유 1슬롯. 11 필드: id / studentId / type / title / videoId / ctaRoute / queuedAt / declineCount / hideUntil / permanentlyHidden / lastShownAt (스펙 §6.2) |
| 스포트라이트 종류 | `SpotlightType` | 3종 enum — `teacherRec` (선생님 추천 영상·곡) / `seasonEvent` (시즌·명절 큐레이션) / `routineSuggestion` (자가 routine 30일+ 추천) (스펙 §5.2) |

#### 정책 용어 (P3 범위)

| 용어 | 정의 |
|---|---|
| 스포트라이트 슬롯 | `SpotlightSlot` UI 위젯 — 축하 overlay 내부 1슬롯. "지금 볼래" / "다음에" 동일 비중 (스펙 §7.4) |
| 노출 조건 | `SpotlightEligibilityService.evaluate(ctx)` — 6 조건 (5분 세션 + 오늘 첫 prompt + 주간 ≤ 2 + 큐 promptable + 14세 미만 동의) 모두 통과 시 eligible (스펙 §7.1) |
| 큐 우선순위 | `SpotlightQueueService.nextPromptableFor()` — 4단계 (teacherRec 필수 → teacherRec 일반 → seasonEvent → routineSuggestion). 같은 type oldest queuedAt 우선 (스펙 §7.2) |
| 거절 cooldown | "다음에" tap 1회 → 7일 hide. type별 독립 카운터 (스펙 §7.3) |
| 8주 hide | 같은 type 5회 거절 → 56일 hide (스펙 §7.3 / SC-9) |
| 영구 hide | 8주 hide 후 1회 재시도 → 또 거절 → `permanentlyHidden=true`. 학생이 옵션에서 명시적 재활성 (P4) (스펙 §7.3) |
| 스포트라이트 시드 | `SpotlightSeedingService` 3 generator — `seedTeacherRecommendation` / `seedSeasonEvent` / `seedRoutineSuggestion` (중복 차단 + 큐잉) |

#### 데이터 단위

| 한글 | 영문 (FE) | 정의 |
|---|---|---|
| 노출 조건 평가 | `SpotlightEligibilityService.evaluate()` | 순수 함수 — `SpotlightEligibilityContext` (sessionDuration / now / promptsShownToday / promptsShownThisWeek / studentIsUnder14 / studentHasParentConsent) → `SpotlightEligibilityResult` (eligible / reason) |
| 큐 우선순위 평가 | `SpotlightQueueService.nextPromptableFor()` | repo.listForStudent → §7.2 우선순위 정렬 → hideUntil/permanentlyHidden 필터 → 1개 반환 (또는 null) |
| 거절 학습 적용 | `SpotlightDeclineLearningService.decline()` | declineCount +1 + type별 누적 계산 → cooldown 7d / 8주 hide / 영구 hide 분기 적용 |

#### Deprecated 표현 (P3 추가)

| 폐기 표현 | 대신 사용 |
|---|---|
| "필수 알림" / "강제 푸시" | "스포트라이트 권유" 또는 `SpotlightPrompt` — 푸시 알림 0건 (KPI §8) + "필수" 메시징 금지 (§7.4) |
| "추천 거절 패널티" / "거절 페널티" | "거절 학습" 또는 `SpotlightDeclineLearningService` — 페널티 메시징 0 (§7.4 동일 비중) |

---

## 16. 연습장 제본 (Practice Journal — Binding) — 2026-06-16

> 스펙: `docs/specs/practice_journal/practice_journal_master.md` §8.1 · §9.2 · §12 Phase 2
> 범위: 곡(레퍼토리) 완성 → 완성본 제본 + 책장(완성본/연습중 구분).

### 핵심 엔티티 (FE)

| 한글 | 영문 (FE) | 정의 |
|---|---|---|
| 완성본 | `BoundVolume` | 완성한 곡 1권. 필드: `childProfileId` / `pieceId` / `pieceName` / `volumeNo: int` / `boundDate`. 책등은 로마숫자(VOL. I·II·III) — `volumeNo`는 자녀 프로필별 1부터 증가 |
| 책등 | `BoundVolumeSpine` | 책장의 한 권 시각 단위 — 완성본=실선+로마숫자, 연습중=점선 |
| 책장 | `BoundShelfScreen` | 완성본(실선)과 연습중(점선)을 구분해 보여주는 화면 |

### 정책 용어

| 용어 | 정의 |
|---|---|
| 제본 | 곡(레퍼토리) 완성(archive) 시 완성본 1권 생성. `PracticeJournalRepository.bindVolume(childProfileId, pieceId, pieceName)` — 멱등(같은 `pieceId` 중복 제본 시 권 수 불변) |
| 곡 완성 트리거 | 이 앱에서 레퍼토리 archive = 곡 완성. `RepertoireArchiveNotifier.archive()` 성공 후 `practice_journal_facade` 경유로 제본 + `boundVolumesProvider` invalidate |
| 연습중 | 아직 완성(archive)되지 않은 활성 레퍼토리(`activeRepertoiresProvider`). 책장에서 점선 책등으로 표시 |

### 사용하지 않는 표현

| 폐기 표현 | 대신 사용 |
|---|---|
| 출판 / 발매 | "제본"(완성본 생성). "출판"은 P3 발표회 연계에만 한정 |

---

## 17. UX 용어 통일 — 2026/06/17 검토 반영 (#760~#764)

> 사용자 UX 검토(00-검토.md) 기반 사용자-facing 라벨 통일. 도메인 클래스명/개념은 기존 유지, 표시 라벨만 정규화.

| 개념 | 정규 라벨 (SSOT) | 사용하지 않는 표현 | AppStrings |
|------|------------------|--------------------|------------|
| 일정 협상 상태 | 시간 조율 중 / 시간 조율 중 (N회차) | 시간협상, 시간조율 | statusNegotiating, statusNegotiatingShort |
| 다른 시간 제안 CTA | 다른 시간 제안하기 | 일정 비교, 다른 일정 제안, 다른 시간 제안 | counterPropose, eventProposeAlternative, scheduleChangeCounter |
| 레슨 보관 액션 | 보관함으로 이동 | 보관, 레슨 보관 | archive, archiveLessonTitle |
| 레슨 편집 라벨 | 전체 수정(수기) / 곡·메모 수정(수강권) | 편집 (수기), 내용 수정 | editManual, editContent |
| 수업방식 카드 | 레슨·예약 규칙 | 수업방식 | categoryLessonStyle, lessonStyleScreenTitle |
| 알림 카테고리(시간 변경) | 시간 변경 요청 | 스케줄 변경(알림 카테고리 한정) | notificationSchedule |
| 운영시간 진입점 | 운영시간 | 레슨 운영 시간 | profileShortcutAvailability (§14 매핑 일치) |
| 앱 공지 진입점 | 앱 업데이트 안내 | 새 소식과 로드맵 | newsRoadmapTitle |

> 비고: ScheduleChange 도메인 개념(스케줄 변경)은 변경 없음 — 위 "시간 변경 요청"은 알림 설정 카테고리 라벨에 한정.

## 변경 이력

| 날짜 | 변경 |
|------|------|
| 2026-06-18 | 학생 상세 전화/문자 상단 승격 + 메뉴 그룹핑 (검토 #28) — 매일 쓰는 전화·문자를 more(...) 메뉴(2탭) → 신원 스트립(1탭, `StudentContactActions`). more 메뉴를 관리/상태 변경 섹션(`_MoreSectionLabel`)으로 그룹핑 + 학생 보관 맨 아래 분리. 데이터·플로우 불변(UI/IA만). |
| 2026-06-18 | 레슨 요약 공유 버튼 (검토 #62) — 레슨 상세 공유 액션을 로컬 텍스트 스낵바 → 서버 토큰 발급(`POST /lesson-summaries/{id}/share`, BE 기구현)으로 교체. URL 클립보드 복사 + "학생과 공유하기" 토스트. FE-only(LessonSummaryShare 모델 + repo mock/remote + 수동 provider). 구 lessonShareText/shareTextCopied orphan 제거. |
| 2026-06-18 | 만료임박 카드 갱신 제안 CTA (검토 #45) — `SubscriptionCard.onRenew` + 만료임박 화면 wiring → `issueSubscription?renewFromSubscriptionId=` 로 이전 수강권(회차·금액·유효기간·변경허용) 프리필 발급. `_applyRenewalDefaults` 폼 초기값만(발급 로직·빌링 불변, 교사 확인 후 발급). 임박→갱신 한 화면 완결. |
| 2026-06-18 | 정책·알림·지원 시트 성격별 분리 (검토 #43) — 과적재 13항목을 3 섹션(템플릿/알림·소식/지원·계정)으로 청킹(Miller's Law). 가이드 다시 보기→지원·계정 재배치. 카드/시트 라벨 "정책·알림·지원"→"알림·소식·지원"(정책 항목 부재). `_SheetSectionLabel` 섹션 헤더 신설. 5묶음 카드/enum/status 불변(시트 내부만). |
| 2026-06-18 | 취소 정책 두 화면 역할 명시 (검토 #34) — "취소 정책 디폴트"→"취소 정책 기본값"(개발어 제거). 취소/노쇼 정책(변경권·최소취소시간·노쇼·이월, `LessonPolicy`) vs 취소 정책 기본값(지각취소 보상·알림·마감 기본값, `CancellationDefaults`) 역할 분담 명시 + 양방향 교차참조(관련설정 링크/안내 노트). 두 화면 통합 안 함(2 feature/엔티티), FE 표시만. |
| 2026-06-18 | 초대 유효기간 표기 일원화 (검토 #30) — 학생/동료 초대 **7일** / 학부모 초대 **24시간** 차등 유지(정책·BE 불변, FE 표시만) + 모든 초대 면 병기. 학부모 초대 공유 텍스트·다이얼로그(`inviteParentValidityNote`)·수신 코드입력 캡션·학생/동료 공유(`inviteShareMessageFormat`)에 유효기간 추가. 진입점 구조 현행 유지(통합 아님). |
| 2026-06-17 | 입금 용어 분리 + 금액 정확 표기 (검토 #50) — 후불 **미수금**(입금대기(후불)·입금대기 흡수) vs 선불 **입금 확인 대기**(입금 대기 흡수) 분리. 미수금 긴급알림 금액 절사/반올림 제거 → 만/원 정확 표기(`formatKoreanWon` 동등 inline). 표시명·glossary만, enum/식별자 불변. |
| 2026-06-17 | 학생/연습 상태 어휘 정렬 (검토 #26) — StudentStatus.active 표시명 정규→수강중, 연습(PracticeLevel.onBreak/PracticeStatus.paused) 표시명 휴강→기록없음(무기록). 학생 라이프사이클 휴강(paused)·MembershipStatus는 유지(별 축). 표시명만, enum 값 불변. |
| 2026-06-17 | 스케줄 휴무/휴가/휴강 SSOT 통일 (검토 #14) — 휴무(비근무일)·휴가(기간형, "휴가 모드"·"방학 중" 흡수)·휴강(레슨 취소+보상) 3 canonical. Deprecated: 쉬는날→휴무, 방학 중→휴가, 휴가 모드→휴가. 표시명·glossary만 정렬(코드 식별자 불변). |
| 2026-06-16 | §16 연습장 제본(Practice Journal — Binding) 신설 — `BoundVolume` 엔티티(+`pieceName`) + `BoundVolumeSpine`/`BoundShelfScreen` + 정책 용어 3종(제본 / 곡 완성 트리거 / 연습중) + Deprecated 1건(출판→제본). 본 변경은 `.harness/spec/2026-06-16-practice-journal-p2-binding.md` |
| 2026-06-12 | §15 P3 Spotlight 용어 추가 — `SpotlightPrompt` 엔티티 + `SpotlightType` enum (3종) + 정책 용어 7종 (스포트라이트 슬롯 / 노출 조건 / 큐 우선순위 / 거절 cooldown / 8주 hide / 영구 hide / 스포트라이트 시드) + 서비스 메서드 3종 (Eligibility / Queue / DeclineLearning) + Deprecated 표현 2건 ("필수 알림" → "스포트라이트 권유", "거절 패널티" → "거절 학습"). 본 변경은 `.harness/decomposition/2026-06-12-student-gamification-p3-spotlight.md` Job 0 Step 2 |
| 2026-06-12 | §15 P2 Visual Growth 용어 추가 — `StreakFreeze` 엔티티 + 정책 용어 7종 (동결 잔액 / 시험 모드 / 복귀 보너스 / 1년 히트맵 / 트로피 모음 / 30일 chunk / D-day 마이그레이션 / 휴식 권고) + 서비스 메서드 2종 (자동 발급 / 자동 적용) + Deprecated 표현 2건 ("freeze 보상" → "스트릭 동결", "트로피 카테고리" → "트로피 모음"). 본 변경은 `.harness/decomposition/2026-06-11-student-gamification-p2-visual-growth.md` Job 0 Step 2 |
| 2026-06-11 | §15 학생 게이미피케이션 (자가 연습) 신설 — P1 Foundation 5종 핵심 용어 (`StudentQuest` / `QuestOrigin` / `GrowthHeatmap` / `DailyPractice` / `PracticeRecordingService`) + 정책 용어 5종 ([연습 시작] 1버튼 / 1.5초 축하 / 4 경로 wiring / 자동 트리거 / Hive 30일 chunk × 13 box) + 14세 미만 처리 2종 (`parentConsentAt` / 자가 연습 전용 모드) + Deprecated 표현 2건. 본 변경은 `.harness/spec/2026-06-11-student-gamification.md` |
| 2026-06-11 | (architect 검토 반영) §13 `quest_celebrated_at` 의미 재정의 — "11/11 완료" → "Q1~Q10 졸업 시점" + Q11 보너스 분리 (`quest_bonus_shown_provider` FE Hive flag, BE 컬럼 신설 없음) / §14 `minBookingHours` 매핑 반대 방향 명확화 (schedule → profile SSOT, `breakTimeBetweenLessons` 와 반대) |
| 2026-06-11 | §14 선생님 설정 IA (5묶음) 신설 — 5묶음 카테고리 + 카테고리 미리보기/카드/퀘스트 졸업/가이드 다시 보기/메뉴 NEW 배지/다음 미션 spotlight 신규 용어 + Deprecated 표현 매핑 (availableSlots/defaultLessonDuration/slotDurationMinutes/breakTimeBetweenLessons 폐기, lessonDurationMinutes 통일). 본 변경은 `.harness/spec/2026-06-11-teacher-settings-redesign.md` |
| 2026-06-08 | §13 퀘스트 시스템 신설 — 11 항목 / 3 그룹 (profile/operation/bonus) / Lock 매트릭스 단순화 (Q6→{Q7~Q10}) / 자동 완료 트리거 / 가입 직후 첫 도착 + 축하 카드 (1회성) / dual-write 마이그레이션 4 단계. 본 §13 은 `.harness/spec/2026-06-08-teacher-quest-system.md` O4 결정 |
| 2026-06-04 | AC-M2 Context Toggle API — POST /auth/context/switch + GET /auth/context. JWT 페이로드 확장 (active_context/academy_id/teacher_id). ContextSwitchLog 자동 기록 + 학원장 자동 복귀 시 활성 위임 auto_end. billing_settlement_spec §1 결제 원칙 명확화 (PG/카드 외부 단말기/자동 송금 X). PaymentMethod.card docstring 보강 |
| 2026-06-04 | §12 학원(Academy) 수강권/청구/정산 (AC-M1 그룹 C) — BillingRule/Invoice/Payment/Settlement/Subscription/TeacherPayoutOverride 6 엔티티 + 8 enum + subscriptions.academy_id + lessons.academy_id/visibility 컬럼 + AcademyInvitePreview FE 호환. FE 갭 #513 |
| 2026-06-04 | §12 학원(Academy) 권한 계층 (AC-M1 그룹 B) 추가 — ContextSwitchLog + AcademyDelegation + AcademyDelegationAction + AcademyActivityLog 4 엔티티 + 5 enum (AcademyContext/ContextSwitchTrigger/DelegationReason/DelegationState/DelegationRevokeReason) |
| 2026-06-04 | §12 학원(Academy) 도메인 신설 — AC-M1 그룹 A 4 엔티티 + 3 enum + 정책 용어 6종. 마일스톤: AC-M1 |
| 2026-06-04 | §5 연습: §3.5 후속 #512 신규 용어 5건 — PracticeLoopStats, StudentRepeatStats, LoopStatsSyncService, StudentRepeatChart, StudentLoopHeatmap (선생님 측 학생별 반복 통계 + 오프라인 동기화) |
| 2026-06-04 | §5 연습: §3.5 후속 #511 신규 용어 2건 — LoopBookmark, BookmarkManagerSheet (멀티 마커 N구간) |
| 2026-06-04 | §5 연습: §3.5 YouTube 구간 반복 연습 신규 용어 5건 — PracticeLoopOverride, AudioMixMode, PlaybackLooper, AudioRoutingService, CountInOverlay (#506) |
| 2026-06-03 | §11 코드 반영 신규 용어 — 코드↔스펙 드리프트 동기화로 식별된 FE 엔티티/enum 30여종 등록 (billing/schedule/lesson/relationship/practice/gamification/follow) |
| 2026-06-01 | E2E 감사 Top 10 반영 — 15용어 추가: 휴가 모드, 알림톡, 입금 대기/추적/되돌리기, 수강권 자동 연장, 스케줄된 회차, 보강 크레딧, 초대 코드/대기, 첫 가용시간, 인증 선생님 배지, 레슨 1회 시간, 쉬는 시간, 발신 프로필. ConnectionStatus deprecate 명시 |
| 2026-05-10 | §10 앱 릴리즈/신뢰 구축: AppVersionSnapshot, AppNewsItem, AppRoadmapItem, AppReleaseSnapshot, AppReviewState 추가 (R6) |
| 2026-05-07 | §7 알림: lessonCancelledByTeacher, teacherAnnouncement 이벤트 타입 추가 (일괄 작업 v2) |
| 2026-05-07 | §2 체험레슨: 수강권 필수 명시 (유료 기본, 무료 선택), 변경/취소 정책 동일 적용 |
| 2026-05-07 | §8 UX 용어: 퀘스트/코치마크/워크스루/셀레브레이션/프로필완성도 추가 (온보딩 v2) |
| 2026-05-04 | 초판 작성 — `docs/specs/glossary.md` 기반 + 전 도메인 확장 + FE-BE 매핑 |
