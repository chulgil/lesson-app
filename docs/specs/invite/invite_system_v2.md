# 초대 시스템 v2 - 맞팔 기반 연결

> 마지막 업데이트: 2025-12-28

## 개요

선생님-학생 간 **상호 팔로우(맞팔)** 기반의 연결 시스템입니다.
수기 등록 학생을 지원하며, 앱 연결 시 자동 맞팔로 간소화된 UX를 제공합니다.

### 핵심 변경점 (v1 → v2)

| 항목 | v1 | v2 |
|------|----|----|
| 연결 방식 | 요청 → 수락 2단계 | **자동 맞팔** (즉시 연결) |
| 학생 등록 | 앱 연결 필수 | **수기 등록 지원** |
| 검색 방식 | 코드 입력 | **연락처 동기화 + 코드** |
| 상태 표시 | 없음 | **아이콘으로 연결 상태 표시** |

---

## 학생 상태 인디케이터 (통합)

기존 **연습 성과 인디케이터**와 **연결 상태**를 하나로 통합합니다.
앱 연결 여부에 따라 표시 내용이 달라집니다.

### 앱 연결됨 → 연습 성과 표시

| 상태 | 아이콘 | 색상 코드 | 설명 |
|------|:------:|:--------:|------|
| **우수** | 🟢 | `Colors.green` | 연습 잘함 (예: 5/7일 이상) |
| **보통** | 🟠 | `Colors.orange` | 적당히 연습 (예: 3-4/7일) |
| **부족** | 🔴 | `Colors.red` | 연습 부족 (예: 1-2/7일) |
| **휴강** | ⚪ | `Colors.grey[400]` | 휴강 중인 학생 |
| **신규 연결** | 🟣 | `Color(0xFF6B5B95)` | 연습 데이터 없음 (첫 연결) |

### 앱 미연결 → 연결 상태 표시

| 상태 | 아이콘 | 색상 코드 | 설명 |
|------|:------:|:--------:|------|
| **초대 보냄** | 🟡 | `Colors.amber` | 내가 팔로우함 (대기 중) |
| **초대 받음** | 🔵 | `Colors.blue` | 상대가 팔로우함 (수락 대기) |
| **오프라인** | ⚪ | `Colors.grey[400]` | 수기 등록 (앱 미사용) |
| **연결 끊김** | ⚪ | `Colors.grey[400]` | 학생이 팔로우 해제함 |

> **Note**: 오프라인과 연결 끊김은 동일한 회색 원으로 표시됩니다.
> 버튼으로 구분: 오프라인 → "앱 초대", 연결 끊김 → "재연결"

### 상태 전환 다이어그램

