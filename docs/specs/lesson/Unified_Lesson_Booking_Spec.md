# 통합 레슨 신청 시스템 스펙

## 개요

네이버 미용실 예약 시스템을 참고한 통합 레슨 신청 플로우.
기존 "체험레슨 신청"을 "레슨 신청"으로 확장하여 모든 유형의 레슨을 하나의 플로우로 처리.

## 배경

### 기존 시스템의 한계

1. **레슨 재개 불가**: 정규레슨 종료 후 같은 선생님께 다시 레슨 신청하는 방법 없음
2. **추가 레슨 불가**: 정규레슨 진행 중 1회 추가 레슨을 요청하는 방법 없음
3. **분리된 플로우**: 체험→정규 전환이 별도 프로세스로 복잡

### 목표

- 모든 레슨 신청을 **하나의 통합 플로우**로 처리
- 선생님-학생 관계에 따라 **자동으로 옵션 활성화/비활성화**
- 사용자 학습 비용 최소화

---

## 레슨 유형 정의

| 유형 | 설명 | 대상 |
|------|------|------|
| **체험레슨** | 첫 만남, 상호 평가용 1회 레슨 | 새로운 선생님 |
| **정기레슨** | 매주 고정 요일/시간 레슨 | 연결된/이전 선생님 |
| **1회 레슨** | 단발성 추가 레슨 | 연결된/이전 선생님 |

---

## 선생님-학생 관계 정의

### TeacherStudentRelation

```dart
enum TeacherStudentRelation {
  none,       // 처음 만남 (이력 없음)
  active,     // 현재 정규레슨 진행 중
  inactive,   // 과거 레슨 이력 있으나 현재 중단
}
```

### 관계별 가능한 레슨 유형

| 관계 | 체험 | 정기 | 1회 | 설명 |
|------|:----:|:----:|:----:|------|
| none | ✅ | ❌ | ❌ | 첫 만남은 체험부터 |
| active | ❌ | ❌ | ✅ | 이미 정기 진행중, 추가만 가능 |
| inactive | ❌ | ✅ | ✅ | 재개 또는 1회 가능 |

---

## 통합 레슨 신청 플로우

### 전체 흐름

```
[선생님 목록/검색]
       ↓
[선생님 선택] → 관계 확인
       ↓
[레슨 유형 선택] ← 관계에 따라 활성화
       ↓
[일정 선택]
  - 체험/1회: 단일 날짜+시간
  - 정기: 요일 + 시작일 + 기간
       ↓
[추가 정보 입력]
  - 체험: 레슨 목표, 현재 수준
  - 정기/1회: 요청사항 (선택)
       ↓
[신청 확인 & 제출]
       ↓
[선생님 알림] → 승인/거절
       ↓
[학생 알림] → 일정 확정
```

### 화면별 상세

#### 1. 선생님 선택 화면

- 기존 `SelectTeacherScreen` 유지
- 선생님 카드에 관계 표시 추가
  - 연결중: "정규레슨 진행중" 배지
  - 과거 이력: "이전 레슨 이력" 표시

#### 2. 레슨 유형 선택 화면 (신규)

```
┌─────────────────────────────────┐
│     레슨 신청                    │
│     김선생님                     │
├─────────────────────────────────┤
│  레슨 유형을 선택해주세요         │
│                                 │
│  ┌─────────────────────────┐   │
│  │ 🎵 체험 레슨             │   │  ← 관계에 따라 활성화
│  │    첫 만남을 위한 1회 레슨│   │
│  └─────────────────────────┘   │
│                                 │
│  ┌─────────────────────────┐   │
│  │ 📅 정기 레슨             │   │  ← 관계에 따라 활성화
│  │    매주 고정 시간 레슨    │   │
│  └─────────────────────────┘   │
│                                 │
│  ┌─────────────────────────┐   │
│  │ ➕ 1회 추가 레슨         │   │  ← 관계에 따라 활성화
│  │    단발성 추가 레슨       │   │
│  └─────────────────────────┘   │
│                                 │
└─────────────────────────────────┘
```

#### 3. 일정 선택 화면

**체험/1회 레슨:**
```
┌─────────────────────────────────┐
│  날짜 선택                       │
│  ┌───┬───┬───┬───┬───┬───┬───┐ │
│  │ 월│ 화│ 수│ 목│ 금│ 토│ 일│ │
│  ├───┼───┼───┼───┼───┼───┼───┤ │
│  │   │   │ ● │   │ ● │ ● │   │ │  ← 선생님 가능 날짜
│  └───┴───┴───┴───┴───┴───┴───┘ │
│                                 │
│  시간 선택 (12월 27일 금요일)     │
│  ┌────┐ ┌────┐ ┌────┐ ┌────┐  │
│  │10시│ │11시│ │14시│ │15시│  │  ← 선생님 빈 시간
│  └────┘ └────┘ └────┘ └────┘  │
│                                 │
│  선택: 12월 27일 (금) 14:00      │
└─────────────────────────────────┘
```

