# 대안 시간 제안 개선 PAD

## GitHub Issues

| # | 이슈 | 차단 관계 |
|---|------|----------|
| #211 | 과거 시간 선택 차단 | 없음 (독립) |
| #212 | Lesson ↔ Subscription 연결 | 없음 (독립) |
| #213 | ClassMembership 스케줄 확장 (lessonSlots) | 없음 (독립) |
| #214 | 수강권 범위 밖 레슨 미리보기 | Blocked by #212, #213 |

```
#211 (과거 차단) ────────────────────→ 완료
#212 (Lesson↔Sub) ──────┐
                        ├──→ #214 (미리보기)
#213 (스케줄 확장) ──────┘
```

## 문제 정의

### 문제 1: 과거 시간 선택 가능

선생님이 대안 시간을 제안할 때 주간 네비게이션으로 과거 주로 이동하면, 과거 날짜의 빈 셀을 탭하여 "3/27(금) 12:00~13:00" 같은 과거 시간을 제안 슬롯으로 선택할 수 있다. 과거 시간에 레슨을 배정하는 것은 무의미하며 학생에게 혼란을 준다.

### 문제 2: 수강권 범위 밖 레슨 불가시

학생의 정규레슨 수강권이 한 달 단위(예: 3/1~3/30)인 경우, 4월 이후 주간 스케줄에는 해당 학생의 레슨이 표시되지 않는다. 그러나 실제로는 대부분의 정규 학생이 다음 달에도 동일 시간에 레슨을 이어가므로, 선생님이 대안 시간을 제안할 때 "4월에 이 시간은 비어있구나"라고 오판하여 이미 점유될 가능성이 높은 시간을 제안할 수 있다.

### 문제 2의 선행 조건

- `Lesson` 엔티티에 `subscriptionId`가 없어 레슨이 어떤 수강권에 속하는지 알 수 없다.
- `ClassMembership`에 `lessonDay`/`lessonTime`이 하나만 있어 주 2회 학생의 두 번째 요일/시간을 저장할 수 없다.

## 솔루션 개요

### A: 과거 시간 선택 차단

대안 제안 화면(`SuggestAlternativeScreen`)과 메인 주간 스케줄(`ScheduleWeeklyGridView`) 모두에서 과거 날짜/시간의 빈 셀을 회색 비활성 스타일로 표시하고 탭을 무시한다. 과거 주로의 네비게이션은 허용하여 선생님이 과거 패턴을 참고할 수 있게 한다.

### B: Lesson ↔ Subscription 연결

`Lesson` 엔티티에 `subscriptionId` 필드를 추가하여 각 레슨이 어떤 수강권으로 커버되는지 직접 참조할 수 있게 한다.

### C: ClassMembership 스케줄 확장

기존 `lessonDay`(String?), `lessonTime`(String?) 단일 필드를 제거하고 `lessonSlots: List<LessonSlot>`으로 교체한다. 주 1회든 2회든 N회든 유연하게 대응 가능한 구조.

### D: 수강권 범위 밖 레슨 미리보기

수강권이 커버하지 않는 기간의 정규 레슨 예상 시간을 연한 색 + 점선으로 표시한다. `ClassMembership.lessonSlots`에서 패턴을 읽어 가상 레슨 블록을 생성하고, 동일 시간에 실제 `Lesson`이 있으면 실선, 없으면 점선으로 렌더링을 분기한다.

## 유저 스토리

### 선생님 (대안 시간 제안)

- 선생님으로서 대안 시간을 제안할 때 과거 날짜/시간은 선택할 수 없어야 한다.
- 선생님으로서 과거 주의 스케줄을 참고용으로 볼 수 있어야 한다.
- 선생님으로서 다음 달에 수강권이 만료되는 학생의 예상 레슨 시간을 연한 색 점선으로 확인하여, 실제로 비어있을 가능성이 낮은 시간을 피해 대안을 제안할 수 있어야 한다.

### 선생님 (주간 스케줄)

- 선생님으로서 메인 주간 스케줄에서 수강권 범위를 넘긴 학생의 예상 레슨 시간을 연한 색 점선으로 확인할 수 있어야 한다.
- 선생님으로서 점선 레슨 블록을 탭하면 해당 학생 상세 화면으로 이동할 수 있어야 한다.

### 선생님 (학생 관리)

- 선생님으로서 주 2회 레슨 학생의 스케줄을 두 요일/시간 모두 정확하게 기록할 수 있어야 한다.

## 수용 기준

### 이슈 A: 과거 시간 선택 차단

- [ ] `SuggestAlternativeScreen`에서 과거 날짜의 빈 셀이 회색 비활성 스타일로 표시됨
- [ ] 오늘 날짜에서 현재 시간 이전 슬롯이 회색 비활성 스타일로 표시됨
- [ ] 비활성 셀을 탭해도 반응 없음 (콜백 미호출)
- [ ] 과거 주로 네비게이션 가능 (← 버튼 활성)
- [ ] 메인 `ScheduleWeeklyGridView`에서도 동일한 과거 비활성 동작 적용
- [ ] 이미 선택된 슬롯은 해당 주에서만 표시됨
- [ ] flutter analyze 에러 0

### 이슈 B: Lesson ↔ Subscription 연결

