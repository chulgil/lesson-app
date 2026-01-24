# 구현 로드맵: 학원/수강권/3자 관계 시스템

> 작성일: 2026-01-24
> 상태: 계획
> 연관 스펙: [role_based_screens.md](../design/role_based_screens.md), [student_class_system.md](../student/student_class_system.md), [subscription_system_spec.md](../subscription/subscription_system_spec.md)

## 개요

이 문서는 학원/수강권/3자 관계 시스템의 **구현 로드맵**입니다.
현재 설계 문서는 95% 완료되어 있으나, 실제 구현은 약 20% 수준입니다.

---

## 현재 상태 분석

### 설계 완료 항목 (문서화됨)

| 스펙 | 엔티티 | 화면 설계 | 상태 |
|------|--------|----------|------|
| LessonClass (학원/개인) | ✅ | ✅ | 설계 완료 |
| ClassMembership (소속 관계) | ✅ | ✅ | 설계 완료 |
| Subscription (수강권) | ✅ | ✅ | 설계 완료 |
| LessonLocation (레슨 장소) | ✅ | ✅ | 설계 완료 |
| Payment (외부 결제) | ✅ | ✅ | 설계 완료 |
| Parent-Child (학부모-자녀) | ✅ | ✅ | 설계 완료 |

### 구현 현황

| 기능 | 구현 상태 | 비고 |
|------|:--------:|------|
| 기본 Student CRUD | ✅ 완료 | 학원/개인 구분 없음 |
| Lesson 관리 | ✅ 완료 | 수강권 연동 없음 |
| Payment (기존) | ✅ 완료 | 단순 금액 입력 방식 |
| 연습/녹음 | ✅ 완료 | - |
| 메트로놈/튜너 | ✅ 완료 | - |
| LessonClass | ❌ 미구현 | 엔티티 없음 |
| ClassMembership | ❌ 미구현 | 엔티티 없음 |
| Subscription | ❌ 미구현 | 엔티티 없음 |
| LessonLocation | ❌ 미구현 | 엔티티 없음 |
| 학부모 앱 | 🔶 부분 | 기본 UI만 존재 |

---

## Phase 1: 기반 엔티티 구현 (2주)

### 1.1 LessonClass 엔티티

```dart
// lib/features/students/domain/entities/lesson_class.dart
class LessonClass {
  final String id;
  final String teacherId;
  final String name;
  final LessonClassType type;       // academy, private
  final String? academyId;          // 학원 ID (academy 타입만)
  final String? academyName;        // 학원명
  final PaymentTarget paymentTarget; // academy, teacher, parent
  final DateTime createdAt;
  final DateTime updatedAt;
}

enum LessonClassType { academy, private }
enum PaymentTarget { academy, teacher, parent }
```

**작업 항목**:
- [ ] `lesson_class.dart` 엔티티 생성
- [ ] `mock_lesson_class_repository.dart` 생성
- [ ] `lesson_class_providers.dart` 생성
- [ ] Hive TypeAdapter 생성
- [ ] `build_runner` 실행

### 1.2 ClassMembership 엔티티

```dart
// lib/features/students/domain/entities/class_membership.dart
class ClassMembership {
  final String id;
  final String studentId;
  final String lessonClassId;
  final String? instrument;
  final String? level;
  final DayOfWeek? regularLessonDay;
  final TimeOfDay? regularLessonTime;
  final int? lessonDurationMinutes;
  final MembershipStatus status;    // active, paused, terminated
  final DateTime joinedAt;
  final DateTime? terminatedAt;
}

enum MembershipStatus { active, paused, terminated }
```

**작업 항목**:
- [ ] `class_membership.dart` 엔티티 생성
- [ ] `mock_membership_repository.dart` 생성
- [ ] `membership_providers.dart` 생성
- [ ] Hive TypeAdapter 생성

### 1.3 LessonLocation 엔티티

```dart
// lib/features/students/domain/entities/lesson_location.dart
class LessonLocation {
  final String id;
  final String? lessonClassId;      // 학원/클래스와 연결 (선택)
  final LessonLocationType type;
  final String? name;               // 장소명
  final String? address;
  final String? detailAddress;      // 층/호
  final String? phone;
  final double? latitude;
  final double? longitude;
  final String? memo;               // 추가 안내사항
  final String? roomName;           // 레슨실 이름
}

enum LessonLocationType {
  academyRoom,     // 학원 레슨실
  teacherStudio,   // 선생님 작업실
  studentHome,     // 학생 집 방문
  online,          // 온라인
  other,           // 기타
}
```

