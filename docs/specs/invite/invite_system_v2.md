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

## 연결 혜택 (액터별)

앱 연결 시 각 액터가 얻는 혜택입니다. 연결을 유도하는 핵심 가치 제안입니다.

### 선생님 혜택

| 혜택 | 미연결 | 연결 후 |
|------|:------:|:------:|
| **연습 현황 파악** | ❌ | ✅ 실시간 연습 기록 확인 |
| **연습 성과 인디케이터** | ❌ | ✅ 한눈에 학생별 연습량 파악 |
| **레슨 전 준비** | 수기 기록 의존 | ✅ 지난 연습 기록 자동 확인 |
| **연습 과제 전달** | 구두/문자 | ✅ 앱에서 직접 과제 배정 |
| **연습 알림** | ❌ | ✅ 연습 안 한 학생에게 알림 발송 |
| **녹음 피드백** | ❌ | ✅ 학생 녹음 확인 및 피드백 |
| **레슨 알림** | 문자 발송 | ✅ 푸시 알림 자동 발송 |
| **결제 알림** | 문자 발송 | ✅ 결제 요청 푸시 알림 |

#### 선생님 입장 요약

> **"학생이 앱 연결하면 연습 관리가 자동화됩니다"**
> - 연습 안 하는 학생 바로 파악
> - 레슨 전 준비 시간 단축
> - 문자 발송 없이 알림 자동화

### 학생 혜택

| 혜택 | 미연결 | 연결 후 |
|------|:------:|:------:|
| **연습 기록** | ❌ | ✅ 연습 시간/곡 자동 기록 |
| **연습 스트릭** | ❌ | ✅ 연속 연습일 확인 (동기부여) |
| **메트로놈** | ❌ | ✅ 앱 내장 메트로놈 사용 |
| **녹음 기능** | ❌ | ✅ 연습 녹음 및 저장 |
| **레슨 노트 확인** | ❌ | ✅ 선생님이 작성한 레슨 노트 확인 |
| **연습 과제 확인** | 구두/문자 | ✅ 앱에서 과제 목록 확인 |
| **레슨 알림** | 문자 | ✅ 푸시 알림으로 레슨 리마인더 |
| **진도 확인** | ❌ | ✅ 내 레퍼토리 및 진도 확인 |

#### 학생 입장 요약

> **"앱 연결하면 연습이 재미있어집니다"**
> - 스트릭으로 연습 습관 형성
> - 녹음으로 내 연습 듣기
> - 선생님 피드백 바로 확인

### 학부모 혜택

| 혜택 | 미연결 | 연결 후 |
|------|:------:|:------:|
| **자녀 연습 현황** | 물어봐야 함 | ✅ 앱에서 실시간 확인 |
| **연습 스트릭** | ❌ | ✅ 자녀의 연습 지속성 확인 |
| **레슨 스케줄** | 문자/전화 | ✅ 앱에서 일정 확인 |
| **레슨 노트** | ❌ | ✅ 선생님 레슨 노트 확인 |
| **결제 내역** | 수기 기록 | ✅ 결제 내역 자동 기록 |
| **결제 알림** | 문자 | ✅ 푸시 알림으로 결제 요청 |
| **연습 알림** | ❌ | ✅ 자녀에게 연습 알림 발송 |

#### 학부모 입장 요약

> **"앱 연결하면 자녀 레슨 상황을 한눈에 파악합니다"**
> - 연습 현황 실시간 확인
> - 결제 내역 자동 관리
> - 선생님 피드백 바로 확인

### 연결 가치 정리

