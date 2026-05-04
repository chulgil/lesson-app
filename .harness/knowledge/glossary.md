# 유비쿼터스 언어 (Ubiquitous Language)

> 최종 업데이트: 2026-05-04
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
| 체험 레슨 | Trial Lesson | `LessonBooking(type: trial)` | `LessonBooking(lesson_type: trial)` | 정규 등록 전 시험 레슨 |
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

---

## 4. 수강권 (Subscription)

| 한글 | 영문 | FE 클래스 | BE 클래스 | 설명 |
|------|------|-----------|-----------|------|
| 수강권 | Subscription | `Subscription` | `Subscription` | 레슨 횟수/기간 권리 |
| 수강권 제안 | Proposal | `SubscriptionProposal` | `SubscriptionProposal` | 선생님→학생 수강권 제안 |
| 수강권 템플릿 | Template | `SubscriptionTemplate` | `SubscriptionTemplate` | 미리 설정한 수강권 상품 |
| 수강권 상태 | Subscription Status | `SubscriptionStatus` | `SubscriptionStatus` | active/expiringSoon/expired/paused |
| 입금 상태 | Payment Status | `paymentConfirmed` | `payment_confirmed` | 외부 입금 확인 여부 (앱 내 결제 아님) |

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
| 관계 상태 | Relationship Status | `RelationshipStatus` | `RelationStatus` | ⚠️ FE-BE 불일치 |
| 팔로우 | Follow | `Follow` | `Follow` | 소식 구독 (레슨 무관) |
| 학급 | Class | `LessonClass` | `LessonClass` | 선생님의 레슨 그룹 |
| 소속 | Membership | `ClassMembership` | `ClassMembership` | 학생의 학급 소속 |

---

## 7. 알림 (Notification)

| 한글 | 영문 | FE 클래스 | BE 클래스 | 설명 |
|------|------|-----------|-----------|------|
| 알림 | Notification | `AppNotification` | `Notification` | ⚠️ FE-BE 불일치. 인앱/푸시 알림 |
| 만료 알림 설정 | Expiry Reminder Settings | `SubscriptionExpiryReminderSettings` | `SubscriptionSettings.renewal_alert_days_set` | D-14/D-7/D-1/D-0 토글 |

---

## 8. UX 용어

| 한글 | 영문 | 설명 |
|------|------|------|
| 제로 탭 | Zero Tap | 추가 버튼 없이 동작 완료 (QR 스캔 = 연결) |
| 원클릭 | One Click | 한 번 탭으로 동작 완료 |
| 원샷 UX | One-Shot UX | 한 번 탭으로 모든 연관 작업 완료 |
| 노트북 | Notebook | 디자인 시스템 메타포 (종이+잉크+연필) |

---

## 9. FE-BE 불일치 요약

> 아래는 역사적 이유로 이름이 다른 것. **신규 엔티티는 반드시 동일 이름 사용.**

| 개념 | Frontend | Backend | 통일 방향 |
|------|----------|---------|----------|
| 사용자 | `AuthUser` | `User` | FE 사정 (Flutter Auth 충돌 회피) — 유지 |
| 알림 | `AppNotification` | `Notification` | FE 사정 (dart:html 충돌 회피) — 유지 |
| 관계 상태 | `RelationshipStatus` | `RelationStatus` | BE rename 권장 → `RelationshipStatus` |
| 레슨 요청 | `UnifiedLessonRequest` | `LessonRequest` | FE가 여러 소스 통합 — 유지 |
| 요청 상태 | `UnifiedRequestStatus` | `RequestStatus` | 동일 사유 — 유지 |
| 스케줄 예외 | `TimeException` | `ScheduleException` | BE 이름이 정확 — FE rename 권장 |

---

## 변경 이력

| 날짜 | 변경 |
|------|------|
| 2026-05-04 | 초판 작성 — `docs/specs/glossary.md` 기반 + 전 도메인 확장 + FE-BE 매핑 |
