# 이동시간/쉬는시간 블록 시각화 및 편집 스펙

> 작성일: 2026-03-16
> 도메인: schedule
> 상태: 구현 완료

## 문제점

### 현재 UX 문제

1. **이동시간 미시각화**: `breakTimeBetweenLessons` (10분)이 설정되어 있지만 타임라인에 블록으로 표시되지 않음
2. **잘못된 탭 동작**: 레슨 사이 빈 공간(쉬는시간/이동시간 포함)을 탭하면 "레슨 추가"로 이동
3. **개별 설정 불가**: 레슨별 이동시간 설정 없음 — 방문 레슨과 학원 레슨의 이동시간이 동일

## 설계 원칙

1. **명시적 시각화**: 레슨 사이의 쉬는시간/이동시간을 별도 블록으로 시각적 구분
2. **직관적 편집**: 블록 탭 → 이동시간 편집 BottomSheet (레슨 추가가 아닌)
3. **이중 스코프**: 개별 레슨 적용 vs 전역 기본값 저장 선택 가능

---

## UI 설계

### 블록 타입

| 타입 | 아이콘 | 배경색 | 표시 조건 |
|------|--------|--------|-----------|
| 쉬는시간 (breakTime) | ☕ | `scheduleBreakBackground` | `travelTimeAfter == null` → 전역 `breakTimeBetweenLessons` 사용 |
| 이동시간 (travelTime) | 🚗 | `scheduleTravelBackground` | `travelTimeAfter != null` (개별 설정) |

### 블록 레이아웃

```
┌─────────────────────────────────┐
│ ☕ 쉬는 시간 10분          [✏️]  │  ← compact (≤10분)
└─────────────────────────────────┘

┌─────────────────────────────────┐
│ 🚗 이동 20분               [✏️]  │
│    → 서연 (학생 자택 방문)        │  ← 장소 정보 (>10분)
└─────────────────────────────────┘
```

### 탭 동작 매트릭스

| 블록 | 탭 | 롱프레스 |
|------|-----|---------|
| 레슨 블록 | 레슨 상세 | 액션 메뉴 |
| 쉬는시간/이동시간 블록 | 편집 BottomSheet | - |
| 빈 슬롯 (가용시간 내) | 레슨 추가 | - |

### 편집 BottomSheet

```
┌─────────────────────────────────┐
│  ──── (handle)                  │
│                                 │
│  이동시간 설정                    │
│                                 │
│  ┌─────────────────────────────┐│
│  │ ● 민준 (하모니 음악학원)     ││
│  │ │                           ││
│  │ 📍 서연 (학생 자택 방문)     ││
│  └─────────────────────────────┘│
│                                 │
│  이동시간                        │
│  [없음] [5분] [10분] [15분]     │
│  [20분] [30분] [45분] [60분]    │
│                                 │
│  적용 범위                       │
│  ○ 이 레슨만 적용               │
│  ○ 기본 쉬는시간으로 저장        │
│                                 │
│  [          저장          ]     │
└─────────────────────────────────┘
```

---

## 엔티티 변경

### Lesson 엔티티

```dart
/// 이 레슨 후 다음 레슨까지 이동시간 (분)
/// null = 전역 breakTimeBetweenLessons 사용
/// 0 = 이동시간 없음
final int? travelTimeAfter;
```

### AppColors 추가

```dart
// Break/travel time block
static const scheduleBreakBackground = Color(0xFFF0EDE8);
static const scheduleBreakBorder = Color(0xFFD4CFC8);
static const scheduleBreakIcon = Color(0xFF8C8478);
static const scheduleTravelBackground = Color(0xFFEDE8F0);
static const scheduleTravelBorder = Color(0xFFCFC8D4);
static const scheduleTravelIcon = Color(0xFF78848C);
```

---

## 구현 파일

| 파일 | 변경 | 용도 |
|------|------|------|
| `lesson.dart` | 수정 | `travelTimeAfter` 필드 추가 |
| `app_colors.dart` | 수정 | 6개 색상 상수 추가 |
| `timeline_break_block.dart` | **신규** | 쉬는시간/이동시간 블록 위젯 |
| `travel_time_edit_sheet.dart` | **신규** | 이동시간 편집 BottomSheet |
| `schedule_timeline_view.dart` | 수정 | 블록 렌더링 + 탭 분기 수정 |
| `mock_lesson_repository.dart` | 수정 | Mock 이동시간 데이터 |

---

## 변경 이력

| 날짜 | 내용 |
|------|------|
| 2026-03-16 | 초안 작성 + 구현 완료 |
