# 학생 중심 아키텍처 설계

> 작성일: 2024-12-22
> 최종 수정: 2024-12-22
> 상태: 설계 완료 + 스트릭 기능 구현 완료

---

## 개요

### 설계 철학

**"학생이 연습 공간의 주인, 선생님은 초대된 코치"**

기존의 선생님 중심 모델에서 학생 중심 모델로 전환하되, 선생님도 학생 관리 도구로 활용할 수 있도록 **양방향 초대 시스템**을 구현합니다.

### 핵심 변경점

| 구분 | 기존 모델 | 신규 모델 |
|------|----------|----------|
| 데이터 소유권 | 선생님 중심 | 학생 중심 |
| 관계 생성 | 선생님이 학생 추가 | 양방향 초대 (QR/URL) |
| 연습 기록 | 선생님 관리 | 학생 소유, 선생님 읽기 |
| 과제 관리 | 선생님 생성 | 선생님 제안 → 학생 수락 |

---

## 데이터 모델

### 핵심 엔티티

#### 1. PracticeSpace (연습 공간)

> 학생이 소유하는 개인 연습 공간

```dart
class PracticeSpace {
  final String id;
  final String ownerId; // Student's user ID
  final String name; // e.g., "내 바이올린 연습"
  final List<String> instruments;
  final DateTime createdAt;

  // Settings
  final bool allowCoachComments;
  final bool showStreakPublicly;
}
```

#### 2. CoachConnection (코치 연결)

> 학생과 선생님의 연결 관계

```dart
enum ConnectionStatus { pending, active, paused, ended }
enum ConnectionSource { studentInvite, teacherInvite, appSearch }

class CoachConnection {
  final String id;
  final String practiceSpaceId;
  final String? coachUserId; // null if external teacher
  final String studentUserId;

  // External teacher info (if coachUserId is null)
  final ExternalTeacher? externalTeacher;

  final ConnectionStatus status;
  final ConnectionSource source;
  final String instrument; // Which instrument this coach teaches

  // Permissions
  final bool canViewPractice;
  final bool canComment;
  final bool canSuggestAssignments;

  final DateTime connectedAt;
  final DateTime? endedAt;
}
```

##### 멀티 코치 연습 기록 정책 ✅ 결정됨

> **결정**: 통합 관리 (모든 선생님이 모든 연습 기록 조회)

| 정책 | 설명 |
|------|------|
| **통합 관리** | 연결된 모든 선생님이 학생의 전체 연습 기록 조회 가능 |
| 악기별 분리 | ❌ (선택되지 않음) |

**이유**:
- 학생의 전반적인 연습 현황을 파악하는 것이 지도에 도움
- 다른 선생님의 과제와 중복/충돌 방지 가능
- 악기별 분리는 UX 복잡성 증가 대비 이점이 적음

```dart
// 예시: 피아노 선생님도 바이올린 연습 기록 조회 가능
final allPracticeRecords = await getPracticeLogs(studentId);
// → 모든 악기의 연습 기록 반환
```

```dart
class ExternalTeacher {
  final String name;
  final String instrument;
  final String? lessonDay; // e.g., "토요일"
  final String? notes;
}
```

#### 3. PracticeLog (연습 기록)

> 학생 소유의 연습 기록

```dart
class PracticeLog {
  final String id;
  final String practiceSpaceId;
  final String studentUserId;

  final DateTime date;
  final int durationMinutes;
  final List<PracticeItem> items;
  final String? notes;

  // Streak tracking
  final int currentStreak;
  final int longestStreak;

  final DateTime createdAt;
}

class PracticeItem {
  final String id;
  final String title; // e.g., "스케일 G major"
  final bool completed;
  final int? minutes;
  final String? notes;
}
```

#### 4. CoachFeedback (코치 피드백)

> 선생님이 작성하는 피드백 (읽기 권한으로 조회)

```dart
class CoachFeedback {
  final String id;
  final String practiceLogId;
  final String coachUserId;

  final String content;
  final List<String>? suggestions; // Assignment suggestions

  final DateTime createdAt;
}
```

#### 5. Assignment (과제)

> 선생님 제안 → 학생 수락 구조

```dart
enum AssignmentStatus { suggested, accepted, declined, completed }

class Assignment {
  final String id;
  final String practiceSpaceId;
  final String? suggestedByCoachId; // null if student created
  final String studentUserId;

  final String title;
  final String? description;
  final DateTime? dueDate;

  final AssignmentStatus status;
  final DateTime? acceptedAt;
  final DateTime? completedAt;

  final DateTime createdAt;
}
```

---

## 양방향 초대 시스템