**작업 항목**:
- [ ] `lesson_location.dart` 엔티티 생성
- [ ] `mock_location_repository.dart` 생성
- [ ] `location_providers.dart` 생성
- [ ] Hive TypeAdapter 생성

---

## Phase 2: 수강권 시스템 구현 (2주)

### 2.1 Subscription 엔티티

```dart
// lib/features/subscription/domain/entities/subscription.dart
class Subscription {
  final String id;
  final String studentId;
  final String lessonClassId;
  final String? paymentId;          // 연결된 결제 (선택)
  final SubscriptionType type;      // trial, monthly, package
  final int? totalLessons;          // 회차제: 총 횟수
  final int? usedLessons;           // 회차제: 사용 횟수
  final DateTime? startDate;
  final DateTime? endDate;
  final int amount;                 // 금액
  final SubscriptionStatus status;  // active, expiring, expired
  final DateTime createdAt;
}

enum SubscriptionType { trial, monthly, package }
enum SubscriptionStatus { active, expiringSoon, expired }
```

**작업 항목**:
- [ ] `subscription.dart` 엔티티 생성
- [ ] `mock_subscription_repository.dart` 생성
- [ ] `subscription_providers.dart` 생성
- [ ] Hive TypeAdapter 생성

### 2.2 Payment 엔티티 확장

```dart
// lib/features/lessons/domain/entities/payment.dart (기존 수정)
class Payment {
  final String id;
  final String? studentId;          // 기존
  final String? lessonClassId;      // 🆕 추가
  final int amount;
  final PaymentMethod method;       // 🆕 card, transfer, cash
  final PaymentStatus status;       // pending, confirmed, overdue
  final DateTime? dueDate;          // 🆕 납부기한
  final DateTime? paidAt;           // 🆕 결제 완료일
  final String? bankAccount;        // 🆕 입금 계좌
  final String? memo;
  final DateTime createdAt;
}

enum PaymentMethod { card, transfer, cash }
enum PaymentStatus { pending, confirmed, overdue }
```

**작업 항목**:
- [ ] 기존 `payment.dart` 확장
- [ ] PaymentMethod, PaymentStatus enum 추가
- [ ] Repository 메서드 추가
- [ ] Provider 수정

### 2.3 수강권 Provider

```dart
// lib/features/subscription/presentation/providers/subscription_providers.dart

@riverpod
Future<List<Subscription>> studentSubscriptions(
  Ref ref,
  String studentId,
) async {
  final repository = ref.watch(subscriptionRepositoryProvider);
  return repository.getByStudentId(studentId);
}

@riverpod
class SubscriptionNotifier extends _$SubscriptionNotifier {
  @override
  Future<Subscription?> build(String subscriptionId) async {
    // ...
  }

  Future<void> useLessonCredit() async {
    // 레슨 1회 차감
  }

  Future<void> checkExpiry() async {
    // 만료 임박 체크
  }
}
```

**작업 항목**:
- [ ] `subscription_providers.dart` 생성
- [ ] `subscription_crud_provider.dart` 생성
- [ ] 레슨 완료 시 수강권 차감 로직
- [ ] 수강권 만료 알림 로직

---

## Phase 3: 선생님 앱 UI 구현 (2주)

### 3.1 학생 목록 화면 수정

**파일**: `lib/features/students/presentation/screens/student_list_screen.dart`

**변경 사항**:
- [ ] 학원/개인레슨별 그룹핑 추가
- [ ] 컨텍스트 배지 (🏫/👤) 표시
- [ ] 수강권 잔여 표시
- [ ] 필터 옵션 (전체/학원/개인)

### 3.2 학생 상세 화면 수정

**파일**: `lib/features/students/presentation/screens/student_detail_screen.dart`

**변경 사항**:
- [ ] 소속 정보 (LessonClass) 표시
- [ ] 수강권 현황 카드 추가
- [ ] 학부모 정보 섹션 추가
- [ ] 레슨 장소 정보 섹션 추가