**정기 레슨:**
```
┌─────────────────────────────────┐
│  정기 레슨 설정                  │
│                                 │
│  요일 선택                       │
│  ┌───┬───┬───┬───┬───┬───┬───┐ │
│  │ 월│ 화│ 수│ 목│ 금│ 토│ 일│ │
│  │   │ ● │   │   │   │ ● │   │ │  ← 복수 선택 가능
│  └───┴───┴───┴───┴───┴───┴───┘ │
│                                 │
│  시간 선택                       │
│  화요일: [14:00 ▼]              │
│  토요일: [10:00 ▼]              │
│                                 │
│  시작일: [2025년 1월 7일 ▼]     │
│                                 │
│  기간: [3개월 ▼] (12회)         │
│                                 │
└─────────────────────────────────┘
```

---

## 데이터 모델

### LessonType (신규)

```dart
enum LessonType {
  trial,    // 체험레슨
  regular,  // 정기레슨
  oneTime,  // 1회 레슨
}
```

### LessonBooking (수정)

```dart
class LessonBooking {
  final String id;
  final String teacherId;
  final String studentId;
  final LessonType type;           // 추가
  final BookingStatus status;
  final DateTime createdAt;

  // 단일 레슨용 (체험, 1회)
  final DateTime? scheduledDate;
  final TimeOfDay? scheduledTime;
  final int? durationMinutes;

  // 정기 레슨용
  final List<RegularLessonSlot>? regularSlots;  // 추가
  final DateTime? regularStartDate;              // 추가
  final int? regularWeeks;                       // 추가 (기간)

  // 공통
  final String? studentMessage;
  final String? teacherMessage;
}

class RegularLessonSlot {
  final int dayOfWeek;      // 0=월, 6=일
  final TimeOfDay time;
  final int durationMinutes;
}
```

### TeacherStudentRelation (신규)

```dart
class TeacherStudentRelation {
  final String teacherId;
  final String studentId;
  final RelationStatus status;
  final DateTime? lastLessonDate;
  final int totalLessonCount;
}

enum RelationStatus {
  none,      // 이력 없음
  active,    // 정규레슨 진행중
  inactive,  // 과거 이력, 현재 중단
}
```

---

## API / Provider 변경

### 신규 Provider

```dart
// 선생님-학생 관계 조회
@riverpod
Future<TeacherStudentRelation> teacherStudentRelation(
  TeacherStudentRelationRef ref,
  String teacherId,
  String studentId,
) async {
  // Repository에서 관계 조회
}

// 관계에 따른 가능한 레슨 유형
@riverpod
List<LessonType> availableLessonTypes(
  AvailableLessonTypesRef ref,
  TeacherStudentRelation relation,
) {
  switch (relation.status) {
    case RelationStatus.none:
      return [LessonType.trial];
    case RelationStatus.active:
      return [LessonType.oneTime];
    case RelationStatus.inactive:
      return [LessonType.regular, LessonType.oneTime];
  }
}
```

### 기존 Provider 수정

```dart
// LessonBookingManager에 type 파라미터 추가
Future<LessonBooking> createBooking({
  required String teacherId,
  required LessonType type,  // 추가
  DateTime? scheduledDate,
  TimeOfDay? scheduledTime,
  List<RegularLessonSlot>? regularSlots,
  // ...
});
```

---

## 화면 변경 사항

### 변경 대상

| 화면 | 변경 내용 |
|------|----------|
| `SelectTeacherScreen` | 관계 배지 표시 추가 |
| `TrialLessonRequestScreen` | → `LessonRequestScreen`으로 리네임 |
| (신규) | `LessonTypeSelectScreen` 추가 |
| (신규) | `RegularLessonScheduleScreen` 추가 |

### 라우트 변경

```dart
// Before
static const trialLessonRequest = '/schedule/trial/request';

// After
static const lessonRequest = '/schedule/lesson/request';
static const lessonTypeSelect = '/schedule/lesson/type';
static const regularLessonSchedule = '/schedule/lesson/regular-schedule';
```

---

## 마이그레이션 계획

### Phase 1: 데이터 모델 확장
1. `LessonType` enum 추가
2. `LessonBooking`에 type 필드 추가
3. `TeacherStudentRelation` 모델 추가
4. Repository 메서드 추가

