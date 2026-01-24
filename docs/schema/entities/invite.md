# Invite 관련 엔티티

> 작성일: 2026-01-24
> 상태: 📋 설계 완료 (미구현)
> 관련 스펙: [invite_system_v2.md](../../specs/invite/invite_system_v2.md)

---

## 개요

초대 시스템과 맞팔(Mutual Follow) 시스템의 핵심 엔티티입니다.

```
초대 시스템
├── Follow (맞팔 관계)
│   └── FollowUserRole
├── InviteMethod (초대 방법)
└── TeacherSettings (선생님 설정)

학원 멤버십
├── Membership (학원-사용자 관계)
│   ├── MembershipRole
│   └── MembershipStatus

연습 상태
└── PracticeLevel (연습 레벨)
```

---

## Hive TypeId 할당 (예정)

> ⚠️ 구현 시 할당 필요

| TypeId | 엔티티 |
|:------:|--------|
| TBD | Follow |
| TBD | FollowUserRole |
| TBD | InviteMethod |
| TBD | TeacherSettings |
| TBD | Membership |
| TBD | MembershipRole |
| TBD | MembershipStatus |
| TBD | PracticeLevel |

---

## Follow (맞팔 관계)

```dart
class Follow {
  final String id;
  final String followerId;       // 팔로우 하는 사람
  final FollowUserRole followerRole;
  final String followeeId;       // 팔로우 받는 사람
  final FollowUserRole followeeRole;
  final DateTime createdAt;
}
```

### 필드 설명

| 필드 | 타입 | 설명 |
|------|------|------|
| id | String | 고유 식별자 |
| followerId | String | 팔로우 하는 사람 ID |
| followerRole | FollowUserRole | 팔로우 하는 사람 역할 |
| followeeId | String | 팔로우 받는 사람 ID |
| followeeRole | FollowUserRole | 팔로우 받는 사람 역할 |
| createdAt | DateTime | 생성일 |

### 맞팔 판단 로직

```dart
// A가 B를 팔로우하는 레코드
Follow(followerId: A, followeeId: B)

// B가 A를 팔로우하는 레코드
Follow(followerId: B, followeeId: A)

// 두 레코드 모두 존재 → 맞팔(연결) 상태
bool isMutualFollow(String userA, String userB) {
  return exists(followerId: userA, followeeId: userB) &&
         exists(followerId: userB, followeeId: userA);
}
```

---

## FollowUserRole (팔로우 사용자 역할)

```dart
enum FollowUserRole {
  teacher,   // 선생님
  student,   // 학생
}
```

| 값 | 설명 |
|------|------|
| teacher | 선생님 |
| student | 학생 |

---

## InviteMethod (초대 방법)

```dart
enum InviteMethod {
  sms,     // 📱 문자 메시지
  kakao,   // 💬 카카오톡 공유
  link,    // 🔗 링크 복사
  qr,      // 📷 QR 코드
}
```

| 값 | 아이콘 | 설명 |
|------|:------:|------|
| sms | 📱 | 문자 메시지 |
| kakao | 💬 | 카카오톡 공유 |
| link | 🔗 | 링크 복사 |
| qr | 📷 | QR 코드 |

---

## TeacherSettings (선생님 설정)

```dart
class TeacherSettings {
  final String teacherId;
  final bool autoAcceptConnection;  // 기본: true
  final DateTime? updatedAt;
}
```

### 필드 설명

| 필드 | 타입 | 기본값 | 설명 |
|------|------|:------:|------|
| teacherId | String | - | 선생님 ID |
| autoAcceptConnection | bool | true | 연결 요청 자동 수락 여부 |
| updatedAt | DateTime? | null | 수정일 |

---

## PracticeLevel (연습 레벨)

> **Note**: 학생의 주간 연습 현황을 나타내는 상태

```dart
enum PracticeLevel {
  newStudent,   // 🟣 신규 연결 (아직 데이터 없음)
  excellent,    // 🟢 우수 (5/7일 이상)
  average,      // 🟠 보통 (3-4/7일)
  poor,         // 🔴 부족 (1-2/7일)
  onBreak,      // ⚪ 휴강 중
}
```

| 값 | 색상 | 조건 |
|------|:------:|------|
| newStudent | 🟣 | 신규 연결 (연습 데이터 없음) |
| excellent | 🟢 | 주 5일 이상 연습 |
| average | 🟠 | 주 3-4일 연습 |
| poor | 🔴 | 주 1-2일 연습 |
| onBreak | ⚪ | 휴강 중 |