### 3.3 수강권 발급 화면 (신규)

**파일**: `lib/features/subscription/presentation/screens/issue_subscription_screen.dart`

**구현 항목**:
- [ ] 화면 생성
- [ ] 수강권 유형 선택 (체험/월정액/회차)
- [ ] 기간/횟수 입력
- [ ] 금액 입력
- [ ] 결제 요청 발송

### 3.4 미수금 관리 화면 수정

**파일**: `lib/features/lessons/presentation/screens/payment_management_screen.dart`

**변경 사항**:
- [ ] 개인레슨 미수금만 표시 (학원은 제외)
- [ ] 입금 확인 버튼
- [ ] 독촉 알림 버튼

---

## Phase 4: 학생 앱 UI 구현 (2주)

### 4.1 홈 화면 수정

**파일**: `lib/features/student_home/presentation/screens/student_home_screen.dart`

**변경 사항**:
- [ ] 소속 정보 (학원/개인) 배지 추가
- [ ] 수강권 잔여 표시
- [ ] 다중 레슨 탭 (여러 악기/선생님)

### 4.2 수강권 상세 화면 (신규)

**파일**: `lib/features/subscription/presentation/screens/student_subscription_screen.dart`

**구현 항목**:
- [ ] 화면 생성
- [ ] 잔여 횟수/기간 표시
- [ ] 이용 내역 표시
- [ ] 만료 임박 알림

### 4.3 레슨 장소 화면 (신규)

**파일**: `lib/features/lessons/presentation/screens/lesson_location_screen.dart`

**구현 항목**:
- [ ] 화면 생성
- [ ] 지도 연동 (Google Maps 또는 네이버 지도)
- [ ] 길찾기 버튼
- [ ] 메모 표시

---

## Phase 5: 학부모 앱 UI 구현 (2주)

### 5.1 프로필 선택 화면 보완

**파일**: `lib/features/parent_home/presentation/screens/profile_selector_screen.dart`

**변경 사항**:
- [ ] 자녀별 소속 배지 표시
- [ ] 수강권 요약 정보 표시

### 5.2 대시보드 화면 수정

**파일**: `lib/features/parent_home/presentation/screens/parent_dashboard_screen.dart`

**변경 사항**:
- [ ] 수강권 현황 카드 추가
- [ ] 미결제 알림 영역
- [ ] 레슨 장소 바로가기

### 5.3 결제 관리 화면 (신규)

**파일**: `lib/features/parent_home/presentation/screens/payment_management_screen.dart`

**구현 항목**:
- [ ] 화면 생성
- [ ] 미결제 내역 표시
- [ ] 복수 자녀 통합 결제
- [ ] 입금 완료 알림 버튼
- [ ] 결제 완료 내역

### 5.4 수강권 조회 화면 (신규)

**파일**: `lib/features/parent_home/presentation/screens/child_subscription_screen.dart`

**구현 항목**:
- [ ] 화면 생성
- [ ] 자녀별 수강권 현황
- [ ] 이용 내역 표시

---

## Phase 6: 통합 및 테스트 (1주)

### 6.1 데이터 마이그레이션

**작업 항목**:
- [ ] 기존 Student → ClassMembership 변환 스크립트
- [ ] 기존 Payment → 새 Payment 형식 변환
- [ ] Hive 스키마 마이그레이션

### 6.2 라우팅 통합

**파일**: `lib/core/router/routes/`

**작업 항목**:
- [ ] `subscription_routes.dart` 추가
- [ ] `location_routes.dart` 추가
- [ ] 기존 라우트 수정

### 6.3 테스트

**작업 항목**:
- [ ] 엔티티 단위 테스트
- [ ] Provider 단위 테스트
- [ ] 화면 UI 테스트
- [ ] E2E 시나리오 테스트

---

## 우선순위 매트릭스