```
┌──────────────────────────────────────────────────────────────┐
│                        상태 전환 흐름                         │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│   [선생님: 수기 등록]                                         │
│         │                                                    │
│         ▼                                                    │
│     ⚪ 오프라인                                               │
│         │                                                    │
│         │ "앱 초대" 클릭                                      │
│         ▼                                                    │
│     🟡 초대 보냄 ────── 학생 팔로우 ──────► 🟣 신규 연결      │
│                                                              │
│   [학생: 선생님 검색]                                         │
│         │                                                    │
│         │ 전화번호/코드로 팔로우                              │
│         ▼                                                    │
│     🔵 초대 받음 ────── 선생님 수락 ──────► 🟣 신규 연결      │
│         │           (자동/수동 설정)                         │
│         │                                                    │
│         │ 수기 학생과 매칭 시                                 │
│         ▼                                                    │
│     🟣 신규 연결 (자동 연결)                                  │
│                                                              │
│                                                              │
│   [앱 연결 후] → 연습 성과에 따라 변경                        │
│                                                              │
│     🟣 신규 연결 ──── 연습 시작 ────► 🟢🟠🔴 연습 성과        │
│                                                              │
│                                                              │
│   [연결 해제]                                                 │
│                                                              │
│     🟢🟠🔴 연습성과 ── 학생이 언팔 ──► ⚪ 연결 끊김           │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

### 연결 승인 규칙

1. **선생님 → 학생 초대**: 학생이 팔로우하면 자동 맞팔
2. **학생 → 선생님 팔로우**: 선생님 설정에 따라 처리
   - **자동 수락 (기본)**: 즉시 맞팔 처리
   - **수동 수락**: 선생님이 알림에서 수락/거절
3. **수기 학생 매칭**: 전화번호 일치 시 자동 연결

### 선생님 설정

| 설정 | 기본값 | 설명 |
|------|:------:|------|
| 자동 연결 수락 | ✅ On | 학생 요청 시 자동으로 연결 수락 |

> **자동 수락 Off 시**: 학생이 선생님을 팔로우하면 🔵 초대 받음 상태가 되고,
> 선생님이 알림 센터에서 수락하면 연결됩니다.

---

## 사용자 흐름

### 선생님 플로우

```
홈 화면
├── [학생 추가] 버튼 (헤더)
│   └── 학생 추가 화면
│       ├── 🔍 연락처에서 찾기 → 연락처 목록 (앱 가입자 표시)
│       ├── 📱 전화번호로 찾기 → +82 입력 → 검색 결과
│       ├── 🔗 내 코드 공유 → QR/링크/문자 공유
│       └── ✏️ 수기 등록 → 이름, 전화번호 입력 → ⚪ 오프라인 상태
│
└── 학생 목록
    ├── 👤 김민수 🟢 ← 우수 (연습 잘함)
    ├── 👤 박철수 🟣 ← 신규 연결 (연습 데이터 없음)
    ├── 👤 이지은 🟡 ← 초대 보냄 (수락 대기)
    ├── 👤 박서준 🔵 ← 초대 받음 → 탭하면 자동 연결
    ├── 👤 최유리 ⚪ ← 오프라인 → "앱 초대" 버튼
    └── 👤 한지민 ⚪ ← 연결 끊김 → "재연결" 버튼
```

### 학생/학부모 플로우

```
홈 화면
├── [선생님 찾기] 버튼 (헤더)
│   └── 선생님 찾기 화면
│       ├── 🔍 연락처에서 찾기 → 선생님 목록
│       ├── 📱 전화번호로 찾기 → +82 입력
│       └── 🔢 코드로 연결 → 6자리 코드 입력
│
└── 내 선생님
    ├── 👤 김선생님 🟣 ← 신규 연결
    ├── 👤 이선생님 🟢 ← 우수 (연습 잘함)
    └── 👤 박선생님 🟡 ← 초대 보냄 (자동 수락 예정)
```

---

## 화면 구성

### 변경된 화면

| 화면 | 변경 사항 |
|------|----------|
| InviteScreen | → **AddConnectionScreen** (역할별 제목) |
| CodeInputScreen | 유지 (보조 수단) |
| InviteConfirmScreen | → **제거** (자동 연결) |
| PendingRequestsScreen | → **제거** (알림 센터로 통합) |
| MyConnectionsScreen | → 학생/선생님 목록에 통합 |

### 새로운 화면

| 화면 | 경로 | 설명 |
|------|------|------|
| AddConnectionScreen | /add | 연결 추가 (역할별 UI) |
| ContactSyncScreen | /add/contacts | 연락처 동기화 |
| PhoneSearchScreen | /add/phone | 전화번호 검색 |
| ManualAddScreen | /add/manual | 수기 등록 (선생님 전용) |
| TeacherSettingsScreen | /settings | 선생님 설정 (연결 수락 방식 등) |

### 선생님 설정 화면

```
TeacherSettingsScreen (/settings)
├── 프로필 섹션
│   ├── 프로필 사진
│   ├── 이름
│   └── 전화번호
│
├── 연결 설정 섹션
│   └── 🔘 자동 연결 수락 [Switch: On/Off]
│       └── 설명: "학생이 연결을 요청하면 자동으로 수락합니다"
│
├── 알림 설정 섹션
│   ├── 레슨 알림
│   ├── 연습 알림
│   └── 결제 알림
│
└── 계정 섹션
    ├── 로그아웃
    └── 계정 삭제
