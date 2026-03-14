# 학생별 이동시간 관리 — 스케줄 연동

> v1.0 | 2026-03-15 | Refs #177

## 1. 개요

### 1.1 문제

음악 레슨 선생님은 학생 집, 학원, 스튜디오 등 여러 장소를 이동하며 레슨합니다. 레슨 시간이 60분이라도 실제 소요 시간은 **레슨시간 + 이동시간**입니다.

비유: 택시 기사가 승객을 태우러 가는 "공차 시간"처럼, 선생님에게는 다음 학생에게 이동하는 시간이 필수로 존재합니다.

### 1.2 현재 상태

- `LessonLocation` 엔티티: 5가지 장소 유형 (학원/홈스튜디오/학생집/외부/온라인) ✅
- `breakTimeBetweenLessons`: 모든 레슨에 동일하게 적용되는 쉬는시간 ✅
- **학생별 이동시간**: 미구현 ❌

### 1.3 해결 방식

`ClassMembership`에 `travelTimeMinutes` 필드를 추가하여 학생별 이동시간을 관리합니다. 슬롯 생성 시 이전 레슨의 이동시간을 고려하여 다음 예약 가능 시간을 계산합니다.

---

## 2. 데이터 모델

### 2.1 ClassMembership 확장

```dart
// 기존 필드에 추가
final int travelTimeMinutes;    // 이동시간 (분, 기본: 0)
final String? lessonLocationId;  // 기본 레슨 장소 ID
```

### 2.2 Lesson 확장

```dart
// 기존 LessonLocationInfo에 이동시간 포함
final int? travelTimeMinutes;  // 이 레슨의 이동시간 (ClassMembership에서 복사)
```

---

## 3. 이동시간과 쉬는시간의 관계

### 3.1 버퍼 계산 규칙

```
다음 레슨 예약 가능 시간 = 현재 레슨 종료 + max(쉬는시간, 이동시간)
```

| 쉬는시간 | 이동시간 | 실제 버퍼 | 이유 |
|:-------:|:-------:|:--------:|------|
| 10분 | 0분 (같은 장소) | 10분 | 쉬는시간 적용 |
| 10분 | 20분 (학생 집) | 20분 | 이동시간이 더 김 |
| 10분 | 30분 (먼 거리) | 30분 | 이동시간이 더 김 |
| 0분 | 0분 (온라인) | 0분 | 둘 다 불필요 |

### 3.2 슬롯 생성 로직 변경

```dart
// 현재 (breakTime만 고려)
effectiveBuffer = breakTimeBetweenLessons;

// 변경 후 (이동시간도 고려)
final travelTime = nextLesson?.travelTimeMinutes ?? 0;
effectiveBuffer = max(breakTimeBetweenLessons, travelTime);
```

---

## 4. 선생님 UX

### 4.1 학생별 이동시간 설정

**위치**: 학생 상세 → 멤버십 설정 또는 레슨 장소 설정

```
┌─────────────────────────────────────┐
│ 레슨 장소 & 이동시간                  │
├─────────────────────────────────────┤
│  📍 레슨 장소: 학생 집               │
│     서울시 강남구 역삼동              │
│                                     │
│  🚗 이동시간: [20분 ▼]              │
│     (0분 / 10분 / 20분 / 30분 / 45분 / 60분) │
│                                     │
│  💡 이동시간은 스케줄에 반영되어      │
│     다음 레슨 예약 시 겹치지 않습니다 │
└─────────────────────────────────────┘
```

### 4.2 스케줄 뷰 표시

주간/일간 스케줄에 이동시간 블록을 시각적으로 표시:

```
14:00 ┃████████████████┃ 김서연 (바이올린) 📍학생집
15:00 ┃░░░░░░░░░░░░░░░░┃ 이동 (20분) ← 회색 빗금 블록
15:20 ┃████████████████┃ 이하은 (피아노) 📍학원
16:20 ┃                ┃ 예약 가능
```

### 4.3 레슨 추가 시 이동시간 경고

```
⚠️ 이전 레슨(김서연, 15:00 종료) 후 이동시간 20분이 필요합니다.
   15:20 이후에 레슨을 시작할 수 있습니다.
```

---

## 5. 구현 단계

### Phase 1: 데이터 모델 + 설정 UI

| # | 작업 | 파일 |
|---|------|------|
| 1-1 | ClassMembership에 travelTimeMinutes, lessonLocationId 추가 | class_membership.dart |
| 1-2 | 멤버십 설정 UI에 이동시간 드롭다운 추가 | membership 관련 화면 |
| 1-3 | Mock 데이터에 이동시간 추가 | mock repositories |

### Phase 2: 슬롯 생성 + 충돌 검사 연동

| # | 작업 | 파일 |
|---|------|------|
| 2-1 | _computeSlotsForDate에 이동시간 반영 | mock_teacher_availability_repository.dart |
| 2-2 | _findConflictingSlot에 이동시간 포함 | mock_teacher_availability_repository.dart |
| 2-3 | 레슨 추가 시 이동시간 경고 표시 | add_lesson_screen.dart |

### Phase 3: 스케줄 뷰 시각화

| # | 작업 | 파일 |
|---|------|------|
| 3-1 | 주간 그리드에 이동시간 블록 표시 | schedule_weekly_grid_view.dart |
| 3-2 | 일간 타임라인에 이동시간 블록 표시 | schedule_timeline_view.dart |
| 3-3 | 레슨 카드에 장소 + 이동시간 표시 | lesson_card.dart, schedule_tab.dart |

---

## 6. 기존 인프라 재사용

| 인프라 | 상태 | 재사용 방식 |
|--------|:----:|-----------|
| LessonLocation 엔티티 | ✅ | lessonLocationId로 참조 |
| LocationRepository | ✅ | 장소 CRUD 그대로 사용 |
| LocationProvider | ✅ | 장소 조회 그대로 사용 |
| breakTimeBetweenLessons | ✅ | max(breakTime, travelTime) 계산 |
| _findConflictingSlot | ✅ | breakTimeMinutes 파라미터 확장 |
