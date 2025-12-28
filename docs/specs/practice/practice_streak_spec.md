# 연습 스트릭 기능 명세

> 작성일: 2024-12-22
> 상태: ✅ 구현 완료

---

## 개요

### 목적
학생의 연습 동기 부여를 위한 연속 연습일 추적 시스템

### 핵심 가치
- **동기 부여**: 연속 연습일 시각화로 연습 습관 형성
- **성취감**: 레벨별 이모지와 색상으로 달성감 제공
- **유연성**: 주말 제외 정책으로 현실적인 목표 설정

---

## 기능 요구사항

### 스트릭 규칙

| 규칙 | 설명 |
|------|------|
| 스트릭 증가 | 하루 1회 이상 연습 기록 시 |
| 스트릭 유지 | 연속된 평일에 연습 기록 |
| 스트릭 리셋 | 평일에 연습 기록 없을 시 |
| **주말 제외** | 토/일은 리셋 대상에서 제외 |

### 주말 제외 정책 상세

```
예시 1: 금요일 연습 → (토,일 skip) → 월요일 연습
        → 스트릭 유지 ✅

예시 2: 금요일 연습 → (토,일 skip) → 화요일 연습
        → 스트릭 리셋 ❌ (월요일 평일에 연습 안 함)

예시 3: 토요일에 연습
        → 스트릭에 포함 ✅ (보너스)
```

### 스트릭 레벨 시스템

| 레벨 | 연속일 | 이모지 | 색상 테마 | 메시지 |
|------|--------|--------|----------|--------|
| 0 | 0일 | - | 회색 | "첫 연습을 시작해보세요!" |
| 1 | 1-6일 | ✨ | 보라색 | "좋은 시작이에요!" |
| 2 | 7-29일 | 🔥 | 주황/빨강 | "꾸준히 하고 있어요!" |
| 3 | 30일+ | 🔥🔥 | 골드 | "대단해요! 마스터 레벨!" |

---

## 데이터 모델

### PracticeStreak

```dart
class PracticeStreak {
  final String id;
  final String studentId;
  final int currentStreak;       // 현재 연속일
  final int longestStreak;       // 최장 기록
  final DateTime? lastPracticeDate;
  final DateTime updatedAt;

  // Computed getters
  bool get isActive => _checkIsActive();
  bool get practicedToday => _checkPracticedToday();
  int get streakLevel => _calculateLevel();
  String get fireEmoji => _getEmoji();
  String get motivationMessage => _getMessage();
}
```

### 레벨 계산 로직

```dart
int get streakLevel {
  if (currentStreak >= 30) return 3;  // 골드
  if (currentStreak >= 7) return 2;   // 주황
  if (currentStreak >= 1) return 1;   // 보라
  return 0;                            // 회색
}
```

### 이모지 매핑

```dart
String get fireEmoji {
  switch (streakLevel) {
    case 3: return '🔥🔥';
    case 2: return '🔥';
    case 1: return '✨';
    default: return '';
  }
}
```

---

## UI 컴포넌트

### 1. PracticeStreakCard (대형 카드)

**위치**: 학생 홈 화면 대시보드 상단

**구성**:
- 헤더: "연습 스트릭" + 이모지
- 숫자: 현재 연속일 (대형 폰트)
- 메시지: 동기부여 메시지
- 주간 점: 이번 주 연습 상태 시각화
- 최고 기록: "최고 기록: N일"

**그라데이션 색상**:
```dart
List<Color> _getGradientColors(int streakLevel) {
  switch (streakLevel) {
    case 3: return [Color(0xFFFFB800), Color(0xFFFF8C00)];  // 골드
    case 2: return [Color(0xFFFF6B6B), Color(0xFFFF8E53)];  // 주황
    case 1: return [AppColors.primary, AppColors.primaryLight]; // 보라
    default: return [Color(0xFF9E9E9E), Color(0xFF757575)]; // 회색
  }
}
```

### 2. PracticeStreakBadge (소형 배지)

**위치**: 프로필, 학생 리스트 등

**구성**:
- 이모지 + 연속일 ("🔥 7일")
- 스트릭 0일이면 표시 안 함

### 3. RecordPracticeButton (연습 기록 버튼)

