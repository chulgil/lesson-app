# Practice System Master Spec

> 구현 상태: ⚠️ 부분 구현 (56%) — 뱃지, 보고서, 백업, A/B 비교 미구현
> Last updated: 2026-03-07
> Status: Single Source of Truth for practice domain
> 원본 문서 18개 통합

---

## 목차

1. [개요](#1-개요)
2. [연습 코어](#2-연습-코어)
3. [레퍼토리 관리](#3-레퍼토리-관리)
4. [녹음 시스템](#4-녹음-시스템)
5. [공유 및 리포트](#5-공유-및-리포트)
6. [백업 시스템](#6-백업-시스템)
7. [구현 현황](#7-구현-현황)
8. [Claude 구현 가이드](#8-claude-구현-가이드)
9. [관련 스펙](#9-관련-스펙)
10. [변경 이력](#10-변경-이력)

---

## 1. 개요

### 1.1 배경

기존 "과제" 용어가 학생에게 부담감을 주어 연습 동기를 저하시키는 문제를 해결하고, 게이미피케이션 요소를 통해 자발적인 연습을 유도하는 시스템.

### 1.2 목표

- 부담감 없는 연습 관리 시스템 구축
- 레퍼토리와 연습의 자연스러운 연동
- 뱃지/보상 시스템을 통한 동기 부여
- 연령별 최적화된 UI/UX 제공

### 1.3 경쟁사 대비 차별점

| 기능 | Lessonaza | Practice Space | Tonara | Simply Piano |
|------|:---------:|:--------------:|:------:|:------------:|
| 메트로놈 (커스텀 네이티브) | O | 기본 | X | X |
| 튜너 (실시간 음고 감지) | O | X | X | O (피아노만) |
| 녹음 + 스마트 트림 | O | X | X | X |
| A-B 구간 반복 재생 | O | X | X | X |
| 중간 무음 스킵 | O | X | X | X |
| 파형 핀치줌 + 속도 조절 | O | X | X | X |
| 선생님-학생 연습 연동 | O | O | O | X |
| 연령별 UI 최적화 (3단계) | O | X | X | X |
| 레퍼토리 히스토리 타임라인 | O | X | X | X |
| 연습 스트릭 (주말 제외) | O | X | O | X |

**핵심 차별점**: 메트로놈 + 튜너 + 녹음 + 스마트 트림을 **단일 앱 내 통합** 제공. 경쟁사 Practice Space는 기본 메트로놈만, Tonara는 게이미피케이션에 집중하되 녹음/튜너 부재. 레슨 관리 앱과 연습 도구 앱을 분리해 사용해야 하는 불편함을 해소.

### 1.4 대상 사용자

| 사용자 | 역할 |
|--------|------|
| 선생님 | 연습 설정, 진도 확인, 좋아요 피드백 |
| 학생 | 연습 확인, 완료 체크, 뱃지 수집, 녹음 관리 |
| 학부모 | (향후) 연습 현황 알림 수신, 대시보드 조회 |

### 1.5 용어

| 기존 용어 | 변경 용어 | 사용 맥락 |
|-----------|-----------|-----------|
| 과제 | **이번 주 연습** | 학생 화면 |
| 과제 추가 | **연습 설정** | 선생님 화면 |
| 과제 완료 | **연습 완료** | 공통 |

### 1.6 우선순위

| 코드 | 표시명 | 색상 | 의미 |
|------|--------|------|------|
| `must` | 필수 / 꼭 해오기 | 빨강 | 반드시 완료해야 함 |
| `should` | 추천 / 해오면 좋아요 | 노랑 | 권장사항 |
| `could` | 도전 / 도전해볼까? | 초록 | 선택적 도전 |

#### PracticePriority Enum (정식 정의)

> 소스: `features/practice/domain/entities/practice_item.dart`

```dart
enum PracticePriority {
  must,    // 필수 - 꼭 해오기 (빨강, AppColors.error)
  should,  // 추천 - 해오면 좋아요 (노랑, AppColors.practiceNormal)
  could;   // 도전 - 도전해볼까? (초록, AppColors.practiceGood)

  String get label;       // 선생님 UI: 필수/추천/도전
  String get childLabel;  // 어린이 UI: 꼭 해와요!/해보면 좋아요~/도전해볼까?
  String get shortLabel;  // 성인 UI: 필수/권장/선택
  Color get color;        // 우선순위별 색상
  String get emoji;       // 어린이 UI: 별 개수 (⭐⭐⭐/⭐⭐/⭐)
  String get dot;         // 학생/성인 UI: 색상 점 (🔴/🟡/🟢)
  int get sortOrder;      // 정렬 순서 (0/1/2)
}
```

#### PracticeType Enum (정식 정의)

> 소스: `features/practice/domain/entities/practice_item.dart`

```dart
enum PracticeType {
  repertoire,  // 레퍼토리에서 선택
  technique,   // 테크닉/스케일
  theory,      // 이론
  custom;      // 직접 입력

  String get label;     // 레퍼토리/테크닉/이론/직접입력
  IconData get icon;    // music_note/piano/menu_book/edit_note
}
```

### 1.7 연령 그룹

| 코드 | 명칭 | 연령 기준 | UI 특성 |
|------|------|-----------|---------|
| `child` | 어린이 | 12세 이하 | 이모지 많음, 큰 글씨, 격려 메시지, 별표 우선순위 |
| `student` | 학생 | 13-18세 | 깔끔한 리스트, 색상 코드, 적당한 정보량 |
| `adult` | 성인 | 19세 이상 | 미니멀 디자인, 통계 중심, 체크박스 |

연령 판단: 생년월일 기반 자동 계산 (학생 앱) 또는 선생님이 수동 설정 (기본값: 학생)

### 1.8 핵심 데이터 모델 요약

| 모델 | 저장 | 설명 |
|------|:----:|------|
| PracticeItem | Hive | 선생님이 설정한 연습 항목 |
| PracticeRepertoire | Hive | 레퍼토리 (곡 모음) |
| PracticeSection | Hive | 레퍼토리 내 구간/섹션 |
| PracticeRecording | Hive | 녹음 파일 메타데이터 |
| Recording | Hive (typeId: 22) | 공유 가능 녹음 (sharedAt, storageStatus) |
| PracticeStreak | Hive | 연속 연습일 기록 |
| PracticeGoal | Hive | 연습 목표 설정 |
| PracticeNote | Hive | 섹션별 연습 노트 |
| JournalPrivacy | Hive | 연습 저널 공개 범위 (user + student별 저장) |
| PracticeStats | - | 연습 통계 (계산값) |

#### 1.8.1 JournalPrivacy

| 값 | 의미 |
|------|------|
| `private` | 본인만 열람 |
| `partial` | 제한된 범위만 공유 |
| `shared` | 전체 저널 공유 |

저장 규칙은 `currentUserId`와 학생 ID를 함께 묶어서 키를 만들고, 사용자별/학생별 상태가 서로 덮어쓰이지 않도록 한다.

---

## 2. 연습 코어

### 2.1 연습 화면 (Practice Screen)

> 원본: `practice_screen_spec.md` | 상태: **구현 완료**

#### 2.1.1 화면 구조

```
+-----------------------------------------+
| 연습                               [설정]|
+-----------------------------------------+
| +-------------------------------------+ |
| | < 2026년 1월 5일 (일)           >   | |  <- 날짜 선택
| +-------------------------------------+ |
|                                         |
| +-------------------------------------+ |
| | 스즈키 6권                  [+] [v] | |  <- 레퍼토리 카드
| +-------------------------------------+ |
| | [ ] 라폴리아 1~8 마디    반복   [>] | |  <- 섹션 아이템
| | [v] 라폴리아 9~16 마디   2/4   [>] | |
| | [ ] 가보트 전체                 [>] | |
| +-------------------------------------+ |
|                                         |
|                               [+ 추가]  |  <- FAB
+-----------------------------------------+
```

#### 2.1.2 날짜 선택 바

| 요소 | 동작 |
|------|------|
| < / > | 전날/다음날로 이동 |
| 날짜 텍스트 | 탭 시 달력 팝업 (Material DatePicker) |
| "오늘" 배지 | 오늘 날짜일 때만 표시 |

#### 2.1.3 날짜별 표시 로직

- **오늘**: 활성 레퍼토리의 모든 섹션 표시, 완료 여부 실시간 반영, 섹션 추가/편집 가능
- **과거**: 해당 날짜에 연습한 섹션만 표시, 완료 기록 표시 (수정 불가), 녹음 기록 조회 가능

```dart
List<PracticeSection> getSectionsForDate(DateTime date) {
  if (isToday(date)) {
    return activeSections;
  } else {
    return sections.where((s) =>
      s.completionHistory.any((c) => isSameDay(c.date, date))
    ).toList();
  }
}
```

#### 2.1.4 레퍼토리 카드

| 요소 | 동작 |
|------|------|
| 카드 탭 | 레퍼토리 상세 화면으로 이동 |
| [+] 버튼 | 섹션 추가 화면으로 이동 |
| [v] 버튼 | 섹션 목록 접기/펼치기 토글 |
| 롱프레스 | 편집/삭제 메뉴 표시 |

#### 2.1.5 섹션 아이템 표시 규칙

| 아이콘 | 의미 |
|--------|------|
| [ ] / [v] | 연습 완료 여부 (일반 섹션) |
| 별 | 과제 섹션 (선생님 지정) |
| 반복 | 매일 반복 (isRepeat) |
| 발자국 3/5 | N회 반복 진행률 (repeatCount) |

섹션 정렬: 생성순(기본, 최신 위) / 이름순 / 마디순 / 사용자 지정(드래그앤드롭)

#### 2.1.6 미완료 항목

- [ ] 과거 날짜 필터링 (해당 날짜 연습 기록만 표시)
- [ ] 과제 섹션 별 아이콘 표시
- [ ] 섹션 드래그앤드롭 순서 변경

---

### 2.2 연습 목표 시스템 (Practice Goal)

> 원본: `practice_goal_spec.md` | 상태: **설계 완료 (미구현)**

#### 2.2.1 핵심 결정사항

| 항목 | 결정 |
|------|------|
| 목표 설정 주체 | 학생 본인만 설정 |
| 일일 목표 | 연습 시간 + 완료 섹션 수 |
| 주간 목표 | 연습 시간 + 연습 일수 |
| 달성 보상 | 알림 + 스트릭 연계 + 뱃지 |

#### 2.2.2 PracticeGoal 모델

| 필드 | 타입 | 설명 |
|------|------|------|
| dailyTimeMinutes | int? | 일일 연습 시간 목표 (분) |
| dailySectionCount | int? | 일일 완료 섹션 수 목표 |
| weeklyTimeMinutes | int? | 주간 연습 시간 목표 (분) |
| weeklyDayCount | int? | 주간 연습 일수 목표 |
| isActive | bool | 목표 활성화 여부 |

#### 2.2.3 기본값

| 항목 | 추천 기본값 | 옵션 |
|------|:----------:|------|
| 일일 시간 | 30분 | 15, 30, 45, 60분 |
| 일일 섹션 | 3개 | 1, 2, 3, 5개 |
| 주간 시간 | 3시간 | 1, 2, 3, 5시간 |
| 주간 일수 | 5일 | 3, 4, 5, 7일 |

#### 2.2.4 스트릭 연계

- 목표 미설정: 연습만 하면 스트릭 증가 (기존 로직)
- 목표 설정: 일일 목표 달성 시에만 스트릭 증가

```dart
bool shouldIncrementStreak({
  required PracticeGoal? goal,
  required DailyPracticeProgress todayProgress,
  required bool hasAnyPracticeToday,
}) {
  if (goal == null || !goal.hasAnyGoal) return hasAnyPracticeToday;
  return todayProgress.isDailyGoalAchieved(goal);
}
```

#### 2.2.5 UI

- 학생 홈 화면 목표 위젯: 프로그레스 바 표시 (시간/섹션)
- 목표 설정 화면: 칩 선택 방식 + 사용자 지정 입력
- 달성 알림: 일일/주간 목표 달성 시 다이얼로그

#### 2.2.6 파일 구조

```
lib/features/practice/
├── domain/entities/practice_goal.dart          # PracticeGoal 모델
├── domain/repositories/practice_goal_repository.dart
├── data/repositories/mock_practice_goal_repository.dart
├── presentation/
│   ├── providers/practice_goal_provider.dart
│   ├── screens/practice_goal_setting_screen.dart
│   └── widgets/goal/
│       ├── goal_progress_widget.dart
│       ├── goal_achieved_dialog.dart
│       └── goal_setting_chips.dart
```

---

### 2.3 연습 스트릭 (Practice Streak)

> 원본: `practice_streak_spec.md` | 상태: **구현 완료**

#### 2.3.1 스트릭 규칙

| 규칙 | 설명 |
|------|------|
| 스트릭 증가 | 하루 1회 이상 연습 기록 시 |
| 스트릭 유지 | 연속된 평일에 연습 기록 |
| 스트릭 리셋 | 평일에 연습 기록 없을 시 |
| **주말 제외** | 토/일은 리셋 대상에서 제외 |

**주말 제외 정책 상세:**
- 금요일 연습 -> (토,일 skip) -> 월요일 연습 = 스트릭 유지
- 금요일 연습 -> (토,일 skip) -> 화요일 연습 = 스트릭 리셋 (월요일 미연습)
- 토요일에 연습 = 스트릭에 포함 (보너스)

#### 2.3.2 스트릭 레벨 시스템

| 레벨 | 연속일 | 이모지 | 색상 테마 | 메시지 |
|------|--------|--------|----------|--------|
| 0 | 0일 | - | 회색 | "첫 연습을 시작해보세요!" |
| 1 | 1-6일 | sparkle | 보라색 | "좋은 시작이에요!" |
| 2 | 7-29일 | fire | 주황/빨강 | "꾸준히 하고 있어요!" |
| 3 | 30일+ | fire x2 | 골드 | "대단해요! 마스터 레벨!" |

#### 2.3.3 PracticeStreak 모델

```dart
class PracticeStreak {
  final String id;
  final String studentId;
  final int currentStreak;       // 현재 연속일
  final int longestStreak;       // 최장 기록
  final DateTime? lastPracticeDate;
  final DateTime updatedAt;

  bool get isActive => _checkIsActive();
  bool get practicedToday => _checkPracticedToday();
  int get streakLevel => _calculateLevel();
  String get fireEmoji => _getEmoji();
  String get motivationMessage => _getMessage();
}
```

#### 2.3.4 UI 컴포넌트

| 컴포넌트 | 위치 | 설명 |
|----------|------|------|
| PracticeStreakCard | 학생 홈 대시보드 상단 | 대형 카드, 그라데이션, 주간 점 |
| PracticeStreakBadge | 프로필, 학생 리스트 | 소형 배지 (이모지 + 연속일) |
| RecordPracticeButton | 학생 홈 | "오늘 연습 기록하기" / "오늘 연습 완료!" |

---

### 2.4 연습 노트 (Practice Note)

> 원본: `practice_note_spec.md` | 상태: **설계 완료 (미구현)**

#### 2.4.1 핵심 결정사항

| 항목 | 결정 |
|------|------|
| 공개 범위 | 학생 전용 (선생님 비공개) |
| 작성 빈도 | 하루에 여러 개 가능 (시간별 구분) |
| 권한 | 작성자만 수정/삭제 가능 |
| 첨부 | 텍스트만 (Phase 1) |

#### 2.4.2 PracticeNote 모델

| 필드 | 타입 | 설명 |
|------|------|------|
| id | String | 고유 식별자 |
| sectionId | String | 연결된 섹션 ID |
| content | String | 노트 내용 (텍스트) |
| createdAt | DateTime | 작성 시간 |
| updatedAt | DateTime? | 수정 시간 |

#### 2.4.3 UI 흐름

1. 섹션 상세 화면: 최근 연습노트 미리보기 (1줄)
2. 노트 미리보기 터치 -> 연습노트 리스트 화면
3. 리스트에서 날짜별 그룹핑, 시간 표시
4. [+] 버튼으로 새 노트 추가 (다이얼로그)
5. [...] 메뉴로 수정/삭제

#### 2.4.4 향후 확장

| 기능 | Phase | 설명 |
|------|:-----:|------|
| 이미지 첨부 | 2 | 악보 사진, 손 모양 등 |
| 음성 메모 | 2 | 녹음 대신 간단한 음성 메모 |
| 선생님 공유 | 2 | 특정 노트만 선생님에게 공유 |
| 태그/검색 | 2 | 노트 태그 및 검색 기능 |

---

### 2.5 연습 센터 버튼 (Central Practice Button)

> 원본: `central_practice_button.md` | 상태: **Phase 1 구현 완료**

#### 2.5.1 개요

학생 홈 화면 하단 네비게이션 바 중앙에 위치한 돌출 버튼. 메트로놈/튜너에 빠르게 접근.

#### 2.5.2 상호작용

| 제스처 | 동작 |
|--------|------|
| 탭 (Tap) | 튜너 탭으로 PracticeToolsModal 열기 (initialTab: 1) |
| 길게 누르기 (Long Press) | 메트로놈 탭으로 PracticeToolsModal 열기 (initialTab: 0) |

#### 2.5.3 디자인

- 크기: 64x64dp 원형, elevation 8dp
- 색상: Primary gradient (`AppColors.primary` -> `AppColors.primaryDark`)
- 아이콘: 튜닝포크 + 메트로놈 조합 (CustomPainter, 32x32dp)
- 눌림 상태: Scale 0.95 (AnimatedScale)

#### 2.5.4 구현 Phase

| Phase | 내용 | 상태 |
|-------|------|:----:|
| 1 | 정적 아이콘, 탭 -> PracticeToolsModal | 구현 완료 |
| 2 | 탭 -> 메트로놈 즉시 시작, 길게 -> 모달 | 예정 |
| 3 | 커스텀 아이콘, 메트로놈 활성 시 애니메이션 | 예정 |

#### 2.5.5 파일

- `lib/core/widgets/practice_center_button.dart`
- `lib/features/practice/presentation/widgets/practice_tools_modal.dart`

---

### 2.6 연습 설정 (선생님)

> 원본: `Practice_System_Spec.md` 3.1절 | 상태: **Phase 1-2 구현 완료**

#### 2.6.1 연습 추가 방식

**A. 레퍼토리에서 선택** (구현 완료)
- 학생의 레퍼토리 목록 표시
- 기존 레퍼토리 선택 또는 새 레퍼토리 생성
- 곡명 입력 후 다중 구간 지정 가능
- 선택 시 PracticeSection 자동 생성 및 연동

**B. 다중 연습 구간 지원** (구현 완료)
- 구간 타입: 마디(measure) / 줄(line) 선택
- 여러 구간 추가 가능 (+ 구간 추가 버튼)
- 각 구간별 삭제 가능 (최소 1개 유지)

**C. 직접 입력** (테크닉/이론/기타)
- 자유 텍스트 입력
- 레퍼토리 연동 없음

#### 2.6.2 우선순위 설정

- 기본값: 추천(should)
- 단일 선택 (라디오 버튼)
- 색상 코드: 빨강(필수) / 노랑(추천) / 초록(도전)

#### 2.6.3 연습 완료 (학생)

- 횟수: +/- 버튼으로 조작 (기본값 0)
- "연습 완료" 클릭 시: 횟수 0이면 자동 1, 완료 상태 변경, 선생님 알림, 뱃지 체크
- 완료 취소: 완료된 항목 다시 클릭 시 가능, 횟수는 유지

#### 2.6.4 좋아요 피드백 (선생님)

- 시점: 실시간 알림에서 바로, 또는 레슨 상세에서 언제든
- 표시: "선생님이 좋아요를 눌렀어요!" + 하트 아이콘

#### 2.6.5 PracticeItem 모델

```dart
class PracticeItem {
  final String id;
  final String lessonId;
  final String studentId;
  final String teacherId;
  final PracticeType type;         // repertoire, technique, theory, custom
  final String title;
  final String? description;       // 최대 200자
  final String? repertoireId;
  final String? sectionId;
  final PracticePriority priority; // must, should, could
  bool isCompleted;
  int practiceCount;               // 기본 0, 완료 시 최소 1
  DateTime? completedAt;
  bool hasLike;
  DateTime? likedAt;
  final DateTime createdAt;
  DateTime? updatedAt;
}
```

---

### 2.7 뱃지 시스템

> 원본: `Practice_System_Spec.md` 6절 | 상태: **설계 완료 (미구현)**

#### 2.7.1 뱃지 목록

**꾸준함 (Consistency)**

| ID | 이름 | 조건 |
|----|------|------|
| `first_practice` | 첫 연습 | 연습 1회 완료 |
| `streak_3` | 3일 연속 | 연속 3일 |
| `streak_7` | 7일 연속 | 연속 7일 |
| `streak_30` | 30일 연속 | 연속 30일 |
| `streak_100` | 100일 연속 | 연속 100일 |

**성실함 (Diligence)**

| ID | 이름 | 조건 |
|----|------|------|
| `perfect_week` | 완벽한 한 주 | 주간 완료율 100% |
| `must_master` | 필수 달인 | 필수 연습 10회 완료 |
| `practice_king` | 연습왕 | 월간 완료율 90% 이상 |

**도전 (Challenge)**

| ID | 이름 | 조건 |
|----|------|------|
| `first_piece` | 첫 곡 완주 | 레퍼토리 1곡 완료 |
| `five_pieces` | 5곡 마스터 | 레퍼토리 5곡 완료 |
| `challenge_king` | 도전왕 | 도전 연습 10회 완료 |

**특별 (Special)**

| ID | 이름 | 조건 |
|----|------|------|
| `first_like` | 선생님 칭찬 | 좋아요 5회 받기 |
| `loved_student` | 사랑받는 학생 | 좋아요 20회 받기 |
| `performance` | 무대 경험 | 발표회 참가 (수동 부여) |

#### 2.7.2 뱃지 획득 로직

- 연습 완료 시 `BadgeChecker`가 조건 체크
- 새 뱃지 획득 시 팝업 알림

---

## 3. 레퍼토리 관리

### 3.1 레퍼토리 상세 (Repertoire Detail)

> 원본: `repertoire_detail_spec.md` | 상태: **구현 완료**

#### 3.1.1 화면 구성

| 화면 | 상태 |
|------|:----:|
| 레퍼토리 상세 (정보, 섹션 목록, 통계) | 구현 완료 |
| 레퍼토리 추가 (이름/설명/기간, 빠른 선택, 저장 후 섹션 추가) | 구현 완료 |
| 레퍼토리 편집 (이름/설명/기간 수정, 아카이브/삭제) | 구현 완료 |
| 빠른 추가 (레퍼토리 + 여러 섹션 동시 생성) | 구현 완료 |
| 빠른 편집 (레퍼토리 + 여러 섹션 동시 수정) | 미구현 |
| 아카이브 목록 | 구현 완료 |

#### 3.1.2 레퍼토리 상세 레이아웃

- 헤더: 레퍼토리 이름 + 녹음/메뉴 버튼
- 기본 정보: 이름, 설명, 연습 기간 (읽기 전용, 편집 아이콘 -> 편집 화면)
- 기간 표시: `2026.01.01 ~ 2026.06.30` 또는 `2026.01.01 ~ 진행중`
- 통계: 섹션 N개 / 완료 N개 / 연습 N시간
- 섹션 목록: 곡명, 범위, 반복 아이콘, 상세 이동

#### 3.1.3 레퍼토리 추가

- 이름 (필수), 설명 (선택)
- 기간 설정: 시작일/종료일 (DateRangeSection 위젯)
- 빠른 선택: 스즈키 1~6권, 크로이처, 세브시크, 바흐, 스케일 등
- "저장 후 섹션 추가하기" 버튼

#### 3.1.4 아카이브 시스템

- **아카이브**: 완료된 레퍼토리를 숨김 처리 (삭제 X)
- **복원**: 아카이브에서 다시 활성화
- **영구 삭제**: 아카이브에서 완전 삭제

```dart
class PracticeRepertoire {
  final bool isArchived;
  final DateTime? archivedAt;
  bool get isActive => !isArchived;
}
```

#### 3.1.5 미완료 항목

- [ ] 섹션 정렬 옵션 (최신순/오래된순/이름순/마디순/사용자지정)
- [ ] 섹션 드래그앤드롭 순서 변경

#### 3.1.6 파일

```
lib/features/practice/presentation/screens/
├── repertoire_detail_screen.dart
├── add_repertoire_screen.dart
├── edit_repertoire_screen.dart
├── repertoire_archive_screen.dart
└── quick_add_screen.dart
```

---

### 3.2 섹션 상세 (Section Detail)

> 원본: `section_detail_spec.md` | 상태: **구현 완료**

#### 3.2.1 화면 구조

```
+-----------------------------------------+
| <- 섹션 상세                        [...] |  <- 편집/삭제 메뉴
+-----------------------------------------+
| 라폴리아                                 |
| 1~8 마디                                |
| 발자국 5회 반복                          |
| 2026.01.01 ~ 진행중 (매일반복)           |
+-----------------------------------------+
| 연습노트 [미리보기...]                   |
+-----------------------------------------+
| 연습 통계                                |
| 연습 횟수 12회 | 총 시간 45분 | 녹음 8개 |
+-----------------------------------------+
| 녹음 시작 버튼                           |
+-----------------------------------------+
| 녹음 기록 (8)                 [당일 v]   |
| ★ 01/04 14:30  2:15  BPM 80  [>][...]   |
|    01/04 10:20  1:45  BPM 76  [>][...]   |
+-----------------------------------------+
| [v] 연습 완료                            |
+-----------------------------------------+
| ====== 메트로놈 바 ======                |
+-----------------------------------------+
```

#### 3.2.2 섹션 정보 카드 표시 규칙

| 항목 | 조건 | 구현 |
|------|------|:----:|
| 곡명 | 항상 표시 | 구현 완료 |
| 별칭 | 값이 있을 때 | 구현 완료 |
| 범위 | "전체"일 때 숨김 | 구현 완료 |
| N회 반복 | repeatCount > 0 | 구현 완료 |
| 기간 | 항상 표시 (종료일 없으면 "매일반복") | 구현 완료 |

#### 3.2.3 기간 표시 규칙

| 시작일 | 종료일 | 표시 |
|--------|--------|------|
| 섹션 startDate | 있음 | `2026.01.05 ~ 2026.06.30` |
| 섹션 startDate | null | `2026.01.05 ~ 진행중 (매일반복)` |
| null | null | 레퍼토리 startDate 사용 |

#### 3.2.4 녹음 기록 필터

| 필터 | 설명 | 기준 |
|------|------|------|
| **전체** | 해당 섹션의 모든 녹음 | - |
| **주간** | 선택 날짜가 포함된 월~일 | selectedDate |
| **당일** | 선택 날짜의 녹음만 (기본값) | selectedDate |

#### 3.2.5 연습 완료 처리

**일반 완료 (repeatCount 없음)**: 토글 체크박스

**N회 반복 완료 (repeatCount > 0)**:
- 발자국 스탬프 N개 표시
- 개별 스탬프 탭하여 완료 토글
- 모든 스탬프 완료 = 자동 연습 완료
- "전체 완료 처리" 버튼으로 남은 스탬프 무시 가능

#### 3.2.6 섹션 추가/편집 입력 필드

| 필드 | 필수 | 기본값 |
|------|:----:|--------|
| 곡명 | 필수 | - |
| 별칭 | 선택 | null |
| 범위 유형 (마디/줄/전체) | 필수 | 마디 |
| 시작/종료 범위 | 전체 아닐 때 | 1 / 8 |
| 시작일 | 필수 | 오늘 |
| 종료일 | 선택 | null (진행중) |
| N회 반복 | 선택 | 0 (없음) |

#### 3.2.7 PracticeSection 모델

```dart
class PracticeSection {
  final String id;
  final String repertoireId;
  final String pieceName;          // 곡명 (필수)
  final String? sectionName;       // 별칭 (선택)
  final RangeType rangeType;       // measure, line, all
  final int startMeasure;
  final int endMeasure;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isRepeat;             // endDate == null 시 true
  final int repeatCount;           // 0 = 없음
  final List<PracticeRecording> recordings;
  final DateTime createdAt;
}
```

#### 3.2.8 미완료 항목

- [ ] N회 반복 스탬프 UI (발자국 탭하여 완료)
- [ ] 과제 섹션 대표녹음 공유 안내

#### 3.2.9 파일

```
lib/features/practice/presentation/
├── screens/
│   ├── section_detail_screen.dart
│   ├── add_section_screen.dart
│   └── edit_section_screen.dart
└── widgets/
    ├── section_detail/
    │   ├── section_info_card.dart
    │   ├── practice_stats_card.dart
    │   ├── completion_toggle.dart
    │   ├── recording_control.dart
    │   ├── recording_filter_dropdown.dart
    │   └── section_recording_list_item.dart
    └── section_form/
        ├── date_range_section.dart
        ├── date_row.dart
        ├── range_picker_button.dart
        └── range_picker_sheet.dart
```

---

### 3.3 레퍼토리 빠른 편집 (Repertoire Quick Edit)

> 원본: `repertoire_quick_edit_spec.md` | 상태: **빠른 추가만 구현, 빠른 편집 미구현**

#### 3.3.1 목적

레퍼토리와 섹션을 **한 화면**에서 추가/편집. 기존 분리된 4단계 플로우를 1단계로 단순화.

#### 3.3.2 화면 구성

| 화면 | 라우트 | 상태 |
|------|--------|:----:|
| 빠른 추가 | `/practice/repertoire/quick-add` | 구현 완료 |
| 빠른 편집 | `/practice/repertoire/:id/quick-edit` | 미구현 |

#### 3.3.3 통합 화면 구조

- 레퍼토리 기본 정보 (이름, 빠른 선택, 기간)
- 섹션 목록 (ListView, 각 섹션 카드에 곡명/구간/별칭)
- [+ 섹션 추가] 버튼
- [저장하기] 버튼
- 관리 (편집 모드만): 아카이브/삭제

#### 3.3.4 섹션 카드 필드

| 필드 | 필수 | 설명 |
|------|:----:|------|
| 곡명 | 필수 | 곡/연습곡 이름 |
| 구간 유형 | 필수 | 전체 / 줄 / 마디 |
| 시작/끝 범위 | 조건부 | 줄/마디 선택 시 |
| 섹션 별칭 | 선택 | 선택적 이름 |
| N회 반복 | 선택 | 2~10회 |
| 목표 연습시간 | 선택 | 분 단위 |

> 섹션은 별도 날짜 없이 **레퍼토리 기간을 상속**

#### 3.3.5 편집 모드 변경 감지

- 레퍼토리 정보 변경 / 섹션 추가/삭제/수정 추적
- 변경사항 있을 때만 [저장] 활성화
- 뒤로가기 시 확인 다이얼로그

#### 3.3.6 저장 로직 (편집 모드)

1. 레퍼토리 업데이트
2. 삭제된 섹션 처리 (`isDeleted=true`)
3. 새 섹션 생성 (`isNew && !isDeleted`)
4. 수정된 섹션 업데이트 (`!isNew && isModified`)
5. Provider 무효화

---

### 3.4 레퍼토리 히스토리 (Repertoire History)

> 원본: `repertoire_history_spec.md` | 상태: **설계 완료 (미구현)**

#### 3.4.1 목적

"작년에 무슨 곡 했죠?" -> 레퍼토리를 월별 그룹 타임라인으로 시각화하여 2년간 배운 곡의 흐름을 한눈에 파악.

#### 3.4.2 핵심 결정사항

| 항목 | 결정 |
|------|------|
| 뷰 형식 | 월별 그룹 타임라인 (최신 -> 과거) |
| 진입 경로 | 연습 탭 > [히스토리] 아이콘 |
| 데이터 소스 | PracticeRepertoire.startDate/endDate/isArchived |
| 범위 | 활성 + 아카이브 통합 표시 |

#### 3.4.3 타임라인 항목 표시

| 요소 | 표시 내용 |
|------|----------|
| 곡명 | PracticeRepertoire.name |
| 기간 | "3월~9월 (6개월)" or "1월~ (진행 중)" |
| 섹션 수 | sections.length |
| 녹음 수 | 모든 섹션 녹음 합산 |
| 완성도 | completionRate x 100% 프로그레스 바 |
| 상태 뱃지 | [완료] / [진행 중] / [아카이브] |

#### 3.4.4 필터

- 상태: 전체 / 진행 중 / 완료 / 아카이브
- 기간: 전체 / 올해 / 작년 / 사용자 지정

#### 3.4.5 데이터 모델

```dart
class RepertoireTimeline {
  final List<MonthGroup> monthGroups;
  final int totalCount;
  final int completedCount;
  final int inProgressCount;
}

class MonthGroup {
  final String yearMonth;     // "2025-03"
  final int year;
  final int month;
  final List<PracticeRepertoire> repertoires;
}
```

#### 3.4.6 엣지 케이스

| 상황 | 동작 |
|------|------|
| 레퍼토리 0개 | "아직 레퍼토리가 없습니다" 빈 상태 |
| startDate 없는 레거시 데이터 | createdAt을 startDate로 대체 |
| 같은 달 시작/종료 | "3월 (1개월 미만)" 표시 |
| 매우 긴 기간 (2년+) | 연도별 구분선 추가 |

---

## 4. 녹음 시스템

### 4.1 녹음 요구사항 (Recording Requirements)

> 원본: `recording_requirement.md` | 상태: **Phase 1~1.5 구현 완료**

#### 4.1.1 녹음 유형

| 유형 | 주체 | 최대 길이 | 파일 저장 |
|------|------|-----------|----------|
| 레슨 피드백 녹음 | 선생님 | 5분 | 없음 (AI 텍스트 변환 후 삭제) |
| 학생 연습 녹음 | 학생 | 3분 | 무제한 (로컬) |
| 선생님 참고 음원 | 선생님 | - | 유튜브 URL 또는 서버 업로드 |
| 선생님 피드백 | 선생님 | - | 텍스트 또는 AI 변환 |

#### 4.1.2 학생 연습 녹음 플로우

```
[학생 연습 화면]
├── 레퍼토리 선택
├── [녹음 시작] -> 연주 -> [녹음 종료]
├── 녹음 목록에 추가 (로컬 저장)
├── 잘 된 녹음을 [대표로 선택]
├── [외부 앱 공유] -> 카카오톡/메시지 등
└── [선생님께 공유] -> 서버 업로드
```

#### 4.1.3 Recording 모델 (HiveType 22)

```dart
@HiveType(typeId: 22)
class Recording {
  @HiveField(0) final String id;
  @HiveField(1) final String repertoireId;
  @HiveField(2) final String studentId;
  @HiveField(3) final RecordingType type;      // student, teacher, feedback
  @HiveField(4) final String localPath;
  @HiveField(5) final String? serverUrl;
  @HiveField(6) final int durationSeconds;
  @HiveField(7) final bool isRepresentative;
  @HiveField(8) final DateTime recordedAt;
  @HiveField(9) final DateTime? sharedAt;
  @HiveField(10) final StorageStatus storageStatus; // local, active, archived, deleted
  @HiveField(11) final String? title;

  bool get isShared => sharedAt != null;
}
```

#### 4.1.4 서버 보관 정책

| 기간 | 저장소 | 설명 |
|------|--------|------|
| 0~30일 | 활성 저장소 | 빠른 스트리밍 재생 |
| 31~180일 | S3 아카이브 | 저비용 보관 |
| 180일 이후 | 삭제 | 자동 영구 삭제 |

#### 4.1.5 프로 구독 모델

| 기능 | 무료 | 프로 |
|------|:----:|:----:|
| 일반 녹음 | 가능 | 가능 |
| 재생/삭제/A-B 루프/속도 조절 | 가능 | 가능 |
| 대표 녹음 선택 | 가능 | 가능 |
| **스마트 녹음** (무음 트리밍) | 불가 | 가능 |
| **중간 무음 스킵** | 불가 | 가능 |

구독 해지 후: 기존 스마트 녹음 파일은 정상 재생 (`.trim` 메타데이터 유지). 새 녹음만 제한.

#### 4.1.6 iOS 녹음 경로 복구 (Issue #9, 구현 완료)

iOS 앱 재배포 시 컨테이너 UUID 변경 -> Hive DB 녹음 경로 무효화 문제.

복구 순서:
1. 상대 경로 재구성 (`/Documents/` 이후 경로 추출 -> 현재 base path 결합)
2. 파일명 검색 (파일명으로 파일 맵에서 검색)
3. ID 패턴 검색 (녹음 ID 앞 8자리로 패턴 매칭)

복구 불가능한 고아 기록은 DB에서 자동 삭제.

#### 4.1.7 녹음 완전 삭제 (구현 완료)

삭제 대상: `*.m4a` + `*.m4a.trim` + Hive DB 기록 모두 삭제

#### 4.1.8 녹음 진단 화면 (구현 완료)

디버그 FAB 길게 누르기 -> 개발자 옵션 -> "녹음 파일 진단"

진단 항목: 기본 경로, 실제 파일 수, DB 기록 수, 매칭됨, DB 불일치, 고아 파일 (개별/전체 삭제 가능)

#### 4.1.9 구현 로드맵

| Phase | 내용 | 상태 |
|-------|------|:----:|
| 1 (MVP) | 학생 녹음, 재생/삭제, 대표 녹음, 스마트 녹음, A-B 루프, 속도 조절, 파형 | 구현 완료 |
| 1.5 | iOS 경로 복구, 완전 삭제, 진단 화면 | 구현 완료 |
| 1.5 (진행중) | 트림 후 실제 재생 시간 표시 (Issue #7), 연습완료 날짜별 동기화 (Issue #8) | 트림 후 재생 시간 표시 완료, 연습완료 동기화 완료 |
| 2 | 대표 녹음 서버 업로드, 선생님 주차 요약, 텍스트 피드백 | 텍스트 피드백 원격 CRUD 완료, 업로드/주차 요약 예정 |
| 3 | 레슨 피드백 AI 음성->텍스트, 선생님 참고 음원 | 예정 |
| 4 | 선생님 음성 피드백, 선생님 직접 참고 녹음 | 예정 |
| 5 | iCloud/ZIP 백업 | 예정 |
| 6 | 프로 구독 (스마트 녹음 제한) | 예정 |

---

### 4.2 스마트 녹음 & 자동 트림 (Smart Recording)

> 원본: `smart_recording_spec.md` | 상태: **Phase 1~5 전체 구현 완료**

#### 4.2.1 개요

녹음 시작/종료 시 무음(약한 소리) 구간을 자동으로 트리밍. 원본 보존 + `.trim` 메타데이터 방식.

#### 4.2.2 핵심 결정사항

| 항목 | 결정 |
|------|------|
| 처리 방식 | 자동 트리밍 (후처리, 원본 보존) |
| 적용 범위 | 앞뒤 + 중간 무음 스킵 |
| 임계값 | 사용자 조절 가능 슬라이더 (기본 40%, 범위 20%~60%) |
| 중간 무음 스킵 | 5초 이상 무음 시 건너뛰기 (5~30초 조절 가능) |
| 앞뒤 버퍼 | 소리 시작 3초 전, 소리 종료 3초 후 유지 |
| 중간 무음 버퍼 | 각 1.5초 (총 3초 유지) |

#### 4.2.3 트리밍 계산 로직

```dart
// 시작 트림: soundStartTime - recordingStartTime - 3초 버퍼
// 종료 트림: recordingEndTime - soundEndTime - 3초 버퍼
// 음수면 트림 안 함

// 예시: 총 20초, 소리 시작 6.6초, 소리 종료 13.4초
// 시작 트림: 6.6 - 3 = 3.6초 (3.6초부터 재생)
// 종료 트림: (20 - 13.4) - 3 = 3.6초 (16.4초에서 종료)
```

#### 4.2.4 중간 무음 스킵

1. 녹음 중: 소리가 threshold 이상 무음이면 `SilencePeriod` 기록
2. 녹음 완료: 무음 구간을 제외한 `PlayableSegment` 목록 생성 (3초 버퍼)
3. 재생 시: 세그먼트 끝에 도달하면 다음 세그먼트 시작점으로 자동 seek

#### 4.2.5 메타데이터 형식 (.trim JSON)

```json
{
  "trimStart": 3600,
  "trimEnd": 4140,
  "totalDuration": 60000,
  "contentStart": 3600,
  "contentEnd": 55860,
  "segments": [
    {"start": 3600, "end": 20000},
    {"start": 35000, "end": 55860}
  ]
}
```

#### 4.2.6 기본 설정값

```dart
SmartRecordingSettings.defaults = SmartRecordingSettings(
  smartRecordingEnabled: true,
  trimThreshold: 0.40,
  middleSilenceSkipEnabled: true,
  middleSilenceThreshold: 5,  // 5초
);
```

#### 4.2.7 엣지 케이스

| 케이스 | 처리 |
|--------|------|
| 전체가 무음 | 트리밍 없이 저장 |
| 앞뒤 무음 < 3초 | 트림 없음 (버퍼보다 짧음) |
| 중간 무음 < threshold | 무시 |
| 중간 무음 스킵 OFF | 중간 무음 건너뛰지 않음 |
| 스마트 녹음 OFF | 일반 녹음으로 동작 |
| 레거시 메타데이터 | key=value 형식 파싱 지원 |

---

### 4.3 바로 녹음 (Quick Recording)

> 원본: `quick_recording_spec.md` | 상태: **설계 완료 (미구현)**

#### 4.3.1 목적

레퍼토리/섹션을 먼저 선택하지 않고도 즉시 녹음. 기존 4단계 플로우를 1단계로 단축.

#### 4.3.2 핵심 원칙

1. **기존 UI 100% 재사용**: 새 화면 없이 기존 섹션 상세 화면 활용
2. **디폴트 섹션 활용**: "무제 > 바로 녹음" 섹션 자동 생성
3. **연습 도구 통합**: 메트로놈/튜너/녹음을 한 곳에서 접근
4. **컨텍스트 스마트 동작**: 현재 화면에 따라 적절히 분기

#### 4.3.3 디폴트 레퍼토리/섹션

앱 첫 실행 시 자동 생성:
- 레퍼토리: "무제" (`isDefault: true`, ID: `default_repertoire`)
- 섹션: "바로 녹음" (`isDefault: true`, ID: `default_quick_record_section`)

#### 4.3.4 연습 도구 모달 개선

녹음 버튼을 상단 중앙에 추가. 메트로놈/튜너는 하단 좌우.

#### 4.3.5 녹음 버튼 동작 로직

```dart
void _onRecordingButtonTap(BuildContext context, WidgetRef ref) {
  final currentRoute = GoRouterState.of(context).uri.path;
  final sectionMatch = RegExp(r'/practice/section/(.+)').firstMatch(currentRoute);

  Navigator.pop(context);  // 모달 닫기

  if (sectionMatch != null) {
    // 섹션 화면 -> 현재 섹션에서 녹음 시작
    final sectionId = sectionMatch.group(1)!;
    ref.read(recordingTriggerProvider.notifier).trigger(sectionId);
  } else {
    // 다른 화면 -> 디폴트 섹션으로 이동
    context.push('/practice/section/${DefaultIds.quickRecordSectionId}');
  }
}
```

#### 4.3.6 녹음 파일 관리 (섹션 이동)

바로 녹음한 파일을 다른 섹션으로 이동 가능:
- 녹음 관리 화면에서 [섹션 이동] 버튼
- 레퍼토리 선택 -> 섹션 선택 -> 이동

---

### 4.4 녹음 재생 플레이어 UI (Recording Player)

> 원본: `recording_player_ui.md` | 상태: **전체 구현 완료**

#### 4.4.1 바텀시트 레이아웃

```
+-----------------------------------------------------+
|                    -----                              |  Drag handle
|               녹음 제목 또는 날짜                      |
|  파형 시각화 (터치/핀치줌)                             |
|      00:45                              02:30         |
|   [A][B]  x1.0 v  [공유]                    Play/Pause|
+-----------------------------------------------------+
```

#### 4.4.2 컨트롤

| 컨트롤 | 설명 |
|--------|------|
| A-B Loop | A점/B점 설정, 구간 반복 재생 + 파형 하이라이트 |
| Speed | 0.5x / 0.75x / 1.0x / 1.25x / 1.5x / 2.0x |
| 외부 공유 | share_plus 패키지, OS 공유 시트 |
| Play/Pause | 56dp 원형 버튼, AppColors.primary |

#### 4.4.3 파형 시각화

**녹음 시 파형**: Wave 또는 Amplitude 스타일 선택 가능
- 막대 그래프: 너비 3dp, 간격 2dp, 업데이트 100ms, 최소 녹음 5초

**재생 시 파형 (핀치 줌)**:

| 제스처 | 동작 |
|--------|------|
| 탭 | 해당 위치로 seek |
| 핀치 아웃/인 | 줌 인/아웃 (1x~10x) |
| 수평 드래그 | 줌 상태에서 파형 스크롤 |
| A/B 핸들 드래그 | 마커 위치 조정 (20px 터치 영역) |

1.5x 이상 줌 시 미니맵 오버뷰 표시

#### 4.4.4 파일 저장

| 항목 | 값 |
|------|-----|
| 파일명 | `{UUID}.m4a` |
| 저장 경로 | `Documents/recordings/{repertoireId}/{UUID}.m4a` |
| 메타데이터 | `{UUID}.m4a.trim` |
| 포맷 | M4A (AAC-LC), 128kbps, 44100Hz, Mono |
| 최대 길이 | 180초 (3분) |

#### 4.4.5 색상

```dart
static const playerBackground = Color(0xFF1C1C1E);  // iOS dark sheet
static const playerWaveformPlayed = AppColors.primary;
static const playerWaveformUnplayed = Color(0xFF3A3A3C);
static const playerSeekIndicator = Colors.white;
```

#### 4.4.6 파일

```
lib/features/practice/presentation/
├── widgets/
│   ├── recording_player_sheet.dart     # 바텀시트 플레이어 + 공유
│   ├── recording_waveform.dart         # 팩토리 위젯
│   └── waveform/
│       ├── waveform_style.dart         # enum WaveformStyle
│       ├── wave_waveform.dart          # 곡선 웨이브
│       ├── amplitude_waveform.dart     # 진폭 막대 그래프
│       ├── zoomable_waveform.dart      # 핀치 줌 + A-B 드래그
│       └── ab_loop.dart               # ABLoop 클래스
```

---

### 4.5 녹음 비교 (Recording Comparison)

> 원본: `recording_comparison_spec.md` | 상태: **설계 완료 (미구현)**

#### 4.5.1 목적

같은 곡의 과거/현재 녹음을 비교하여 실력 성장 체감. A/B 순차 비교 재생.

#### 4.5.2 사용자 플로우

```
섹션 상세 > 녹음 목록 상단 [비교] 버튼 (녹음 2개 이상 시)
    -> RecordingComparisonSheet (바텀시트)
        -> Step 1: 녹음 A 선택 ("이전 녹음", 오래된 것 먼저)
        -> Step 2: 녹음 B 선택 ("현재 녹음", A 이후만)
        -> Step 3: 비교 재생 화면
            -> A/B 개별 재생 + 메타데이터 비교 카드 + [번갈아 듣기]
```

#### 4.5.3 비교 메타데이터

```dart
class RecordingComparison {
  final PracticeRecording recordingA;  // 이전
  final PracticeRecording recordingB;  // 현재

  int? get bpmDelta;            // BPM 변화량
  double? get bpmChangePercent; // BPM 변화율
  int get durationDelta;        // 시간 차이 (초)
  int get daysBetween;          // 경과 일수
}
```

비교 카드 표시: BPM 변화 (96 -> 120, +24 25%), 시간 변화, 경과 기간

#### 4.5.4 상태표

| 상태 | 동작 |
|------|------|
| 녹음 0~1개 | [비교] 버튼 비활성 |
| A 재생 중 | B 재생 버튼 비활성 |
| 번갈아 듣기 ON | A 재생 완료 -> 자동으로 B 재생 |
| BPM null | BPM 비교 섹션 숨김 |
| 트리밍된 녹음 | .trim 메타데이터 반영 (기존 로직 재사용) |

#### 4.5.5 구현 Phase

| Phase | 내용 | 상태 |
|-------|------|:----:|
| 1 | A/B 순차 비교 재생, 메타데이터 비교 카드, 번갈아 듣기 | 미구현 |
| 2 | 병렬 파형 비교 (두 파형 동시 표시), 동기화 재생, 오버레이 비교 | 미구현 |

---

## 5. 공유 및 리포트

### 5.1 연습 공유 (Practice Sharing)

> 원본: `practice_sharing_spec.md` | 상태: **학생 측 공유 인프라 구현 완료, 선생님 뷰 미구현**

#### 5.1.1 핵심 결정사항

| 항목 | 결정 |
|------|------|
| 공유 주체 | 학생이 대표 녹음을 선생님에게 공유 (수동) |
| 공유 시점 | 대표 녹음 설정 후 [공유] 버튼 |
| 공유 범위 | 수강권 유효 시에만 공유 가능 |

#### 5.1.2 이미 구현된 공유 인프라

| 구현 항목 | 상태 |
|----------|:----:|
| `Recording.sharedAt` 필드 | 구현 완료 |
| `Recording.isShared` getter | 구현 완료 |
| `markAsShared()` Repository 메서드 | 구현 완료 |
| `shareWithTeacher()` Notifier 메서드 | 구현 완료 |
| 공유 확인 다이얼로그 | 구현 완료 |
| "공유됨" 뱃지 UI | 구현 완료 |
| 대표녹음 설정 `setAsRepresentative()` | 구현 완료 |
| `storageStatus` 전환 (local -> active on share) | 구현 완료 |

#### 5.1.3 공유 조건

| 조건 | 공유 가능 | 설명 |
|------|:---------:|------|
| 대표 녹음 미설정 | 불가 | "먼저 대표 녹음을 설정하세요" |
| 이미 공유됨 | 불가 | "공유됨" 뱃지 표시 |
| 수강권 만료 | 불가 | "수강권이 필요합니다" |
| 선생님 미연결 | 불가 | "선생님과 연결이 필요합니다" |
| 대표 + 미공유 + 수강권 유효 | 가능 | [공유] 버튼 활성 |

#### 5.1.4 선생님 뷰 (구현 완료 — 재생 UI 제외)

학생 상세 화면 > [연습 현황] 탭 (`StudentPracticeTab`):
- 이번 주 요약 (연습 일수, 총 시간, 공유 녹음 수)
- 주간 연습 캘린더 (월~일 연습 여부 + 시간)
- 공유된 녹음 목록 (탭하여 `TeacherFeedbackSheet` 오픈)
- 피드백 입력 시 `/recordings/{recording_id}/feedback`에 저장하고 학생에게 `NotificationType.recordingFeedbackReceived` 로컬 알림 디스패치 (`actionUrl: '/recordings/{recordingId}'`)
- 알림 딥링크 대상 = `AppRoutes.recordingDetail` (`/recordings/:recordingId`) → `RecordingDetailScreen`(학생 뷰). `recordingByIdProvider(recordingId)`로 repertoire/student 컨텍스트 없이 녹음을 단독 조회하고, 재생(`RecordingPlayerSheet` 재사용) + `recordingFeedbackListProvider` 읽기 전용 피드백 스레드를 함께 표시

재생 UI는 `SharedRecording` 전용 inline player가 필요 (별도 이슈).

#### 5.1.5 데이터 모델 (신규)

```dart
class StudentPracticeOverview {
  final String studentId;
  final int practiceDaysThisWeek;
  final int totalPracticeMinutes;
  final List<SharedRecording> sharedRecordings;
  final List<DailyPracticeEntry> weeklyEntries;
}
```

#### 5.1.6 구현 Phase

| Phase | 내용 | 상태 |
|-------|------|:----:|
| 1 | 학생 -> 선생님 공유 인프라, 선생님 연습 현황 탭, 피드백 알림 | 완료 (재생 UI 제외) |
| 2 | 학부모 대시보드 실데이터 연동 | 미구현 |
| 3 | `SharedRecording` 재생 UI, 학부모 녹음 재생 | 미구현 |

#### 5.1.7 엣지 케이스

| 상황 | 동작 |
|------|------|
| 공유 후 녹음 삭제 | 선생님 측에서 "파일 없음" 표시 |
| 대표 녹음 변경 후 | 새 대표에 [공유] 버튼, 이전 대표 공유 상태 유지 |
| 오프라인 상태 | 공유 보류, 온라인 시 자동 전송 (Phase 2) |

---

### 5.2 연습 리포트 (Practice Report)

> 원본: `practice_report_spec.md` | 상태: **설계 완료 (미구현)**

#### 5.2.1 핵심 결정사항

| 항목 | 결정 |
|------|------|
| 주간 리포트 | 연습 시간, 완료율, 일별 그래프 |
| 월간 리포트 | 주간 비교, 트렌드 그래프, 성취 요약 |
| 선생님 공유 | Phase 2 (현재는 학생 전용) |

#### 5.2.2 데이터 모델

**DailyPracticeStat (일별 통계)**

| 필드 | 설명 |
|------|------|
| date | 날짜 |
| practiceTimeSeconds | 연습 시간 (초) |
| completedSectionCount | 완료한 섹션 수 |
| totalSectionCount | 전체 섹션 수 |
| hasGoal / goalAchieved | 목표 관련 |

**WeeklyReport (주간 리포트)**

| 필드/계산 | 설명 |
|----------|------|
| dailyStats (7개) | 일별 통계 |
| totalTimeMinutes | 총 연습 시간 |
| practicedDayCount | 연습한 일수 |
| averageDailyMinutes | 평균 일일 연습 시간 |
| goalAchievedDayCount | 목표 달성 일수 |
| mostPracticedDay | 가장 많이 연습한 날 |

**MonthlyReport (월간 리포트)**

| 필드/계산 | 설명 |
|----------|------|
| weeklyReports | 주간 리포트 목록 |
| dailyStats | 일별 통계 (캘린더용) |
| totalTimeMinutes | 총 연습 시간 |
| practicedDayCount | 연습한 총 일수 |
| practiceDayRate | 연습 일수 비율 |
| weeklyAverageMinutes | 주간 평균 연습 시간 |
| comparedToPreviousMonth | 지난 달 대비 변화율 |

#### 5.2.3 레퍼토리별 통계

```dart
class RepertoireStats {
  final String repertoireId;
  final String repertoireName;
  final int practiceSeconds;
  final int completedSections;
  final int totalSections;
}
```

주간/월간 리포트 하단에 레퍼토리별 연습 비중 바 차트 표시.

#### 5.2.4 그래프 라이브러리

`fl_chart: ^0.68.0` (바 차트, 라인 차트)

#### 5.2.5 접근 경로

- 학생 홈 > 연습 탭 > 상단 통계 영역 터치 -> 주간 리포트
- 더보기/설정 > 연습 통계 -> 주간/월간 선택
- 선생님 > 학생 상세 > 연습 현황 탭 > [상세 통계 보기]

#### 5.2.6 공유 시스템 연동

학생이 연습 기록을 선생님에게 공유할 때 주간/월간 리포트 데이터도 함께 공유.

| 공유 데이터 | 선생님 뷰 | 학부모 뷰 (Phase 2) |
|------------|----------|-------------------|
| 주간 연습 시간 | 이번 주 요약 카드 | 퀵스탯 |
| 일별 연습 기록 | 주간 캘린더 | 연습 캘린더 |
| 스트릭 | 스트릭 배지 | 퀵스탯 |
| 공유된 녹음 | 재생 가능 | Phase 3 |

#### 5.2.7 향후 확장

| 기능 | Phase | 설명 |
|------|:-----:|------|
| PDF 내보내기 | 2 | 리포트를 PDF로 저장/공유 |
| 연간 리포트 | 2 | 연간 통계 및 성장 그래프 |
| 비교 기능 | 2 | 다른 학생/평균과 비교 (익명) |

---

## 6. 백업 시스템

> 원본: `backup_implementation_spec.md` | 상태: **설계 완료 (미구현)**

### 6.1 개요

앱 재설치 시에도 녹음 파일과 데이터를 복원할 수 있는 백업 시스템.

### 6.2 Phase 별 범위

| 기능 | Phase 1 | Phase 2 | Phase 3 |
|------|:-------:|:-------:|:-------:|
| Files 앱 노출 (iOS) | 대상 | - | - |
| ZIP 백업/복원 | 대상 | - | - |
| iCloud 자동 백업 | - | 대상 | - |
| Google Drive 백업 | - | 대상 | - |
| 서버 백업 | - | - | 대상 |

### 6.3 Phase 1: 기본 백업

#### 6.3.1 Files 앱 노출 (iOS)

```xml
<!-- ios/Runner/Info.plist -->
<key>UIFileSharingEnabled</key>
<true/>
<key>LSSupportsOpeningDocumentsInPlace</key>
<true/>
```

#### 6.3.2 ZIP 백업/복원

백업 아카이브 구조 (`.lessonbackup` = ZIP):
- `metadata.json` - 앱 버전, 녹음 수, 기기 정보 등
- `hive_snapshot.json` - Hive DB 전체 스냅샷
- `recordings/` - 녹음 파일 + .trim 메타데이터

**BackupService 핵심 메서드:**
- `createBackup()` -> ZIP 파일 생성 -> share_plus로 공유
- `restoreFromBackup(file)` -> 중복 건너뜀, 새 것만 추가 -> `RestoreResult` 반환

### 6.4 Phase 2: 클라우드 백업

#### 6.4.1 iCloud (iOS)

- Container: `iCloud.com.lessonapp.lessonApp`
- 녹음 파일 개별 업로드/다운로드
- `syncAll()` 양방향 동기화
- 새 녹음 생성 시 자동 업로드

#### 6.4.2 Google Drive (Android)

- `driveAppdataScope` 사용 (앱 전용 폴더)
- 주기적 백업 (Google Drive API 호출 제한 고려)
- `uploadBackup()` / `downloadBackup()` / `restoreFromLatest()`

### 6.5 녹음 파일 관리 (추가 기능)

#### 6.5.1 전체 녹음 파일 화면

- 접근: 프로필 > 레슨 녹음 파일
- 기능: 전체 녹음 조회, 섹션 연결 변경, 삭제, 재생, 가져오기

#### 6.5.2 녹음 가져오기

- 지원 형식: `.m4a`, `.mp3`, `.wav`, `.aac`, `.flac`
- 저장 경로: `Documents/recordings/imported/{uuid}.{ext}`
- 상태: orphan (미연결) -> 나중에 섹션 연결 가능

### 6.6 마이그레이션

기존 사용자 첫 백업 유도: 녹음 N개 감지 시 백업 설정 다이얼로그 표시 (1회만)

---

## 7. 구현 현황

### 7.1 전체 현황 요약

| 영역 | 기능 | 상태 | 비고 |
|------|------|:----:|------|
| **연습 코어** | | | |
| | 연습 화면 (날짜 선택, 레퍼토리/섹션 목록) | 구현 완료 | 과거 날짜 필터 반영 완료 |
| | 연습 설정 (선생님: 추가/수정/삭제/좋아요) | 구현 완료 | Phase 1-2 |
| | 연습 완료 (학생: 체크, 횟수) | 구현 완료 | |
| | 연습 스트릭 (주말 제외, 레벨, 카드/배지) | 구현 완료 | |
| | 연습 목표 시스템 | 설계 완료 | 모델/Provider/화면 미구현 |
| | 연습 노트 | 설계 완료 | 모델/Provider/화면 미구현 |
| | 연습 센터 버튼 | Phase 1 완료 | 정적 아이콘 + 모달 |
| | 뱃지 시스템 | 설계 완료 | 전체 미구현 |
| **레퍼토리** | | | |
| | 레퍼토리 상세/추가/편집/아카이브 | 구현 완료 | |
| | 섹션 상세/추가/편집 | 구현 완료 | N회 반복 스탬프 UI 미완 |
| | 빠른 추가 (레퍼토리 + 섹션 동시) | 구현 완료 | |
| | 빠른 편집 | 설계 완료 | 미구현 |
| | 레퍼토리 히스토리 (타임라인) | 설계 완료 | 미구현 |
| **녹음** | | | |
| | 학생 녹음 (로컬, 재생/삭제) | 구현 완료 | |
| | 대표 녹음 선택 | 구현 완료 | |
| | 스마트 녹음 (앞뒤 트림 + 중간 무음 스킵) | 구현 완료 | Phase 1~5 전체 |
| | 재생 플레이어 (파형, A-B 루프, 속도 조절, 핀치 줌) | 구현 완료 | |
| | 외부 앱 공유 (share_plus) | 구현 완료 | |
| | 녹음 경로 복구 (iOS UUID) | 구현 완료 | Issue #9 |
| | 녹음 완전 삭제 + 진단 화면 | 구현 완료 | |
| | 트림 후 실제 재생 시간 표시 | 완료 | Issue #7 |
| | 연습완료 날짜별 동기화 | 완료 | Issue #8 |
| | 바로 녹음 (디폴트 섹션) | 설계 완료 | 미구현 |
| | 녹음 비교 재생 (A/B) | 설계 완료 | 미구현 |
| **공유/리포트** | | | |
| | 선생님에게 녹음 공유 (학생 측 인프라) | 구현 완료 | sharedAt, 공유 버튼 |
| | 선생님 연습 현황 탭 | 설계 완료 | 미구현 |
| | 학부모 대시보드 연동 | 설계 완료 | Phase 2 |
| | 주간/월간 리포트 | 설계 완료 | 미구현 |
| **백업** | | | |
| | ZIP 백업/복원 | 설계 완료 | 미구현 |
| | iCloud / Google Drive | 설계 완료 | 미구현 |

### 7.2 진행 중 이슈

| Issue | 내용 | 상태 |
|-------|------|------|
| #7 | 스마트 녹음 트림 후 실제 재생 시간 표시 | 완료 |
| #8 | 연습완료 날짜별 완료 상태 동기화 | 완료 |
| #9 | iOS 컨테이너 UUID 경로 복구 | 완료 |

### 7.3 구현 파일 구조 (실제)

```
frontend/lib/features/practice/
├── domain/
│   ├── entities/
│   │   ├── practice_repertoire.dart      # 레퍼토리 + 섹션 + 녹음 모델
│   │   ├── recording.dart                # Recording (HiveType 22)
│   │   ├── practice_item.dart            # 연습 항목 (선생님 설정)
│   │   ├── practice_streak.dart          # 스트릭
│   │   ├── practice_goal.dart            # 목표
│   │   ├── practice_note.dart            # 노트
│   │   ├── practice_stats.dart           # 통계
│   │   ├── practice_stats_report.dart    # 리포트
│   │   ├── practice_progress.dart        # 진행률
│   │   ├── practice_log.dart             # 로그
│   │   ├── smart_recording.dart          # 스마트 녹음 상태/설정
│   │   ├── recording_filter_type.dart    # 녹음 필터 enum
│   │   ├── repertoire_timeline.dart      # 히스토리 타임라인
│   │   ├── repertoire_sort_type.dart     # 레퍼토리 정렬
│   │   ├── section_sort_type.dart        # 섹션 정렬
│   │   ├── metronome_settings.dart       # 메트로놈
│   │   ├── tuner_settings.dart           # 튜너
│   │   ├── tuner_types.dart              # 튜너 타입
│   │   └── piece.dart                    # 곡 정보
│   └── repositories/
│       ├── practice_repository.dart
│       ├── practice_goal_repository.dart
│       ├── practice_note_repository.dart
│       └── practice_stats_repository.dart
├── data/
│   ├── repositories/
│   │   ├── mock_practice_repository.dart
│   │   ├── mock_practice_goal_repository.dart
│   │   ├── mock_practice_note_repository.dart
│   │   ├── mock_practice_stats_repository.dart
│   │   ├── remote_practice_repository.dart
│   │   └── remote_recording_repository.dart
│   └── services/
│       └── default_repertoire_service.dart
├── presentation/
│   ├── providers/
│   │   ├── practice_providers.dart               # Barrel export
│   │   ├── practice_repository_provider.dart
│   │   ├── practice_repertoire_repository_provider.dart
│   │   ├── practice_crud_provider.dart
│   │   ├── practice_repertoire_crud_provider.dart
│   │   ├── practice_item_providers.dart
│   │   ├── practice_streak_provider.dart
│   │   ├── practice_goal_provider.dart
│   │   ├── practice_note_provider.dart
│   │   ├── practice_stats_provider.dart
│   │   ├── practice_report_provider.dart
│   │   ├── practice_calendar_provider.dart
│   │   ├── recording_provider.dart
│   │   ├── smart_recording_provider.dart
│   │   ├── repertoire_archive_provider.dart
│   │   ├── repertoire_history_provider.dart
│   │   ├── repertoire_sort_provider.dart
│   │   ├── section_sort_provider.dart
│   │   ├── metronome_provider.dart
│   │   ├── tuner_provider.dart
│   │   ├── tuner_combo_provider.dart
│   │   └── piece_crud_provider.dart
│   ├── screens/
│   │   ├── practice_repertoire_screen.dart       # 메인 연습 화면
│   │   ├── repertoire_detail_screen.dart
│   │   ├── add_repertoire_screen.dart
│   │   ├── edit_repertoire_screen.dart
│   │   ├── repertoire_archive_screen.dart
│   │   ├── repertoire_history_screen.dart
│   │   ├── quick_add_screen.dart
│   │   ├── section_detail_screen.dart
│   │   ├── add_section_screen.dart
│   │   ├── edit_section_screen.dart
│   │   ├── section_picker_screen.dart
│   │   ├── practice_recording_screen.dart
│   │   ├── practice_goal_setting_screen.dart
│   │   ├── practice_note_list_screen.dart
│   │   ├── practice_stats_screen.dart
│   │   └── tuner_screen.dart
│   └── widgets/
│       ├── practice_tools_modal.dart
│       ├── practice_streak_card.dart
│       ├── recording_player_sheet.dart
│       ├── recording_waveform.dart
│       ├── repertoire_timeline_card.dart
│       ├── history_summary_card.dart
│       ├── month_group_header.dart
│       ├── goal/
│       ├── metronome/
│       ├── notes/
│       ├── practice_tools/
│       ├── section_detail/
│       ├── section_form/
│       ├── section_management/
│       ├── smart_recording/
│       ├── stats/
│       ├── tuner/
│       └── waveform/
```

---

## 8. Claude 구현 가이드

### 8.1 핵심 Provider 설계

> Claude가 새 기능을 구현할 때 참조할 Provider 상세. `@riverpod` 어노테이션 사용 필수.

| Provider | 파라미터 | 반환 타입 | 설명 | 파일 |
|----------|---------|----------|------|------|
| practiceRepertoiresProvider | studentId: String | `AsyncValue<List<PracticeRepertoire>>` | 학생의 활성 레퍼토리 목록 | `practice_repertoire_repository_provider.dart` |
| practiceItemsProvider | lessonId: String | `AsyncValue<List<PracticeItem>>` | 레슨별 연습 항목 목록 | `practice_item_providers.dart` |
| practiceStreakProvider | studentId: String | `AsyncValue<PracticeStreak>` | 학생 연습 스트릭 상태 | `practice_streak_provider.dart` |
| practiceGoalProvider | studentId: String | `AsyncValue<PracticeGoal?>` | 학생 연습 목표 (없으면 null) | `practice_goal_provider.dart` |
| practiceNotesProvider | sectionId: String | `AsyncValue<List<PracticeNote>>` | 섹션별 연습 노트 목록 | `practice_note_provider.dart` |
| practiceStatsProvider | studentId: String, period: DateRange | `AsyncValue<PracticeStats>` | 기간별 연습 통계 | `practice_stats_provider.dart` |
| practiceReportProvider | studentId: String, type: ReportType | `AsyncValue<WeeklyReport \| MonthlyReport>` | 주간/월간 리포트 | `practice_report_provider.dart` |
| recordingProvider | sectionId: String | `AsyncValue<List<Recording>>` | 섹션별 녹음 목록 | `recording_provider.dart` |
| smartRecordingProvider | - | `SmartRecordingState` | 스마트 녹음 상태/설정 | `smart_recording_provider.dart` |
| repertoireArchiveProvider | studentId: String | `AsyncValue<List<PracticeRepertoire>>` | 아카이브된 레퍼토리 | `repertoire_archive_provider.dart` |
| repertoireHistoryProvider | studentId: String | `AsyncValue<RepertoireTimeline>` | 레퍼토리 타임라인 | `repertoire_history_provider.dart` |
| metronomeProvider | - | `MetronomeState` | 메트로놈 상태 (BPM, 박자, 재생) | `metronome_provider.dart` |
| tunerProvider | - | `TunerState` | 튜너 상태 (주파수, 음고, 센트) | `tuner_provider.dart` |

### 8.2 구현 파일-코드 매핑 (미구현 기능)

Claude가 미구현 기능을 구현할 때 생성해야 할 파일 목록.

#### 연습 목표 시스템 (Practice Goal)

| 계층 | 파일 | 상태 |
|------|------|:----:|
| Entity | `domain/entities/practice_goal.dart` | 정의 완료 |
| Repository (인터페이스) | `domain/repositories/practice_goal_repository.dart` | 정의 완료 |
| Repository (Mock) | `data/repositories/mock_practice_goal_repository.dart` | 정의 완료 |
| Provider | `presentation/providers/practice_goal_provider.dart` | 정의 완료 |
| Screen | `presentation/screens/practice_goal_setting_screen.dart` | 정의 완료 |
| Widget | `presentation/widgets/goal/goal_progress_widget.dart` | 생성 필요 |
| Widget | `presentation/widgets/goal/goal_achieved_dialog.dart` | 생성 필요 |

#### 뱃지 시스템 (Badge)

| 계층 | 파일 | 상태 |
|------|------|:----:|
| Entity | `domain/entities/badge.dart` | 생성 필요 |
| Service | `domain/services/badge_checker.dart` | 생성 필요 |
| Provider | `presentation/providers/badge_provider.dart` | 생성 필요 |
| Widget | `presentation/widgets/badge/badge_popup.dart` | 생성 필요 |
| Widget | `presentation/widgets/badge/badge_collection.dart` | 생성 필요 |

#### 녹음 비교 (Recording Comparison)

| 계층 | 파일 | 상태 |
|------|------|:----:|
| Entity | `domain/entities/recording_comparison.dart` | 생성 필요 |
| Widget | `presentation/widgets/recording_comparison_sheet.dart` | 생성 필요 |

#### 연습 노트 학생 홈 통합 (Practice Note Integration)

| 계층 | 파일 | 상태 |
|------|------|:----:|
| Entity | `domain/entities/practice_note.dart` | 정의 완료 |
| Repository | `domain/repositories/practice_note_repository.dart` + `data/repositories/mock_practice_note_repository.dart` | 정의 완료 |
| Provider | `presentation/providers/practice_note_provider.dart` | 정의 완료 |
| Widget | `presentation/widgets/note/practice_note_card.dart` | 생성 필요 |
| Screen 통합 | `features/student_home/presentation/screens/student_practice_tab.dart` 에 노트 카드 wiring | 갱신 필요 |

#### 레퍼토리 히스토리 (Repertoire History)

| 계층 | 파일 | 상태 |
|------|------|:----:|
| Entity | `domain/entities/repertoire_history_entry.dart` | 생성 필요 |
| Provider | `presentation/providers/repertoire_history_provider.dart` | 생성 필요 |
| Screen | `presentation/screens/repertoire_history_screen.dart` | 존재 — 본문 미구현 |
| Widget | `presentation/widgets/history/repertoire_history_timeline.dart` | 생성 필요 |

#### 바로 녹음 (Quick Recording)

| 계층 | 파일 | 상태 |
|------|------|:----:|
| Constant | `core/constants/practice_defaults.dart` (default section ID: `default_quick_record_section`) | 생성 필요 |
| Service | `domain/services/quick_recording_service.dart` (디폴트 섹션 자동 생성/조회) | 생성 필요 |
| Widget | `presentation/widgets/quick_record/quick_record_button.dart` | 생성 필요 |
| Screen wiring | `presentation/screens/practice_recording_screen.dart` 에 quick 모드 진입점 | 갱신 필요 |

#### 주간/월간 리포트 (Weekly / Monthly Report)

| 계층 | 파일 | 상태 |
|------|------|:----:|
| Entity | `domain/entities/practice_report.dart` (WeeklyReport, MonthlyReport, RepertoireRatio) | 생성 필요 |
| Service | `domain/services/practice_report_calculator.dart` | 생성 필요 |
| Provider | `presentation/providers/practice_report_provider.dart` | 생성 필요 |
| Screen | `presentation/screens/practice_report_screen.dart` | 생성 필요 |
| Widget | `presentation/widgets/report/practice_chart.dart` (fl_chart 기반) | 생성 필요 |
| Widget | `presentation/widgets/report/repertoire_ratio_bar.dart` | 생성 필요 |

#### 백업 시스템 (Backup Phase 1)

| 계층 | 파일 | 상태 |
|------|------|:----:|
| Entity | `domain/entities/backup_archive.dart` | 생성 필요 |
| Service | `domain/services/backup_service.dart` (ZIP 생성/복원) | 생성 필요 |
| Service | `data/services/file_backup_service.dart` (`.lessonbackup` ZIP I/O — `archive` 패키지) | 생성 필요 |
| Provider | `presentation/providers/backup_provider.dart` | 생성 필요 |
| Screen | `presentation/screens/backup_settings_screen.dart` | 존재 — Phase 1 wiring 필요 |
| Widget | `presentation/widgets/backup/backup_progress_dialog.dart` | 생성 필요 |

#### 백업 시스템 (Backup Phase 2, iCloud / Google Drive)

| 계층 | 파일 | 상태 |
|------|------|:----:|
| Service | `data/services/icloud_backup_service.dart` (iOS only, `cloud_kit` 또는 `path_provider` + iCloud Container) | 생성 필요 |
| Service | `data/services/google_drive_backup_service.dart` (`googleapis` + `driveAppdataScope`) | 생성 필요 |
| iOS plugin | `ios/Runner/CloudBackupPlugin.swift` | 생성 필요 |

---

### 8.3 의존성 그래프 (2026-06-04, Wave 분류)

8개 기능을 의존성 + 작업 격리 가능성으로 3 Wave 분류한다. 각 Wave 내부는 병렬, Wave 사이는 순차.

**Wave 1 — 독립 entity 기반 화면 (병렬 4건):**

| 기능 | 의존 | 격리 가능 |
|------|------|----------|
| 뱃지 시스템 | PointAwardService (gamification — 호출만, 변경 없음) | O |
| 연습 목표 위젯 | PracticeGoal entity (있음) | O |
| 연습 노트 학생 홈 통합 | PracticeNote entity/provider (있음) | O |
| 레퍼토리 히스토리 | Repertoire entity (있음) | O |

**Wave 2 — Recording 인프라 의존 (병렬 2건):**

| 기능 | 의존 | 격리 가능 |
|------|------|----------|
| 바로 녹음 | Recording domain + PracticeSection (디폴트 섹션 추가) | O |
| 녹음 비교 (A/B) | Recording playback service | O |

**Wave 3 — 큰 데이터 작업 (병렬 2건):**

| 기능 | 의존 | 격리 가능 |
|------|------|----------|
| 주간/월간 리포트 | PracticeStats + Recording 데이터 | O |
| 백업 Phase 1 (ZIP) | Hive box + Recording file system | O |

> Backup Phase 2 (iCloud/Drive) 는 Phase 1 의존 — Wave 3 종료 후 Wave 4.

---

## 9. 관련 스펙

| 스펙 | 위치 | 설명 |
|------|------|------|
| 게이미피케이션 | `docs/specs/_archive/old/gamification_spec.md` | 포인트/레벨/뱃지 시스템 (신규) |
| 메트로놈 | `docs/specs/metronome/` | 커스텀 MetronomePlugin, 박자/세분화 |
| 튜너 | `docs/specs/tuner/` | 실시간 음고 감지 |
| 학생 홈 | `docs/specs/user/` | 학생 홈 화면 탭 구성 |
| 학부모 대시보드 | `docs/specs/user/parent_dashboard_spec.md` | 학부모 연습 현황 |
| 수강권/구독 | `docs/specs/lesson/invite/subscription_based_relationship.md` | 공유 권한 기준 |
| 알림 | `docs/specs/notification/` | 연습 완료 알림, 스트릭 경고 |
| 디자인 토큰 | `docs/_tokens/` | 색상, 타이포그래피 |
| UX 가이드라인 | `docs/specs/design/ux_guidelines.md` | 원샷 UX 원칙 |
| 사용자 시스템 | `docs/specs/user/user_master.md` | 역할/관계/인증 통합 마스터 |

---

## 코드 반영 추가 (2026-06-03)

> 코드에는 구현되어 있으나 위 본문에 누락되어 있던 항목을 단방향(코드→스펙)으로 반영. 각 항목은 코드 경로를 근거로 한다.

### A. 노트 접근 요청 (Note Access Request) — 구현됨

> 소스: `domain/entities/note_access_request.dart`, `domain/repositories/note_access_repository.dart`, `data/repositories/mock_note_access_repository.dart`, `presentation/providers/note_access_provider.dart`, `presentation/screens/note_access_request_screen.dart`, `presentation/widgets/note_access_active_banner.dart`

학원(academy) 구성원이 학생/사용자의 연습 노트에 **한시적 접근 권한**을 요청하고, 사용자가 동의/거절/철회하는 동의(consent) 기반 흐름. JournalPrivacy(1.8.1)와 분리된 별도 요청 단위 모델이다.

#### NoteAccessStatus enum (코드 반영 2026-06-03)

| 값 | 의미 |
|----|------|
| `requested` | 요청 전송됨, 응답 대기 |
| `consented` | 사용자가 공유 동의 |
| `rejected` | 사용자가 요청 거절 |
| `revoked` | 동의했던 접근을 철회 |

#### NoteAccessRequest 모델 (코드 반영 2026-06-03)

| 필드 | 타입 | 설명 |
|------|------|------|
| id | String | 고유 ID |
| academyId | String | 접근 요청 학원 ID |
| academyName | String | 표시용 학원명 |
| reason | String | 요청 사유 |
| expiresAt | DateTime (UTC) | 접근 권한 만료 시점 |
| status | NoteAccessStatus | 현재 상태 |
| recipientUserId | String | 요청을 받은 사용자 ID |
| requestorUserId | String | 요청을 시작한 사용자 ID |
| createdAt / updatedAt | DateTime | 생성/수정 시점 (UTC) |

파생 getter: `isActive`(consented && 미만료), `isExpired`, `remainingDays`.

#### Repository (NoteAccessRepository) (코드 반영 2026-06-03)

| 메서드 | 반환 | 설명 |
|--------|------|------|
| `getActiveAccess()` | `NoteAccessRequest?` | 현재 활성 접근 권한 |
| `getAllRequests()` | `List<NoteAccessRequest>` | 요청 이력 전체 |
| `getRequest(requestId)` | `NoteAccessRequest?` | ID로 조회 |
| `consentAccess(requestId)` | `NoteAccessRequest` | 공유 동의 |
| `rejectAccess(requestId)` | `NoteAccessRequest` | 요청 거절 |
| `revokeAccess(requestId)` | `NoteAccessRequest` | 동의 철회 |

- 라우트: `/note-access/:requestId` (`app_routes.dart`의 `noteAccessRequest`, 화면 `NoteAccessRequestScreen`)
- 활성 접근 시 화면 상단에 `NoteAccessActiveBanner` 표시

### B. 피치 분석 (Pitch Analysis) — 구현됨

> 소스: `domain/entities/pitch_analysis.dart`

녹음의 음정 정확도를 시간축 주파수 샘플로 분석해 등급(S/A/B/C/D)을 산출한다.

| 모델 | 핵심 필드 / 계산 |
|------|------------------|
| `FrequencySample` | timestamp, frequency, noteName, octave, centDeviation; `noteLabel` |
| `PitchAnalysisMetrics` | averageCentDeviation, stabilityScore(0~1), frequencyMin/Max, totalSamples, inTuneSamples(±10¢), noteDistribution; `inTunePercent`, `grade`, `gradeColorName` |
| `PitchAnalysisResult` | id, recordingId, samples, metrics, analyzedAt; `computeMetrics()` 정적 산출 |

등급 기준 (코드 반영 2026-06-03): inTunePercent ≥90 S / ≥75 A / ≥60 B / ≥40 C / 그 외 D. stabilityScore는 cent 편차 분산의 역수를 0~1로 정규화(50¢ 분산 → 0).

### C. RecordingFeedback 엔티티 (코드 반영 2026-06-03)

> 소스: `domain/entities/recording_feedback.dart`, `domain/repositories/recording_feedback_repository.dart`, `data/repositories/{mock,remote}_recording_feedback_repository.dart`

5.1.4에서 서술된 선생님 피드백의 데이터 모델 정의.

| 필드 | 타입 |
|------|------|
| id / recordingId / teacherId | String |
| content | String |
| createdAt | DateTime |

Repository(`RecordingFeedbackRepository`): `list(recordingId)`, `create(recordingId, content, teacherId?)`, `update(recordingId, feedbackId, content)`, `delete(recordingId, feedbackId)`. Mock/Remote 양쪽 구현 존재.

### D. 정렬 enum 구현됨 (코드 반영 2026-06-03)

> 소스: `domain/entities/repertoire_sort_type.dart`, `domain/entities/section_sort_type.dart`, providers `repertoire_sort_provider.dart`, `section_sort_provider.dart`

본문 3.1.5/2.1.5에서 "미완료/미구현"으로 표기된 정렬 옵션의 enum과 정렬 확장은 **구현 완료** 상태이다.

- `RepertoireSortType`: createdDesc(기본), createdAsc, nameAsc, custom — displayName(최신순/오래된순/이름순/사용자지정), iconName, `List<PracticeRepertoire>.sortBy()` 확장
- `SectionSortType`: createdDesc(기본), createdAsc, nameAsc, measureAsc, lastPracticedDesc, custom — displayName(최신순/오래된순/이름순/마디순/최근연습순/사용자지정), iconName, `List<PracticeSection>.sortBy()` 확장

### E. StudentPracticeOverview 상세 모델 (코드 반영 2026-06-03)

> 소스: `domain/entities/student_practice_overview.dart`

5.1.5에 요약된 모델의 동반 클래스 정의.

- `DailyPracticeEntry`: date, practiceMinutes, hasPracticed
- `SharedRecording`: recordingId, repertoireName, sectionName, sharedAt, durationSeconds, bpm?, localPath

---

## 10. 변경 이력

| 날짜 | 변경 내용 |
|------|----------|
| 2026-03-07 | Enum 정식 정의 추가 (PracticePriority, PracticeType dart 코드 블록) |
| | 경쟁사 대비 차별점 섹션 추가 (1.3) |
| | Claude 구현 가이드 섹션 추가 (8장) - Provider 설계 상세, 미구현 파일 매핑 |
| | 관련 스펙에 [gamification_spec.md](../_archive/old/gamification_spec.md), user_master.md 참조 추가 |
| | 목차 갱신 (8~10장 추가/재번호) |
| 2026-03-06 | 마스터 스펙 초안 작성 - 18개 원본 문서 통합 |
| | 원본: Practice_System_Spec.md (v2.0, 2026-01-05) |
| | 원본: practice_screen_spec.md (v1.0, 2026-01-05) |
| | 원본: practice_goal_spec.md (2026-01-03) |
| | 원본: practice_streak_spec.md (2024-12-22) |
| | 원본: practice_note_spec.md (2026-01-03) |
| | 원본: practice_sharing_spec.md (2026-03-02) |
| | 원본: practice_report_spec.md (2026-01-03, 공유 연동 2026-03-02) |
| | 원본: central_practice_button.md (2025-01-17) |
| | 원본: recording_requirement.md (2024-12-24, 최종 수정 2026-03-02) |
| | 원본: smart_recording_spec.md (2025-12-31) |
| | 원본: quick_recording_spec.md (2026-01-24) |
| | 원본: recording_player_ui.md (2025-12-30, 최종 수정 2026-03-02) |
| | 원본: recording_comparison_spec.md (2026-03-02) |
| | 원본: repertoire_detail_spec.md (v1.5, 2026-01-24) |
| | 원본: repertoire_history_spec.md (2026-03-02) |
| | 원본: repertoire_quick_edit_spec.md (v1.1, 2026-01-24) |
| | 원본: section_detail_spec.md (v1.1, 2026-01-05) |
| | 원본: backup_implementation_spec.md (2026-01-03, v1.1 2026-01-11) |