### 초대 플로우

#### 학생 → 선생님 초대

```
1. 학생이 "선생님 초대" 버튼 클릭
2. QR 코드 또는 URL 생성
3. 선생님이 스캔/클릭
4. 선생님 앱에서 연결 수락
5. CoachConnection 생성 (status: active)
```

#### 선생님 → 학생 초대

```
1. 선생님이 "학생 초대" 버튼 클릭
2. QR 코드 또는 URL 생성
3. 학생이 스캔/클릭
4. 학생 앱에서 연결 수락
5. CoachConnection 생성 (status: active)
```

### 초대 코드 구조

```dart
class InviteCode {
  final String id;
  final String code; // 6자리 코드 또는 UUID
  final String creatorUserId;
  final InviteType type; // student_to_teacher, teacher_to_student

  final String? practiceSpaceId; // For student invites
  final String? instrument; // Optional: specific instrument

  final DateTime expiresAt; // 24시간 후 만료
  final bool used;

  final DateTime createdAt;
}

enum InviteType { studentToTeacher, teacherToStudent }
```

### URL 형식

```
학생 → 선생님: lessonapp://invite/coach/{code}
선생님 → 학생: lessonapp://invite/student/{code}
```

### 비등록 사용자 초대 ✅ 결정됨

> **결정**: SMS/카카오톡 딥링크 방식

| 상황 | 처리 방식 |
|------|----------|
| 선생님 앱 사용 | 앱 내 QR 스캔/URL 클릭 |
| 선생님 앱 미설치 | SMS/카카오톡으로 초대 링크 전송 → 앱스토어 연결 |

#### 딥링크 플로우

```
1. 학생이 "선생님 초대" 클릭
2. QR 코드 또는 딥링크 URL 생성
   예: https://lessonapp.kr/invite/coach/{code}
3. SMS/카카오톡으로 링크 공유
4. 선생님 클릭 시:
   - 앱 설치됨 → 앱 내 초대 수락 화면
   - 앱 미설치 → 앱스토어 → 설치 후 딥링크 처리
```

---

## 권한 모델

### 데이터 접근 권한

| 데이터 | 학생 | 앱 사용 선생님 | 외부 선생님 |
|--------|------|----------------|-------------|
| 연습 기록 | 읽기/쓰기 | 읽기 | - |
| 연습 통계 | 읽기/쓰기 | 읽기 | - |
| 과제 | 읽기/쓰기/삭제 | 제안/읽기 | - |
| 코치 피드백 | 읽기 | 읽기/쓰기 | - |
| 레슨 노트 | 읽기 | 읽기/쓰기 | - |
| 연결 관리 | 추가/해제 | 해제만 | - |

### 선생님 권한 상세

```dart
class CoachPermissions {
  final bool canViewPractice; // Default: true
  final bool canViewStatistics; // Default: true
  final bool canComment; // Default: true
  final bool canSuggestAssignments; // Default: true
  final bool canCreateLessonNotes; // Default: true

  // Student can customize per coach
}
```

---

## 사용 시나리오

### 시나리오 A: 선생님 앱 사용

```
[학생]                          [선생님]
연습 기록 작성 ─────────────────→ 연습 기록 조회
                              ↓
                          피드백 작성
                              ↓
    피드백 확인 ←─────────────────
    과제 수락
```

### 시나리오 B: 외부 선생님 (앱 미사용)

```
[학생]
외부 선생님 등록 (이름, 악기, 요일만)
    ↓
연습 기록 작성 (선생님 연결)
    ↓
레슨 후 직접 레슨 노트 작성
```

### 시나리오 C: 독학

```
[학생]
연습 공간 생성 (선생님 연결 없이)
    ↓
연습 기록 작성
    ↓
스트릭 추적 & 자기 분석
```

---

## 마이그레이션 전략

### 기존 데이터 처리

| 기존 데이터 | 마이그레이션 방안 |
|-------------|------------------|
| 선생님이 등록한 학생 | 학생에게 PracticeSpace 자동 생성, 기존 선생님을 Coach로 연결 |
| 기존 레슨 기록 | LessonNote로 유지 (선생님 소유) |
| 연습 기록 | 해당 학생의 PracticeSpace로 이동 |

### 단계별 전환

```
Phase 1: 신규 가입자 - 새 모델 적용
Phase 2: 기존 사용자 - 마이그레이션 안내 후 전환
Phase 3: 레거시 모델 지원 종료
```

---

## UI 변경점

### 학생 앱

