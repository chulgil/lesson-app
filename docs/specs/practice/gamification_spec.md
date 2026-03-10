# 게이미피케이션 스펙

> 구현 상태: ❌ 미구현
> 작성일: 2026-03-07
> 상태: 스펙 작성 완료, 구현 대기
> 관련: practice_streak_spec.md, practice_goal_spec.md

---

## 1. 개요

### 1.1 목적

연습 동기를 강화하여 학생의 **자발적 연습 습관**을 형성한다. 경쟁사 Tonara는 게이미피케이션 도입 후 연습률 **68% 증가**를 달성했다. 현재 lesson-app은 스트릭(연속 연습일)만 제공하여, 포인트/레벨/뱃지 시스템이 부재하다.

### 1.2 설계 원칙

| 원칙 | 설명 |
|------|------|
| **보상은 즉각적으로** | 행동 직후 포인트/뱃지 표시 (지연 보상은 효과 감소) |
| **경쟁보다 성장** | 리더보드는 선택적, 개인 성장 그래프 우선 |
| **선생님이 통제** | 포인트 가중치, 뱃지 수여를 선생님이 설정 |
| **학부모에게 투명** | 연습 보상 현황을 학부모 대시보드에 공유 |
| **단순 시작, 점진 확장** | Phase 1은 포인트+레벨만, Phase 2에서 뱃지+리더보드 |

### 1.3 경쟁사 벤치마크

| 기능 | Tonara | Practice Space | Modacity | lesson-app (현재) | lesson-app (목표) |
|------|:------:|:--------------:|:--------:|:----------------:|:----------------:|
| 포인트 시스템 | O (Practice Points) | O (Gems) | X | X | **Phase 1** |
| 레벨/등급 | O (Levels) | O (Rank) | X | X | **Phase 1** |
| 뱃지/업적 | O (Badges) | O (Achievements) | X | X | **Phase 2** |
| 스트릭 | O | O (Fire Streak) | O | **O** | 유지 |
| 리더보드 | O (Class) | O (Global) | X | X | **Phase 2** |
| 선생님 칭찬 | O (Stickers) | X | X | O (좋아요) | **Phase 2 확장** |

---

## 2. 포인트 시스템

### 2.1 포인트 획득 규칙

| 행동 | 기본 포인트 | 조건 | 비고 |
|------|:----------:|------|------|
| 연습 완료 (일일) | 30 | 최소 10분 이상 연습 기록 | 하루 1회만 |
| 과제 항목 완료 | 20 | PracticeItem isCompleted | 항목당 |
| must 과제 완료 | 30 | priority == must | must는 가중치 |
| 연습 목표 달성 | 50 | 일일 목표 시간 충족 | practiceGoal |
| 스트릭 보너스 (7일) | 100 | 7일 연속 연습 | 주간 보너스 |
| 스트릭 보너스 (30일) | 500 | 30일 연속 연습 | 월간 보너스 |
| 선생님 좋아요 | 50 | PracticeItem hasLike | 선생님 피드백 |
| 녹음 등록 | 10 | 녹음 파일 저장 | 녹음당 |

### 2.2 포인트 표시

```
[학생 대시보드 상단]
+------------------------------------------+
| 320 pts   Lv.5 중급 연습생               |
| [=========>          ] 180/500 다음 레벨  |
+------------------------------------------+
```

- 포인트는 **누적** (감소 없음, 동기 저하 방지)
- 일일 획득 포인트는 대시보드에 애니메이션으로 표시
- 포인트 획득 시 햅틱 피드백 + 짧은 사운드

### 2.3 선생님 가중치 설정

선생님이 학생/클래스별로 포인트 가중치를 조정할 수 있다.

```
[선생님 설정 > 게이미피케이션]
+------------------------------------------+
| 포인트 가중치                             |
|                                          |
| 연습 완료    [====|====] 30pt            |
| 과제 완료    [======|==] 20pt            |
| 녹음 등록    [==|======] 10pt            |
|                                          |
| [기본값으로 초기화]                       |
+------------------------------------------+
```