| Phase | 기간 | 의존성 | 중요도 |
|-------|------|--------|--------|
| Phase 1: 기반 엔티티 | 2주 | 없음 | 🔴 Critical |
| Phase 2: 수강권 시스템 | 2주 | Phase 1 | 🔴 Critical |
| Phase 3: 선생님 앱 UI | 2주 | Phase 1, 2 | 🟠 High |
| Phase 4: 학생 앱 UI | 2주 | Phase 1, 2 | 🟠 High |
| Phase 5: 학부모 앱 UI | 2주 | Phase 1, 2 | 🟡 Medium |
| Phase 6: 통합 테스트 | 1주 | Phase 1-5 | 🟠 High |

**총 예상 기간**: 11주 (약 3개월)

---

## 파일 구조 예상

```
lib/
├── features/
│   ├── students/
│   │   ├── domain/
│   │   │   └── entities/
│   │   │       ├── student.dart
│   │   │       ├── lesson_class.dart          # 🆕
│   │   │       ├── class_membership.dart      # 🆕
│   │   │       └── lesson_location.dart       # 🆕
│   │   ├── data/
│   │   │   └── repositories/
│   │   │       ├── mock_student_repository.dart
│   │   │       ├── mock_lesson_class_repository.dart    # 🆕
│   │   │       ├── mock_membership_repository.dart      # 🆕
│   │   │       └── mock_location_repository.dart        # 🆕
│   │   └── presentation/
│   │       └── providers/
│   │           ├── student_providers.dart
│   │           ├── lesson_class_providers.dart          # 🆕
│   │           ├── membership_providers.dart            # 🆕
│   │           └── location_providers.dart              # 🆕
│   │
│   ├── subscription/                                    # 🆕 전체
│   │   ├── domain/
│   │   │   └── entities/
│   │   │       └── subscription.dart
│   │   ├── data/
│   │   │   └── repositories/
│   │   │       └── mock_subscription_repository.dart
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── issue_subscription_screen.dart
│   │       │   ├── student_subscription_screen.dart
│   │       │   └── child_subscription_screen.dart
│   │       ├── widgets/
│   │       │   ├── subscription_card.dart
│   │       │   └── subscription_progress.dart
│   │       └── providers/
│   │           ├── subscription_providers.dart
│   │           └── subscription_crud_provider.dart
│   │
│   ├── parent_home/
│   │   └── presentation/
│   │       └── screens/
│   │           ├── parent_dashboard_screen.dart         # 수정
│   │           ├── payment_management_screen.dart       # 🆕
│   │           └── child_subscription_screen.dart       # 🆕
│   │
│   └── lessons/
│       ├── domain/
│       │   └── entities/
│       │       └── payment.dart                         # 수정
│       └── presentation/
│           └── screens/
│               └── lesson_location_screen.dart          # 🆕
│
└── core/
    └── router/
        └── routes/
            ├── subscription_routes.dart                 # 🆕
            └── location_routes.dart                     # 🆕
```

---

## 리스크 및 완화 방안

| 리스크 | 영향 | 완화 방안 |
|--------|------|----------|
| 기존 데이터 마이그레이션 실패 | 🔴 High | 단계별 마이그레이션, 롤백 스크립트 준비 |
| Hive 스키마 변경 충돌 | 🟠 Medium | 버전 관리, TypeAdapter 신중하게 설계 |
| UI 일관성 깨짐 | 🟡 Low | 공통 컴포넌트 사용, 디자인 가이드 준수 |
| 성능 저하 (복잡한 관계) | 🟠 Medium | 캐싱 전략, 쿼리 최적화 |

---

## 다음 단계

1. **Phase 1 착수**: LessonClass, ClassMembership 엔티티 구현
2. **Mock 데이터 준비**: 테스트용 학원/개인레슨 데이터 생성
3. **기존 코드 영향 분석**: Student, Lesson, Payment 변경 범위 확인
4. **GitHub Issue 생성**: Phase별 작업을 이슈로 등록

---

## 참조 문서

| 문서 | 내용 |
|------|------|
| [role_based_screens.md](../design/role_based_screens.md) | 역할별 화면 설계 |
| [student_class_system.md](../student/student_class_system.md) | 엔티티 상세 설계 |
| [subscription_system_spec.md](../subscription/subscription_system_spec.md) | 수강권 비즈니스 로직 |
| [payment_unified_spec.md](../payment/payment_unified_spec.md) | 결제 상태 관리 |
| [architecture.md](../../architecture.md) | 앱 아키텍처 가이드 |