### Phase 2: Provider 확장
1. `teacherStudentRelationProvider` 추가
2. `availableLessonTypesProvider` 추가
3. `bookingManagerProvider` 수정

### Phase 3: UI 변경
1. `LessonTypeSelectScreen` 신규 구현
2. `TrialLessonRequestScreen` → `LessonRequestScreen` 리팩토링
3. `RegularLessonScheduleScreen` 신규 구현
4. `SelectTeacherScreen` 관계 배지 추가

### Phase 4: 라우트 & 네비게이션
1. 라우트 경로 변경
2. 기존 "체험레슨 신청" 버튼 텍스트 변경

---

## 기존 관계 온보딩 시스템

### 배경

이미 오프라인에서 레슨 중인 선생님-학생이 앱에 처음 진입할 때,
불필요한 체험레슨 단계를 거치지 않고 바로 연결할 수 있어야 함.

### 핵심 결정사항

| 항목 | 결정 |
|------|------|
| 연결 방식 | **양방향** - 선생님/학생 모두 연결 시작 가능 |
| 관계 증명 | **선생님 승인만** - 선생님이 확인하면 연결 완료 |
| 선생님 없을 때 | **초대 기능** - 학생이 선생님에게 앱 초대 링크 발송 |
| 레슨 정보 입력 | **선생님이 설정** - 학생은 연결만, 선생님이 일정 등록 |
| 승인 후 플로우 | **즉시 일정 등록** - 승인 후 바로 레슨 일정 등록 화면 |
| 과거 이력 | **선생님 선택** - 새로 시작 또는 과거 기록 수동 입력 |

---

### 연결 플로우

#### 플로우 1: 선생님이 기존 학생 초대

```
선생님: 학생 관리 → "기존 학생 초대"
       → 초대 코드/링크 생성
       → 공유 (링크 복사 / 공유하기 버튼)

학생: 앱 가입 → 초대 코드 입력
     → 선생님과 연결 요청 자동 생성
     → 선생님 승인 대기

선생님: 연결 요청 알림 수신
       → "기존 학생 확인" 승인
       → 레슨 일정 등록 화면으로 이동
       → (선택) 과거 레슨 이력 입력
```

#### 플로우 2: 학생이 기존 선생님 연결 요청

```
학생: 선생님 검색 → 선생님 선택
     → "이미 레슨 중이에요" 선택
     → 연결 요청 발송

선생님: 연결 요청 알림 수신
       → "기존 학생 확인" 승인
       → 레슨 일정 등록 화면으로 이동
```

#### 플로우 3: 선생님이 앱에 없음

```
학생: 선생님 검색 → 결과 없음
     → "선생님 초대하기" 선택
     → 선생님 정보 입력 (이름, 연락처)
     → 초대 링크 생성 → 공유

선생님: 초대 링크로 앱 가입
       → 가입 완료 시 학생 연결 요청 알림
       → 승인 → 레슨 일정 등록
```

---

### 화면 설계

#### 선생님: 학생 추가 옵션

```
┌─────────────────────────────────┐
│     학생 추가                    │
├─────────────────────────────────┤
│                                 │
│  ┌─────────────────────────┐   │
│  │ 👤 신규 학생             │   │
│  │    체험레슨부터 시작      │   │
│  └─────────────────────────┘   │
│                                 │
│  ┌─────────────────────────┐   │
│  │ 🔗 기존 학생 초대        │   │
│  │    이미 레슨 중인 학생    │   │
│  └─────────────────────────┘   │
│                                 │
│  ┌─────────────────────────┐   │
│  │ 📋 학생 정보 직접 등록   │   │
│  │    학생 앱 미사용 시      │   │
│  └─────────────────────────┘   │
│                                 │
└─────────────────────────────────┘
```

#### 학생: 선생님과의 관계 선택

```
┌─────────────────────────────────┐
│     김선생님                     │
├─────────────────────────────────┤
│                                 │
│  이 선생님과의 관계를 선택해주세요 │
│                                 │
│  ┌─────────────────────────┐   │
│  │ 🆕 처음 만나요           │   │
│  │    체험레슨 신청         │   │
│  └─────────────────────────┘   │
│                                 │
│  ┌─────────────────────────┐   │
│  │ ✅ 이미 레슨 중이에요    │   │
│  │    기존 관계 연결 요청    │   │
│  └─────────────────────────┘   │
│                                 │
└─────────────────────────────────┘
```

#### 학생: 선생님 초대

