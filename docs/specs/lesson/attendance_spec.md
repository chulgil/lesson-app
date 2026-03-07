# 출석 관리 스펙

> 작성일: 2026-03-07
> 상태: 스펙 작성 완료, 구현 대기
> 이슈: [#73](https://github.com/chulgil/lesson-app/issues/73)

---

## 1. 개요

레슨 출석 상태를 체계적으로 관리하고, 수강권 차감 규칙과 연동하여 선생님의 출결 관리 부담을 최소화하는 시스템.

### 1.1 현재 상태

기존 `LessonStatus` enum에 출석 관련 상태가 이미 정의되어 있으나, 전용 출석 관리 UI가 없음.

```dart
// 현재 lesson.dart의 LessonStatus
enum LessonStatus {
  scheduled,
  completed,                    // 출석 (완료)
  cancelled,                    // 취소 (레거시)
  cancelledByStudentAdvance,    // 학생 사전 취소 (24h+, 미차감)
  cancelledByStudentLate,       // 학생 당일 취소 (차감)
  cancelledByTeacher,           // 선생님 취소 (미차감)
  cancelledMutual,              // 합의 취소 (미차감)
  noShow,                       // 노쇼 (레거시)
  studentAbsent,                // 결석 (차감)
  reschedulePending,            // 변경 대기
}
```

### 1.2 문제점

| 문제 | 설명 |
|------|------|
| 출석 확인 UI 없음 | 레슨 완료 후 출석 상태를 변경하려면 레슨 상세로 진입해야 함 |
| 일괄 출석 처리 불가 | 그룹 레슨 시 학생별 출석을 하나씩 처리해야 함 |
| 출석 통계 없음 | 학생별/월별 출석률을 확인할 수 없음 |

---

## 2. 출석 상태 매핑

### 2.1 LessonStatus → 출석 상태

| LessonStatus | 출석 표시 | 수강권 차감 | 비고 |
|:------------|:--------:|:---------:|------|
| `completed` | 출석 | O | 정상 완료 |
| `cancelledByStudentAdvance` | - (취소) | X | 사전 취소, 출석 대상 아님 |
| `cancelledByStudentLate` | 결석 | O | 당일 취소 = 차감 |
| `cancelledByTeacher` | - (취소) | X | 선생님 사유, 출석 대상 아님 |
| `cancelledMutual` | - (취소) | X | 합의, 출석 대상 아님 |
| `studentAbsent` | 결석 | O | 무단 결석 |
| `noShow` | 결석 | O | 연락 없이 불참 |
| `scheduled` | 예정 | - | 아직 미진행 |
| `reschedulePending` | 예정 | - | 변경 대기 |

### 2.2 출석 판정 기준

```
레슨 예정 시간 도래
    |
    +-- 선생님이 레슨 노트 작성 → completed (출석)
    |
    +-- 선생님이 "미진행" 선택
    |       |
    |       +-- 학생 결석 → studentAbsent (차감)
    |       +-- 학생 노쇼 → noShow (차감)
    |       +-- 학생 당일 취소 → cancelledByStudentLate (차감)
    |       +-- 선생님 사유 → cancelledByTeacher (미차감)
    |       +-- 합의 취소 → cancelledMutual (미차감)
    |
    +-- 24시간 경과 (미확인) → completed (자동 출석 처리)
```

---

## 3. 화면 설계

### 3.1 레슨 후 출석 확인 (Quick Action)

**진입 경로**: 홈 > "즉시 확인 필요" > 레슨 확인 알림, 또는 스케줄 탭 > 완료된 레슨 카드

```
+-----------------------------------------------+
| 레슨 확인                              [X]     |
+-----------------------------------------------+
|                                               |
|  3/7(금) 14:00 김민수 바이올린                  |
|                                               |
|  +-------------------+  +-------------------+ |
|  | [v] 레슨 완료      |  | [x] 미진행        | |
|  |  수강권 1회 차감    |  |  사유 선택 필요    | |
|  +-------------------+  +-------------------+ |
|                                               |
+-----------------------------------------------+
```

### 3.2 그룹 레슨 일괄 출석

**진입 경로**: 스케줄 탭 > 그룹 레슨 카드 > 출석 관리

```
+-----------------------------------------------+
| < 토요 초급반 출석       3/7(토) 10:00          |
+-----------------------------------------------+
|                                               |
| [전체 출석] [전체 결석]                         |
|                                               |
| +-------------------------------------------+ |
| | 김민수     바이올린   [출석 v]  결석  노쇼  | |
| +-------------------------------------------+ |
| | 이서연     바이올린   [출석 v]  결석  노쇼  | |
| +-------------------------------------------+ |
| | 박지호     첼로       출석  [결석 v]  노쇼  | |
| +-------------------------------------------+ |
| | 최유진     바이올린   출석  결석  [노쇼 v]  | |
| +-------------------------------------------+ |
|                                               |
|  출석 2명 / 결석 1명 / 노쇼 1명                |
|                                               |
|              [출석 확정]                        |
+-----------------------------------------------+
```

### 3.3 출석 통계 (학생별)

**진입 경로**: 학생 상세 > 출석 섹션, 또는 통계 대시보드

```
+-----------------------------------------------+
| 출석 현황                     [3개월 v]         |
+-----------------------------------------------+
|                                               |
| 출석률  ████████████████████░░  92%            |
|         22회 출석 / 24회 중                     |
|                                               |
| [월별 상세]                                    |
| +--------+------+------+------+------+        |
| |  월    | 예정 | 출석 | 결석 | 취소 |        |
| +--------+------+------+------+------+        |
| | 3월   |   8  |   7  |   1  |   0  |        |
| | 2월   |   8  |   8  |   0  |   0  |        |
| | 1월   |   8  |   7  |   0  |   1  |        |
| +--------+------+------+------+------+        |
|                                               |
+-----------------------------------------------+
```

### 3.4 선생님 전체 출석 현황

**진입 경로**: 통계 대시보드 > 출석률 카드

```
+-----------------------------------------------+
| < 출석 현황                    [이번 달 v]      |
+-----------------------------------------------+
|                                               |
| 전체 출석률  95.2% (38/40)                     |
|                                               |
| [학생별 출석률]                                 |
| +-------------------------------------------+ |
| | 김민수  ████████████████████  100% (8/8)  | |
| | 이서연  ██████████████████░░   88% (7/8)  | |
| | 박지호  ████████████████░░░░   75% (6/8)  | |
| +-------------------------------------------+ |
|                                               |
| [결석/노쇼 이력]                                |
| 3/7  박지호 - 노쇼 (수강권 차감)               |
| 3/3  이서연 - 결석 (수강권 차감)               |
|                                               |
+-----------------------------------------------+
```

---

## 4. Provider 설계

```dart
// 학생별 출석 통계
@riverpod
Future<AttendanceStats> studentAttendanceStats(
  Ref ref, {
  required String studentId,
  required AttendancePeriod period,
}) async { ... }

// 선생님 전체 출석 현황
@riverpod
Future<TeacherAttendanceOverview> teacherAttendanceOverview(
  Ref ref, {required DateTime month}
) async { ... }

// 그룹 레슨 출석 목록
@riverpod
Future<List<GroupAttendanceEntry>> groupLessonAttendance(
  Ref ref, {required String lessonClassId, required DateTime date}
) async { ... }
```

### 4.1 주요 모델

```dart
class AttendanceStats {
  final int totalScheduled;   // 예정된 총 레슨
  final int attended;          // 출석
  final int absent;            // 결석 (studentAbsent + noShow + cancelledByStudentLate)
  final int cancelledByOther;  // 선생님/합의 취소 (출석 대상 아님)
  final List<MonthlyAttendance> monthly;

  double get attendanceRate =>
    totalScheduled - cancelledByOther > 0
      ? attended / (totalScheduled - cancelledByOther)
      : 0;
}

class MonthlyAttendance {
  final DateTime month;
  final int scheduled;
  final int attended;
  final int absent;
  final int cancelled;
}

class GroupAttendanceEntry {
  final String studentId;
  final String studentName;
  final String instrument;
  final AttendanceType type; // attended, absent, noShow
}

enum AttendanceType { attended, absent, noShow }

enum AttendancePeriod { oneMonth, threeMonths, sixMonths, oneYear }
```

---

## 5. 수강권 차감 연동

> 상세 정책: [lesson_cancellation_policy.md](../subscription/lesson_cancellation_policy.md)

### 5.1 차감 규칙 요약

| 출석 상태 | 수강권 차감 | 조건 |
|----------|:---------:|------|
| 출석 (completed) | O | 정상 |
| 결석 (studentAbsent) | O | 무단 결석 |
| 노쇼 (noShow) | O | 연락 없이 불참 |
| 당일 취소 (cancelledByStudentLate) | O | 24시간 이내 취소 |
| 사전 취소 (cancelledByStudentAdvance) | X | 24시간 이전 취소 |
| 선생님 취소 (cancelledByTeacher) | X | 선생님 사유 |
| 합의 취소 (cancelledMutual) | X | 상호 합의 |

### 5.2 자동 차감 플로우

```
출석 확정 (completed / studentAbsent / noShow / cancelledByStudentLate)
    |
    +-- 해당 학생의 활성 수강권 조회
    |
    +-- remainingCount > 0 → remainingCount -= 1
    |
    +-- remainingCount == 0 → "수강권 소진" 알림 발송
```

---

## 6. 구현 계획

### Phase 1: 레슨 후 출석 확인 (MVP)

| 항목 | 설명 |
|------|------|
| Quick Action | 레슨 종료 후 출석/미진행 선택 UI |
| 미진행 사유 선택 | BottomSheet로 사유 선택 |
| 수강권 자동 차감 | 출석 확정 시 차감 로직 |

### Phase 2: 통계 + 그룹 출석

| 항목 | 설명 |
|------|------|
| 학생별 출석 통계 | 학생 상세에 출석 섹션 추가 |
| 그룹 레슨 일괄 출석 | 한 화면에서 전체 학생 출석 처리 |
| 선생님 전체 출석 현황 | 통계 대시보드 연동 |

### Phase 3: 알림 + 자동화

| 항목 | 설명 |
|------|------|
| 출석 미확인 알림 | 레슨 종료 30분 후 미확인 시 알림 |
| 24시간 자동 처리 | 미확인 레슨 자동 완료 처리 |
| 결석 패턴 감지 | 연속 결석 시 선생님에게 알림 |

---

## 7. 위젯 구조

### 7.1 AttendanceConfirmationSheet (BottomSheet)

레슨 종료 후 출석 여부를 빠르게 확정하는 BottomSheet. 스케줄 카드 또는 알림에서 진입.

```
AttendanceConfirmationSheet (showModalBottomSheet)
├── _LessonInfoHeader
│   ├── Text: 날짜 + 시간 (e.g. "3/7(금) 14:00")
│   ├── Text: 학생 이름
│   └── Text: 악기명
├── _ActionButtons (Row)
│   ├── _CompletedButton ("레슨 완료")
│   │   └── 탭 시: status → completed, 수강권 1회 차감, sheet 닫기
│   └── _NotCompletedButton ("미진행")
│       └── 탭 시: _AbsenceReasonSelector 표시
└── _AbsenceReasonSelector (AnimatedSwitcher, 미진행 선택 시만 표시)
    ├── RadioListTile: studentAbsent ("학생 결석 - 수강권 차감")
    ├── RadioListTile: noShow ("노쇼 - 수강권 차감")
    ├── RadioListTile: cancelledByStudentLate ("학생 당일 취소 - 수강권 차감")
    ├── RadioListTile: cancelledByTeacher ("선생님 사유 취소 - 미차감")
    ├── RadioListTile: cancelledMutual ("합의 취소 - 미차감")
    └── ElevatedButton: "확정" (사유 선택 후 활성화)
```

| 속성 | 타입 | 설명 |
|------|------|------|
| `lesson` | `Lesson` | 대상 레슨 객체 |
| `onConfirmed` | `void Function(LessonStatus)` | 출석 확정 콜백 |

**데이터 소스**: `lessonDetailProvider(lessonId)` — 레슨 정보 조회. 확정 시 `attendanceConfirmProvider`를 통해 상태 변경 + 수강권 차감.

**표시 형식**: 차감 대상 사유는 빨간 텍스트로 "(수강권 차감)" 표시, 미차감 사유는 회색 텍스트로 "(미차감)" 표시.

---

### 7.2 GroupAttendanceScreen (전체 화면)

그룹 레슨의 학생 전원을 한 화면에서 일괄 출석 처리하는 화면.

```
GroupAttendanceScreen (Scaffold)
├── AppBar
│   ├── leading: BackButton
│   ├── title: Text (클래스명 + 날짜/시간)
│   └── actions: [] (없음)
├── Column
│   ├── _BulkActionBar (Padding + Row)
│   │   ├── OutlinedButton: "전체 출석" → 모든 학생 attended로 변경
│   │   └── OutlinedButton: "전체 결석" → 모든 학생 absent로 변경
│   ├── Expanded > ListView.separated
│   │   └── _StudentAttendanceRow (per student)
│   │       ├── CircleAvatar: 학생 프로필 이미지
│   │       ├── Column
│   │       │   ├── Text: 학생 이름 (bold)
│   │       │   └── Text: 악기명 (caption, grey)
│   │       └── SegmentedButton<AttendanceType>
│   │           ├── Segment: "출석" (attended) — 선택 시 초록
│   │           ├── Segment: "결석" (absent) — 선택 시 빨강
│   │           └── Segment: "노쇼" (noShow) — 선택 시 회색
│   ├── Divider
│   ├── _SummaryFooter (Padding + Row)
│   │   ├── Text: "출석 N명"  (초록)
│   │   ├── Text: "결석 N명"  (빨강)
│   │   └── Text: "노쇼 N명"  (회색)
│   └── SafeArea > Padding
│       └── ElevatedButton.wide: "출석 확정" (모든 학생 선택 완료 시 활성화)
```

| 속성 | 타입 | 설명 |
|------|------|------|
| `lessonClassId` | `String` | 그룹 레슨 클래스 ID |
| `date` | `DateTime` | 해당 레슨 날짜 |

**데이터 소스**: `groupLessonAttendanceProvider(lessonClassId, date)` — 학생 목록 + 현재 출석 상태 조회. 확정 시 `groupAttendanceConfirmProvider`를 통해 일괄 상태 변경 + 수강권 차감.

**표시 형식**: SegmentedButton 색상 — 출석: `AppColors.success` (초록), 결석: `AppColors.error` (빨강), 노쇼: `AppColors.grey` (회색). 미선택 학생이 있으면 "출석 확정" 버튼 비활성화.

---

### 7.3 AttendanceStatsSection (학생 상세 내 위젯)

학생 상세 화면에 삽입되는 출석 통계 섹션. 출석률, 월별 상세, 결석 이력을 표시.

```
AttendanceStatsSection (Column)
├── _SectionHeader (Row)
│   ├── Text: "출석 현황" (sectionTitle)
│   └── DropdownButton<AttendancePeriod>: 기간 선택 (1/3/6/12개월)
├── SizedBox(h: 16)
├── _AttendanceRateBar (Column)
│   ├── Row
│   │   ├── Text: "출석률" (label)
│   │   └── Text: "92%" (bold, 색상은 rate에 따라 변경)
│   ├── LinearProgressIndicator
│   │   ├── value: attendanceRate (0.0~1.0)
│   │   └── color: rate >= 0.9 → success, >= 0.7 → warning, < 0.7 → error
│   └── Text: "22회 출석 / 24회 중" (caption)
├── SizedBox(h: 24)
├── _MonthlyTable (Table)
│   ├── TableRow (header): 월 | 예정 | 출석 | 결석 | 취소
│   └── TableRow (per month): 데이터 행
├── SizedBox(h: 24)
└── _AbsenceHistoryList (Column)
    ├── Text: "결석/노쇼 이력" (subtitle)
    └── ListView (shrinkWrap, NeverScrollableScrollPhysics)
        └── _AbsenceHistoryTile (per entry)
            ├── Text: 날짜 (e.g. "3/7")
            ├── Text: 사유 (e.g. "노쇼")
            └── Text: "수강권 차감" or "미차감" (badge)
```

| 속성 | 타입 | 설명 |
|------|------|------|
| `studentId` | `String` | 학생 ID |
| `initialPeriod` | `AttendancePeriod` | 초기 조회 기간 (기본: threeMonths) |

**데이터 소스**: `studentAttendanceStatsProvider(studentId, period)` — `AttendanceStats` 반환. 기간 변경 시 provider를 family 파라미터로 재호출.

**표시 형식**: 출석률 색상 기준 — 90% 이상: `AppColors.success`, 70~89%: `AppColors.warning`, 70% 미만: `AppColors.error`. 결석 이력은 최근 순 정렬, 최대 10건 표시.

---

## 8. Mock 데이터 설계

### 8.1 AttendanceStats Mock

```dart
final mockAttendanceStats = AttendanceStats(
  totalScheduled: 24,
  attended: 22,
  absent: 2,
  cancelledByOther: 0,
  monthly: [
    MonthlyAttendance(
      month: DateTime(2026, 3),
      scheduled: 8,
      attended: 7,
      absent: 1,
      cancelled: 0,
    ),
    MonthlyAttendance(
      month: DateTime(2026, 2),
      scheduled: 8,
      attended: 8,
      absent: 0,
      cancelled: 0,
    ),
    MonthlyAttendance(
      month: DateTime(2026, 1),
      scheduled: 8,
      attended: 7,
      absent: 1,
      cancelled: 0,
    ),
  ],
);
// attendanceRate = 22 / (24 - 0) = 91.7%
```

### 8.2 MonthlyAttendance Mock (6개월 확장)

```dart
final mockMonthlyAttendanceExtended = [
  MonthlyAttendance(month: DateTime(2026, 3), scheduled: 8, attended: 7, absent: 1, cancelled: 0),
  MonthlyAttendance(month: DateTime(2026, 2), scheduled: 8, attended: 8, absent: 0, cancelled: 0),
  MonthlyAttendance(month: DateTime(2026, 1), scheduled: 8, attended: 7, absent: 0, cancelled: 1),
  MonthlyAttendance(month: DateTime(2025, 12), scheduled: 7, attended: 6, absent: 1, cancelled: 0),
  MonthlyAttendance(month: DateTime(2025, 11), scheduled: 8, attended: 8, absent: 0, cancelled: 0),
  MonthlyAttendance(month: DateTime(2025, 10), scheduled: 8, attended: 7, absent: 1, cancelled: 0),
];
```

### 8.3 GroupAttendanceEntry Mock (4명 혼합 상태)

```dart
final mockGroupAttendance = [
  GroupAttendanceEntry(
    studentId: 'student-001',
    studentName: '김민수',
    instrument: '바이올린',
    type: AttendanceType.attended,
  ),
  GroupAttendanceEntry(
    studentId: 'student-002',
    studentName: '이서연',
    instrument: '바이올린',
    type: AttendanceType.attended,
  ),
  GroupAttendanceEntry(
    studentId: 'student-003',
    studentName: '박지호',
    instrument: '첼로',
    type: AttendanceType.absent,
  ),
  GroupAttendanceEntry(
    studentId: 'student-004',
    studentName: '최유진',
    instrument: '바이올린',
    type: AttendanceType.noShow,
  ),
];
// 출석 2명, 결석 1명, 노쇼 1명
```

### 8.4 AbsenceHistory Mock (결석/노쇼 이력)

```dart
final mockAbsenceHistory = [
  AbsenceHistoryEntry(
    date: DateTime(2026, 3, 7),
    studentName: '박지호',
    reason: LessonStatus.noShow,
    deducted: true,
  ),
  AbsenceHistoryEntry(
    date: DateTime(2026, 3, 3),
    studentName: '이서연',
    reason: LessonStatus.studentAbsent,
    deducted: true,
  ),
  AbsenceHistoryEntry(
    date: DateTime(2026, 2, 14),
    studentName: '김민수',
    reason: LessonStatus.cancelledByTeacher,
    deducted: false,
  ),
];
```

---

## 9. 구현 파일 위치

```
features/lessons/
├── domain/entities/
│   └── attendance.dart                          # AttendanceStats, MonthlyAttendance,
│                                                # GroupAttendanceEntry, AbsenceHistoryEntry,
│                                                # AttendanceType, AttendancePeriod
├── data/repositories/
│   └── mock_attendance_repository.dart          # Mock 데이터 + Repository 구현
└── presentation/
    ├── screens/
    │   └── group_attendance_screen.dart          # 그룹 레슨 일괄 출석 화면
    ├── widgets/
    │   ├── attendance_confirmation_sheet.dart    # 레슨 후 출석 확인 BottomSheet
    │   └── attendance_stats_section.dart         # 학생 상세 출석 통계 섹션
    └── providers/
        └── attendance_providers.dart             # studentAttendanceStatsProvider,
                                                  # groupLessonAttendanceProvider,
                                                  # attendanceConfirmProvider,
                                                  # groupAttendanceConfirmProvider

features/students/
└── presentation/widgets/
    └── student_detail/
        └── student_attendance_section.dart       # 학생 상세 화면에 AttendanceStatsSection 삽입하는 래퍼

features/analytics/  (Phase 2 - 통계 대시보드 연동)
```

**파일별 역할 요약**:

| 파일 | 역할 | 의존 Provider |
|------|------|--------------|
| `attendance.dart` | 엔티티/모델 정의 | - |
| `mock_attendance_repository.dart` | Mock 데이터 반환, Repository 인터페이스 + 구현 | - |
| `attendance_confirmation_sheet.dart` | 개별 레슨 출석 확인 UI | `attendanceConfirmProvider` |
| `group_attendance_screen.dart` | 그룹 일괄 출석 UI | `groupLessonAttendanceProvider`, `groupAttendanceConfirmProvider` |
| `attendance_stats_section.dart` | 출석 통계 표시 위젯 | `studentAttendanceStatsProvider` |
| `attendance_providers.dart` | 모든 출석 관련 Provider 정의 | `attendanceRepositoryProvider` |
| `student_attendance_section.dart` | 학생 상세에서 AttendanceStatsSection을 호출하는 래퍼 | `studentAttendanceStatsProvider` |

---

## 10. 경쟁사 벤치마크

### 10.1 StudioMate (스튜디오메이트)

| 항목 | 내용 |
|------|------|
| 출석 방식 | 일괄 출석 토글 — 학생 리스트에서 한 번 탭으로 출석/결석 전환 |
| 색상 코딩 | 출석 = 초록, 결석 = 빨강, 노쇼 = 회색 |
| 장점 | 직관적 토글 UI, 빠른 일괄 처리 |
| 한계 | 수강권 차감과 별도 관리 — 출석 처리와 차감이 분리되어 누락 위험 |

### 10.2 My Music Staff

| 항목 | 내용 |
|------|------|
| 출석 방식 | 자동 출석 처리 — 레슨 종료 24시간 후 미확인 시 자동 "완료" 처리 |
| 통계 | 월별 출석 리포트 PDF 내보내기 지원 |
| 장점 | 선생님이 매번 확인하지 않아도 되는 편의성 |
| 한계 | 실제 결석을 놓칠 수 있음 — 자동 완료 후 수정이 번거로움 |

### 10.3 Lessonaza 차별점

| 비교 항목 | 경쟁사 | Lessonaza |
|----------|--------|-----------|
| 수강권 연동 | 출석과 차감이 별도 시스템 | 출석 확정 즉시 수강권 자동 차감/미차감 분기 |
| 미진행 사유 | 단순 결석/출석 2분류 | 5단계 세분화 (학생 결석, 노쇼, 당일 취소, 선생님 취소, 합의 취소) |
| 차감 투명성 | 차감 여부를 별도 확인 필요 | 사유 선택 시 "(수강권 차감)" / "(미차감)" 즉시 표시 |
| 자동화 | 자동 완료만 지원 | 자동 완료 + 결석 패턴 감지 + 수강권 소진 알림 |
| 그룹 레슨 | 기본 일괄 처리 | SegmentedButton으로 학생별 3분류(출석/결석/노쇼) + 전체 일괄 토글 |

---

## 11. 관련 문서

| 문서 | 역할 |
|------|------|
| [lesson_cancellation_policy.md](../subscription/lesson_cancellation_policy.md) | 취소/차감 정책 상세 |
| [analytics_dashboard_spec.md](../analytics/analytics_dashboard_spec.md) | 통계 대시보드 (출석률 포함) |
| [teacher_ux_review.md](../design/teacher_ux_review.md) | UX 검토 (섹션 6.2 우선순위 2위) |

---

## 변경 이력

| 날짜 | 변경 내용 |
|------|----------|
| 2026-03-07 | 위젯 구조, Mock 데이터 설계, 구현 파일 위치 상세화, 경쟁사 벤치마크 추가 |
| 2026-03-07 | 초안 작성 (이슈 #73) |