---

## Membership (학원 멤버십)

```dart
class Membership {
  final String id;
  final String organizationId;  // 학원 ID
  final String userId;
  final MembershipRole role;
  final MembershipStatus status;
  final DateTime joinedAt;
  final DateTime? invitedAt;
  final String? invitedBy;      // 초대한 사람 ID
}
```

### 필드 설명

| 필드 | 타입 | 설명 |
|------|------|------|
| id | String | 고유 식별자 |
| organizationId | String | 학원 ID |
| userId | String | 사용자 ID |
| role | MembershipRole | 역할 (owner/manager/instructor) |
| status | MembershipStatus | 상태 |
| joinedAt | DateTime | 가입일 |
| invitedAt | DateTime? | 초대일 |
| invitedBy | String? | 초대한 사람 ID |

---

## MembershipRole (멤버십 역할)

```dart
enum MembershipRole {
  owner,      // 👑 원장
  manager,    // 📋 매니저
  instructor, // 🎵 강사
}
```

| 값 | 아이콘 | 설명 | 권한 |
|------|:------:|------|------|
| owner | 👑 | 원장 | 모든 권한 |
| manager | 📋 | 매니저 | 학생/강사 관리, 정산 조회 |
| instructor | 🎵 | 강사 | 자기 학생만 관리 |

---

## MembershipStatus (멤버십 상태)

```dart
enum MembershipStatus {
  pending,    // 초대/가입 대기 중
  active,     // 활성 멤버
  suspended,  // 일시 정지
  left,       // 탈퇴
}
```

| 값 | 설명 |
|------|------|
| pending | 초대/가입 대기 중 |
| active | 활성 멤버 |
| suspended | 일시 정지 |
| left | 탈퇴 |

---

## 관련 엔티티 참조

### 학생 연결 상태

> 📦 [student.md](student.md)의 `ConnectionStatus` 참조

| 값 | 설명 |
|------|------|
| offline | ⚪ 미연결 (앱 미사용) |
| inviteSent | 🟡 초대 발송됨 |
| connected | 🟢 연결됨 |

### 학부모-선생님 연결

> 📦 [parent.md](parent.md)의 `ParentTeacherConnection` 참조

### 결제 관련

> 📦 [payment.md](payment.md)의 `PaymentStatus`, `Payment` 참조

---

## 연결 상태 매트릭스

```
┌─────────────────────────────────────────────────────────────┐
│                    학생 상태 인디케이터                        │
├─────────────────────────────────────────────────────────────┤
│  ConnectionStatus  │  PracticeLevel  │  최종 표시            │
├─────────────────────────────────────────────────────────────┤
│  offline           │  -              │  ⚪ 미연결            │
│  inviteSent        │  -              │  🟡 초대 대기         │
│  connected         │  newStudent     │  🟣 신규              │
│  connected         │  excellent      │  🟢 우수              │
│  connected         │  average        │  🟠 보통              │
│  connected         │  poor           │  🔴 부족              │
│  connected         │  onBreak        │  ⚪ 휴강              │
└─────────────────────────────────────────────────────────────┘
```

---

## 초대 → 연결 플로우

```
[선생님이 학생 초대]
        │
        ▼
    Follow 생성
    (teacher → student)
        │
        ▼
    학생 앱에 알림
        │
        ├──[학생이 수락]──► Follow 생성 (student → teacher)
        │                         │
        │                         ▼
        │                   맞팔 완성! 🎉
        │                   ConnectionStatus = connected
        │
        └──[학생이 거절]──► 초대 삭제
```

---

## 파일 위치 (예정)

```
lib/features/invite/domain/entities/follow.dart
lib/features/invite/domain/entities/membership.dart
lib/features/invite/domain/entities/invite_method.dart
lib/features/profile/domain/entities/teacher_settings.dart
lib/features/students/domain/entities/practice_level.dart
```

---

## 관련 문서

| 문서 | 설명 |
|------|------|
| [invite_system_v2.md](../../specs/invite/invite_system_v2.md) | 초대 시스템 스펙 (맞팔 시스템) |
| [student.md](student.md) | 학생 엔티티 (ConnectionStatus) |
| [parent.md](parent.md) | 학부모 엔티티 (ParentTeacherConnection) |
| [payment.md](payment.md) | 결제 엔티티 |
