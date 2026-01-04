# 섹션 상세 화면 (View) 스펙

> 작성일: 2026-01-04
> 버전: 1.0
> 상태: 설계 완료
> 요구사항: [requirement2.md](../../requirement/requirement2.md)

---

## 1. 개요

### 1.1 목적
섹션 상세 화면에서 연습 상태 확인, 녹음 관리, 연습 완료 처리를 위한 사용자 인터페이스 제공

### 1.2 핵심 기능
| 기능 | 설명 |
|------|------|
| 섹션 정보 표시 | 곡명, 범위, 반복 설정 등 |
| 녹음 기록 필터 | 전체/주간/당일 필터 선택 |
| 연습 완료 처리 | 일반 완료 또는 N회 반복 스탬프 |
| 녹음 관리 | 녹음, 재생, 대표녹음 설정, 삭제 |
| 연습 노트 | 섹션별 메모 관리 |

---

## 2. 화면 구조

### 2.1 전체 레이아웃

```
┌─────────────────────────────────────────┐
│ ← 섹션 상세                        [⋮] │
├─────────────────────────────────────────┤
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │ 📋 섹션 정보 카드                   │ │
│ │ 곡명: 라폴리아                      │ │
│ │ 범위: 1~8 마디 | 🔁 매일반복        │ │
│ │ 기간: 2026.01.01 ~ 진행중           │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ 연습노트                                │
│ ┌─────────────────────────────────────┐ │
│ │ [연습 노트 미리보기...]              │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ 연습 통계                               │
│ ┌─────────────────────────────────────┐ │
│ │ 🔁 연습 횟수   ⏱️ 총 시간   🎤 녹음 │ │
│ │     12회         45분        8개   │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │ ✓ 연습 완료                         │ │
│ │ 또는                                │ │
│ │ 🐾🐾🐾🐾 (N회 반복 스탬프)           │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ 녹음                                    │
│ ┌─────────────────────────────────────┐ │
│ │         🎤 녹음 시작                │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ 녹음 기록 (8)     [당일 ▼] ← 필터      │
│ ┌─────────────────────────────────────┐ │
│ │ ⭐ 01/04 14:30  2:15  BPM 80  [▶][⋮]│ │
│ │    01/04 10:20  1:45  BPM 76  [▶][⋮]│ │
│ │    01/03 15:00  2:30  -       [▶][⋮]│ │
│ └─────────────────────────────────────┘ │
│                                         │
│ ━━━━━━━━━━━━ 메트로놈 바 ━━━━━━━━━━━━━  │
└─────────────────────────────────────────┘
```

---

## 3. 녹음 기록 필터

### 3.1 요구사항 (requirement2.md)
> 섹션상세 (과거일자)
> - 녹음기록에서 대표녹음있음을 아래 선택박스로 바꿈
> - 선택박스(전체, 일주일(기준은 해당일이 포함되는 주 전체로 월~일), 당일)
> - 디폴트는 당일
> - 과거일자의 경우 당일선택은 과거일자 기준으로 선택한 일자의 녹음리스트가 표시

### 3.2 필터 타입

```dart
enum RecordingFilterType {
  /// 모든 녹음
  all,
  /// 선택한 날짜가 포함된 주 (월~일)
  weekly,
  /// 선택한 날짜의 녹음만
  daily,
}
```

### 3.3 필터 UI

```
녹음 기록 (8)                    [당일 ▼]
                                 ┌─────────┐
                                 │ 전체    │
                                 │ 주간    │
                                 │✓당일    │ ← 기본값
                                 └─────────┘
```

### 3.4 필터 로직

| 필터 | 설명 | 기준일 |
|------|------|--------|
| **전체** | 해당 섹션의 모든 녹음 | - |
| **주간** | 선택한 날짜가 포함된 월~일 주간 | selectedDate |
| **당일** | 선택한 날짜의 녹음만 | selectedDate |

