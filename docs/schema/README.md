# 데이터 스키마 문서

> 마지막 업데이트: 2026-01-24

이 폴더는 **구현 상세** 문서를 포함합니다.
비즈니스 요구사항과 UI 설계는 `docs/specs/`를 참조하세요.

---

## 문서 구조

```
docs/schema/
├── README.md                 # 이 문서
├── entities/                 # 엔티티 정의
│   ├── booking.md            # Booking (레슨 예약)
│   ├── class_membership.md   # ClassMembership (학생-클래스 관계)
│   ├── lesson_class.md       # LessonClass (학원/개인 클래스)
│   ├── lesson_location.md    # LessonLocation (레슨 장소)
│   ├── lesson_schedule.md    # LessonSchedule (스케줄 설정)
│   ├── parent.md             # Parent (학부모)
│   ├── payment.md            # Payment, Invoice (결제)
│   ├── practice_space.md     # PracticeSpace (연습 공간)
│   ├── student.md            # Student (학생)
│   └── subscription.md       # Subscription (수강권)
└── api/                      # API 스펙 (추후)
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
| [LessonLocation](entities/lesson_location.md) | 레슨 장소 | [student_class_system.md](../specs/student/student_class_system.md) | 63-65 |

### 학생/연습

| 엔티티 | 설명 | 관련 스펙 | Hive TypeId |
|--------|------|----------|:-----------:|
| [Student](entities/student.md) | 학생 | [student_class_system.md](../specs/student/student_class_system.md) | - |
| [ClassMembership](entities/class_membership.md) | 학생-클래스 소속 관계 | [student_class_system.md](../specs/student/student_class_system.md) | 66-67 |
| [PracticeSpace](entities/practice_space.md) | 연습 공간, 코치 연결 | [student_centered_architecture.md](../specs/lesson/student_centered_architecture.md) | 81-89 |

### 결제/수강권

| 엔티티 | 설명 | 관련 스펙 | Hive TypeId |
|--------|------|----------|:-----------:|
| [Payment](entities/payment.md) | 결제, 청구서 | [payment_unified_spec.md](../specs/payment/payment_unified_spec.md) | 70-80 |
| [Subscription](entities/subscription.md) | 수강권 | [subscription_system_spec.md](../specs/subscription/subscription_system_spec.md) | 50-52 |

### 사용자

| 엔티티 | 설명 | 관련 스펙 | Hive TypeId |
|--------|------|----------|:-----------:|
| [Parent](entities/parent.md) | 학부모 | [parent_system.md](../specs/user/parent_system.md) | - |

---

## Hive TypeId 할당 현황

| 범위 | 도메인 | 엔티티 |
|------|--------|--------|
| 50-59 | 수강권 | Subscription (55-57) |
| 60-69 | 클래스 | LessonClass (60-62), LessonLocation (63-65), ClassMembership (66-67) |
| 70-80 | 결제 | Payment, Invoice, TeacherPaymentConfig |
| 81-89 | 연습공간 | PracticeSpace, CoachConnection, Assignment, InviteCode |
| 90-93 | 예약 | Booking, LessonType, BookingStatus, TeacherStudentRelation |
| 94-101 | 스케줄 | FifthWeekPolicy, RegularLessonSettings, TeacherAvailability, TeacherPolicy |

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
