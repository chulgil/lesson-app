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

## 변경 이력

| 날짜 | 변경 |
|------|------|
| 2026-06-01 | E2E 감사 Top 10 반영 — 15용어 추가: 휴가 모드, 알림톡, 입금 대기/추적/되돌리기, 수강권 자동 연장, 스케줄된 회차, 보강 크레딧, 초대 코드/대기, 첫 가용시간, 인증 선생님 배지, 레슨 1회 시간, 쉬는 시간, 발신 프로필. ConnectionStatus deprecate 명시 |
| 2026-05-10 | §10 앱 릴리즈/신뢰 구축: AppVersionSnapshot, AppNewsItem, AppRoadmapItem, AppReleaseSnapshot, AppReviewState 추가 (R6) |
| 2026-05-07 | §7 알림: lessonCancelledByTeacher, teacherAnnouncement 이벤트 타입 추가 (일괄 작업 v2) |
| 2026-05-07 | §2 체험레슨: 수강권 필수 명시 (유료 기본, 무료 선택), 변경/취소 정책 동일 적용 |
| 2026-05-07 | §8 UX 용어: 퀘스트/코치마크/워크스루/셀레브레이션/프로필완성도 추가 (온보딩 v2) |
| 2026-05-04 | 초판 작성 — `docs/specs/glossary.md` 기반 + 전 도메인 확장 + FE-BE 매핑 |
