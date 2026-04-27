# 스케줄 뷰 UX 개선 스펙

> 작성일: 2026-03-12
> 도메인: schedule
> 상태: 구현 완료 (일부 검증 필요)

## 개요

**선생님 전용** 스케줄 화면의 3가지 뷰 모드(리스트/타임라인/주간) UX를 개선하여 가독성, 일관성, 사용성을 향상시킨다.

> ⚠️ **학생 스케줄과 분리 설계**: 선생님(주 15-20레슨, 관리자 시점)과 학생(주 1-3레슨, 소비자 시점)은 근본적으로 다른 UX가 필요합니다. 타임라인/주간 그리드는 선생님 전용이며, 학생에게는 적용하지 않습니다.
>
> | | 선생님 | 학생 |
> |---|---|---|
> | 주간 레슨 수 | 15-20회 | 1-3회 |
> | 핵심 질문 | "지금 누구 가르치지? 다음은?" | "다음 레슨 언제?" |
> | 필요한 뷰 | 타임라인 + 주간 그리드 + 리스트 | 리스트 (캘린더+카드) |
> | 비유 | 의사 스케줄러 / Uber 드라이버 | 환자 포털 / Uber 라이더 |

## 뷰 모드 구조

| 모드 | 아이콘 | 캘린더 | 콘텐츠 | 주요 용도 |
|------|--------|--------|--------|-----------|
| 리스트 (기본) | ≡ | WeekCalendarWidget (월간 확장 가능) | 레슨 카드 리스트 | 월간 일정 확인 |
| 타임라인 (일간) | ▤ | CompactWeekStrip | 시간축 타임라인 | 하루 일정 상세 확인 |
| 주간 그리드 | ⊞ | CompactWeekStrip | 7일 그리드 | 주간 전체 조감 |

### 공통 헤더

모든 뷰에서 동일:
- 좌측: "스케줄" 제목
- 우측: 3-segment 뷰 토글 + 레슨 추가(+) 버튼

### 캘린더 분리

- **리스트 모드**: `WeekCalendarWidget` — 터치로 주 탐색, 헤더 탭으로 월간 확장
- **타임라인/주간**: `CompactWeekStrip` — 컴팩트한 요일 스트립

> 이유: 리스트 모드는 월간 개요가 필요 (다른 뷰에서는 월간 확인 불가). 타임라인/주간은 콘텐츠 영역이 넓어야 하므로 컴팩트 스트립 사용.

---

## 타임라인 (일간) 뷰

### 시간 범위

- **가용시간 기반**: 선생님의 `TeacherAvailability.weeklySchedules`에서 해당 요일의 시작/종료 시간을 가져옴
- **마진**: 가용시간 ±1시간 (예: 14:00-18:00 → 13시~19시 표시)
- **레슨 고려**: 가용시간 밖에 레슨이 있으면 범위 확장
- **기본값**: 가용시간 미설정 시 08:00~18:00

### 현재 시간 표시 (Now Indicator)

- 오늘인 경우만 표시
- 빨간색 선 + 원형 노드 + 현재 시각 레이블
- 30초마다 자동 업데이트
- 자동 스크롤: 오늘 → now 위치, 다른 날 → 첫 레슨 위치

### 빈 영역 탭

- 빈 시간대를 탭하면 레슨 추가 화면으로 이동
- 날짜, 시간, 분이 자동으로 채워짐 (30분 단위 스냅)
- 기존 레슨 위에 탭하면 무시 (레슨 블록의 onTap이 처리)

### 레슨 블록 색상

| 상태 | 배경 | 악센트 |
|------|------|--------|
| 오늘 - 현재/예정 | 악기별 선명한 색상 | 악기별 진한 색상 |
| 오늘 - 지남 | 악기별 연한 색상 (alpha 0.5) | 악기별 연한 색상 (alpha 0.4) |
| 다른 날 | `scheduleMutedBackground` | `scheduleMutedAccent` |

### 레슨 블록 텍스트 (2줄)

```
Line 1: 이름  악기  시간분   (예: 지선  피아노  60분)
Line 2: 곡명                  (예: 쇼팽 녹턴)
```

- 이름은 `NameUtils.givenName()` 사용 (성 제거)
- 30분 레슨은 1줄만 표시 (compact mode)

---

## 주간 그리드 뷰

### 레이아웃

```
[CompactWeekStrip]         ← 공통 요일 스트립 (요일명 + 레슨 수 표시)
[Time Grid]                 ← 시간축 × 7일 그리드
[Now Indicator]             ← 오늘 열에 빨간 선 (Stack 오버레이)
[Summary Bar]               ← 이번 주 통계
```

> 별도 요일 헤더 없음 — CompactWeekStrip이 요일/날짜/레슨 수를 이미 표시

### 열(Column) 배경색 — 미니멀 팔레트 (§7.123 Mode A, 2026-04-27 갱신)

`TeacherAvailability` 의 `weeklySchedules` + `exceptions` 을 단일 톤으로 표현. 변별은 라벨 칩 + 1px 수직 디바이더(§7.122) 가 담당.

