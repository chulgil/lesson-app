# Calendar System Master Spec

> Last updated: 2026-03-07

## 1. 개요

선생님(Teacher) 역할 사용자를 위한 스케줄 관리 탭. 주간 캘린더와 날짜별 레슨 목록을 결합하여 일정을 한눈에 파악하고 관리할 수 있도록 한다. 마치 종이 수첩의 일주일 페이지처럼, 날짜를 선택하면 해당 날짜의 레슨 목록이 바로 표시된다.

## 2. 핵심 기능

### 2.1 주간 캘린더 (WeekCalendarWidget)

- 공통 위젯 `core/widgets/week_calendar_widget.dart`를 사용
- 레슨이 있는 날짜에 도트 표시 (`lessonDates` 파라미터)
- 날짜 선택 시 `teacherSelectedDateProvider`를 통해 상태 업데이트
- 좌우 스와이프로 주 전환

### 2.2 날짜별 레슨 목록

- 선택된 날짜의 레슨만 필터링하여 리스트 표시
- 날짜 헤더: `M월 d일 EEEE` 형식 + 오늘 배지 + 레슨 개수 + 정렬 옵션
- 빈 상태: "예정된 레슨이 없습니다" 아이콘 + 메시지
- 에러 상태: 에러 아이콘 + "다시 시도" 버튼

### 2.3 레슨 정렬

| 정렬 타입 | 설명 |
|-----------|------|
| `timeAsc` | 시간순 (기본값) |
| `nameAsc` | 학생 이름순 |

- `PopupMenuButton`으로 정렬 전환
- `teacherLessonSortTypeProvider`로 상태 관리

### 2.4 레슨 카드 (_LessonTimeCard)

각 레슨 항목은 카드 형태로 표시:

| 영역 | 내용 |
|------|------|
| 좌측 색상 바 | 레슨 상태별 색상 (예정: primary, 완료: success, 취소: tertiary, 결석: error) |
| 시간 | 레슨 시작 시간 (고정 56px) |
| 정보 | 학생명 + 악기, 컨텍스트 배지 (학원/개인), 수강권 배지, 곡 정보 |
| 상태 | 예정/완료/취소/결석 텍스트 |
| 화살표 | 상세 페이지 이동 (`/lessons/{id}`) |

### 2.5 레슨 추가

- 헤더 우측 `+` 버튼
- 선택된 날짜와 다음 시간 정보를 쿼리 파라미터로 전달
- 경로: `/lessons/add?date=YYYY-MM-DD&hour=N`

### 2.6 컨텍스트 배지

- 학생의 멤버십 정보 기반으로 레슨 클래스 조회
- 학원(academy): `🏫 {클래스명}` 표시
- 개인레슨: `👤 개인레슨` 표시
- 수강권 배지: `SubscriptionBadge` 위젯 사용

## 3. 화면/UI 구조

```
CalendarTab (ConsumerWidget)
├── Header
│   ├── "스케줄" 타이틀
│   └── + 버튼 (레슨 추가)
├── WeekCalendarWidget (공통 위젯)
├── Date Header
│   ├── 날짜 텍스트 + "오늘" 배지
│   ├── 레슨 개수
│   └── 정렬 드롭다운
└── Lesson List (ListView.separated)
    └── _LessonTimeCard
        ├── 상태 색상 바 (left border)
        ├── 시간
        ├── 학생 정보 + 배지
        └── 상태 라벨 + 화살표
```

## 4. 데이터 모델

### CalendarEventType (enum)

```dart
/// calendar/domain/entities/calendar_event.dart
enum CalendarEventType {
  lesson,    // 레슨
  practice,  // 연습
  break_;    // 휴강

  String get label {
    switch (this) {
      case CalendarEventType.lesson: return '레슨';
      case CalendarEventType.practice: return '연습';
      case CalendarEventType.break_: return '휴강';
    }
  }
}
```

### CalendarViewType (enum)

```dart
/// calendar/domain/entities/calendar_event.dart
enum CalendarViewType {
  month,  // 월
  week,   // 주
  day;    // 일

  String get label {
    switch (this) {
      case CalendarViewType.month: return '월';
      case CalendarViewType.week: return '주';
      case CalendarViewType.day: return '일';
    }
  }
}
```

> 현재 코드에서 `CalendarViewType`과 `CalendarEventType`은 정의되어 있으나, 화면에서는 주간 뷰만 구현됨.

### Providers

| Provider | 타입 | 설명 |
|----------|------|------|
| `teacherSelectedDateProvider` | `StateProvider<DateTime>` | 선택된 날짜 (오늘 기본값) |
| `teacherLessonSortTypeProvider` | `StateProvider<LessonSortType>` | 정렬 타입 (시간순 기본값) |
| `lessonsProvider` | (외부) | 전체 레슨 목록 |
| `activeStudentMembershipsProvider` | (외부) | 학생별 활성 멤버십 |
| `activeStudentSubscriptionsProvider` | (외부) | 학생별 활성 수강권 |
| `lessonClassProvider` | (외부) | 레슨 클래스 정보 |

### 사용하는 외부 엔티티

- `Lesson` - 레슨 정보 (날짜, 시간, 학생, 악기, 상태, 곡 등)
- `LessonStatus` - 레슨 상태 enum (scheduled, completed, cancelled, noShow 등)
- `LessonClass` / `LessonClassType` - 레슨 클래스 (학원/개인)
- `Subscription` - 수강권 정보

## 5. 구현 파일 위치

> `features/calendar/` 기준 상대 경로. 새 파일 추가 시 이 표를 업데이트한다.

| 레이어 | 파일 경로 | 설명 |
|--------|----------|------|
| **Entity** | `calendar/domain/entities/calendar_event.dart` | CalendarEventType, CalendarViewType enum |
| **Entity** | `calendar/domain/entities/entities.dart` | Entity barrel export |
| **Screen** | `calendar/presentation/screens/calendar_tab.dart` | 캘린더 탭 메인 화면 (선생님용) |
| **공통 위젯** | `core/widgets/week_calendar_widget.dart` | 주간 캘린더 공통 위젯 |

---

## 6. 구현 현황

| 기능 | 상태 |
|------|------|
| 주간 캘린더 표시 | 구현 완료 |
| 날짜 선택 및 필터링 | 구현 완료 |
| 레슨 목록 표시 | 구현 완료 |
| 정렬 (시간순/이름순) | 구현 완료 |
| 레슨 카드 UI | 구현 완료 |
| 레슨 추가 네비게이션 | 구현 완료 |
| 컨텍스트 배지 (학원/개인) | 구현 완료 |
| 수강권 배지 | 구현 완료 |
| 빈 상태/에러 상태 | 구현 완료 |
| 월간/일간 뷰 전환 | 미구현 (enum만 정의) |

## 7. 관련 스펙

| 스펙 | 관계 |
|------|------|
| [UX 가이드라인](../design/ux_guidelines.md) | UX 규칙 |
| [학생 홈 대시보드](../student_home/student_home_master.md) | 학생 스케줄 탭 (유사 구조) |
| [연습 시스템](../practice/practice_master.md) | 연습 일정 연동 |

---

## 8. 변경 이력

| 날짜 | 내용 |
|------|------|
| 2026-03-06 | 기존 구현 기반 스펙 문서 생성 (역공학) |
| 2026-03-07 | Dart enum 코드 블록 추가, 구현 파일 위치 섹션 추가, 관련 스펙 링크 보강 |