---

## 3. 레벨 시스템

### 3.1 레벨 정의

| 레벨 | 이름 | 필요 포인트 | 누적 포인트 |
|:----:|------|:----------:|:----------:|
| 1 | 첫 발걸음 | 0 | 0 |
| 2 | 꾸준한 시작 | 100 | 100 |
| 3 | 연습 습관 형성 | 200 | 300 |
| 4 | 성실한 연습생 | 300 | 600 |
| 5 | 중급 연습생 | 500 | 1,100 |
| 6 | 열정적 연주자 | 700 | 1,800 |
| 7 | 숙련된 연습가 | 1,000 | 2,800 |
| 8 | 연습의 달인 | 1,500 | 4,300 |
| 9 | 음악 마스터 | 2,000 | 6,300 |
| 10 | 전설의 연주자 | 3,000 | 9,300 |

### 3.2 레벨업 연출

```
+------------------------------------------+
|                                          |
|        Level UP!                         |
|                                          |
|    Lv.4 성실한 연습생 -> Lv.5 중급 연습생 |
|                                          |
|    [축하 애니메이션]                      |
|                                          |
|              [확인]                       |
+------------------------------------------+
```

- 레벨업 시 전체 화면 오버레이 (goal_achieved_dialog 패턴 재사용)
- Confetti 애니메이션 + 사운드
- 선생님/학부모에게 자동 알림

---

## 4. 뱃지 시스템 (Phase 2)

### 4.1 자동 뱃지

| 뱃지 | 조건 | 아이콘 |
|------|------|--------|
| 첫 연습 | 첫 연습 기록 | music_note |
| 7일 스트릭 | 7일 연속 | local_fire_department |
| 30일 스트릭 | 30일 연속 | whatshot |
| 100일 스트릭 | 100일 연속 | military_tech |
| 첫 녹음 | 첫 녹음 저장 | mic |
| 과제 올클리어 | 주간 과제 100% 완료 | task_alt |
| 연습왕 | 월간 포인트 1위 (클래스 내) | emoji_events |
| 꾸준함의 힘 | 3개월 연속 주 5일+ 연습 | trending_up |
| 레퍼토리 마스터 | 레퍼토리 5곡 완주 | library_music |

### 4.2 선생님 수여 뱃지

선생님이 직접 학생에게 특별 뱃지를 수여할 수 있다.

| 뱃지 | 용도 | 아이콘 |
|------|------|--------|
| 최고의 발전 | 레슨에서 큰 성장 보인 학생 | star |
| 완벽한 연주 | 완벽하게 연주한 곡 | workspace_premium |
| 도전 정신 | 어려운 곡에 도전 | rocket_launch |

```
[선생님 > 학생 상세 > 뱃지 수여]
+------------------------------------------+
| 뱃지 수여하기                             |
|                                          |
| [최고의 발전] [완벽한 연주] [도전 정신]   |
|                                          |
| 메시지: [정말 잘했어요! 계속 화이팅!    ] |
|                                          |
|              [수여하기]                    |
+------------------------------------------+
```

### 4.3 뱃지 표시

```
[학생 프로필 > 뱃지 섹션]
+------------------------------------------+
| 획득한 뱃지 (7/15)                        |
|                                          |
| [첫연습] [7일] [30일] [첫녹음]           |
| [올클리어] [최고발전] [도전정신]          |
|                                          |
| [ 미획득 뱃지 8개 보기 ]                  |
+------------------------------------------+
```

- 미획득 뱃지는 회색 잠금 아이콘으로 표시 (달성 조건 표시)
- 뱃지 탭 시 획득 날짜, 조건, 선생님 메시지 표시

---

## 5. 리더보드 (Phase 2, 선택적)

### 5.1 설계 원칙

