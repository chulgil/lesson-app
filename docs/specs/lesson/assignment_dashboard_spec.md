# 과제 현황 대시보드 스펙

> 구현 상태: ✅ 구현 완료
> 작성일: 2026-03-07
> 마지막 업데이트: 2026-03-11
> 상태: Phase 1-3 구현 완료
> 이슈: [#67](https://github.com/chulgil/lesson-app/issues/67), [#101](https://github.com/chulgil/lesson-app/issues/101) (closed)
> 관련 문서: [teacher_ux_review.md](../design/teacher_ux_review.md), [lesson_note_spec.md](lesson_note_spec.md)
> 엔티티: [practice_item.dart](../../../frontend/lib/features/practice/domain/entities/practice_item.dart)

---

## 1. 개요

### 1.1 배경

선생님이 "이번 주 학생들 과제 현황"을 한눈에 볼 수 없음.
현재는 레슨 상세 > 과제 탭에서만 개별 학생별로 확인 가능 (N번 탐색 필요).
경쟁사(Tonara, My Music Staff)는 과제 대시보드를 제공.

### 1.2 목표

- 선생님이 홈 탭에서 전체 학생 과제 완료율을 한눈에 파악
- 과제 미완료 학생을 빠르게 식별하여 독려 가능

### 1.3 핵심 결정사항

| 항목 | 결정 |
|------|------|
| 위치 | 홈 탭 대시보드 - "오늘의 레슨" 섹션 위 |
| 데이터 | `PracticeItem` 엔티티 (isCompleted 기준) |
| 범위 | 이번 주 과제 (최근 7일 내 레슨에서 할당된 과제) |
| 상세 진입 | 학생 이름 탭 -> 학생 상세 화면 |

---

## 2. 화면 설계

### 2.1 홈 탭 내 과제 현황 섹션

```
+-------------------------------------------+
| 과제 현황                       [전체보기] |
+-------------------------------------------+
| 이번 주 완료율                             |
| [=========>          ] 65% (13/20)        |
|                                           |
| 미완료 학생                                |
| +---------------------------------------+ |
| | [김] 김민수  스케일 3회 연습   0/3     | |
| | [박] 박철수  비브라토 10분     미시작   | |
| +---------------------------------------+ |
+-------------------------------------------+
```

### 2.2 UI 구성 요소

| 요소 | 설명 |
|------|------|
| 진행률 바 | LinearProgressIndicator - 전체 완료율 |
| 미완료 리스트 | 미완료 과제가 있는 학생 (최대 3명, 긴급도순) |
| 전체보기 버튼 | `AssignmentDashboardScreen`으로 이동 (✅ 전용 화면 구현 완료) |

### 2.3 색상 규칙

| 완료율 | 색상 |
|--------|------|
| 80% 이상 | AppColors.success (green) |
| 50-79% | AppColors.warning (orange) |
| 50% 미만 | AppColors.error (red) |

---

## 3. 데이터 흐름

### 3.1 기존 Provider 활용

| Provider | 용도 | 파일 |
|----------|------|------|
| `practiceItemsByStudentProvider` | 학생별 과제 목록 | practice_item_providers.dart |

### 3.2 신규 Provider

```dart
// 이번 주 전체 과제 현황 (홈 대시보드용)
@riverpod
Future<WeeklyAssignmentSummary> weeklyAssignmentSummary(
  WeeklyAssignmentSummaryRef ref,
  String teacherId,
) async {
  // teacherId로 학생 목록 조회 -> 각 학생의 미완료 PracticeItem 집계
}
```

**WeeklyAssignmentSummary 모델**:

```dart
class WeeklyAssignmentSummary {
  final int totalItems;       // 전체 과제 수
  final int completedItems;   // 완료된 과제 수
  final List<StudentAssignmentStatus> incompleteStudents; // 미완료 학생 목록
}

class StudentAssignmentStatus {
  final String studentId;
  final String studentName;
  final int totalItems;
  final int completedItems;
  final PracticeItem? mostUrgentItem; // 가장 긴급한 미완료 과제
}
```

---

## 4. 구현 계획

### Phase 1: Provider + 모델 (MVP)

1. `WeeklyAssignmentSummary` 모델 생성
2. `weeklyAssignmentSummaryProvider` 구현
3. Mock repository에서 데이터 집계 로직 구현

### Phase 2: UI 위젯

1. `AssignmentSummarySection` 위젯 생성
2. 홈 탭 대시보드에 삽입 (즉시 확인 필요 아래, 오늘의 레슨 위)
3. 진행률 바 + 미완료 학생 리스트 구현

### Phase 3: 상호작용

1. 학생 이름 탭 -> 학생 상세 이동
2. "전체보기" -> 학생 탭 이동 (향후 전용 화면)

---

## 5. 관련 파일

| 파일 | 역할 | 상태 |
|------|------|:----:|
| `practice/domain/entities/practice_item.dart` | PracticeItem 엔티티 | ✅ |
| `practice/presentation/providers/practice_item_providers.dart` | 기존 Provider | ✅ |
| `home/presentation/providers/assignment_summary_provider.dart` | WeeklyAssignmentSummary 모델 + Provider | ✅ |
| `home/presentation/widgets/assignment_summary_section.dart` | 홈 탭 과제 요약 위젯 (전체보기 버튼 포함) | ✅ |
| `home/presentation/screens/assignment_dashboard_screen.dart` | 과제 전용 대시보드 화면 | ✅ |
| `lessons/presentation/widgets/practice_items_section.dart` | 레슨별 과제 UI | ✅ |
| 라우트: `AppRoutes.assignmentDashboard = '/assignments'` | home_routes.dart에 등록 | ✅ |

---

## 6. 변경 이력

| 날짜 | 변경 내용 |
|------|----------|
| 2026-03-11 | 구현 완료 반영 (#101). 전용 대시보드 화면 추가, 전체보기 버튼 연결, 관련 파일 업데이트 |
| 2026-03-07 | 초기 스펙 작성 |