**상태별 UI**:
| 상태 | 버튼 |
|------|------|
| 오늘 연습 안 함 | "오늘 연습 기록하기" (활성) |
| 오늘 연습 완료 | "오늘 연습 완료!" (비활성, 녹색 체크) |

---

## Provider 구조

### practice_streak_provider.dart

```dart
/// 스트릭 조회 (읽기 전용)
final practiceStreakProvider = FutureProvider.family<PracticeStreak, String>(
  (ref, studentId) async {
    final repository = ref.watch(practiceRepositoryProvider);
    return repository.getStreak(studentId);
  }
);

/// 연습 기록 및 스트릭 업데이트
final recordPracticeProvider = FutureProvider.family<PracticeStreak, String>(
  (ref, studentId) async {
    final repository = ref.watch(practiceRepositoryProvider);
    return repository.recordPractice(studentId);
  }
);

/// 스트릭 상태 관리 (StateNotifier)
class StreakNotifier extends StateNotifier<AsyncValue<PracticeStreak>> {
  Future<void> recordPractice() async { ... }
  Future<void> refresh() async { ... }
}

final streakNotifierProvider = StateNotifierProvider.family<
  StreakNotifier, AsyncValue<PracticeStreak>, String>(
  (ref, studentId) => StreakNotifier(ref, studentId)
);
```

---

## Repository 메서드

### PracticeRepository

```dart
abstract class PracticeRepository {
  // 스트릭 관련 메서드
  Future<PracticeStreak> getStreak(String studentId);
  Future<PracticeStreak> updateStreak(String studentId);
  Future<PracticeStreak> recordPractice(String studentId);
}
```

### 스트릭 계산 알고리즘

```dart
PracticeStreak _calculateStreak(String studentId) {
  // 1. 연습 기록 가져오기 (날짜 내림차순)
  // 2. 실제 연습한 날짜만 필터링
  // 3. 주말 제외 정책 적용하여 연속일 계산
  // 4. 최장 기록 계산
  // 5. PracticeStreak 객체 반환
}
```

---

## 파일 구조

```
lib/
├── models/
│   └── practice.dart                    # PracticeStreak 모델
├── repositories/
│   └── practice_repository.dart         # 스트릭 계산 로직
├── providers/practice/
│   ├── practice_streak_provider.dart    # Riverpod Provider
│   └── practice_providers.dart          # Barrel export
└── features/practice/presentation/
    └── widgets/
        └── practice_streak_card.dart    # UI 위젯들
```

---

## 사용 예시

### 학생 홈 화면에서 스트릭 카드 표시

```dart
class StudentHomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // 스트릭 카드
        const PracticeStreakCard(
          studentId: currentStudentId,
          onTap: () => /* 연습 기록 화면으로 이동 */,
        ),
        // ... 기타 위젯
      ],
    );
  }
}
```

### 프로필에서 스트릭 배지 표시

```dart
Row(
  children: [
    Text(studentName),
    const SizedBox(width: 8),
    PracticeStreakBadge(studentId: studentId),
  ],
)
```

---

## 테스트 시나리오

### 정상 케이스

| 시나리오 | 기대 결과 |
|----------|----------|
| 오늘 첫 연습 기록 | 스트릭 1 |
| 연속 7일 연습 | 스트릭 7, 레벨 2, 🔥 |
| 금→월 연습 (주말 skip) | 스트릭 유지 |

### 엣지 케이스

| 시나리오 | 기대 결과 |
|----------|----------|
| 금→화 연습 (월 미연습) | 스트릭 리셋 |
| 토요일만 연습 | 스트릭 1 (보너스) |
| 연습 기록 없는 신규 유저 | 스트릭 0, 레벨 0 |

---

## 향후 개선 사항

| 기능 | 우선순위 | 설명 |
|------|----------|------|
| 푸시 알림 | Phase 2 | "스트릭 끊어질 위험!" 알림 |
| 친구 비교 | Phase 2 | 친구 스트릭과 비교 |
| 업적 배지 | Phase 2 | 마일스톤 달성 배지 |
| 백엔드 동기화 | Phase 2 | 서버 저장 및 멀티 디바이스 |

---

## 관련 문서

- [requirement.md](requirement.md) - 전체 요구사항
- [student_centered_architecture.md](student_centered_architecture.md) - 학생 중심 아키텍처