```

---

## 데이터 모델

### Student 모델 확장

```dart
class Student {
  final String id;
  final String name;
  final String? phoneNumber;           // +국가번호 형식
  final ConnectionStatus connectionStatus;  // 연결 상태
  final PracticeLevel? practiceLevel;  // 연습 성과 (연결된 경우만)
  final String? connectedUserId;       // 연결된 앱 사용자 ID
  final DateTime createdAt;
  final DateTime? connectedAt;
  final DateTime? disconnectedAt;      // 연결 끊긴 시간
  // ... 기존 필드
}

enum ConnectionStatus {
  offline,        // ⚪ 수기 등록 (앱 미사용)
  inviteSent,     // 🟡 초대 보냄
  inviteReceived, // 🔵 초대 받음
  connected,      // 🟣🟢🟠🔴 앱 연결됨 (연습 성과에 따라 색상 결정)
  disconnected,   // ⚪ 연결 끊김 (학생이 언팔)
}

enum PracticeLevel {
  newStudent,   // 🟣 신규 연결 (연습 데이터 없음)
  excellent,    // 🟢 우수 (5/7일 이상)
  average,      // 🟠 보통 (3-4/7일)
  poor,         // 🔴 부족 (1-2/7일)
  onBreak,      // ⚪ 휴강
}
```

### Follow 모델 (신규)

```dart
class Follow {
  final String id;
  final String followerId;      // 팔로우하는 사람
  final FollowUserRole followerRole;
  final String followeeId;      // 팔로우 받는 사람
  final FollowUserRole followeeRole;
  final DateTime createdAt;
}

enum FollowUserRole {
  teacher,
  student,
}
```

### TeacherSettings 모델 (확장)

```dart
class TeacherSettings {
  final String teacherId;
  final bool autoAcceptConnection;  // 학생 연결 요청 자동 수락 (기본: true)
  // ... 기타 설정
}
```

> **Note**: `autoAcceptConnection`이 `false`인 경우,
> 학생이 팔로우하면 알림 센터에서 수락/거절할 수 있습니다.

### 연결 판정 로직

```dart
// 맞팔 여부 확인
bool isMutualFollow(String userId1, String userId2) {
  final follow1 = follows.any((f) =>
    f.followerId == userId1 && f.followeeId == userId2);
  final follow2 = follows.any((f) =>
    f.followerId == userId2 && f.followeeId == userId1);
  return follow1 && follow2;
}

// 팔로우 처리 (설정 반영)
Future<void> handleFollow(String followerId, String followeeId, FollowUserRole followerRole) async {
  await createFollow(followerId, followeeId);

  // Case 1: 상대방이 이미 나를 팔로우했다면 자동 맞팔
  if (hasFollowed(followeeId, followerId)) {
    await createConnection(followerId, followeeId);
    await notifyConnection(followerId, followeeId);
    return;
  }

  // Case 2: 학생이 선생님을 팔로우하는 경우
  if (followerRole == FollowUserRole.student) {
    final teacherSettings = await getTeacherSettings(followeeId);

    if (teacherSettings.autoAcceptConnection) {
      // 자동 수락: 즉시 맞팔 처리
      await createFollow(followeeId, followerId);
      await createConnection(followerId, followeeId);
      await notifyConnection(followerId, followeeId);
    } else {
      // 수동 수락: 선생님에게 알림만 발송
      await notifyConnectionRequest(followeeId, followerId);
    }
  }

  // Case 3: 선생님이 학생을 팔로우하는 경우 (앱 초대)
  if (followerRole == FollowUserRole.teacher) {
    // 학생에게 초대 알림 발송
    await notifyInviteReceived(followeeId, followerId);
  }
}

