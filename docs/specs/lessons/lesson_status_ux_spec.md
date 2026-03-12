# 레슨 상태 UX 개선 스펙

> 작성일: 2026-03-12
> 도메인: lessons
> 상태: 스펙 작성 (구현 전)

## 문제점

### 현재 상태 관리 방식

레슨 완료/예정 상태가 **수동 처리** 방식으로, 선생님이 일일이 팝업 메뉴에서 "완료 처리"를 해야 함.

| 문제 | 설명 |
|------|------|
| 수동 완료 처리 | 레슨 시간이 지나도 자동으로 "완료"가 되지 않음 |
| 완료 버튼 접근성 | AppBar 팝업 메뉴 안에 숨겨져 있어 발견하기 어려움 |
| 예정 상태 미표시 | 미래 레슨에 "예정" 상태가 시각적으로 강조되지 않음 |
| 타임라인 과거 배지 | 과거 미완료 레슨에 경고 아이콘(⚠️)이 표시되나, 의미 불명확 |

---

## 설계 원칙

1. **시간 기반 자동 상태**: 레슨 종료 시간이 지나면 자동으로 "완료" 처리
2. **명시적 예외만 수동**: 취소, 결석, 노쇼만 선생님이 직접 설정
3. **시각적 즉시 인지**: 예정/완료/과거 상태를 한눈에 구분

---

## 상태 전이 규칙

### 자동 전이

```
scheduled → completed  (레슨 종료 시간 경과 시 자동)
```

- 조건: `lesson.date + lesson.startTime + lesson.duration < now`
- 적용 시점: 화면 로딩 시 Provider에서 계산 (DB 상태 변경 아님)
- 실제 DB 업데이트: 선생님이 레슨 상세 진입 시 또는 백그라운드 배치

### 수동 전이 (기존 유지)

```
scheduled → cancelled / noShow / studentAbsent  (선생님 수동)
completed → scheduled  (실수로 완료된 경우 되돌리기)
```

---

## UI 변경

### 1. 레슨 상세 화면 — 완료 버튼 정리

**Before**:
- AppBar 팝업 메뉴에 "완료 처리" 항목

**After**:
- 자동 완료이므로 "완료 처리" 메뉴 **제거**
- 예외 처리만 남김: "취소", "결석 처리", "노쇼 처리"
- 자동 완료된 레슨의 상세 화면 상단에 "✓ 완료된 레슨" 배지

### 2. 타임라인 (일간) — 상태 배지 개선

**Before**:
- 과거 완료: ✅ 초록 체크
- 과거 미완료: ⚠️ 경고 아이콘

**After**:
- 과거 (자동 완료): ✅ 초록 체크 (기존과 동일)
- 미래 예정: ❕ "예정" 텍스트 배지 (primary 색상)
- 현재 진행 중: 🔴 빨간 점 (진행 중 표시)

### 3. 리스트 뷰 — 상태 라벨 통일

| 상태 | 라벨 | 색상 | 아이콘 |
|------|------|------|--------|
| 예정 (미래) | "예정" | primary (보라) | — |
| 진행 중 (현재 시간대) | "진행중" | warning (주황) | 🔴 dot |
| 완료 (과거, 자동) | "완료" | success (초록) | ✓ |
| 취소 | "취소" | tertiary (회색) | — |
| 결석/노쇼 | "결석" | error (빨강) | — |

### 4. 주간 그리드 — 색상만으로 구분 (기존 유지)

- 오늘: 선명한 악기 색상
- 과거: 회색 뮤트
- 미래: 약간 연한 악기 색상

---

## 구현 계획

### Phase 1: 자동 완료 로직 (Provider 레벨)

```dart
/// Provider에서 표시용 상태를 계산
LessonStatus get displayStatus {
  if (status != LessonStatus.scheduled) return status;

  final endTime = _calculateEndDateTime();
  if (endTime.isBefore(DateTime.now())) {
    return LessonStatus.completed;
  }
  return LessonStatus.scheduled;
}
```

- `Lesson` 모델에 `displayStatus` getter 추가
- UI는 `displayStatus`만 참조
- 실제 DB 상태(`status`)는 변경하지 않음 (선생님이 피드백 작성 시 DB 업데이트)

### Phase 2: UI 변경

1. 레슨 상세 AppBar 메뉴에서 "완료 처리" 제거
2. 타임라인 배지 로직 변경 (`displayStatus` 기반)
3. 리스트 카드 상태 라벨 통일

### Phase 3: 피드백 프롬프트 연동

- 자동 완료된 레슨 상세 진입 시 "피드백을 작성해주세요" 배너 (기존 로직 유지)
- 피드백 작성 완료 시 실제 DB 상태도 `completed`로 업데이트

---

## 관련 파일

| 파일 | 변경 내용 |
|------|----------|
| `lesson.dart` (entity) | `displayStatus` getter 추가 |
| `lesson_detail_screen.dart` | "완료 처리" 메뉴 제거 |
| `timeline_lesson_block.dart` | `_buildPastBadge` → `displayStatus` 기반 |
| `lesson_card.dart` | 상태 라벨 `displayStatus` 기반 |
| `lesson_header_card.dart` | 상태 배지 `displayStatus` 기반 |

---

## 변경 이력

| 날짜 | 내용 |
|------|------|
| 2026-03-12 | 초안 작성 — 현재 UX 문제 분석 + 자동 완료 설계 |