```
┌─────────────────────────────────────────────────────────────┐
│                      연결의 핵심 가치                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   [선생님]                                                   │
│   "연습 관리 자동화"                                          │
│   └── 연습 현황 파악 → 효과적인 레슨 준비                      │
│                                                             │
│   [학생]                                                     │
│   "연습이 재미있어짐"                                         │
│   └── 스트릭 + 녹음 → 연습 동기부여                           │
│                                                             │
│   [학부모]                                                   │
│   "레슨 상황 투명화"                                          │
│   └── 연습/레슨/결제 → 한눈에 관리                            │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 미연결 시에도 가능한 기능 (수기 등록)

| 기능 | 선생님 | 학생 | 학부모 |
|------|:------:|:----:|:------:|
| 학생 프로필 관리 | ✅ | ❌ | ❌ |
| 레슨 스케줄 등록 | ✅ | ❌ | ❌ |
| 레슨 노트 작성 | ✅ | ❌ | ❌ |
| 연습 과제 등록 | ✅ | ❌ | ❌ |
| 결제 기록 | ✅ | ❌ | ❌ |

> **Note**: 수기 등록된 학생은 선생님만 관리 가능합니다.
> 학생/학부모가 직접 사용하려면 앱 연결이 필요합니다.

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

### 설정 변경 시 처리

자동 연결 수락 설정이 변경될 때의 처리 로직입니다.

#### On → Off 변경 시

```
[현재 상태: 자동 수락 On]
        │
        ▼
[선생님이 Off로 변경]
        │
        ├── 기존 연결: 영향 없음 (유지)
        ├── 대기 중인 요청 (🔵): 없음 (자동 수락이었으므로)
        └── 변경 이후: 새 요청은 수동 수락 필요
```

| 항목 | 처리 |
|------|------|
| 기존 연결된 학생 | **유지** - 설정 변경이 기존 연결에 영향 없음 |
| 변경 후 새 요청 | **수동 수락** - 알림에서 수락/거절 |

#### Off → On 변경 시

```
[현재 상태: 자동 수락 Off]
        │
        ├── 대기 중인 요청들 (🔵 초대 받음)
        │   ├── 학생 A: 2시간 전 요청
        │   └── 학생 B: 1일 전 요청
        │
        ▼
[선생님이 On으로 변경]
        │
        ├── 옵션 A: 대기 중인 요청 모두 자동 수락
        ├── 옵션 B: 대기 중인 요청은 그대로 유지 (수동 수락)
        └── **선택: 옵션 B** (기존 대기 요청은 수동 처리)
```

| 항목 | 처리 |
|------|------|
| 대기 중인 요청 | **유지** - 선생님이 개별적으로 수락/거절 |
| 변경 후 새 요청 | **자동 수락** - 즉시 연결 |

#### 설정 변경 API

```dart
Future<void> updateAutoAcceptSetting({
  required String teacherId,
  required bool autoAccept,
}) async {
  // 1. 설정 업데이트
  await updateTeacherSettings(
    teacherId: teacherId,
    autoAcceptConnection: autoAccept,
  );

  // 2. 대기 중인 요청은 그대로 유지 (별도 처리 없음)
  // - On→Off: 대기 중인 요청 없음
  // - Off→On: 기존 요청은 수동 처리 유지

  // 3. 설정 변경 로그 기록 (향후 분석용)
  await logSettingChange(
    teacherId: teacherId,
    setting: 'autoAcceptConnection',
    newValue: autoAccept,
  );
}
```

#### 설정 변경 확인 다이얼로그

```
[Off → On 변경 시]
  "자동 연결 수락을 켜시겠습니까?"
  "앞으로 학생의 연결 요청이 자동으로 수락됩니다."
  "대기 중인 요청은 개별적으로 처리해야 합니다."

  [취소]  [확인]
```

```
[On → Off 변경 시]
  "자동 연결 수락을 끄시겠습니까?"
  "앞으로 학생의 연결 요청을 직접 수락해야 합니다."

  [취소]  [확인]
```

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

### 전화번호 불일치 병합

수기 등록 학생의 전화번호와 앱 가입 시 사용하는 전화번호가 다를 수 있습니다.

#### 시나리오

```
[선생님: 수기 등록]
  이름: 김민수
  전화번호: +82 10-1234-5678 (부모님 번호)
        │
        ▼
[학생: 앱 가입]
  이름: 김민수
  전화번호: +82 10-9999-8888 (본인 번호)
        │
        ▼
