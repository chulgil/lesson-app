# 데이터 스키마 문서

> 마지막 업데이트: 2026-01-25

이 폴더는 **구현 상세** 문서를 포함합니다.
비즈니스 요구사항과 UI 설계는 `docs/specs/`를 참조하세요.

---

## 문서 구조

```
docs/schema/
├── README.md                   # 이 문서
├── entities/                   # 엔티티 정의
│   ├── booking.md              # Booking (레슨 예약)
│   ├── cancellation_policy.md  # CancellationPolicy (취소/노쇼 정책)
│   ├── class_membership.md     # ClassMembership (학생-클래스 관계)
│   ├── lesson_class.md         # LessonClass (학원/개인 클래스)
│   ├── lesson_location.md      # LessonLocation (레슨 장소)
│   ├── lesson_schedule.md      # LessonSchedule (스케줄 설정)
│   ├── parent.md               # Parent (학부모, 자녀, 연결, 설정)
│   ├── payment.md              # Payment, Invoice (결제)
│   ├── practice_goal.md        # PracticeGoal (연습 목표)
│   ├── practice_note.md        # PracticeNote (연습노트)
│   ├── practice_space.md       # PracticeSpace (연습 공간)
│   ├── student.md              # Student (학생)
│   ├── subscription.md         # Subscription (수강권)
│   ├── teacher_availability.md # TeacherAvailability (가용시간)
│   ├── review.md               # TeacherReview, LessonFeedback (리뷰)
│   ├── teacher.md              # Teacher, Certificate (선생님)
│   ├── invite.md               # Follow, Membership (초대/연결)
│   └── notification.md         # AppNotification, NotificationSettings (알림)
└── api/                        # API 스펙 (추후)
    └── ...
```

---

## 엔티티 인덱스

### 레슨/예약

| 엔티티 | 설명 | 관련 스펙 | Hive TypeId |
|--------|------|----------|:-----------:|
| [Booking](entities/booking.md) | 레슨 예약 | [Unified_Lesson_Booking_Spec.md](../specs/lesson/Unified_Lesson_Booking_Spec.md) | 90-93 |
| [LessonSchedule](entities/lesson_schedule.md) | 스케줄 설정, 5주차 정책 | [lesson_schedule.md](../specs/lesson/lesson_schedule.md) | 94-101 |
| [LessonClass](entities/lesson_class.md) | 학원/개인레슨 클래스 | [student_class_system.md](../specs/student/student_class_system.md) | 60-62 |
| [LessonLocation](entities/lesson_location.md) | 레슨 장소 | [student_class_system.md](../specs/student/student_class_system.md) | - |
| [TeacherAvailability](entities/teacher_availability.md) | 선생님 가용시간 (3계층) | [trial_lesson_system.md](../specs/trial/trial_lesson_system.md) | TBD |
| [CancellationPolicy](entities/cancellation_policy.md) | 취소/노쇼 정책 | [trial_lesson_system.md](../specs/trial/trial_lesson_system.md) | TBD |

### 학생/연습

| 엔티티 | 설명 | 관련 스펙 | Hive TypeId |
|--------|------|----------|:-----------:|
| [Student](entities/student.md) | 학생 | [student_class_system.md](../specs/student/student_class_system.md) | - |
| [ClassMembership](entities/class_membership.md) | 학생-클래스 소속 관계 | [student_class_system.md](../specs/student/student_class_system.md) | TBD |
| [PracticeSpace](entities/practice_space.md) | 연습 공간, 코치 연결 | [student_centered_architecture.md](../specs/lesson/student_centered_architecture.md) | 81-89 |
| [PracticeNote](entities/practice_note.md) | 연습노트 | [practice_note_spec.md](../specs/practice/practice_note_spec.md) | 31 |
| [PracticeGoal](entities/practice_goal.md) | 연습 목표 | [practice_goal_spec.md](../specs/practice/practice_goal_spec.md) | 32 |

### 결제/수강권