- 리더보드는 **선생님이 활성화 설정** (기본: 비활성)
- **클래스 내** 리더보드만 (전체 공개 X — 비교 스트레스 방지)
- **주간 리셋** (만년 1등 방지, 매주 새로운 기회)
- 순위 대신 **티어 표시** (상위 30% = Gold, 60% = Silver, 나머지 = Bronze)

### 5.2 UI

```
[학생 > 연습 탭 > 이번 주 랭킹]
+------------------------------------------+
| 이번 주 연습 랭킹           [클래스명]    |
|                                          |
| Gold   이하은  520pt  ●●●●●●●           |
| Gold   이서연  480pt  ●●●●●●○           |
| Silver 김민준  320pt  ●●●●●○○           |
| Silver 정다은  280pt  ●●●●○○○           |
| Bronze 박지호  150pt  ●●●○○○○           |
|                                          |
| 나의 순위: Silver (3위/5명)              |
+------------------------------------------+
```

---

## 6. 학부모 연동

### 6.1 학부모 대시보드 표시

```
[학부모 > 자녀 대시보드]
+------------------------------------------+
| 김민준의 연습 현황                        |
|                                          |
| 320 pts  Lv.5 중급 연습생                |
| 이번 주: +180pt (목표 대비 120%)         |
|                                          |
| 최근 뱃지: [7일 스트릭] [올클리어]       |
+------------------------------------------+
```

### 6.2 알림

| 이벤트 | 학부모 알림 |
|--------|-----------|
| 레벨업 | "김민준이 Lv.5 중급 연습생이 되었습니다!" |
| 뱃지 획득 | "김민준이 '7일 스트릭' 뱃지를 획득했습니다!" |
| 주간 랭킹 | "김민준이 이번 주 Silver 등급입니다" |

---

## 7. 데이터 모델

### 7.1 엔티티

```dart
/// 학생 포인트 및 레벨 정보
class StudentGamification {
  final String id;
  final String studentId;
  final int totalPoints;       // 누적 포인트
  final int currentLevel;      // 현재 레벨 (1-10)
  final int pointsInLevel;     // 현재 레벨 내 포인트
  final int pointsToNextLevel; // 다음 레벨까지 필요 포인트
  final List<String> badges;   // 획득한 뱃지 ID 목록
  final DateTime updatedAt;
}

/// 포인트 이력
class PointHistory {
  final String id;
  final String studentId;
  final int points;            // 획득 포인트
  final PointSource source;    // 획득 경로
  final String? referenceId;   // 관련 엔티티 ID (practiceLog, practiceItem 등)
  final DateTime earnedAt;
}

/// 포인트 획득 경로
enum PointSource {
  dailyPractice,    // 일일 연습 완료
  taskCompleted,    // 과제 항목 완료
  mustTaskCompleted, // must 과제 완료
  goalAchieved,     // 연습 목표 달성
  streakBonus7,     // 7일 스트릭 보너스
  streakBonus30,    // 30일 스트릭 보너스
  teacherLike,      // 선생님 좋아요
  recording,        // 녹음 등록
  teacherBadge,     // 선생님 수여 뱃지
}

/// 뱃지
class Badge {
  final String id;
  final String name;           // 뱃지 이름
  final String description;    // 설명
  final String iconName;       // Material Icon 이름
  final BadgeType type;        // auto / teacher
  final String? condition;     // 자동 뱃지: 달성 조건 설명
  final DateTime? earnedAt;    // 획득 일시
  final String? teacherMessage; // 선생님 수여 시 메시지
}

enum BadgeType {
  auto,     // 자동 (조건 달성 시)
  teacher,  // 선생님 수여
}
```

### 7.2 Provider 설계