[코드로 선생님에게 연결 시도]
        │
        ▼
[전화번호 불일치 감지!]
        │
        ├── 자동 병합 불가
        └── 선생님에게 확인 요청
```

#### 병합 처리 방식

| 상황 | 처리 |
|------|------|
| 전화번호 일치 | 자동 병합 (수기 → 연결됨) |
| 전화번호 불일치 + 이름 일치 | 선생님에게 확인 요청 알림 |
| 전화번호 불일치 + 이름 불일치 | 새 학생으로 등록 |

#### 병합 확인 알림

```dart
// 병합 후보 감지 시 선생님에게 알림
await notifyMergeCandidate(
  teacherId: teacherId,
  existingStudentId: offlineStudent.id,  // 수기 등록
  newStudentId: appStudent.id,            // 앱 가입
  matchType: 'name_only',                 // 이름만 일치
);
```

#### 병합 확인 UI

```
알림: "김민수님이 연결을 요청했습니다"
      "기존 등록된 '김민수' 학생과 동일인인가요?"

      [예, 병합합니다]  [아니오, 별도 학생입니다]
```

#### 병합 API

```dart
// 병합 수락
Future<void> mergeStudents({
  required String offlineStudentId,  // 수기 등록
  required String appStudentId,      // 앱 가입
  required String teacherId,
}) async {
  // 1. 수기 등록 학생의 데이터를 앱 학생에게 이전
  await transferStudentData(
    fromId: offlineStudentId,
    toId: appStudentId,
  );

  // 2. 수기 등록 학생 삭제 (soft delete)
  await softDeleteStudent(offlineStudentId);

  // 3. 앱 학생의 connectionStatus 업데이트
  await updateStudentConnectionStatus(
    studentId: appStudentId,
    status: ConnectionStatus.connected,
  );

  // 4. 연결 완료 처리
  await createConnection(appStudentId, teacherId);
}

// 병합 거절 (별도 학생으로 처리)
Future<void> rejectMerge({
  required String offlineStudentId,
  required String appStudentId,
  required String teacherId,
}) async {
  // 앱 학생을 새 학생으로 등록
  await createConnection(appStudentId, teacherId);
  // 수기 등록 학생은 그대로 유지 (오프라인)
}
```

#### 데이터 이전 항목

| 데이터 | 이전 방식 |
|--------|----------|
| 레슨 기록 | 수기 학생 → 앱 학생으로 이전 |
| 결제 기록 | 수기 학생 → 앱 학생으로 이전 |
| 연습 과제 | 수기 학생 → 앱 학생으로 이전 |
| 메모 | 수기 학생 → 앱 학생으로 이전 |
| 전화번호 | 앱 학생 번호 유지 (부모 번호 별도 저장) |

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

### 푸시 알림 백그라운드 액션

앱이 백그라운드/종료 상태일 때 푸시 알림에서 바로 액션을 처리하는 방식입니다.

#### 알림 페이로드 구조

```dart
// FCM 메시지 페이로드
{
  "notification": {
    "title": "연결 요청",
    "body": "김민수님이 연결을 원합니다"
  },
  "data": {
    "type": "connection_request",
    "notification_id": "notif_123",
    "student_id": "student_456",
    "teacher_id": "teacher_789",
    "student_name": "김민수",
    "actions": ["accept", "reject"]
  },
  "android": {
    "notification": {
      "click_action": "FLUTTER_NOTIFICATION_CLICK"
    }
  },
  "apns": {
    "payload": {
      "aps": {
        "category": "CONNECTION_REQUEST"
      }
    }
  }
}
```

#### iOS 카테고리 등록

```swift
// iOS Notification Categories (AppDelegate)
let acceptAction = UNNotificationAction(
  identifier: "ACCEPT_ACTION",
  title: "수락",
  options: .foreground
)

let rejectAction = UNNotificationAction(
  identifier: "REJECT_ACTION",
  title: "거절",
  options: .destructive
)