```dart
/// 주간 범위 계산 (월~일)
DateTimeRange getWeekRange(DateTime date) {
  // 월요일이 1, 일요일이 7
  final weekday = date.weekday;
  final monday = date.subtract(Duration(days: weekday - 1));
  final sunday = monday.add(const Duration(days: 6));
  return DateTimeRange(
    start: DateTime(monday.year, monday.month, monday.day),
    end: DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59),
  );
}

/// 녹음 필터링
List<PracticeRecording> filterRecordings({
  required List<PracticeRecording> recordings,
  required RecordingFilterType filter,
  required DateTime? selectedDate,
}) {
  if (selectedDate == null) {
    selectedDate = DateTime.now();
  }

  switch (filter) {
    case RecordingFilterType.all:
      return recordings;

    case RecordingFilterType.weekly:
      final weekRange = getWeekRange(selectedDate);
      return recordings.where((r) {
        return r.createdAt.isAfter(weekRange.start) &&
               r.createdAt.isBefore(weekRange.end.add(const Duration(seconds: 1)));
      }).toList();

    case RecordingFilterType.daily:
      return recordings.where((r) {
        return r.createdAt.year == selectedDate.year &&
               r.createdAt.month == selectedDate.month &&
               r.createdAt.day == selectedDate.day;
      }).toList();
  }
}
```

### 3.5 대표녹음 표시

기존 "대표 녹음 있음" 배지를 필터 드롭다운으로 대체:

**Before:**
```
녹음 기록 (8)        [대표 녹음 있음 ⭐]
```

**After:**
```
녹음 기록 (8)                    [당일 ▼]
```

> 대표 녹음은 녹음 목록에서 ⭐ 아이콘으로 표시됨

---

## 4. 연습 완료 처리

### 4.1 요구사항 (requirement2.md)
> 학생이 섹션상세에서
> 1. 오늘 연습에 반복이 없으면 연습완료로 표시
> 2. 섹션반복이 있다면 연습노트 밑 반복UI에 고양이 발바닥 스탬프를 반복수대로 하나씩 체크해서 다 채우면 연습 완료로 체크(다 체크하지 않더라도 완료가능)

### 4.2 일반 완료 (repeatCount 없음)

```
┌─────────────────────────────────────────┐
│ ☐ 연습 완료                             │
└─────────────────────────────────────────┘
          ↓ 탭
┌─────────────────────────────────────────┐
│ ✓ 연습 완료                      12:30 │
│ 🎉 대표녹음을 선생님께 공유해보세요!   │ ← 과제인 경우만
└─────────────────────────────────────────┘
```

### 4.3 N회 반복 완료 (repeatCount 있음)

```
┌─────────────────────────────────────────┐
│ 🐾 연습 반복 (3/5회)                    │
│                                         │
│ 🐾 🐾 🐾 🐾 🐾                           │
│ ✓  ✓  ✓  ○  ○                          │
│                                         │
│ ☐ 전체 완료 처리                        │
└─────────────────────────────────────────┘
```

**동작:**
- 🐾 탭 → 해당 스탬프 완료 토글
- 모든 스탬프 완료 시 → 자동으로 연습 완료
- "전체 완료 처리" → 남은 스탬프 무시하고 완료 처리

---

## 5. 연습 시간 표시

### 5.1 요구사항
- 연습 시간(분) 추가해서 연습완료시 총 연습시간 표기
- 반복이 있으면 기본(분)에서 반복한 횟수대로 총 연습시간 표기

### 5.2 연습 통계 카드 개선

```
┌─────────────────────────────────────────┐
│ 🔁 연습 횟수   ⏱️ 총 시간   🎤 녹음    │
│     12회        45분        8개       │
└─────────────────────────────────────────┘
```

### 5.3 시간 계산

```dart
/// 섹션별 총 연습 시간 (초)
int get totalPracticeTimeSeconds {
  // 기본 연습 시간 = 녹음들의 총 시간
  final recordingTime = recordings.fold<int>(
    0, (sum, r) => sum + r.durationSeconds,
  );

  return recordingTime;
}

/// 포맷된 연습 시간
String get formattedTotalTime {
  final minutes = totalPracticeTimeSeconds ~/ 60;
  if (minutes < 60) {
    return '${minutes}분';
  }
  final hours = minutes ~/ 60;
  final remainingMinutes = minutes % 60;
  return '${hours}시간 ${remainingMinutes}분';
}
```