// 언팔로우 처리
Future<void> handleUnfollow(String unfollowerId, String unfolloweeId) async {
  // 1. Follow 레코드 삭제
  await deleteFollow(unfollowerId, unfolloweeId);

  // 2. 맞팔 상태였다면 Connection 비활성화
  if (hasConnection(unfollowerId, unfolloweeId)) {
    await deactivateConnection(unfollowerId, unfolloweeId);

    // 3. Student.connectionStatus 업데이트
    await updateStudentConnectionStatus(
      studentId: getStudentId(unfollowerId, unfolloweeId),
      status: ConnectionStatus.disconnected,
    );

    // 4. 상대방에게 연결 해제 알림
    await notifyDisconnection(unfolloweeId, unfollowerId);
  }
}

// 연결 요청 응답 처리 (수동 수락 모드)
Future<void> handleConnectionResponse({
  required String teacherId,
  required String studentId,
  required bool accept,
}) async {
  if (accept) {
    // 수락: 맞팔 생성
    await createFollow(teacherId, studentId);
    await createConnection(studentId, teacherId);
    await notifyConnection(studentId, teacherId);
  } else {
    // 거절: 학생의 팔로우 삭제 + 알림
    await deleteFollow(studentId, teacherId);
    await notifyConnectionRejected(studentId, teacherId);

    // 거절 후 24시간 동안 재요청 불가 (스팸 방지)
    await setConnectionCooldown(studentId, teacherId, Duration(hours: 24));
  }
}
```

---

## 연락처 동기화

### 전화번호 형식

```dart
// 표준 형식: +국가번호 전화번호
// 예: +82 10-1234-5678 → +821012345678

String normalizePhoneNumber(String phone, String countryCode) {
  final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.startsWith('0')) {
    return '+$countryCode${digits.substring(1)}';
  }
  return '+$countryCode$digits';
}
```

### 동기화 흐름

```
1. 연락처 권한 요청 (첫 검색 시)
2. 연락처 전화번호 정규화
3. 서버에 해시 전송 (프라이버시)
4. 가입자 목록 반환
5. 로컬 캐시 저장
```

### 미가입자 처리

```
연락처에 있지만 미가입:
├── "초대하기" 버튼 표시
├── 탭하면 공유 옵션
│   ├── 📱 문자로 초대
│   └── 💬 카카오톡으로 초대
└── 설치 링크 + 선생님 코드 포함
```

---

## 기능별 사용 가능 여부

### 연결 상태별 기능

| 기능 | ⚪ 오프라인 | 🟡/🔵 대기중 | 🟣🟢🟠🔴 연결됨 |
|------|:----------:|:-----------:|:--------:|
| 학생 프로필 | ✅ (선생님) | ✅ (선생님) | ✅ |
| 레슨 스케줄 | ✅ (선생님) | ✅ (선생님) | ✅ 양쪽 |
| 레슨 노트 | ✅ (선생님) | ✅ (선생님) | ✅ 양쪽 |
| 연습 과제 | ✅ (선생님) | ✅ (선생님) | ✅ 양쪽 |
| 결제 관리 | ✅ (선생님) | ✅ (선생님) | ✅ 양쪽 |
| 연습 기록 | ❌ | ❌ | ✅ 학생 |
| 메트로놈 | ❌ | ❌ | ✅ 학생 |
| 녹음 | ❌ | ❌ | ✅ 학생 |
| 실시간 알림 | ❌ | ❌ | ✅ 양쪽 |

---

## 알림 시스템

### 연결 관련 알림

| 이벤트 | 수신자 | 메시지 | 액션 |
|--------|--------|--------|------|
| 팔로우 받음 (자동수락 OFF) | 선생님 | "김민수님이 연결을 원합니다" | [수락] [거절] |
| 초대 받음 | 학생 | "김선생님이 연결을 요청했습니다" | [수락] |
| 자동 연결 | 양쪽 | "김민수님과 연결되었습니다" | - |
| 연결 거절됨 | 학생 | "연결 요청이 거절되었습니다" | - |
| 연결 해제 | 양쪽 | "김민수님과의 연결이 해제되었습니다" | - |

### 알림 액션 API

```dart
// 알림에서 [수락] 버튼 클릭 시
void onAcceptTapped(String notificationId, String studentId, String teacherId) {
  handleConnectionResponse(
    teacherId: teacherId,
    studentId: studentId,
    accept: true,
  );
  dismissNotification(notificationId);
}