```
┌─────────────────────────────────┐
│     선생님 초대                  │
├─────────────────────────────────┤
│                                 │
│  선생님 정보                     │
│  ┌─────────────────────────┐   │
│  │ 이름 *                   │   │
│  │ [김민정 선생님         ] │   │
│  └─────────────────────────┘   │
│  ┌─────────────────────────┐   │
│  │ 연락처 *                 │   │
│  │ [010-1234-5678        ] │   │
│  └─────────────────────────┘   │
│  ┌─────────────────────────┐   │
│  │ 악기 (선택)              │   │
│  │ [바이올린           ▼] │   │
│  └─────────────────────────┘   │
│                                 │
│  ┌─────────────────────────┐   │
│  │       초대 링크 생성      │   │
│  └─────────────────────────┘   │
│                                 │
└─────────────────────────────────┘

        ↓ 링크 생성 후

┌─────────────────────────────────┐
│     초대 링크                    │
├─────────────────────────────────┤
│                                 │
│  선생님께 이 링크를 보내주세요    │
│                                 │
│  ┌─────────────────────────┐   │
│  │ https://lessonapp.com/  │   │
│  │ invite/abc123           │   │
│  └─────────────────────────┘   │
│                                 │
│  ┌────────┐  ┌────────────┐   │
│  │링크 복사│  │ 공유하기 📤│   │
│  └────────┘  └────────────────┘   │
│                                 │
│  💡 선생님이 가입하시면 자동으로  │
│     연결 요청이 전송됩니다       │
│                                 │
└─────────────────────────────────┘
```

#### 선생님: 연결 승인 후 일정 등록

```
┌─────────────────────────────────┐
│     레슨 일정 등록               │
│     김민수 학생                  │
├─────────────────────────────────┤
│                                 │
│  과거 레슨 이력                  │
│  ○ 지금부터 새로 시작            │
│  ● 기존 레슨 이력 입력           │
│                                 │
│  레슨 시작일                     │
│  [2024년 3월 1일          ▼]   │
│                                 │
│  ─────────────────────────────  │
│                                 │
│  정기 레슨 일정                  │
│                                 │
│  요일 선택                       │
│  [월] [화] [수] [목] [금] [토] [일]│
│        ●                   ●    │
│                                 │
│  화요일: [15:00 ▼] / [60분 ▼]  │
│  토요일: [10:00 ▼] / [60분 ▼]  │
│                                 │
│  ┌─────────────────────────┐   │
│  │         등록 완료         │   │
│  └─────────────────────────┘   │
│                                 │
└─────────────────────────────────┘
```

---

## 선생님 레슨 설정 시스템

### 가용시간과 레슨 유형 통합

```
┌─────────────────────────────────┐
│  레슨 설정                       │
├─────────────────────────────────┤
│                                 │
│  📅 정기 레슨 가용 시간          │
│  ┌─────────────────────────┐   │
│  │ 월  14:00-18:00  [편집]  │   │
│  │ 화  14:00-18:00  [편집]  │   │
│  │ 수  휴무                 │   │
│  │ 목  14:00-18:00  [편집]  │   │
│  │ 금  14:00-18:00  [편집]  │   │
│  │ 토  10:00-13:00  [편집]  │   │
│  │ 일  휴무                 │   │
│  └─────────────────────────┘   │
│                                 │
│  ─────────────────────────────  │
│                                 │
│  🎵 체험 레슨 허용    [ON]      │
│  ➕ 1회 레슨 허용     [ON]      │
│                                 │
│  💡 체험/1회 레슨은 정기 레슨    │
│     가용 시간 내에서 예약 가능   │
│                                 │
└─────────────────────────────────┘
```

### 레슨 유형별 로직

| 유형 | 가용시간 | 설정 방식 |
|------|----------|----------|
| 정기 레슨 | 요일/시간대별 설정 | 가용시간 편집 |
| 체험 레슨 | 정기 가용시간 공유 | ON/OFF 토글 |
| 1회 레슨 | 정기 가용시간 공유 | ON/OFF 토글 |

---

## 단일 레슨 예약 프로세스 (체험/1회 통합)

### 핵심 원칙

**체험레슨과 1회레슨은 동일한 프로세스, 타입만 다름**

```
프로그램 관점:
- SingleLessonBooking 모델로 통합
- type 필드로 체험/1회 구분
- 예약/변경/취소 로직 100% 동일
- UI에서 라벨만 다르게 표시
```

### 공통 플로우

#### 신규 예약

```
학생: 선생님 선택 → 날짜/시간 선택 → 레슨 유형 선택 (체험/1회)
     → 예약 신청

선생님: 알림 수신 → 승인/거절
       → 승인 시 예약 확정
```