---

## 6. 섹션 정보 카드

### 6.1 표시 항목

| 항목 | 표시 |
|------|------|
| 곡명 | `section.pieceName` |
| 범위 | `1~8 마디` 또는 `1~3 줄` |
| 별칭 | `section.sectionName` (있는 경우) |
| 반복 | 🔁 매일반복 (isRepeat인 경우) |
| N회반복 | 🐾 3회 반복 (repeatCount 있는 경우) |
| 기간 | `2026.01.01 ~ 2026.01.31` 또는 `~ 진행중` |

### 6.2 UI

```
┌─────────────────────────────────────────┐
│ 🎵 라폴리아                       [편집]│
├─────────────────────────────────────────┤
│ 📏 1~8 마디                             │
│ 🔁 매일 반복                            │
│ 🐾 3회 반복                             │
│ 📅 2026.01.01 ~ 진행중                  │
└─────────────────────────────────────────┘
```

---

## 7. Provider 설계

```dart
/// 녹음 필터 상태
@riverpod
class RecordingFilter extends _$RecordingFilter {
  @override
  RecordingFilterType build() => RecordingFilterType.daily;

  void setFilter(RecordingFilterType filter) {
    state = filter;
  }
}

/// 필터링된 녹음 목록
@riverpod
List<PracticeRecording> filteredRecordings(
  Ref ref, {
  required List<PracticeRecording> recordings,
  required DateTime? selectedDate,
}) {
  final filter = ref.watch(recordingFilterProvider);
  return filterRecordings(
    recordings: recordings,
    filter: filter,
    selectedDate: selectedDate,
  );
}
```

---

## 8. 파일 구조

```
lib/features/practice/
├── domain/
│   └── entities/
│       └── recording_filter_type.dart    # 필터 타입 enum
├── presentation/
│   ├── providers/
│   │   └── recording_filter_provider.dart
│   ├── screens/
│   │   └── section_detail_screen.dart    # 기존 파일 수정
│   └── widgets/
│       └── section_detail/
│           ├── section_info_card.dart
│           ├── practice_stats_card.dart
│           ├── recording_control.dart
│           ├── recording_filter_dropdown.dart  # 신규
│           ├── section_recording_list_item.dart
│           └── completion_toggle.dart
```

---

## 9. 구현 체크리스트

### Phase 1: 녹음 필터 (우선) ✅ 완료
- [x] RecordingFilterType enum 추가
- [x] RecordingFilterDropdown 위젯 구현
- [x] section_detail_screen에 필터 적용
- [x] "대표녹음 있음" 배지 제거 (필터 드롭다운으로 대체)

### Phase 2: 연습 통계 ✅ 완료
- [x] formattedTotalTime 개선
- [x] practice_stats_card 업데이트

### Phase 3: 섹션 정보 카드 개선 ✅ 완료
- [x] 반복 정보 표시 추가 (isRepeat → "매일 반복", repeatCount → "N회 반복")
- [x] 기간 표시 추가 (startDate ~ endDate/진행중)
- [x] 편집 버튼 추가 (onEditTap → EditSectionScreen 이동)

---

## 10. 변경 이력

| 버전 | 날짜 | 변경 내용 |
|------|------|----------|
| 1.0 | 2026-01-04 | 초안 작성 - requirement2.md 기반 녹음 필터, 연습 완료 UI 설계 |
| 1.1 | 2026-01-04 | Phase 1 구현 완료 - RecordingFilterType, RecordingFilterDropdown, 필터 로직 적용 |
| 1.2 | 2026-01-04 | 레이아웃 변경 - 연습 완료 UI를 녹음 섹션 위로 이동, 필터 기본값을 '당일'로 표시 |
| 1.3 | 2026-01-04 | DateRow 위젯 개선 - X버튼 터치 인식 개선 (TextButton 사용), 날짜 선택 Material 달력으로 통일 |
| 1.4 | 2026-01-04 | Phase 2 & 3 구현 완료 - 섹션 정보 카드에 반복 정보, 기간 표시, 편집 버튼 추가 (Issue #20) |