| 우선순위 | 상태 | 도메인 표현 | 컬럼 배경 | 라벨 칩 |
|---|---|---|---|---|
| 1 | **휴가 (다일)** | `TimeException(type=vacation)` | `ink alpha 0.10` (≈#DDD8CB warm dark gray) | "휴가" 칩 |
| 2 | **휴무 (단일)** | `TimeException(type=holiday)` | `ink alpha 0.10` | "휴무" 칩 |
| 3 | **정기 휴무일** | weeklySchedules 미등록 요일 | `ink alpha 0.10` | (라벨 없음) |
| 4 | **오늘** | `_DayType.today` | 투명 (헤더 칩으로 변별) | — |
| 5 | **과거/미래 평일** | 그 외 | 투명 | — |

> **Why ink alpha 0.10**: 종이 베이스(`#F2ECDD`, warm cream) 위 무채색 중성 회색(`#E8E8E8`) 은 동시대비로 cool/sky-blue 톤으로 인지됨. ink 알파 블렌딩은 종이 톤을 유지하면서 채도만 낮춰 warm dark gray 로 인지된다.
>
> **Why today 본문 톤 제거**: 헤더의 요일/날짜 칩이 이미 today 변별을 담당. 본문 톤 추가는 §1.3.2 평탄화(변동은 단일 채널) 위반.

### 셀(Slot) 단위 추가 톤 — §7.123 Mode A

| 상태 | 도메인 표현 | 셀 톤 | 클릭 |
|---|---|---|---|
| 추가 오픈 슬롯 (휴무 컬럼 위) | `TimeException(type=additionalSlot)` | `paper` (흰색 override) | 활성 |
| 그 외 (근무시간 내·외 무관) | — | 컬럼 배경 그대로 | 활성 (보강 가능) |

> **Why 근무시간 외 셀 톤 제거**: `ink alpha 0.03` 은 종이 위에서 거의 보이지 않아 시각 노이즈만 추가했다. 근무시간 경계는 사용자에게 의미 있는 시각 단서가 아님 (이미 빈 컬럼 = 휴무 컬럼으로 인지). 클릭은 그대로 활성 — 보강·시험 보충 슬롯 추가 가능.

### 라벨 칩 표시 (§7.123)

- 위치: 컬럼 상단(시간 그리드 첫 행 위), 가로 가운데 정렬
- 텍스트: "휴가", "휴무" (additionalSlot 은 컬럼 라벨 없음 — 슬롯 자체로 충분)
- 색상: `inkSecondary`, `AppTypography.captionSmall`, fontWeight w500
- 배경: 없음 (배경은 컬럼이 이미 회색)

### 현재 시간 표시 (Now Indicator)

- 오늘 열에만 빨간색 원 + 선 표시
- 일간 타임라인과 동일한 스타일
- 시간축 기반으로 정확한 위치에 오버레이

### 빈 영역 탭

- 주간 그리드의 빈 셀 탭 → 레슨 추가 (날짜+시간 자동 채움)
- 휴무/휴가 컬럼의 빈 셀도 클릭 활성 (보강 슬롯 등록 가능)

### 쉬는날·예외 감지

- **정기 휴무일**: `TeacherAvailability.weeklySchedules`에 `isActive` 스케줄이 없는 요일
- **단일 휴무**: `TeacherAvailability.exceptions` 중 `type=holiday` 이고 해당 날짜 `containsDate(date)`
- **다일 휴가**: `TeacherAvailability.exceptions` 중 `type=vacation` 이고 해당 날짜 `containsDate(date)`
- **추가 오픈**: `TeacherAvailability.exceptions` 중 `type=additionalSlot` 이고 startTime/endTime 으로 슬롯 범위 지정
- 우선순위: 휴가 > 휴무 > 정기 휴무일 (한 날짜에 복수 적용 시 가장 강한 라벨)

---

## 글로벌 색상 상수

| 상수명 | 값 | 용도 |
|--------|-----|------|
| `AppColors.scheduleMutedBackground` | #F5F5F5 | 비활성/과거 레슨 배경 |
| `AppColors.scheduleMutedAccent` | #BDBDBD | 비활성/과거 레슨 텍스트 |
| `AppColors.scheduleRestDayBackground` | #E8E8E8 | 쉬는날 열 배경 |

---

## 이름 표시 (글로벌 대응)

- `NameUtils.givenName()` 유틸리티 사용
- 한국어 이름: "박지선" → "지선" (성 제거)
- 서양 이름: "John Smith" → "John"
- CJK 이름 2-4자: 첫 글자 제거
- 단일 이름/단어: 그대로 반환

---

## 관련 파일

| 파일 | 변경 내용 |
|------|----------|
| `schedule_tab.dart` | 뷰 모드별 캘린더 분기, 공통 레이아웃 |
| `schedule_weekly_grid_view.dart` | 전면 재구성 (색상, 카운트, now indicator) |
| `schedule_timeline_view.dart` | 가용시간 기반 범위, hide 임포트 |
| `timeline_lesson_block.dart` | isToday 색상 로직, 2줄 텍스트 |
| `app_colors.dart` | scheduleRestDayBackground 추가 |
| `name_utils.dart` | 이름 추출 유틸리티 |

---

## 변경 이력

| 날짜 | 내용 |
|------|------|
| 2026-03-12 | 초안 작성 — 3가지 뷰 모드 UX 통합 설계 |
| 2026-03-12 | 주간 그리드: 요일 헤더 제거 (CompactWeekStrip과 중복), 배경색 단순화 (오늘만 하이라이트), 리스트 뷰 여백 추가 |
| 2026-03-13 | 학생/선생님 스케줄 분리 설계 명시 — 타임라인/주간 그리드는 선생님 전용 (Issue #154 취소) |
| 2026-04-27 | §7.123 4단 우선순위 도입 — vacation/holiday/regular/today + additionalSlot, 단일 색 + 라벨 칩 변별 |
| 2026-04-27 | §7.123 Mode A 색상 보정 — `scheduleRestDayBackground` 중성 회색 → `ink alpha 0.10` (동시대비 cool 회피), today 본문 톤 + 근무시간 외 셀 톤 제거 (§1.3.2 평탄화) |
