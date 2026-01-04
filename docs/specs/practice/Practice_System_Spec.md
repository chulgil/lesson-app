# 연습 시스템 개요

> **문서 버전**: 2.0
> **최종 수정**: 2026-01-05
> **상태**: 구현 완료
> **역할**: 연습 시스템 전체 개요 및 아키텍처

---

## 관련 문서

| 문서 | 내용 |
|------|------|
| [practice_screen_spec.md](./practice_screen_spec.md) | 연습 화면 (탭, 날짜 선택, 리스트) |
| [repertoire_detail_spec.md](./repertoire_detail_spec.md) | 레퍼토리 상세 (CRUD, 아카이브) |
| [section_detail_spec.md](./section_detail_spec.md) | 섹션 상세/편집 (View, Add, Edit) |
| [recording_requirement.md](./recording_requirement.md) | 녹음 기능 상세 |

---

## 목차

1. [개요](#1-개요)
2. [용어 정의](#2-용어-정의)
3. [기능 요구사항](#3-기능-요구사항)
4. [데이터 모델](#4-데이터-모델)
5. [UI/UX 설계](#5-uiux-설계)
6. [뱃지 시스템](#6-뱃지-시스템)
7. [화면 플로우](#7-화면-플로우)
8. [구현 순서](#8-구현-순서)

---

## 1. 개요

### 1.1 배경

기존 "과제" 용어가 학생에게 부담감을 주어 연습 동기를 저하시킬 수 있다는 문제를 해결하고, 게이미피케이션 요소를 통해 자발적인 연습을 유도하는 시스템을 설계한다.

### 1.2 목표

- 부담감 없는 연습 관리 시스템 구축
- 레퍼토리와 연습의 자연스러운 연동
- 뱃지/보상 시스템을 통한 동기 부여
- 연령별 최적화된 UI/UX 제공

### 1.3 대상 사용자

| 사용자 | 역할 |
|--------|------|
| 선생님 | 연습 설정, 진도 확인, 좋아요 피드백 |
| 학생 | 연습 확인, 완료 체크, 뱃지 수집 |
| 학부모 | (향후) 연습 현황 알림 수신 |

---

## 2. 용어 정의

### 2.1 용어 변경

| 기존 용어 | 변경 용어 | 사용 맥락 |
|-----------|-----------|-----------|
| 과제 | **이번 주 연습** | 학생 화면 |
| 과제 추가 | **연습 설정** | 선생님 화면 |
| 과제 완료 | **연습 완료** | 공통 |
| 과제 목록 | **연습 목록** | 공통 |

### 2.2 우선순위 용어

| 코드 | 표시명 | 색상 | 의미 |
|------|--------|------|------|
| `must` | 필수 / 꼭 해오기 | 🔴 빨강 | 반드시 완료해야 함 |
| `should` | 추천 / 해오면 좋아요 | 🟡 노랑 | 권장사항 |
| `could` | 도전 / 도전해볼까? | 🟢 초록 | 선택적 도전 |

### 2.3 연령 그룹

| 코드 | 명칭 | 연령 기준 | UI 특성 |
|------|------|-----------|---------|
| `child` | 어린이 | 12세 이하 (초등학생) | 이모지 많음, 큰 글씨, 격려 메시지 |
| `student` | 학생 | 13-18세 (중고등학생) | 깔끔한 리스트, 색상 코드, 적당한 정보량 |
| `adult` | 성인 | 19세 이상 | 미니멀 디자인, 통계 중심, 체크박스 |

---

## 3. 기능 요구사항

### 3.1 연습 설정 (선생님)

#### 3.1.1 연습 추가 방식

```
┌─────────────────────────────────────┐
│ 연습 추가                            │
├─────────────────────────────────────┤
│ 방식 선택:                           │
│ ┌─────────────┐ ┌─────────────┐     │
│ │레퍼토리에서 │ │ 직접 입력   │     │
│ └─────────────┘ └─────────────┘     │
└─────────────────────────────────────┘
```

**A. 레퍼토리에서 선택** ✅ 구현됨
- 학생의 레퍼토리 목록 표시
- 기존 레퍼토리 선택 또는 새 레퍼토리 생성
- 곡명 입력 후 다중 구간 지정 가능
- 선택 시 PracticeSection 자동 생성 및 연동

**B. 다중 연습 구간 지원** ✅ 구현됨
- 구간 타입: 마디(measure) / 줄(line) 선택
- 여러 구간 추가 가능 (+ 구간 추가 버튼)
- 각 구간별 삭제 가능 (최소 1개 유지)
- 저장 형식: "곡명 1~5마디, 10~15줄"

**C. 직접 입력** (테크닉/이론/기타)
- 자유 텍스트 입력
- 레퍼토리 연동 없음

#### 3.1.2 우선순위 설정

```
우선순위:
🔴 필수     🟡 추천     🟢 도전
[  ●  ]    [     ]    [     ]
```

- 기본값: 🟡 추천
- 단일 선택 (라디오 버튼)

#### 3.1.3 설명 추가 (선택)

```
설명 (선택):
┌─────────────────────────────────────┐
│ 메트로놈 60으로 정확하게 연습하세요   │
└─────────────────────────────────────┘
```

- 최대 200자
- 선생님의 추가 지시사항

### 3.2 연습 완료 (학생)

#### 3.2.1 완료 체크 방식

```
┌─────────────────────────────────────┐
│ 🔴 Canon in D - A섹션               │
│ 메트로놈 60으로 정확하게             │
│                                     │
│ 연습 횟수:  [ - ]  0회  [ + ]       │
│                                     │
│ [      ✓ 연습 완료      ]          │
└─────────────────────────────────────┘
```

**동작 규칙**:
1. 횟수는 +/- 버튼으로 조작 (기본값: 0)
2. "연습 완료" 버튼 클릭 시:
   - 횟수가 0이면 → 자동으로 1로 설정
   - 완료 상태로 변경
   - 선생님에게 알림 전송
   - 뱃지 조건 체크

#### 3.2.2 완료 취소

- 완료된 항목 다시 클릭 시 취소 가능
- 횟수는 유지됨

### 3.3 좋아요 피드백 (선생님)

#### 3.3.1 좋아요 시점

| 시점 | 설명 |
|------|------|
| 실시간 알림 | 학생 완료 시 알림 → 바로 좋아요 가능 |
| 레슨 상세 | 언제든 해당 레슨의 연습 목록에서 가능 |

#### 3.3.2 좋아요 표시

```
✅ Canon in D - A섹션
   3회 연습 완료 · 12월 23일
   ❤️ 선생님이 좋아요를 눌렀어요!
```

### 3.4 레퍼토리 연동

#### 3.4.1 직접 입력 → 레퍼토리 추가 플로우

```
[직접 입력] 선택
    │
    ▼
┌─────────────────────────────────┐
│ 연습 제목:                       │
│ [엘리제를 위하여 1-16마디      ] │
└─────────────────────────────────┘
    │
    ▼ [추가] 클릭
    │
┌─────────────────────────────────┐
│ 이 연습을 레퍼토리에도           │
│ 추가할까요?                      │
│                                 │
│ 곡명: [엘리제를 위하여        ] │
│ 작곡가: [베토벤              ] │ (선택)
│                                 │
│ [아니요]  [레퍼토리에 추가]     │
└─────────────────────────────────┘
```

### 3.5 연령 판단 로직

#### 3.5.1 자동 계산 (학생 앱 사용 시)

```dart
AgeGroup calculateAgeGroup(DateTime birthDate) {
  final age = DateTime.now().year - birthDate.year;
  if (age <= 12) return AgeGroup.child;
  if (age <= 18) return AgeGroup.student;
  return AgeGroup.adult;
}
```

- 생년월일 기반 자동 계산
- **비공개**: 다른 사용자에게 노출되지 않음

#### 3.5.2 수동 설정 (학생 앱 미사용 시)

```
학생 프로필 편집
┌─────────────────────────────────┐
│ UI 스타일:                       │
│ ○ 어린이 (초등학생 이하)         │
│ ● 학생 (중고등학생)              │
│ ○ 성인                          │
└─────────────────────────────────┘
```

- 선생님이 직접 선택
- 기본값: 학생

---

## 4. 데이터 모델

### 4.1 RangeType (구간 타입) ✅ 신규

```dart
/// Range type for practice sections
enum RangeType {
  measure,  // 마디
  line,     // 줄 (오선지)
}
```

### 4.2 PracticeItem (연습 항목)

```dart
/// Practice priority levels
enum PracticePriority {
  must,    // 🔴 필수
  should,  // 🟡 추천
  could,   // 🟢 도전
}

/// Practice item types
enum PracticeType {
  repertoire,  // 레퍼토리에서 선택
  technique,   // 테크닉/스케일
  theory,      // 이론
  custom,      // 직접 입력
}

/// Practice item model
class PracticeItem {
  final String id;
  final String lessonId;          // 연결된 레슨 ID
  final String studentId;         // 학생 ID
  final String teacherId;         // 선생님 ID

  // Content
  final PracticeType type;
  final String title;             // "Canon in D - A섹션"
  final String? description;      // "메트로놈 60으로 정확하게"
  final String? repertoireId;     // 레퍼토리 연결 (선택)
  final String? sectionId;        // 섹션 연결 (선택)

  // Priority
  final PracticePriority priority;

  // Completion status
  bool isCompleted;
  int practiceCount;              // 연습 횟수 (기본: 0, 완료 시 최소: 1)
  DateTime? completedAt;

  // Teacher feedback
  bool hasLike;                   // 좋아요 여부
  DateTime? likedAt;

  // Timestamps
  final DateTime createdAt;
  DateTime? updatedAt;

  const PracticeItem({
    required this.id,
    required this.lessonId,
    required this.studentId,
    required this.teacherId,
    required this.type,
    required this.title,
    this.description,
    this.repertoireId,
    this.sectionId,
    this.priority = PracticePriority.should,
    this.isCompleted = false,
    this.practiceCount = 0,
    this.completedAt,
    this.hasLike = false,
    this.likedAt,
    required this.createdAt,
    this.updatedAt,
  });
}
```

### 4.2 Badge (뱃지)

```dart
/// Badge categories
enum BadgeCategory {
  consistency,  // 꾸준함
  diligence,    // 성실함
  challenge,    // 도전
  special,      // 특별
}

/// Badge definition
class Badge {
  final String id;
  final String name;              // "첫 연습"
  final String description;       // "첫 연습을 완료했어요"
  final String icon;              // 이모지 또는 아이콘 경로
  final BadgeCategory category;
  final Map<String, dynamic> condition;  // 획득 조건

  const Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    required this.condition,
  });
}

/// Student's earned badge
class StudentBadge {
  final String id;
  final String studentId;
  final String badgeId;
  final DateTime earnedAt;

  const StudentBadge({
    required this.id,
    required this.studentId,
    required this.badgeId,
    required this.earnedAt,
  });
}
```

### 4.3 Student 모델 확장

```dart
/// Age groups for UI differentiation
enum AgeGroup {
  child,    // 어린이 (12세 이하)
  student,  // 학생 (13-18세)
  adult,    // 성인 (19세 이상)
}

/// Extension for age group calculation
extension StudentAgeGroup on Student {
  /// Calculate age group from birth date
  AgeGroup? get calculatedAgeGroup {
    if (birthDate == null) return null;
    final age = DateTime.now().year - birthDate!.year;
    if (age <= 12) return AgeGroup.child;
    if (age <= 18) return AgeGroup.student;
    return AgeGroup.adult;
  }
}

// Student 모델에 추가할 필드
class Student {
  // ... 기존 필드 ...

  /// Manual age group setting (for students without app)
  final AgeGroup? manualAgeGroup;

  /// Effective age group (calculated or manual)
  AgeGroup get effectiveAgeGroup =>
    calculatedAgeGroup ?? manualAgeGroup ?? AgeGroup.student;
}
```

### 4.4 PracticeStats (연습 통계)

```dart
/// Practice statistics for a student
class PracticeStats {
  final String studentId;

  // Streak
  int currentStreak;              // 현재 연속 연습 일수
  int longestStreak;              // 최장 연속 연습 일수
  DateTime? lastPracticeDate;

  // Counts
  int totalCompleted;             // 총 완료 연습 수
  int totalMustCompleted;         // 필수 완료 수
  int totalLikesReceived;         // 받은 좋아요 수

  // Monthly stats
  int monthlyCompleted;           // 이번 달 완료 수
  int monthlyTotal;               // 이번 달 전체 수
  double get monthlyRate =>
    monthlyTotal > 0 ? monthlyCompleted / monthlyTotal : 0;
}
```

---

## 5. UI/UX 설계

### 5.1 어린이 UI (child)

```
┌─────────────────────────────────────────┐
│  🎵 이번 주 연습 🎵                      │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │ ⭐⭐⭐ 꼭 해와요!                 │    │
│  │ 🎹 도레미송 1-8마디              │    │
│  │                                 │    │
│  │ 연습: [ - ] 0번 [ + ]           │    │
│  │                                 │    │
│  │ [  🎉 연습 완료!  ]             │    │
│  └─────────────────────────────────┘    │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │ ⭐⭐ 해보면 좋아요~              │    │
│  │ 🎼 손가락 체조                   │    │
│  │                                 │    │
│  │ [  연습했어요  ]                │    │
│  └─────────────────────────────────┘    │
│                                         │
│  ═══════════════════════════════════    │
│  🏅 모은 뱃지: 🌱 🔥                     │
│  "와! 3일 연속 연습 중이야! 대단해!"    │
└─────────────────────────────────────────┘
```

**특징**:
- 큰 글씨 (16-18pt)
- 이모지 적극 사용
- 별표(⭐)로 우선순위 표시
- 격려 메시지 (반말, 친근한 톤)
- 밝은 색상

### 5.2 학생 UI (student)

```
┌─────────────────────────────────────────┐
│  이번 주 연습                    2/5 완료│
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━│
│                                         │
│  🔴 필수                                │
│  ┌─────────────────────────────────┐    │
│  │ Canon in D - A섹션              │    │
│  │ 메트로놈 60으로 정확하게         │    │
│  │                                 │    │
│  │ 횟수: [-] 0 [+]        [ 완료 ] │    │
│  └─────────────────────────────────┘    │
│                                         │
│  🟡 추천                                │
│  ┌─────────────────────────────────┐    │
│  │ 스케일 G장조                    │    │
│  │                        [     ] │    │
│  └─────────────────────────────────┘    │
│                                         │
│  🟢 도전                                │
│  ┌─────────────────────────────────┐    │
│  │ Canon in D - B섹션 미리보기     │    │
│  │                        [     ] │    │
│  └─────────────────────────────────┘    │
│                                         │
│  ──────────────────────────────────     │
│  🔥 5일 연속 연습 중 · 뱃지 12개 획득   │
└─────────────────────────────────────────┘
```

**특징**:
- 깔끔한 리스트 형태
- 색상 코드 (🔴🟡🟢)로 우선순위
- 진행률 표시 (상단)
- 적당한 정보량
- 존댓말 사용

### 5.3 성인 UI (adult)

```
┌─────────────────────────────────────────┐
│  이번 주 연습                           │
│  ─────────────────────────────────────  │
│  진행률 40% (2/5)     마감: 3일 후      │
│                                         │
│  ■ 필수 (1/2)                          │
│    ☑ Canon in D - A섹션                │
│      └ 메트로놈 60, 정확한 리듬         │
│    ☐ 에튀드 Op.25 No.1                 │
│                                         │
│  ■ 권장 (1/2)                          │
│    ☐ 스케일 G장조                      │
│    ☑ 아르페지오 연습                    │
│                                         │
│  ■ 선택 (0/1)                          │
│    ☐ Canon in D - B섹션 예습           │
│                                         │
│  ─────────────────────────────────────  │
│  연속 연습: 5일 | 이번 달 완료율: 78%   │
└─────────────────────────────────────────┘
```

**특징**:
- 미니멀한 디자인
- 통계/데이터 중심
- 체크박스(☑☐) 스타일
- 마감일 표시
- 존칭 사용 (권장, 선택)

---

## 6. 뱃지 시스템

### 6.1 뱃지 목록

#### 6.1.1 꾸준함 (Consistency)

| ID | 아이콘 | 이름 | 설명 | 조건 |
|----|--------|------|------|------|
| `first_practice` | 🌱 | 첫 연습 | 첫 연습을 완료했어요 | 연습 1회 완료 |
| `streak_3` | 🔥 | 3일 연속 | 3일 연속 연습했어요 | 연속 3일 |
| `streak_7` | ⚡ | 7일 연속 | 일주일 연속 연습했어요 | 연속 7일 |
| `streak_30` | 💪 | 30일 연속 | 한 달 연속 연습했어요 | 연속 30일 |
| `streak_100` | 👑 | 100일 연속 | 100일 연속 연습 달성 | 연속 100일 |

#### 6.1.2 성실함 (Diligence)

| ID | 아이콘 | 이름 | 설명 | 조건 |
|----|--------|------|------|------|
| `perfect_week` | ✅ | 완벽한 한 주 | 주간 연습 100% 완료 | 주간 완료율 100% |
| `must_master` | ⭐ | 필수 달인 | "필수" 연습 10회 완료 | 필수 10회 |
| `practice_king` | 🏆 | 연습왕 | 월간 완료율 90% 이상 | 월 완료율 ≥90% |

#### 6.1.3 도전 (Challenge)

| ID | 아이콘 | 이름 | 설명 | 조건 |
|----|--------|------|------|------|
| `first_piece` | 🎵 | 첫 곡 완주 | 레퍼토리 1곡 완료 | 레퍼토리 1곡 완료 |
| `five_pieces` | 🎹 | 5곡 마스터 | 레퍼토리 5곡 완료 | 레퍼토리 5곡 완료 |
| `challenge_king` | 💎 | 도전왕 | "도전" 연습 10회 완료 | 도전 10회 |

#### 6.1.4 특별 (Special)

| ID | 아이콘 | 이름 | 설명 | 조건 |
|----|--------|------|------|------|
| `first_like` | ❤️ | 선생님 칭찬 | 좋아요 5회 받기 | 좋아요 5회 |
| `loved_student` | 💝 | 사랑받는 학생 | 좋아요 20회 받기 | 좋아요 20회 |
| `performance` | 🎭 | 무대 경험 | 발표회 참가 | 수동 부여 |

### 6.2 뱃지 획득 로직

```dart
class BadgeChecker {
  /// Check and award badges after practice completion
  Future<List<Badge>> checkBadges(String studentId) async {
    final stats = await getStats(studentId);
    final earnedBadges = await getEarnedBadges(studentId);
    final newBadges = <Badge>[];

    // Check streak badges
    if (stats.currentStreak >= 3 && !earnedBadges.contains('streak_3')) {
      newBadges.add(badges['streak_3']!);
    }
    if (stats.currentStreak >= 7 && !earnedBadges.contains('streak_7')) {
      newBadges.add(badges['streak_7']!);
    }
    // ... more checks

    // Award new badges
    for (final badge in newBadges) {
      await awardBadge(studentId, badge.id);
    }

    return newBadges;
  }
}
```

### 6.3 뱃지 획득 알림

```
┌─────────────────────────────────────┐
│                                     │
│         🎉 새 뱃지 획득! 🎉          │
│                                     │
│              🔥                     │
│         "3일 연속"                  │
│                                     │
│    3일 연속으로 연습했어요!          │
│                                     │
│           [ 확인 ]                  │
│                                     │
└─────────────────────────────────────┘
```

---

## 7. 화면 플로우

### 7.1 선생님 플로우

```
레슨 상세 화면
       │
       ├─ [연습 설정] 버튼
       │       │
       │       ▼
       │   연습 추가 바텀시트
       │       │
       │       ├─ [레퍼토리에서 선택]
       │       │       │
       │       │       ▼
       │       │   레퍼토리 목록
       │       │       │
       │       │       └─ 곡/섹션 선택
       │       │
       │       └─ [직접 입력]
       │               │
       │               ▼
       │           텍스트 입력
       │               │
       │               ▼
       │       레퍼토리 추가 확인?
       │               │
       │       ┌───────┴───────┐
       │       ▼               ▼
       │   [아니요]     [추가하기]
       │
       ├─ 연습 목록 확인/수정/삭제
       │
       └─ 학생 완료 알림 수신
               │
               └─ [❤️ 좋아요] 누르기
```

### 7.2 학생 플로우

```
레슨 탭 (홈)
       │
       ├─ 이번 주 연습 카드
       │       │
       │       ▼
       │   연습 목록 화면
       │       │
       │       ├─ 연습 항목 선택
       │       │       │
       │       │       ▼
       │       │   상세 보기 (설명 확인)
       │       │
       │       ├─ 횟수 조절 (+/-)
       │       │
       │       └─ [연습 완료] 체크
       │               │
       │               ├─ 횟수 0 → 자동 1로
       │               ├─ 선생님 알림 전송
       │               └─ 뱃지 조건 체크
       │                       │
       │                       ▼
       │               (새 뱃지 있으면)
       │                   뱃지 획득 팝업
       │
       └─ 뱃지 컬렉션 보기
               │
               └─ 획득/미획득 뱃지 목록
```

---

## 8. 구현 순서

### Phase 1: 기본 연습 기능 (MVP) ✅ 완료

```
1.1 데이터 모델 ✅
├── PracticeItem 모델 생성
├── PracticePriority enum
├── PracticeType enum
└── Repository 인터페이스 정의

1.2 Repository 구현 ✅
├── MockPracticeItemRepository
└── CRUD 메서드

1.3 Provider 구현 ✅
├── practiceItemRepositoryProvider
├── practiceItemsNotifierProvider (FamilyAsyncNotifier)
├── practiceItemsByStudentProvider
└── currentTeacherIdProvider

1.4 선생님 UI ✅
├── 레슨 상세에 PracticeItemsSection 추가
├── AddPracticeItemSheet (연습 추가 바텀시트)
├── 우선순위 선택 UI (ChoiceChip)
├── EditPracticeItemSheet (연습 수정/삭제)
└── 좋아요 기능

1.5 학생 UI ✅ (기본)
├── 이번 주 연습 목록 위젯
├── 완료 체크 기능
└── 연습 횟수 표시
```

### Phase 2: 레퍼토리 연동 ✅ 완료

```
2.1 레퍼토리 선택 기능 ✅
├── 학생 레퍼토리 목록 표시 (Radio 형태)
├── 새 레퍼토리 생성 옵션
├── 곡명 입력 필드
└── PracticeSection 자동 생성 및 연동

2.2 다중 구간 지원 ✅ (신규)
├── RangeType enum (마디/줄)
├── PracticeRangeEntry 클래스
├── 다중 구간 추가/삭제 UI
└── 드롭다운 타입 선택
```

### Phase 3: 좋아요 & 알림

```
3.1 알림 시스템
├── 학생 완료 → 선생님 알림
└── (향후) 학부모 알림

3.2 좋아요 기능
├── 좋아요 버튼 UI
├── 좋아요 상태 저장
└── 학생 화면에 좋아요 표시
```

### Phase 4: 뱃지 시스템

```
4.1 뱃지 데이터
├── Badge 모델
├── StudentBadge 모델
├── 초기 뱃지 데이터 정의
└── Repository 구현

4.2 획득 로직
├── BadgeChecker 서비스
├── 연습 완료 시 체크
└── 조건별 판단 로직

4.3 UI
├── 뱃지 컬렉션 화면
├── 획득 팝업
└── 연령별 뱃지 표시
```

### Phase 5: 통계 및 고도화

```
5.1 연습 통계
├── PracticeStats 모델
├── 스트릭 계산
├── 완료율 계산
└── 통계 화면

5.2 연령별 UI 고도화
├── 어린이용 애니메이션
├── 학생용 진행률 바
└── 성인용 상세 통계
```

---

## 부록

### A. 관련 문서

- [레슨 스케줄 설계](./Lesson_Schedule_Design.md)
- [요구사항 문서](./requirement.md)
- [연습 스트릭 스펙](./practice_streak_spec.md)

### B. 변경 이력

| 버전 | 날짜 | 변경 내용 |
|------|------|----------|
| 1.0 | 2024-12-24 | 초안 작성 |
| 1.1 | 2024-12-24 | Phase 1-2 구현 완료, 다중 구간 지원 추가 |
| 1.2 | 2026-01-04 | 섹션 CRUD 확장: 범위 유형(전체/줄/마디), 녹음 필터(전체/주간/당일), 연습 완료 UI 위치 변경(녹음 위). 상세 스펙은 repertoire_section_crud_spec.md, section_detail_view_spec.md 참조 |

### C. 미결정 사항

- [ ] 학부모 알림 상세 스펙 (향후 결정)
- [ ] 발표회 참가 뱃지 수동 부여 방법
- [ ] 뱃지 레벨업 시스템 (선택적 확장)