```dart
/// 학생 게이미피케이션 정보
@riverpod
Future<StudentGamification> studentGamification(
  Ref ref, String studentId,
) async { ... }

/// 포인트 이력 (최근 N건)
@riverpod
Future<List<PointHistory>> pointHistory(
  Ref ref, String studentId,
) async { ... }

/// 뱃지 목록 (획득 + 미획득)
@riverpod
Future<List<Badge>> studentBadges(
  Ref ref, String studentId,
) async { ... }

/// 주간 클래스 랭킹
@riverpod
Future<List<RankingEntry>> weeklyClassRanking(
  Ref ref, String classId,
) async { ... }

/// 포인트 부여 (연습 완료 시 자동 호출)
@riverpod
class GamificationNotifier extends _$GamificationNotifier {
  Future<PointResult> awardPoints(String studentId, PointSource source, {String? referenceId}) async { ... }
  Future<void> checkAndAwardBadges(String studentId) async { ... }
  Future<void> awardTeacherBadge(String studentId, String badgeId, String message) async { ... }
}
```

---

## 8. Mock 데이터 설계

```dart
// student_1 (김민준): Lv.5, 1100pt
StudentGamification(
  id: 'gam_1',
  studentId: 'student_1',
  totalPoints: 1100,
  currentLevel: 5,
  pointsInLevel: 0,
  pointsToNextLevel: 500,
  badges: ['badge_first_practice', 'badge_streak_7', 'badge_first_recording'],
  updatedAt: DateTime.now(),
);

// student_11 (이하은, 모범생): Lv.7, 2800pt
StudentGamification(
  id: 'gam_11',
  studentId: 'student_11',
  totalPoints: 2800,
  currentLevel: 7,
  pointsInLevel: 0,
  pointsToNextLevel: 1000,
  badges: ['badge_first_practice', 'badge_streak_7', 'badge_streak_30',
           'badge_first_recording', 'badge_all_clear', 'badge_best_growth'],
  updatedAt: DateTime.now(),
);

// student_12 (박준혁, 초보): Lv.2, 100pt
StudentGamification(
  id: 'gam_12',
  studentId: 'student_12',
  totalPoints: 100,
  currentLevel: 2,
  pointsInLevel: 0,
  pointsToNextLevel: 200,
  badges: ['badge_first_practice'],
  updatedAt: DateTime.now(),
);
```

---

## 9. 구현 파일 위치

```
features/gamification/
├── domain/entities/
│   ├── student_gamification.dart    # StudentGamification 엔티티
│   ├── point_history.dart           # PointHistory, PointSource
│   └── badge.dart                   # Badge, BadgeType
├── domain/repositories/
│   └── gamification_repository.dart # Repository 인터페이스
├── data/repositories/
│   └── mock_gamification_repository.dart  # Mock 구현
└── presentation/
    ├── screens/
    │   ├── badge_list_screen.dart    # 뱃지 전체 목록
    │   └── point_history_screen.dart # 포인트 이력
    ├── widgets/
    │   ├── gamification_header.dart  # 포인트+레벨 헤더 (대시보드용)
    │   ├── level_up_dialog.dart      # 레벨업 연출 다이얼로그
    │   ├── badge_grid.dart           # 뱃지 그리드 위젯
    │   ├── badge_award_sheet.dart    # 선생님 뱃지 수여 BottomSheet
    │   ├── point_earned_toast.dart   # 포인트 획득 토스트
    │   └── weekly_ranking_card.dart  # 주간 랭킹 카드
    └── providers/
        └── gamification_providers.dart  # @riverpod providers
```

### 파일-위젯 매핑

| 파일 | 위젯 | 사용 화면 |
|------|------|----------|
| gamification_header.dart | GamificationHeader | StudentDashboardTab |
| level_up_dialog.dart | LevelUpDialog | 포인트 획득 시 자동 표시 |
| badge_grid.dart | BadgeGrid | BadgeListScreen, StudentDetailScreen |
| badge_award_sheet.dart | BadgeAwardSheet | StudentDetailScreen (선생님) |
| point_earned_toast.dart | PointEarnedToast | 연습 완료 시 오버레이 |
| weekly_ranking_card.dart | WeeklyRankingCard | StudentPracticeTab |