| 엔티티 | 설명 | 관련 스펙 | Hive TypeId |
|--------|------|----------|:-----------:|
| [Payment](entities/payment.md) | 결제, 청구서 | [payment_unified_spec.md](../specs/payment/payment_unified_spec.md) | 70-80 |
| [Subscription](entities/subscription.md) | 수강권, 부가 서비스, 교차 수강 | [subscription_system_spec.md](../specs/subscription/subscription_system_spec.md) | 55-62 |

### 사용자

| 엔티티 | 설명 | 관련 스펙 | Hive TypeId |
|--------|------|----------|:-----------:|
| [Parent](entities/parent.md) | 학부모, 자녀, 연결, 설정 | [parent_system.md](../specs/user/parent_system.md) | 63-72 |

### 리뷰

| 엔티티 | 설명 | 관련 스펙 | Hive TypeId |
|--------|------|----------|:-----------:|
| [TeacherReview](entities/review.md) | 선생님 리뷰, 카테고리 평점 | [review_system.md](../specs/review/review_system.md) | TBD |
| [LessonFeedback](entities/review.md#lessonfeedback-레슨-피드백---비공개) | 레슨 피드백 (비공개) | [review_system.md](../specs/review/review_system.md) | TBD |
| [TeacherReviewSettings](entities/review.md#teacherreviewsettings-선생님-리뷰-설정) | 선생님 리뷰 공개 설정 | [review_system.md](../specs/review/review_system.md) | TBD |
| [TeacherReviewStats](entities/review.md#teacherreviewstats-리뷰-통계) | 리뷰 통계 | [review_system.md](../specs/review/review_system.md) | TBD |

### 선생님

| 엔티티 | 설명 | 관련 스펙 | Hive TypeId |
|--------|------|----------|:-----------:|
| [Teacher](entities/teacher.md) | 선생님, 프로필, 인증 | [teacher_registration.md](../specs/user/teacher_registration.md) | TBD |
| [Certificate](entities/teacher.md#certificate-자격증) | 자격증 | [teacher_registration.md](../specs/user/teacher_registration.md) | TBD |
| [ProfileVisibilitySettings](entities/teacher.md#profilevisibilitysettings-공개-범위-설정) | 공개 범위 설정 | [teacher_registration.md](../specs/user/teacher_registration.md) | TBD |
| [TeacherSearchFilter](entities/teacher.md#teachersearchfilter-검색-필터) | 검색 필터/결과 | [teacher_registration.md](../specs/user/teacher_registration.md) | TBD |

### 초대/연결

| 엔티티 | 설명 | 관련 스펙 | Hive TypeId |
|--------|------|----------|:-----------:|
| [Follow](entities/invite.md#follow-맞팔-관계) | 맞팔 관계 | [invite_system_v2.md](../specs/invite/invite_system_v2.md) | TBD |
| [Membership](entities/invite.md#membership-학원-멤버십) | 학원-사용자 관계 | [invite_system_v2.md](../specs/invite/invite_system_v2.md) | TBD |
| [TeacherSettings](entities/invite.md#teachersettings-선생님-설정) | 선생님 초대 설정 | [invite_system_v2.md](../specs/invite/invite_system_v2.md) | TBD |
| [PracticeLevel](entities/invite.md#practicelevel-연습-레벨) | 연습 레벨 (성과) | [invite_system_v2.md](../specs/invite/invite_system_v2.md) | TBD |

### 알림

| 엔티티 | 설명 | 관련 스펙 | Hive TypeId |
|--------|------|----------|:-----------:|
| [NotificationType](entities/notification.md#notificationtype) | 알림 유형 enum | [notification_system.md](../specs/notification/notification_system.md) | TBD |
| [NotificationPriority](entities/notification.md#notificationpriority) | 알림 우선순위 | [notification_system.md](../specs/notification/notification_system.md) | TBD |
| [AppNotification](entities/notification.md#appnotification) | 알림 엔티티 | [notification_system.md](../specs/notification/notification_system.md) | TBD |
| [NotificationTemplate](entities/notification.md#notificationtemplate) | 알림 템플릿 | [notification_system.md](../specs/notification/notification_system.md) | TBD |
| [NotificationSettings](entities/notification.md#notificationsettings) | 사용자별 알림 설정 | [notification_system.md](../specs/notification/notification_system.md) | TBD |

---

## Hive TypeId 할당 현황

| 범위 | 도메인 | 엔티티 |
|------|--------|--------|
| 31-34 | 연습/수강권 | PracticeNote (31), PracticeGoal (32), BillingType (33), FifthWeekPolicy (34) |
| 55-62 | 수강권 | Subscription (55-57), SubscriptionOption (58-60), SubscriptionScope (61), SubscriptionUsage (62) |
| 60-62 | 클래스 | LessonClass (60-62) |
| 63-72 | 학부모 | Parent (63), Child (64), ParentChildRelation (65), ConnectionStatus (66), ProfileType (67), ParentPermission (68), UserProfile (69), ParentTeacherConnection (70), ParentVisibilitySettings (71), ParentNotificationSettings (72) |
| 73-80 | 결제 | Payment, Invoice, TeacherPaymentConfig |
| 81-89 | 연습공간 | PracticeSpace, CoachConnection, Assignment, InviteCode |
| 90-93 | 예약 | Booking, LessonType, BookingStatus, TeacherStudentRelation |
| 94-101 | 스케줄 | FifthWeekPolicy, RegularLessonSettings, TeacherAvailability, TeacherPolicy |
| TBD | 가용시간 | TeacherAvailability (schema), WeeklySchedule, TimeException, GoogleCalendarSync |
| TBD | 취소정책 | CancellationPolicy, NoShowPolicy, CancellationRecord, PenaltyResult |
| TBD | 리뷰 | TeacherReview, ReviewerType, ReviewTrigger, CategoryRatings, LessonFeedback, LessonSatisfaction, TeacherResponse, TeacherReviewSettings, ReviewVisibility, TeacherBadge, TeacherReviewStats |
| TBD | 선생님 | Teacher, ProfileCompletionLevel, PhoneVerification, Certificate, CertificateStatus, CertificateType, TeacherVerification, VerificationBadge, ProfileVisibilitySettings, ProfileVisibility, Education, Career, FeeRange, LessonType, Video |
| TBD | 초대 | Follow, FollowUserRole, InviteMethod, TeacherSettings, Membership, MembershipRole, MembershipStatus, PracticeLevel |

---

## 문서 분리 원칙

| 구분 | 위치 | 내용 |
|------|------|------|
| **설계 (What)** | `docs/specs/` | 비즈니스 요구사항, 상태 enum 테이블, 관계도, UI 설계 |
| **구현 (How)** | `docs/schema/` | Dart 엔티티, JSON 스키마, Hive TypeId, API 스펙 |

### Spec 문서에 남길 내용
- 상태 enum 이름과 의미 (테이블 형식)
- 엔티티 간 관계도 (ASCII)
- UI 설계 (ASCII 또는 Figma 링크)
- 비즈니스 규칙

### Schema로 이동한 내용
- 전체 Dart class 코드
- 필드별 상세 설명 및 타입
- JSON 직렬화 예시
- Hive TypeId 할당
- Repository 메서드 시그니처

---

## 파일 위치 규칙

```dart
// 엔티티 파일 위치 (예시)
lib/features/students/domain/entities/lesson_class.dart
lib/features/schedule/domain/entities/booking.dart
lib/features/schedule/domain/entities/teacher_availability.dart
lib/features/schedule/domain/entities/teacher_policy.dart
lib/features/lessons/domain/entities/payment.dart
lib/features/practice/domain/entities/practice_space.dart
```

---

## 관련 문서

| 문서 | 설명 |
|------|------|
| [architecture.md](../architecture.md) | 앱 아키텍처 가이드 |
| [implementation_roadmap.md](../specs/dev/implementation_roadmap.md) | 구현 로드맵 |
