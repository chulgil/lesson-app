# 양방향 초대 시스템 스펙

> 마지막 업데이트: 2025-12-28

## 개요

선생님과 학생이 서로를 초대하여 연결을 맺는 양방향 초대 시스템입니다.

### 핵심 기능
- **QR 코드**: 앱 내에서 스캔하여 즉시 연결
- **URL 링크**: 카카오톡, 문자 등으로 공유
- **6자리 코드**: 수동 입력으로 연결
- **연결 요청 관리**: 수락/거절 워크플로우

---

## 사용자 흐름

### 1. 초대 생성 (선생님/학생)

```
메인 화면 → "초대하기" → InviteScreen
                          ├── QR 코드 표시
                          ├── URL 복사/공유
                          └── 6자리 코드 표시
```

### 2. 초대 수락

```
방법 A: QR 스캔
  카메라 → QR 인식 → InviteConfirmScreen → 연결 요청 전송

방법 B: URL 클릭
  브라우저 → 앱 실행 → InviteConfirmScreen → 연결 요청 전송

방법 C: 코드 입력
  CodeInputScreen → 6자리 입력 → InviteConfirmScreen → 연결 요청 전송
```

### 3. 연결 승인

```
PendingRequestsScreen
  ├── 요청 카드 표시
  ├── "수락" → 연결 생성
  └── "거절" → 요청 삭제
```

---

## 데이터 모델

### Invite (초대)

| 필드 | 타입 | 설명 |
|------|------|------|
| id | String | UUID |
| creatorId | String | 생성자 ID |
| creatorRole | InviteUserRole | teacher / student |
| inviteCode | String | 6자리 코드 |
| inviteUrl | String | 딥링크 URL |
| method | InviteMethod | qrCode / urlLink / inviteCode |
| status | InviteStatus | active / used / expired / revoked |
| expiresAt | DateTime | 만료 시간 (기본 7일) |
| createdAt | DateTime | 생성 시간 |

### ConnectionRequest (연결 요청)

| 필드 | 타입 | 설명 |
|------|------|------|
| id | String | UUID |
| inviteId | String | 초대 ID |
| requesterId | String | 요청자 ID |
| requesterRole | InviteUserRole | 요청자 역할 |
| targetId | String | 대상자 ID |
| status | ConnectionRequestStatus | pending / accepted / rejected / cancelled / expired |
| message | String? | 선택적 메시지 |
| createdAt | DateTime | 생성 시간 |
| respondedAt | DateTime? | 응답 시간 |

### Connection (연결)

| 필드 | 타입 | 설명 |
|------|------|------|
| id | String | UUID |
| teacherId | String | 선생님 ID |
| studentId | String | 학생 ID |
| connectionRequestId | String | 원본 요청 ID |
| status | ConnectionStatus | active / inactive |
| connectedAt | DateTime | 연결 시간 |

---

## 열거형 (Enums)

### InviteMethod
```dart
enum InviteMethod {
  qrCode,       // QR 코드
  urlLink,      // URL 링크
  inviteCode,   // 6자리 코드
  inAppSearch,  // 앱 내 검색 (향후)
}
```

### InviteStatus
```dart
enum InviteStatus {
  active,    // 활성
  used,      // 사용됨
  expired,   // 만료
  revoked,   // 취소
}
```

### InviteUserRole
```dart
enum InviteUserRole {
  teacher,   // 선생님
  student,   // 학생
}
```

### ConnectionRequestStatus
```dart
enum ConnectionRequestStatus {
  pending,    // 대기 중
  accepted,   // 수락됨
  rejected,   // 거절됨
  cancelled,  // 취소됨
  expired,    // 만료됨
}
```

---

## 화면 구성

| 화면 | 경로 | 설명 |
|------|------|------|
| InviteScreen | /invite | QR/URL/코드 생성 |
| ScanInviteScreen | /invite/scan | QR 스캔 |
| CodeInputScreen | /invite/code | 6자리 코드 입력 |
| InviteConfirmScreen | /invite/confirm | 연결 요청 확인 |
| InviteHistoryScreen | /invite/history | 내가 생성한 초대 내역 |
| PendingRequestsScreen | /invite/requests | 대기 중인 연결 요청 |
| MyConnectionsScreen | /connections | 내 연결 목록 |

---

## Provider 구조

### Repository
```dart
abstract class InviteRepository {
  // 초대 CRUD
  Future<Invite> createInvite(String creatorId, InviteUserRole creatorRole, InviteMethod method);
  Future<Invite?> getInviteByCode(String code);
  Future<void> revokeInvite(String inviteId);

  // 연결 요청
  Future<ConnectionRequest> createConnectionRequest(...);
  Future<void> acceptConnectionRequest(String requestId);
  Future<void> rejectConnectionRequest(String requestId);

  // 연결
  Future<List<Connection>> getConnectionsByUser(String userId, InviteUserRole role);
  Future<void> deactivateConnection(String connectionId);
}
```

### Notifiers
- `InviteCreator`: 초대 생성
- `InviteRevoker`: 초대 취소
- `ConnectionRequester`: 연결 요청 생성
- `ConnectionRequestResponder`: 요청 수락/거절
- `ConnectionManager`: 연결 비활성화

---

## 딥링크 형식

```
lessonapp://invite/{inviteCode}
```

예시:
```
lessonapp://invite/ABC123
```

---

## 비즈니스 규칙

### 초대 생성
- 초대 유효기간: 7일 (기본)
- 6자리 코드: 대문자 + 숫자 조합
- 동시 활성 초대 제한: 없음

### 연결 요청
- 동일인에게 중복 요청 불가 (대기 중일 때)
- 선생님 ↔ 학생만 연결 가능 (동일 역할 불가)
- 요청 만료: 7일

### 연결 관리
- 연결 비활성화 가능 (삭제 아님)
- 양측 모두 비활성화 가능
- 비활성화 후 재연결 가능

---

## 패키지 의존성

| 패키지 | 용도 |
|--------|------|
| qr_flutter | QR 코드 생성 |
| mobile_scanner | QR 코드 스캔 |
| share_plus | URL/텍스트 공유 |

---

## 파일 구조

```
lib/
├── models/
│   └── invite.dart              # 모델, 열거형
├── repositories/
│   └── invite_repository.dart   # 인터페이스 + Mock
├── providers/
│   └── invite/
│       ├── invite_provider.dart
│       └── invite_provider.g.dart
└── features/
    └── invite/
        └── presentation/
            └── screens/
                ├── invite_screen.dart
                ├── scan_invite_screen.dart
                ├── code_input_screen.dart
                ├── invite_confirm_screen.dart
                ├── invite_history_screen.dart
                ├── pending_requests_screen.dart
                └── my_connections_screen.dart
```

---

## 향후 확장

1. **앱 내 검색 연동**: InviteMethod.inAppSearch로 검색 결과에서 바로 연결 요청
2. **그룹 초대**: 여러 학생 동시 초대
3. **초대 통계**: 생성/사용 통계 대시보드
4. **만료 알림**: 초대 만료 전 알림