---

## 10. 기존 연습 시스템 연동

### 10.1 포인트 자동 부여 트리거

| 기존 코드 위치 | 트리거 | 포인트 |
|--------------|--------|:------:|
| `practice_crud_provider.dart` > createPracticeLog | 일일 연습 기록 생성 | 30 |
| `practice_item_providers.dart` > toggleComplete | 과제 항목 완료 | 20/30 |
| `practice_goal_provider.dart` > checkGoalAchieved | 목표 달성 | 50 |
| `practice_streak_provider.dart` > updateStreak | 7일/30일 스트릭 | 100/500 |
| `recording_provider.dart` > saveRecording | 녹음 저장 | 10 |
| `practice_item_providers.dart` > toggleLike | 선생님 좋아요 | 50 |

### 10.2 연동 방식

```dart
// 기존 연습 완료 로직에 포인트 부여 추가 (예시)
Future<void> completePractice(String studentId) async {
  // 1. 기존: 연습 기록 저장
  await ref.read(practiceRepositoryProvider).createPracticeLog(log);

  // 2. 추가: 포인트 부여
  await ref.read(gamificationNotifierProvider.notifier)
    .awardPoints(studentId, PointSource.dailyPractice, referenceId: log.id);

  // 3. 추가: 뱃지 조건 체크
  await ref.read(gamificationNotifierProvider.notifier)
    .checkAndAwardBadges(studentId);
}
```

---

## 11. 구현 계획

### Phase 1: 포인트 + 레벨 (MVP)

| 항목 | 설명 | 우선순위 |
|------|------|:--------:|
| StudentGamification 엔티티 | 포인트, 레벨 저장 | 필수 |
| PointHistory 엔티티 | 포인트 이력 추적 | 필수 |
| MockGamificationRepository | 개발용 Mock 데이터 | 필수 |
| GamificationHeader 위젯 | 학생 대시보드 상단 표시 | 필수 |
| PointEarnedToast | 포인트 획득 시 토스트 | 필수 |
| LevelUpDialog | 레벨업 연출 | 필수 |
| 연습 시스템 연동 | 기존 Provider에 포인트 로직 추가 | 필수 |
| 선생님 가중치 설정 | 포인트 배율 조정 UI | 선택 |

### Phase 2: 뱃지 + 리더보드

| 항목 | 설명 | 우선순위 |
|------|------|:--------:|
| Badge 엔티티 | 자동/선생님 뱃지 | 필수 |
| BadgeListScreen | 뱃지 전체 조회 | 필수 |
| BadgeAwardSheet | 선생님 뱃지 수여 | 필수 |
| 자동 뱃지 체크 로직 | 조건 달성 시 자동 수여 | 필수 |
| WeeklyRankingCard | 클래스 내 주간 랭킹 | 선택 |
| 학부모 연동 | 포인트/뱃지 알림 | 선택 |

### Phase 3: 고급 기능

| 항목 | 설명 |
|------|------|
| 포인트 상점 | 포인트로 테마/스티커 교환 (장기) |
| 도전 과제 | 선생님이 만드는 특별 챌린지 |
| 시즌 리셋 | 분기별 랭킹 리셋 + 시즌 보상 |

---

## 12. 관련 문서

| 문서 | 역할 |
|------|------|
| [practice_streak_spec.md](practice_streak_spec.md) | 스트릭 시스템 (게이미피케이션 하위) |
| [practice_goal_spec.md](practice_goal_spec.md) | 연습 목표 (포인트 트리거) |
| [practice_master.md](practice_master.md) | 연습 시스템 마스터 |
| [analytics_dashboard_spec.md](../analytics/analytics_dashboard_spec.md) | 통계 대시보드 (연습 랭킹 포함) |

---

## 변경 이력

| 날짜 | 변경 내용 |
|------|----------|
| 2026-03-07 | 초안 작성 — 포인트/레벨/뱃지/리더보드/학부모 연동 |
