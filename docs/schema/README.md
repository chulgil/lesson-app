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
│   ├── lesson_class.md       # LessonClass (학원/개인 클래스)
│   ├── class_membership.md   # ClassMembership (학생-클래스 관계)
│   ├── subscription.md       # Subscription (수강권)
│   ├── lesson_location.md    # LessonLocation (레슨 장소)
│   ├── student.md            # Student (학생)
│   └── parent.md             # Parent (학부모)
└── api/                      # API 스펙 (추후)
    └── ...
```

---

## 엔티티 인덱스

| 엔티티 | 설명 | 관련 스펙 |
|--------|------|----------|
| [LessonClass](entities/lesson_class.md) | 학원/개인레슨 클래스 | [student_class_system.md](../specs/student/student_class_system.md) |
| [ClassMembership](entities/class_membership.md) | 학생-클래스 소속 관계 | [student_class_system.md](../specs/student/student_class_system.md) |
| [Subscription](entities/subscription.md) | 수강권 | [subscription_system_spec.md](../specs/subscription/subscription_system_spec.md) |
| [LessonLocation](entities/lesson_location.md) | 레슨 장소 | [student_class_system.md](../specs/student/student_class_system.md) |
| [Student](entities/student.md) | 학생 (단순화) | [student_class_system.md](../specs/student/student_class_system.md) |
| [Parent](entities/parent.md) | 학부모 | [parent_system.md](../specs/user/parent_system.md) |

---

## 문서 분리 원칙

| 구분 | 위치 | 내용 |
|------|------|------|
| **설계 (What)** | `docs/specs/` | 비즈니스 요구사항, 상태 enum, 관계도, UI 설계 |
| **구현 (How)** | `docs/schema/` | Dart 엔티티, JSON 스키마, 테이블 설계, API 스펙 |

### Spec 문서에 남길 내용
- 상태 enum 이름과 의미 (예: `SubscriptionStatus`)
- 엔티티 간 관계도 (ASCII)
- UI 설계 (ASCII 또는 Figma 링크)
- 비즈니스 규칙

### Schema로 이동한 내용
- 전체 Dart class 코드
- 필드별 상세 설명 및 타입
- JSON 직렬화 예시
- Repository 메서드 시그니처
- 마이그레이션 스크립트

---

## 파일 위치 규칙

```dart
// 엔티티 파일 위치
lib/features/students/domain/entities/lesson_class.dart
lib/features/students/domain/entities/class_membership.dart
lib/features/subscription/domain/entities/subscription.dart
```

---

## 관련 문서

| 문서 | 설명 |
|------|------|
| [architecture.md](../architecture.md) | 앱 아키텍처 가이드 |
| [implementation_roadmap.md](../specs/dev/implementation_roadmap.md) | 구현 로드맵 |