| 화면 | 변경 내용 |
|------|----------|
| 홈 | "내 연습 공간" 중심 UI |
| 선생님 탭 | "내 코치" 목록 + 초대 버튼 |
| 연습 기록 | 스트릭 표시 + 코치 피드백 영역 |
| 설정 | 코치별 권한 설정 |

### 선생님 앱

| 화면 | 변경 내용 |
|------|----------|
| 홈 | "연결된 학생" 목록 |
| 학생 상세 | 학생 연습 기록 조회 (읽기 전용) |
| 초대 | QR/URL 생성 기능 |
| 피드백 | 학생 연습 기록에 코멘트 |

---

## 구현된 기능 상세

### 연습 스트릭 (Practice Streak) ✅ 구현 완료

> 구현일: 2024-12-22

#### 데이터 모델

```dart
class PracticeStreak {
  final String id;
  final String studentId;
  final int currentStreak;      // 현재 연속 연습일
  final int longestStreak;      // 최장 연속 기록
  final DateTime? lastPracticeDate;
  final DateTime updatedAt;

  // Computed properties
  bool get isActive;            // 스트릭 활성 상태
  bool get practicedToday;      // 오늘 연습 여부
  int get streakLevel;          // 0: 없음, 1: 1-6일, 2: 7-29일, 3: 30+일
  String get fireEmoji;         // ✨, 🔥, 🔥🔥
  String get motivationMessage; // 동기부여 메시지
}
```

#### 주말 제외 스트릭 알고리즘

```dart
/// 주말 제외 정책: 토/일에 연습 안 해도 스트릭 유지
bool _isWeekend(DateTime date) {
  return date.weekday == DateTime.saturday ||
         date.weekday == DateTime.sunday;
}

bool _isGapOnlyWeekends(DateTime newerDate, DateTime olderDate) {
  final daysDiff = newerDate.difference(olderDate).inDays;
  if (daysDiff <= 1) return true;

  for (int i = 1; i < daysDiff; i++) {
    final gapDate = olderDate.add(Duration(days: i));
    if (!_isWeekend(gapDate)) return false;
  }
  return true;
}
```

#### 스트릭 레벨 UI

| 레벨 | 조건 | 이모지 | 그라데이션 색상 |
|------|------|--------|----------------|
| 0 | 스트릭 없음 | - | 회색 (#9E9E9E → #757575) |
| 1 | 1-6일 | ✨ | 보라색 (Primary → PrimaryLight) |
| 2 | 7-29일 | 🔥 | 주황/빨강 (#FF6B6B → #FF8E53) |
| 3 | 30일+ | 🔥🔥 | 골드 (#FFB800 → #FF8C00) |

#### 구현된 위젯

| 위젯 | 용도 | 위치 |
|------|------|------|
| `PracticeStreakCard` | 대시보드용 대형 카드 | 학생 홈 화면 상단 |
| `PracticeStreakBadge` | 소형 배지 | 프로필, 리스트 등 |
| `RecordPracticeButton` | 오늘 연습 기록 버튼 | 대시보드 |

#### Provider 구조

```dart
// 스트릭 조회
final practiceStreakProvider = FutureProvider.family<PracticeStreak, String>(
  (ref, studentId) => repository.getStreak(studentId)
);

// 스트릭 상태 관리 (StateNotifier)
final streakNotifierProvider = StateNotifierProvider.family<
  StreakNotifier, AsyncValue<PracticeStreak>, String>(
  (ref, studentId) => StreakNotifier(ref, studentId)
);
```

#### 파일 위치

| 파일 | 설명 |
|------|------|
| `lib/models/practice.dart` | PracticeStreak 모델 |
| `lib/repositories/practice_repository.dart` | 스트릭 계산 로직 |
| `lib/providers/practice/practice_streak_provider.dart` | Riverpod Provider |
| `lib/features/practice/presentation/widgets/practice_streak_card.dart` | UI 위젯 |

---

## 결정된 정책 요약

### 의사결정 기록 (2024-12-22)

| 항목 | 결정 | 이유 |
|------|------|------|
| **멀티 코치 연습 기록** | 통합 관리 | 모든 선생님이 전체 연습 기록 조회 가능 |
| **비등록 사용자 초대** | SMS/카카오톡 딥링크 | 앱 미설치 선생님도 초대 가능 |
| **스트릭 리셋 정책** | 주말 제외 | 토/일에 연습 안 해도 스트릭 유지 |

---

## 관련 문서

- [requirement.md](requirement.md) - 전체 요구사항
- [Lesson_Schedule_Design.md](Lesson_Schedule_Design.md) - 레슨 스케줄 설계
- [practice_streak_spec.md](practice_streak_spec.md) - 스트릭 기능 상세 명세
