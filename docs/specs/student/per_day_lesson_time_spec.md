# 요일별 레슨 시간 개별 설정 스펙

> 이슈: [#120](https://github.com/chulgil/lesson-app/issues/120)
> 작성일: 2026-03-11
> 상태: 구현 완료

---

## 1. 개요

학생 추가/수정 시 선택한 요일마다 다른 레슨 시작 시간을 설정할 수 있도록 ScheduleSection을 개선한다.

### 현재 동작
- 모든 요일에 동일한 시간 1개만 설정 가능
- `lessonTime: TimeOfDay` 단일 값

### 개선 후 동작
- 요일 선택 시 해당 요일 아래에 개별 시간 설정 UI 표시
- 기본값은 공통 시간, 필요 시 요일별 개별 수정

---

## 2. UI 설계

### 2.1 요일 선택 후 시간 표시

```
레슨 요일
[월] [화] [수] [목] [금] [토] [일]

선택된 요일별 시간:
  월  14:00  [변경]
  수  15:30  [변경]
```

- 요일 선택 시 아래에 해당 요일 + 시간 행 추가 (AnimatedList)
- [변경] 탭 시 TimePicker 표시
- 새 요일 추가 시 마지막 설정된 시간을 기본값으로 사용

### 2.2 데이터 구조

```dart
// 기존: 단일 TimeOfDay
TimeOfDay lessonTime;

// 변경: 요일별 Map
Map<int, TimeOfDay> dayTimeMap; // key: 요일 인덱스 (0=월~6=일)
```

---

## 3. 구현 범위

| 항목 | 설명 |
|------|------|
| ScheduleSection 위젯 | 요일별 시간 행 추가 |
| AddStudentScreen | dayTimeMap 상태 관리 |
| EditStudentScreen | dayTimeMap 로드/저장 |
| Student 엔티티 | 기존 lessonDay + lessonTime 문자열 유지 (호환성) |

### 3.1 저장 형식

기존 `lessonTime` 문자열 필드 활용 (DB 스키마 변경 없음):
- 모든 요일 동일 시간: `"14:00"` (기존과 동일)
- 요일별 다른 시간: `"월14:00,수15:30"` (요일+시간 쌍)

---

## 4. 관련 파일

| 파일 | 변경 |
|------|------|
| `schedule_section.dart` | 요일별 시간 행 UI 추가 |
| `add_student_screen.dart` | dayTimeMap 상태 관리 |
| `edit_student_screen.dart` | dayTimeMap 파싱/저장 |