let connectionCategory = UNNotificationCategory(
  identifier: "CONNECTION_REQUEST",
  actions: [acceptAction, rejectAction],
  intentIdentifiers: [],
  options: .customDismissAction
)

UNUserNotificationCenter.current().setNotificationCategories([connectionCategory])
```

#### Flutter 백그라운드 핸들러

```dart
// firebase_messaging 백그라운드 핸들러
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  final data = message.data;
  final type = data['type'];

  // 연결 요청 알림은 액션 버튼으로만 처리
  // 백그라운드에서 자동 처리하지 않음
  if (type == 'connection_request') {
    // 로컬 알림으로 표시 (액션 버튼 포함)
    await _showLocalNotificationWithActions(
      title: message.notification?.title ?? '',
      body: message.notification?.body ?? '',
      payload: data,
    );
  }
}

// 알림 액션 응답 처리
void _handleNotificationAction(NotificationResponse response) async {
  final payload = jsonDecode(response.payload ?? '{}');
  final action = response.actionId;

  switch (action) {
    case 'accept':
      await _handleAcceptInBackground(payload);
      break;
    case 'reject':
      await _handleRejectInBackground(payload);
      break;
    default:
      // 알림 탭 - 앱 열기
      _navigateToConnectionRequests();
  }
}

// 백그라운드에서 수락 처리
Future<void> _handleAcceptInBackground(Map<String, dynamic> payload) async {
  try {
    await api.acceptConnection(
      studentId: payload['student_id'],
      teacherId: payload['teacher_id'],
    );

    // 성공 로컬 알림
    await _showLocalNotification(
      title: '연결 완료',
      body: '${payload['student_name']}님과 연결되었습니다',
    );
  } catch (e) {
    // 실패 시 앱 열기 유도
    await _showLocalNotification(
      title: '연결 실패',
      body: '앱을 열어 다시 시도해주세요',
    );
  }
}

// 백그라운드에서 거절 처리
Future<void> _handleRejectInBackground(Map<String, dynamic> payload) async {
  try {
    await api.rejectConnection(
      studentId: payload['student_id'],
      teacherId: payload['teacher_id'],
    );
    // 거절은 별도 알림 없음
  } catch (e) {
    await _showLocalNotification(
      title: '처리 실패',
      body: '앱을 열어 다시 시도해주세요',
    );
  }
}
```

#### 알림 액션 실패 처리

| 상황 | 처리 |
|------|------|
| 네트워크 오류 | 로컬 알림으로 재시도 유도 |
| 이미 처리됨 | 무시 (idempotent) |
| 만료된 요청 | "요청이 만료되었습니다" 알림 |
| 서버 오류 | 로컬 알림으로 앱 열기 유도 |

#### Android 액션 버튼 설정

```dart
// flutter_local_notifications 설정
final androidDetails = AndroidNotificationDetails(
  'connection_channel',
  '연결 알림',
  importance: Importance.high,
  priority: Priority.high,
  actions: [
    AndroidNotificationAction(
      'accept',
      '수락',
      icon: DrawableResourceAndroidBitmap('ic_check'),
      showsUserInterface: false,
    ),
    AndroidNotificationAction(
      'reject',
      '거절',
      icon: DrawableResourceAndroidBitmap('ic_close'),
      showsUserInterface: false,
    ),
  ],
);
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
- [ ] 전화번호 불일치 병합 로직 (mergeStudents)
- [ ] 설정 변경 시 처리 (updateAutoAcceptSetting)
- [ ] 푸시 알림 백그라운드 액션 (FCM + Local Notification)

### Phase 3
- [ ] 알림 센터 통합
- [ ] 연결 해제 기능
- [ ] 검색 노출 설정
- [ ] 연속 거절 시 영구 차단 (3회 이상)
- [ ] iOS 알림 카테고리 등록
- [ ] Android 알림 액션 버튼

---

## 관련 문서

- [브레인스토밍 Q&A](../../proposal/invite_ux_improvement.md)
- [기존 초대 시스템 v1](./invite_system.md)