// 알림에서 [거절] 버튼 클릭 시
void onRejectTapped(String notificationId, String studentId, String teacherId) {
  handleConnectionResponse(
    teacherId: teacherId,
    studentId: studentId,
    accept: false,
  );
  dismissNotification(notificationId);
}
```

### 알림 센터 통합

```
알림 센터
├── 연결 알림
│   ├── 🔵 박학생님이 연결을 원합니다 [수락] [거절]
│   ├── 🟣 김민수님과 연결되었습니다
│   └── ⚪ 이학생님과의 연결이 해제되었습니다
├── 레슨 알림
└── 연습 알림
```

---

## 거절 후 처리 플로우

### 연결 거절 시나리오

```
[학생이 선생님을 팔로우]
        │
        ▼
[선생님 자동 수락 OFF]
        │
        ▼
[선생님 알림 수신: "김민수님이 연결을 원합니다"]
        │
        ├──[수락]──► handleConnectionResponse(accept: true)
        │              └── 맞팔 생성 → 🟣 신규 연결
        │
        └──[거절]──► handleConnectionResponse(accept: false)
                       │
                       ├── 1. 학생의 팔로우 레코드 삭제
                       ├── 2. 학생에게 거절 알림 발송
                       ├── 3. 24시간 쿨다운 설정
                       └── 4. 선생님 학생 목록에서 해당 학생 제거
```

### 거절 후 상태 변화

| 시점 | 선생님 측 | 학생 측 |
|------|----------|---------|
| 팔로우 직후 | 🔵 초대 받음 (학생 목록에 표시) | 🟡 초대 보냄 |
| 거절 직후 | **목록에서 제거** | 🟡 초대 보냄 → **제거 + 알림** |
| 24시간 내 | 재요청 불가 | "잠시 후 다시 시도해주세요" |
| 24시간 후 | - | 재요청 가능 |

### 거절 관련 API

```dart
// 쿨다운 확인
Future<bool> canRequestConnection(String studentId, String teacherId) async {
  final cooldown = await getConnectionCooldown(studentId, teacherId);
  return cooldown == null || cooldown.isBefore(DateTime.now());
}

// 쿨다운 설정
Future<void> setConnectionCooldown(
  String studentId,
  String teacherId,
  Duration duration,
) async {
  await db.connectionCooldowns.insert({
    'studentId': studentId,
    'teacherId': teacherId,
    'expiresAt': DateTime.now().add(duration),
  });
}

// 쿨다운 조회
Future<DateTime?> getConnectionCooldown(String studentId, String teacherId) async {
  final record = await db.connectionCooldowns.findOne({
    'studentId': studentId,
    'teacherId': teacherId,
  });
  return record?['expiresAt'];
}
```

### 거절 알림 메시지

| 상황 | 메시지 |
|------|--------|
| 거절됨 | "연결 요청이 거절되었습니다" |
| 쿨다운 중 재요청 | "잠시 후 다시 시도해주세요" |
| 3회 연속 거절 | "이 선생님에게 더 이상 요청할 수 없습니다" (향후) |

---

## 재연결 플로우

### 연결 끊김 시나리오

```
[학생 또는 선생님이 언팔로우]
        │
        ▼
handleUnfollow()
        │
        ├── Follow 레코드 삭제
        ├── Connection 비활성화
        ├── Student.connectionStatus = disconnected
        └── 상대방에게 알림 발송
                │
                ▼
[양측 상태 변화]
        │
        ├── 선생님: 학생 목록에 ⚪ 연결 끊김 + [재연결] 버튼
        └── 학생: 선생님 목록에서 제거 or ⚪ 연결 끊김
