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

## 연결 상태 정의

### 상태 종류

| 상태 | 아이콘 | 색상 코드 | 설명 | 조건 |
|------|:------:|:--------:|------|------|
| **앱 연결** | 🟢 | `Colors.green` | 상호 연결 완료 | 양쪽 모두 팔로우 |
| **초대 보냄** | 🟡 | `Colors.amber` | 내가 팔로우함 | 나만 팔로우 |
| **초대 받음** | 🔵 | `Colors.blue` | 상대가 팔로우함 | 상대만 팔로우 |
| **오프라인** | ⚪ | `Colors.grey[400]` | 수기 등록 | 앱 미사용 |

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
│     🟡 초대 보냄 ────── 학생 팔로우 ──────► 🟢 앱 연결        │
│                                                              │
│   [학생: 선생님 검색]                                         │
│         │                                                    │
│         │ 전화번호/코드로 팔로우                              │
│         ▼                                                    │
│     🔵 초대 받음 ────── 선생님 수락 ──────► 🟢 앱 연결        │
│         │               (자동)                               │
│         │                                                    │
│         │ 수기 학생과 매칭 시                                 │
│         ▼                                                    │
│     🟢 앱 연결 (자동 연결)                                    │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

### 자동 맞팔 규칙

1. **선생님 → 학생 초대**: 학생이 팔로우하면 자동 맞팔
2. **학생 → 선생님 팔로우**: 선생님이 자동 맞팔 (승인 불필요)
3. **수기 학생 매칭**: 전화번호 일치 시 자동 연결

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
│       └── ✏️ 수기 등록 → 이름, 전화번호 입력 → 📝 오프라인 상태
│
└── 학생 목록
    ├── 👤 김민수 🟢 ← 앱 연결됨 (전체 기능)
    ├── 👤 이지은 🟡 ← 초대 보냄 (수락 대기)
    ├── 👤 박서준 🔵 ← 초대 받음 → 탭하면 자동 연결
    └── 👤 최유리 ⚪ ← 오프라인 → "앱 초대" 버튼
```

### 학생/학부모 플로우

```
홈 화면
├── [선생님 찾기] 버튼 (헤더)
│   └── 선생님 찾기 화면
│       ├── 🔍 연락처에서 찾기 → 선생님 목록
│       ├── 📱 전화번호로 찾기 → +82 입력
│       └── 📝 코드로 연결 → 6자리 코드 입력
│
└── 내 선생님
    ├── 👤 김선생님 🟢 ← 앱 연결됨
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

---

## 데이터 모델

### Student 모델 확장

```dart
class Student {
  final String id;
  final String name;
  final String? phoneNumber;        // +국가번호 형식
  final ConnectionStatus status;    // 연결 상태
  final String? connectedUserId;    // 연결된 앱 사용자 ID
  final DateTime createdAt;
  final DateTime? connectedAt;
  // ... 기존 필드
}

enum ConnectionStatus {
  offline,      // 📝 수기 등록
  inviteSent,   // 📤 초대 보냄
  inviteReceived, // 📩 초대 받음
  connected,    // 🔗 앱 연결
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

// 자동 맞팔 처리
Future<void> handleFollow(String followerId, String followeeId) async {
  await createFollow(followerId, followeeId);

  // 상대방이 이미 나를 팔로우했다면 자동 맞팔
  if (hasFollowed(followeeId, followerId)) {
    await createConnection(followerId, followeeId);
    await notifyConnection(followerId, followeeId);
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

| 기능 | 📝 오프라인 | 📤/📩 대기중 | 🔗 연결됨 |
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

| 이벤트 | 수신자 | 메시지 |
|--------|--------|--------|
| 팔로우 받음 | 선생님/학생 | "김민수님이 연결을 원합니다" |
| 자동 연결 | 양쪽 | "김민수님과 연결되었습니다" |
| 연결 해제 | 양쪽 | "김민수님과의 연결이 해제되었습니다" |

### 알림 센터 통합

```
알림 센터
├── 연결 알림
│   ├── 📩 박학생님이 연결을 원합니다 [수락] [거절]
│   └── 🔗 김민수님과 연결되었습니다
├── 레슨 알림
└── 연습 알림
```

---

## UI 컴포넌트

### ConnectionStatusIcon

```dart
class ConnectionStatusIcon extends StatelessWidget {
  final ConnectionStatus status;
  final double size;

  const ConnectionStatusIcon({
    super.key,
    required this.status,
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
    return switch (status) {
      ConnectionStatus.connected => Colors.green,       // 🟢
      ConnectionStatus.inviteSent => Colors.amber,      // 🟡
      ConnectionStatus.inviteReceived => Colors.blue,   // 🔵
      ConnectionStatus.offline => Colors.grey[400]!,    // ⚪ 연한 회색
    };
  }
}
```

### 학생 리스트 아이템

```dart
ListTile(
  leading: StudentAvatar(student),
  title: Row(
    children: [
      Text(student.name),
      SizedBox(width: 8),
      ConnectionStatusIcon(status: student.status),  // 🔗 📤 📩 📝
    ],
  ),
  subtitle: Text(student.status.label),  // "앱 연결됨", "초대 보냄" 등
  trailing: student.status == ConnectionStatus.offline
    ? TextButton(onPressed: _inviteToApp, child: Text('앱 초대'))
    : null,
)
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
- [ ] 자동 맞팔 로직
- [ ] 연결 상태 아이콘 표시
- [ ] 수기 등록 학생
- [ ] 코드/링크 공유

### Phase 2
- [ ] 전화번호 직접 검색
- [ ] 연락처 동기화
- [ ] 미가입자 초대

### Phase 3
- [ ] 알림 센터 통합
- [ ] 연결 해제 기능
- [ ] 검색 노출 설정

---

## 관련 문서

- [브레인스토밍 Q&A](../../proposal/invite_ux_improvement.md)
- [기존 초대 시스템 v1](./invite_system.md)