#### 일정 변경

```
학생: 예약 상세 → 일정 변경 요청 → 새 날짜/시간 선택
     → 변경 요청 발송

선생님: 알림 수신 → 승인/거절
       → 승인 시 일정 변경 확정
```

#### 예약 취소

```
학생: 예약 상세 → 취소 요청
     → 취소 정책에 따라 처리

선생님: 알림 수신 (정책에 따라 자동 처리 or 확인)
```

### 레슨 유형별 차이점

| 항목 | 체험레슨 | 1회레슨 |
|------|----------|---------|
| 대상 | 새로운 선생님 (관계 없음) | 기존/연결된 선생님 |
| 예약 프로세스 | **동일** | **동일** |
| 변경 프로세스 | **동일** | **동일** |
| 취소 프로세스 | **동일** | **동일** |
| 레슨 후 | 정규레슨 전환 제안 | 완료 |
| 결제 | 체험가 or 무료 | 1회 레슨비 |

---

## 정기 레슨 관리

### 정기레슨 특성

| 구분 | 단일 레슨 (체험/1회) | 정기 레슨 |
|------|---------------------|----------|
| 일정 | 1회성 날짜/시간 | 반복 패턴 (매주 X요일 Y시) |
| 관리 | 개별 예약 | 시리즈 + 개별 회차 |
| 변경 | 건별 변경 | 패턴 변경 or 특정 회차 변경 |

### 정기레슨 중 특정 회차 변경

특정 주만 시간 변경이 필요할 때 **두 가지 방법 모두 가능**:

```
예: 매주 화요일 3시 레슨
    → 다음 주 화요일만 5시로 변경하고 싶음
```

**방법 1: 예외 회차 등록**
```
학생/선생님: 해당 회차 선택 → "이번 주만 변경"
           → 새 시간 선택 (5시)
           → 상대방 승인
           → 해당 주만 5시, 이후는 기존대로 3시
```

**방법 2: 취소 + 1회 레슨 추가**
```
학생/선생님: 해당 회차 취소
           → 1회 레슨으로 새로 예약 (5시)
           → 상대방 승인
```

### 정기레슨 상태

```dart
// 정기레슨 시리즈 상태
enum RegularLessonStatus {
  active,      // 진행 중
  paused,      // 일시 중단
  terminated,  // 종료
}

// 개별 회차 상태 (단일 레슨과 동일)
enum LessonInstanceStatus {
  scheduled,   // 예정됨
  modified,    // 예외 시간으로 변경됨
  completed,   // 완료
  cancelled,   // 취소됨
  noShow,      // 노쇼
}
```

---

## 데이터 모델 추가

### TeacherInvitation (신규)

```dart
class TeacherInvitation {
  final String id;
  final String studentId;
  final String teacherName;
  final String teacherContact;  // 전화번호 or 이메일
  final String? instrument;
  final String inviteCode;
  final String inviteLink;
  final InviteStatus status;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final String? teacherId;  // 선생님 가입 후 연결
}

enum InviteStatus {
  pending,    // 초대 발송됨, 대기 중
  accepted,   // 선생님 가입 완료
  connected,  // 연결 승인 완료
  expired,    // 만료됨
}
```

### ConnectionRequest (신규)

```dart
class ConnectionRequest {
  final String id;
  final String fromUserId;
  final String toUserId;
  final ConnectionType type;
  final RequestStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;
}

enum ConnectionType {
  studentToTeacher,   // 학생이 선생님에게
  teacherToStudent,   // 선생님이 학생에게
  inviteAccepted,     // 초대 링크로 가입한 선생님
}

enum RequestStatus {
  pending,
  approved,
  rejected,
}
```

### TeacherLessonSettings (확장)

```dart
class TeacherLessonSettings {
  final String teacherId;
  final Map<int, List<TimeSlot>> availableSlots;  // 요일별 가용시간
  final bool trialLessonEnabled;   // 체험레슨 허용
  final bool oneTimeLessonEnabled; // 1회레슨 허용
  final int defaultLessonDuration; // 기본 레슨 시간 (분)
}
```

---

## 향후 확장 가능성

1. **패키지 레슨**: N회 묶음 레슨 (예: 10회 패키지)
2. **그룹 레슨**: 여러 학생이 함께 신청
3. **대기열 시스템**: 원하는 시간이 없을 때 대기 신청
4. **자동 매칭**: 조건에 맞는 선생님 자동 추천

---

## 참고

- 기존 스펙: [Lesson_Schedule_Design.md](./Lesson_Schedule_Design.md)
- 아이디어: [requirement.md](../../idea/lesson-app/requirement.md)