```

### 재연결 흐름

```
[선생님: 학생 목록]
        │
        ▼
⚪ 김민수 [재연결] 버튼
        │
        ▼ 탭
handleReconnect()
        │
        ├── 새로운 Follow 생성 (선생님 → 학생)
        ├── 학생에게 알림: "김선생님이 재연결을 요청했습니다"
        └── Student.connectionStatus = inviteSent (🟡)
                │
                ▼
[학생: 알림 수신 or 선생님 목록 확인]
        │
        ├──[수락]──► 맞팔 생성 → 🟣 신규 연결
        │              └── 기존 연습 데이터 복구
        │
        └──[무시]──► 상태 유지 (🟡 초대 보냄)
```

### 재연결 API

```dart
// 재연결 요청 (선생님 → 학생)
Future<void> handleReconnect(String teacherId, String studentId) async {
  // 1. 기존 disconnected 상태 확인
  final student = await getStudent(studentId);
  if (student.connectionStatus != ConnectionStatus.disconnected) {
    throw InvalidStateException('재연결 대상이 아닙니다');
  }

  // 2. 선생님의 팔로우 생성
  await createFollow(teacherId, studentId);

  // 3. 학생 상태 업데이트
  await updateStudentConnectionStatus(
    studentId: studentId,
    status: ConnectionStatus.inviteSent,
  );

  // 4. 학생에게 재연결 알림 발송
  await notifyReconnectRequest(studentId, teacherId);
}

// 재연결 수락 (학생)
Future<void> acceptReconnect(String studentId, String teacherId) async {
  // 1. 학생의 팔로우 생성 (맞팔 완성)
  await createFollow(studentId, teacherId);

  // 2. Connection 재활성화
  await reactivateConnection(studentId, teacherId);

  // 3. 상태 업데이트
  await updateStudentConnectionStatus(
    studentId: studentId,
    status: ConnectionStatus.connected,
  );

  // 4. 양측에 알림
  await notifyReconnected(studentId, teacherId);
}
```

### 재연결 시 데이터 처리

| 데이터 | 처리 방식 |
|--------|----------|
| 연습 기록 | **복구** - 기존 기록 유지, 연결 후 계속 기록 |
| 레슨 기록 | **유지** - 연결 끊김 중에도 선생님이 관리 |
| 결제 기록 | **유지** - 연결 끊김 중에도 선생님이 관리 |
| 연습 과제 | **복구** - 연결 끊김 중 추가된 과제도 표시 |
| 연습 성과 | **재계산** - 재연결 시점부터 7일 기준 |

### 재연결 알림

| 이벤트 | 수신자 | 메시지 |
|--------|--------|--------|
| 재연결 요청 | 학생 | "김선생님이 재연결을 요청했습니다" |
| 재연결 수락 | 선생님 | "김민수님과 다시 연결되었습니다" |
| 재연결 완료 | 양쪽 | - |

---

## UI 컴포넌트

### StudentStatusIndicator (통합 인디케이터)

```dart
class StudentStatusIndicator extends StatelessWidget {
  final Student student;
  final double size;