- [ ] `Lesson` 엔티티에 `subscriptionId: String?` 필드 추가
- [ ] Mock Lesson 데이터에 subscriptionId 반영
- [ ] `build_runner` 코드 생성 완료
- [ ] 기존 테스트 회귀 없음

### 이슈 C: ClassMembership 스케줄 확장

- [ ] `ClassMembership`에서 `lessonDay`, `lessonTime` 필드 제거
- [ ] `lessonSlots: List<LessonSlot>` 필드 추가
- [ ] `LessonSlot` 엔티티: `{dayOfWeek: int, startTime: String, endTime: String}`
- [ ] 주 2회 학생의 Mock 데이터에 2개의 LessonSlot 반영
- [ ] 기존에 `lessonDay`/`lessonTime`을 참조하던 코드 모두 `lessonSlots`로 마이그레이션
- [ ] `build_runner` 코드 생성 완료
- [ ] flutter analyze 에러 0

### 이슈 D: 수강권 범위 밖 레슨 미리보기

- [ ] `ClassMembership.lessonSlots` 기반으로 가상 레슨 블록 생성
- [ ] `Lesson.subscriptionId` → `Subscription.endDate`로 수강권 범위 판단
- [ ] 수강권 범위 내 레슨: 기존 실선 스타일
- [ ] 수강권 범위 밖 레슨: 연한 색 + 점선 스타일 (이름 + 악기 표시)
- [ ] `flexible` 스케줄 학생은 미리보기 없음
- [ ] 메인 `ScheduleWeeklyGridView`에서 미리보기 표시
- [ ] `SuggestAlternativeScreen`의 `AlternativeTimeGrid`에서도 동일 표시
- [ ] 점선 블록 탭 → 학생 상세 화면으로 이동
- [ ] 데이터는 항상 fetch, 렌더링만 수강권 범위에 따라 분기

## 구현 결정 사항

### 과거 판단 기준

```
과거 = (셀 날짜 < 오늘) OR (셀 날짜 == 오늘 AND 셀 시간 < 현재 시간)
```

대안 제안 화면과 메인 주간 스케줄 모두 동일 기준 적용. 기존 `_DayType` enum(past/today/future)에 시간 단위 판단을 추가하는 방식.

### Lesson ↔ Subscription 연결

`Lesson.subscriptionId`로 직접 참조. 체험레슨처럼 수강권 없이 생성된 레슨은 `null`. Backend 미운영 상태이므로 Mock 데이터만 업데이트.

### LessonSlot 구조

```dart
class LessonSlot {
  final int dayOfWeek;    // 0=Mon...6=Sun
  final String startTime; // "14:00"
  final String endTime;   // "15:00"
}
```

`ClassMembership.lessonDay`/`lessonTime` 완전 제거 후 `lessonSlots`로 교체. 하위 호환 없이 clean cut.

### 미리보기 데이터 흐름

1. `weekLessonsProvider`로 실제 레슨 fetch (기존)
2. `classMembershipsProvider`로 fixed 학생의 `lessonSlots` fetch
3. 각 학생의 `subscriptionId` → `Subscription.endDate` 조회
4. 해당 주의 각 요일에 lessonSlot 매칭 → 실제 Lesson 존재 여부 확인
5. 실제 Lesson 있음 + 수강권 범위 내 → 실선
6. 실제 Lesson 없음 OR 수강권 범위 밖 → 연한 점선

### 미리보기 렌더링

기존 `_DayType`에 의한 과거/오늘/미래 색상 구분에 더해, 레슨 블록 수준에서 `isPreview` 플래그를 추가:
- `isPreview: false` → 기존 실선 렌더링
- `isPreview: true` → 연한 색(opacity 0.4) + 점선 border (`strokeAlign: BorderSide.strokeAlignInside`)

## 영향받는 모듈

### 이슈 A

| 모듈 | 변경 |
|------|------|
| `schedule/presentation/widgets/alternative_time_grid.dart` | `onEmptyCellTap` 호출 전 과거 판단 + 회색 비활성 스타일 |
| `schedule/presentation/widgets/schedule_weekly_grid_view.dart` | 빈 셀 탭 시 과거 차단 로직 추가 |

### 이슈 B

| 모듈 | 변경 |
|------|------|
| `lessons/domain/entities/lesson.dart` | `subscriptionId: String?` 필드 추가 |
| `lessons/data/repositories/mock_lesson_repository.dart` | Mock 데이터에 subscriptionId 반영 |

### 이슈 C

| 모듈 | 변경 |
|------|------|
| `students/domain/entities/class_membership.dart` | `lessonDay`/`lessonTime` 제거, `lessonSlots` 추가 |
| `students/domain/entities/lesson_slot.dart` | **신규** — LessonSlot 엔티티 |
| `students/data/repositories/mock_student_repository.dart` | Mock 데이터 마이그레이션 |
| `lessonDay`/`lessonTime` 참조 코드 전체 | `lessonSlots`로 교체 |

### 이슈 D

| 모듈 | 변경 |
|------|------|
| `schedule/presentation/providers/week_lessons_provider.dart` | 미리보기 블록 생성 로직 추가 |
| `schedule/presentation/widgets/schedule_weekly_grid_view.dart` | `isPreview` 렌더링 분기 |
| `schedule/presentation/widgets/alternative_time_grid.dart` | 동일 미리보기 렌더링 |