  const StudentStatusIndicator({
    super.key,
    required this.student,
    this.size = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _getColor(),
      ),
    );
  }

  Color _getColor() {
    // 앱 연결됨 → 연습 성과 표시
    if (student.connectionStatus == ConnectionStatus.connected) {
      // practiceLevel이 null이면 신규 학생으로 처리
      return switch (student.practiceLevel ?? PracticeLevel.newStudent) {
        PracticeLevel.excellent => Colors.green,           // 🟢 우수
        PracticeLevel.average => Colors.orange,            // 🟠 보통
        PracticeLevel.poor => Colors.red,                  // 🔴 부족
        PracticeLevel.onBreak => Colors.grey[400]!,        // ⚪ 휴강
        PracticeLevel.newStudent => const Color(0xFF6B5B95), // 🟣 신규
      };
    }

    // 앱 미연결 → 연결 상태 표시
    return switch (student.connectionStatus) {
      ConnectionStatus.inviteSent => Colors.amber,       // 🟡 초대 보냄
      ConnectionStatus.inviteReceived => Colors.blue,    // 🔵 초대 받음
      ConnectionStatus.offline => Colors.grey[400]!,     // ⚪ 오프라인
      ConnectionStatus.disconnected => Colors.grey[400]!, // ⚪ 연결 끊김
      _ => Colors.grey[400]!,
    };
  }
}
```

### 학생 리스트 아이템

```dart
ListTile(
  leading: Stack(
    children: [
      StudentAvatar(student),
      Positioned(
        bottom: 0,
        right: 0,
        child: StudentStatusIndicator(student: student, size: 14),
      ),
    ],
  ),
  title: Row(
    children: [
      Text(student.name),
      SizedBox(width: 8),
      _buildBadge(student),  // 정규, 바이올린 등
    ],
  ),
  subtitle: Text(_getSubtitle(student)),
  trailing: _buildTrailing(student),
)

// 연결 상태에 따른 후행 버튼
Widget? _buildTrailing(Student student) {
  return switch (student.connectionStatus) {
    ConnectionStatus.offline => TextButton(
      onPressed: _inviteToApp,
      child: Text('앱 초대'),
    ),
    ConnectionStatus.inviteReceived => TextButton(
      onPressed: () => _acceptConnection(student),
      child: Text('수락'),
    ),
    ConnectionStatus.disconnected => TextButton(
      onPressed: _reconnect,
      child: Text('재연결'),
    ),
    _ => null,
  };
}
```

---

## 보안 고려사항

### 연결 해제

- 양쪽 모두 언제든 연결 해제 가능
- 연결 해제 시 알림 발송
- 해제 후 재연결 가능

### 스팸 방지

- 하루 팔로우 제한: 50명
- 연속 거절 시 일시 차단
- 신고 기능 (향후)

### 프라이버시

- 전화번호 해시로 서버 전송
- 연락처 동기화 선택적
- 검색 노출 설정 (향후)

---

## 마이그레이션

### v1 → v2 전환

```dart
// 기존 Connection → Follow 변환
for (final conn in existingConnections) {
  // 양방향 팔로우 생성
  await createFollow(conn.teacherId, conn.studentId);
  await createFollow(conn.studentId, conn.teacherId);
}

// 기존 ConnectionRequest → Follow 변환
for (final req in pendingRequests) {
  await createFollow(req.requesterId, req.targetId);
}
```

---

## 구현 우선순위

### Phase 1 (MVP)
- [ ] 자동 맞팔 로직 (handleFollow)
- [ ] 언팔로우 로직 (handleUnfollow)
- [ ] 연결 요청 응답 (handleConnectionResponse)
- [ ] **통합 인디케이터** (연습 성과 + 연결 상태)
- [ ] 수기 등록 학생
- [ ] 코드/링크 공유
- [ ] 신규 연결 상태 (🟣 보라색)
- [ ] 🔵 초대 받음 → [수락] 버튼
- [ ] 연결 끊김/재연결 버튼
- [ ] 선생님 설정 화면 (TeacherSettingsScreen)
- [ ] 자동 연결 수락 On/Off 설정
- [ ] 거절 후 24시간 쿨다운

### Phase 2
- [ ] 전화번호 직접 검색
- [ ] 연락처 동기화
- [ ] 미가입자 초대
- [ ] 재연결 기능 (handleReconnect, acceptReconnect)
- [ ] 재연결 시 데이터 복구 로직

### Phase 3
- [ ] 알림 센터 통합
- [ ] 연결 해제 기능
- [ ] 검색 노출 설정
- [ ] 연속 거절 시 영구 차단 (3회 이상)

---

## 관련 문서

- [브레인스토밍 Q&A](../../proposal/invite_ux_improvement.md)
- [기존 초대 시스템 v1](./invite_system.md)
